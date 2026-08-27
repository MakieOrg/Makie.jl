# RayMakie / Lava: LavaArray pass-through for Makie's conversion + bounds path.
#
# When a user passes a Mantle.LavaArray{Point3f, 1} as `positions` (or any
# Point-typed array attribute) to a Makie plot, the default Makie pipeline
# contains scalar-iteration sites that will error or warn on a GPU array:
#
#   - Makie.extrema_nan uses explicit iterate(itr) -- hits for any positions
#     passed to colorrange computation.
#   - Makie.iterate_transformed at boundingbox.jl:140 calls
#     filter(p -> !is_clipped(...), apply_transform_and_model(plot, points)).
#     GPUArrays.jl's filter uses boolean logical indexing which is broken for
#     LavaArray (errors with BoundsError), so we need to short-circuit.
#   - Makie.convert_single_argument / convert_arguments / float_convert /
#     el32convert: existing Makie methods already handle canonical
#     LavaArray{Point{N,Float32}} correctly (pass-through), but we add explicit
#     overloads so non-canonical eltypes error loudly instead of silently
#     attempting CPU element-type conversion.
#
# These overloads short-circuit the above paths for canonical
# LavaArray{Point{N, Float32}} and replace iterate-based bounds computation
# with AK.mapreduce-based equivalents that stay on the GPU.
#
# Non-canonical eltypes (e.g., LavaArray{Point3{Float64}}) error loudly --
# silent CPU element-type conversion is not supported. Caller must convert
# to canonical Point3f on the GPU side before constructing the LavaArray.

import Makie
# `Mantle`, not `Lava`: the host array and the backend moved with the runtime
# on 2026-08-27. `LavaDeviceArray` — the device-side one — stayed with the
# compiler, which is the whole shape of the split in one line.
import Mantle: LavaArray, LavaBackend
import AcceleratedKernels as AK
using GeometryBasics: Point

# --- Conversion path ----------------------------------------------------------

# Canonical pass-through for Point{N, Float32}.
# Non-canonical eltype: error rather than silently iterating on CPU.
function Makie.convert_single_argument(a::LavaArray{<:Point{N, T}, 1}) where {N, T}
    T === Float32 || error(
        "RayMakie: positions LavaArray must have eltype Point{N, Float32}; " *
        "got Point{$N, $T}. Convert on the GPU side before passing to Makie " *
        "(`LavaArray(Point3f.(...))` or an explicit kernel) -- silent CPU " *
        "element-type conversion is not supported.")
    return a
end

# PointBased recipes (Scatter, MeshScatter, Lines, ...) take an
# AbstractVector{<:VecTypes{N,T}}.  Provide a direct overload that bypasses
# the elconvert chain entirely.
function Makie.convert_arguments(::Makie.PointBased, positions::LavaArray{<:Point{N, Float32}, 1}) where {N}
    N in (2, 3) || throw(ArgumentError("Only 2D and 3D points are supported; got $N-D."))
    return (positions,)
end

# float_convert and el32convert are identity on canonical Point{N, Float32}.
# Providing explicit overloads prevents the fallback `elconvert` chain from
# attempting a convert(AbstractArray{...}, ::LavaArray) round-trip.
Makie.float_convert(x::LavaArray{<:Point{N, Float32}, 1}) where {N} = x
Makie.el32convert(x::LavaArray{<:Point{N, Float32}, 1}) where {N} = x

# --- Bounds computation -------------------------------------------------------

# extrema_nan: the default method uses explicit iterate(), which triggers
# scalar GPU indexing.  Replace with two AK.mapreduce passes (min + max)
# that stay on the GPU.  NaN points are excluded by mapping them to the
# neutral element (+Inf for min, -Inf for max) before reducing.
function Makie.extrema_nan(itr::LavaArray{<:Point{N, Float32}, 1}) where {N}
    if isempty(itr)
        return (Point{N, Float32}(NaN), Point{N, Float32}(NaN))
    end

    neutral_min = Point{N, Float32}(Inf32)
    neutral_max = Point{N, Float32}(-Inf32)

    # min pass: NaN points replaced with +Inf so they don't affect the minimum.
    lo = AK.mapreduce(
        p -> any(isnan, p) ? neutral_min : p,
        (a, b) -> Point{N, Float32}(min.(a, b)...),
        itr, LavaBackend();
        init=neutral_min, neutral=neutral_min,
        block_size=64, switch_below=0)

    # max pass: NaN points replaced with -Inf so they don't affect the maximum.
    hi = AK.mapreduce(
        p -> any(isnan, p) ? neutral_max : p,
        (a, b) -> Point{N, Float32}(max.(a, b)...),
        itr, LavaBackend();
        init=neutral_max, neutral=neutral_max,
        block_size=64, switch_below=0)

    return (lo, hi)
end

# --- Bounding box iteration ---------------------------------------------------

# iterate_transformed: the default calls filter(p -> !is_clipped(...), ...) where
# filter uses LavaArray boolean indexing which is broken (BoundsError).
# Without clip planes (the common case): skip the filter, apply transform via
# GPU broadcast (apply_transform_and_model already broadcasts on AbstractArray).
# With clip planes: collect to CPU after applying transform, then filter on CPU.
# This costs O(N) memory traffic but is correct; warn so users know.
function Makie.iterate_transformed(plot, points::LavaArray{<:Point{N, Float32}, 1}) where {N}
    cp = plot.clip_planes[]
    transformed = Makie.apply_transform_and_model(plot, points)
    if isempty(cp)
        # No clip planes: transform via broadcast (stays on GPU), no filter needed.
        return transformed
    else
        # Clip planes: collect to CPU, filter there.
        # For large LavaArrays this costs O(N) DMA; users who set clip planes accept
        # this cost.  Surface a warning so it is visible in profiles.
        @warn "RayMakie: iterate_transformed on a LavaArray with clip planes falls " *
              "back to CPU collection; this is O(N) memory traffic. Consider " *
              "removing clip planes or pre-filtering on the GPU side." maxlog=1
        cpu_points = Array(transformed)
        return filter(p -> !Makie.is_clipped(cp, p), cpu_points)
    end
end

# --- Marker-transform bounds (closes P3.4a footgun) --------------------------

# limits_with_marker_transforms (Makie data_limits.jl:36, boundingbox.jl:54)
# enumerates positions to compute per-instance marker-transformed bboxes. With
# a LavaArray that is scalar-iteration -- triggers @allowscalar.
#
# For uniform scale + rotation (the common case), the marker bbox is fixed in
# instance-local space and just gets translated by each grain's position. So
# the per-instance loop reduces to: extrema(positions) +/- the uniform marker
# bbox. extrema_nan over LavaArray is already GPU-safe (above).
#
# Per-instance LavaArray scales/rotation is not yet supported -- error loudly.
# Per-instance CPU Vector scales/rotation is also rejected on the GPU path
# because looking each up by index inside a GPU mapreduce is non-trivial; the
# user can pre-compute the per-instance contribution into a LavaArray and pass
# scalar attrs here.
function _check_uniform_attr(attr, name::String)
    attr isa LavaArray && error(
        "limits_with_marker_transforms: per-instance $name as a LavaArray is not " *
        "yet supported on the GPU path. Pass a scalar instead, or compute the " *
        "expanded bounds yourself.")
    # AbstractVector includes static vectors (Vec3f, Quaternionf etc.) which Makie
    # treats as scalars via attr_broadcast_getindex.  Use Makie.VecTypes to
    # distinguish: VecTypes = scalar, plain AbstractVector = per-instance.
    if attr isa AbstractVector && !(attr isa Makie.VecTypes)
        error(
            "limits_with_marker_transforms: per-instance $name (Vector) alongside " *
            "a LavaArray positions is not yet supported on the GPU path. Pass a " *
            "scalar $name (uniform across all instances).")
    end
    return nothing
end

function Makie.limits_with_marker_transforms(positions::LavaArray{<:Point{N, Float32}, 1},
                                              scales, rotation, element_bbox) where {N}
    isempty(positions) && return Makie.Rect3d()
    _check_uniform_attr(scales, "scales")
    _check_uniform_attr(rotation, "rotation")
    first_scale = Makie.attr_broadcast_getindex(scales, 1)
    first_rot   = Makie.attr_broadcast_getindex(rotation, 1)
    marker_bbox = first_rot * (element_bbox * first_scale)
    pos_lo, pos_hi = Makie.extrema_nan(positions)
    bb_min = Makie.to_ndim(Makie.Point3d, pos_lo, 0) + minimum(marker_bbox)
    bb_max = Makie.to_ndim(Makie.Point3d, pos_hi, 0) + maximum(marker_bbox)
    return Makie.Rect3d(bb_min, bb_max - bb_min)
end

function Makie.limits_with_marker_transforms(positions::LavaArray{<:Point{N, Float32}, 1},
                                              scales, rotation, model, element_bbox) where {N}
    isempty(positions) && return Makie.Rect3d()
    _check_uniform_attr(scales, "scales")
    _check_uniform_attr(rotation, "rotation")
    first_scale = Makie.attr_broadcast_getindex(scales, 1)
    first_rot   = Makie.attr_broadcast_getindex(rotation, 1)
    model3 = model[Makie.Vec(1, 2, 3), Makie.Vec(1, 2, 3)]
    # Uniform marker contribution: enumerate the 8 corners of element_bbox once,
    # apply rotation+scale+model to each, take min/max -- this is fixed cost
    # (8 vertices) so no GPU concern.
    vertices = Makie.decompose(Makie.Point3d, element_bbox)
    marker_min = Makie.Point3d(Inf, Inf, Inf)
    marker_max = Makie.Point3d(-Inf, -Inf, -Inf)
    for v in vertices
        p = model3 * (first_rot * (first_scale .* v))
        marker_min = min.(marker_min, p)
        marker_max = max.(marker_max, p)
    end
    pos_lo, pos_hi = Makie.extrema_nan(positions)
    bb_min = Makie.to_ndim(Makie.Point3d, pos_lo, 0) + marker_min
    bb_max = Makie.to_ndim(Makie.Point3d, pos_hi, 0) + marker_max
    return Makie.Rect3d(bb_min, bb_max - bb_min)
end
