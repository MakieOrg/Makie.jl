# RayMakie: GPU-array pass-through for Makie's conversion + bounds path.
#
# When a user passes a GPU array of `Point3f` as `positions` (or any Point-typed
# attribute) to a Makie plot, the default pipeline contains scalar-iteration
# sites that error or warn:
#
#   - Makie.extrema_nan uses explicit iterate(itr) -- hit by any positions
#     passed to colorrange computation.
#   - Makie.iterate_transformed at boundingbox.jl:140 calls
#     filter(p -> !is_clipped(...), apply_transform_and_model(plot, points)).
#     GPUArrays' filter uses boolean logical indexing, which is broken for these
#     arrays (BoundsError), so we short-circuit.
#   - Makie.convert_single_argument / convert_arguments / float_convert /
#     el32convert: the existing Makie methods already pass canonical
#     `Point{N,Float32}` arrays through, but explicit overloads make a
#     non-canonical eltype error loudly instead of silently converting on CPU.
#
# These dispatch on `AbstractGPUArray`, not on one backend's array type. They
# were written against `Mantle.GPU array`, which meant every one of them was a
# Vulkan-only method — and, once the runtime moved behind an extension, a name
# that did not resolve at all without a driver. Nothing here is driver-specific:
# the reductions go through AcceleratedKernels on whatever backend the array
# reports, so a `MtlArray` gets the same treatment a `GPU array` does.
#
# Non-canonical eltypes (e.g. `Point3{Float64}`) error loudly -- silent CPU
# element-type conversion is not supported. Convert on the GPU side first.

import Makie
import AcceleratedKernels as AK
using GeometryBasics: Point

# --- Conversion path ----------------------------------------------------------

# Canonical pass-through for Point{N, Float32}.
# Non-canonical eltype: error rather than silently iterating on CPU.
function Makie.convert_single_argument(a::AbstractGPUArray{<:Point{N, T}, 1}) where {N, T}
    T === Float32 || error(
        "RayMakie: positions GPU array must have eltype Point{N, Float32}; " *
        "got Point{$N, $T}. Convert on the GPU side before passing to Makie " *
        "(`GPU array(Point3f.(...))` or an explicit kernel) -- silent CPU " *
        "element-type conversion is not supported.")
    return a
end

# PointBased recipes (Scatter, MeshScatter, Lines, ...) take an
# AbstractVector{<:VecTypes{N,T}}.  Provide a direct overload that bypasses
# the elconvert chain entirely.
function Makie.convert_arguments(::Makie.PointBased, positions::AbstractGPUArray{<:Point{N, Float32}, 1}) where {N}
    N in (2, 3) || throw(ArgumentError("Only 2D and 3D points are supported; got $N-D."))
    return (positions,)
end

# float_convert and el32convert are identity on canonical Point{N, Float32}.
# Providing explicit overloads prevents the fallback `elconvert` chain from
# attempting a convert(AbstractArray{...}, ::GPU array) round-trip.
Makie.float_convert(x::AbstractGPUArray{<:Point{N, Float32}, 1}) where {N} = x
Makie.el32convert(x::AbstractGPUArray{<:Point{N, Float32}, 1}) where {N} = x

# --- Bounds computation -------------------------------------------------------

# extrema_nan: the default method uses explicit iterate(), which triggers
# scalar GPU indexing.  Replace with two AK.mapreduce passes (min + max)
# that stay on the GPU.  NaN points are excluded by mapping them to the
# neutral element (+Inf for min, -Inf for max) before reducing.
function Makie.extrema_nan(itr::AbstractGPUArray{<:Point{N, Float32}, 1}) where {N}
    if isempty(itr)
        return (Point{N, Float32}(NaN), Point{N, Float32}(NaN))
    end

    neutral_min = Point{N, Float32}(Inf32)
    neutral_max = Point{N, Float32}(-Inf32)

    # min pass: NaN points replaced with +Inf so they don't affect the minimum.
    lo = AK.mapreduce(
        p -> any(isnan, p) ? neutral_min : p,
        (a, b) -> Point{N, Float32}(min.(a, b)...),
        itr, KernelAbstractions.get_backend(itr);
        init=neutral_min, neutral=neutral_min,
        block_size=64, switch_below=0)

    # max pass: NaN points replaced with -Inf so they don't affect the maximum.
    hi = AK.mapreduce(
        p -> any(isnan, p) ? neutral_max : p,
        (a, b) -> Point{N, Float32}(max.(a, b)...),
        itr, KernelAbstractions.get_backend(itr);
        init=neutral_max, neutral=neutral_max,
        block_size=64, switch_below=0)

    return (lo, hi)
end

# --- Bounding box iteration ---------------------------------------------------

# iterate_transformed: the default calls filter(p -> !is_clipped(...), ...) where
# filter uses GPU array boolean indexing which is broken (BoundsError).
# Without clip planes (the common case): skip the filter, apply transform via
# GPU broadcast (apply_transform_and_model already broadcasts on AbstractArray).
# With clip planes: collect to CPU after applying transform, then filter on CPU.
# This costs O(N) memory traffic but is correct; warn so users know.
function Makie.iterate_transformed(plot, points::AbstractGPUArray{<:Point{N, Float32}, 1}) where {N}
    cp = plot.clip_planes[]
    transformed = Makie.apply_transform_and_model(plot, points)
    if isempty(cp)
        # No clip planes: transform via broadcast (stays on GPU), no filter needed.
        return transformed
    else
        # Clip planes: collect to CPU, filter there.
        # For large GPU arrays this costs O(N) DMA; users who set clip planes accept
        # this cost.  Surface a warning so it is visible in profiles.
        @warn "RayMakie: iterate_transformed on a GPU array with clip planes falls " *
              "back to CPU collection; this is O(N) memory traffic. Consider " *
              "removing clip planes or pre-filtering on the GPU side." maxlog=1
        cpu_points = Array(transformed)
        return filter(p -> !Makie.is_clipped(cp, p), cpu_points)
    end
end

# --- Marker-transform bounds (closes P3.4a footgun) --------------------------

# limits_with_marker_transforms (Makie data_limits.jl:36, boundingbox.jl:54)
# enumerates positions to compute per-instance marker-transformed bboxes. With
# a GPU array that is scalar-iteration -- triggers @allowscalar.
#
# For uniform scale + rotation (the common case), the marker bbox is fixed in
# instance-local space and just gets translated by each grain's position. So
# the per-instance loop reduces to: extrema(positions) +/- the uniform marker
# bbox. extrema_nan over GPU array is already GPU-safe (above).
#
# Per-instance GPU array scales/rotation is not yet supported -- error loudly.
# Per-instance CPU Vector scales/rotation is also rejected on the GPU path
# because looking each up by index inside a GPU mapreduce is non-trivial; the
# user can pre-compute the per-instance contribution into a GPU array and pass
# scalar attrs here.
function _check_uniform_attr(attr, name::String)
    attr isa AbstractGPUArray && error(
        "limits_with_marker_transforms: per-instance $name as a GPU array is not " *
        "yet supported on the GPU path. Pass a scalar instead, or compute the " *
        "expanded bounds yourself.")
    # AbstractVector includes static vectors (Vec3f, Quaternionf etc.) which Makie
    # treats as scalars via attr_broadcast_getindex.  Use Makie.VecTypes to
    # distinguish: VecTypes = scalar, plain AbstractVector = per-instance.
    if attr isa AbstractVector && !(attr isa Makie.VecTypes)
        error(
            "limits_with_marker_transforms: per-instance $name (Vector) alongside " *
            "a GPU array positions is not yet supported on the GPU path. Pass a " *
            "scalar $name (uniform across all instances).")
    end
    return nothing
end

function Makie.limits_with_marker_transforms(positions::AbstractGPUArray{<:Point{N, Float32}, 1},
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

function Makie.limits_with_marker_transforms(positions::AbstractGPUArray{<:Point{N, Float32}, 1},
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

"""
    scalarat(a, i) -> eltype(a)

Element `i` of `a`, as a host value.

For the handful of places where a SIZE depends on the data — a stream
compaction has to know how many elements it produced before it can allocate the
array to put them in. That count lives on the device and the allocation happens
on the host, so exactly one scalar has to cross; this reads that one scalar
instead of the array around it.

Not a way to iterate a device array. `a[i]` in a loop is scalar indexing, which
GPUArrays refuses on purpose. If more than a couple of these appear in a pass,
the pass is still sequential and wants rewriting, not this function.
"""
scalarat(a::AbstractArray, i::Integer) = a[i]
scalarat(a::AbstractGPUArray, i::Integer) = only(Array(view(a, i:i)))

"""
Face normals accumulated into the vertices each face touches.

The accumulation is a scatter with contention — several faces add into the same
vertex — so it goes through atomics. `normals` is a flat `Float32` array of
`3 * nvertices` rather than a `Vec3f` array because an atomic add applies to a
scalar memory location, and three of them per corner is the whole trick.
"""
# Two things about these helpers that the compiler only tells you obliquely.
#
# `ntuple(…, Val(N))` rather than `for k in 1:N`, because a face index has to be
# a COMPILE-TIME constant: `face[k]` reads a field of a tuple, and a GPU has
# nowhere to put a dynamically indexed one. `Val` unrolls it.
#
# `Base.to_index` rather than `Int`, because a face element is an
# `OffsetInteger` (`GLTriangleFace` stores its indices 0-based) and
# `Int(::OffsetInteger)` HAS NO METHOD — on the host or anywhere else. Indexing
# an `Array` with one works through `to_index`, which is the conversion that
# exists; `Int` only looked plausible. It also keeps the kernel working for a
# face type that holds plain integers.
#
# Both mistakes surface as the same `method lookup failure` pointing at the
# array access, naming neither the tuple nor the conversion.

"""Newell's method — what GeometryBasics uses; for a triangle it is the cross product."""
@inline function facenormal(vertices, face::GeometryBasics.NgonFace{N}) where {N}
    return sum(ntuple(Val(N)) do k
        a = vertices[Base.to_index(face[k])]
        b = vertices[Base.to_index(face[k == N ? 1 : k + 1])]
        Vec3f((a[2] - b[2]) * (a[3] + b[3]),
              (a[3] - b[3]) * (a[1] + b[1]),
              (a[1] - b[1]) * (a[2] + b[2]))
    end)
end

"""Add one face's normal into each vertex it touches."""
@inline function scatternormal!(normals, face::GeometryBasics.NgonFace{N}, n) where {N}
    ntuple(Val(N)) do k
        base = 3 * (Base.to_index(face[k]) - 1)
        Atomix.@atomic normals[base + 1] += n[1]
        Atomix.@atomic normals[base + 2] += n[2]
        Atomix.@atomic normals[base + 3] += n[3]
        nothing
    end
    return nothing
end

"""
Face normals accumulated into the vertices each face touches.

The accumulation is a scatter with contention — several faces add into the same
vertex — so it goes through atomics. `normals` is a flat `Float32` array of
`3 * nvertices` rather than a `Vec3f` array because an atomic add applies to one
scalar memory location, and three of them per corner is the whole trick.
"""
@kernel function face_normals_kernel!(normals, @Const(vertices), @Const(faces))
    f = @index(Global, Linear)
    @inbounds begin
        face = faces[f]
        scatternormal!(normals, face, facenormal(vertices, face))
    end
end

"""
    GeometryBasics.normals(vertices::AbstractGPUArray, faces, NormalType)

Vertex normals for a mesh whose VERTICES are on a device, computed there.

`GeometryBasics.normals` gathers `vertices[face]` per face and accumulates into
the vertices it touches, as a host loop. Indexing a device array with an
`NgonFace` is not something GPUArrays answers
(`MethodError: vectorized_getindex!(::MVector{3,Point3f}, ::LavaArray{Point3f,1},
::NgonFace{3,…})`), and that `MethodError` comes out of Makie's
`convert_arguments(Mesh, vertices, indices)` — so `mesh!` with device vertices
used to fail before any backend saw the plot.

Here rather than in GeometryBasics because GeometryBasics has no GPU dependency
and should not grow one for this.

`faces` is copied to the device if it is not already there; it is the topology,
typically far smaller than the vertices, and it is read once per call. The
vertices themselves never move.

Not bit-identical to the host version: atomics fix no summation order, so a
vertex shared by several faces can differ in the last few ulps before
normalisation. The tests compare with `≈` for that reason.
"""
function GeometryBasics.normals(vertices::AbstractGPUArray,
                                faces::AbstractVector{<:GeometryBasics.NgonFace},
                                ::Type{NormalType}) where {NormalType}
    nv = length(vertices)
    flat = similar(vertices, Float32, 3 * nv)
    fill!(flat, 0.0f0)

    devfaces = faces isa AbstractGPUArray ? faces :
               copyto!(similar(vertices, eltype(faces), length(faces)), faces)

    backend = KernelAbstractions.get_backend(vertices)
    face_normals_kernel!(backend)(flat, vertices, devfaces; ndrange = length(devfaces))

    out = similar(vertices, NormalType, nv)
    out .= normalize.(tovec3.(view(flat, 1:3:(3nv - 2)),
                              view(flat, 2:3:(3nv - 1)),
                              view(flat, 3:3:(3nv))))
    return out
end

@inline tovec3(x, y, z) = Vec3f(x, y, z)
