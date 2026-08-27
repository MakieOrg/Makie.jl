# =============================================================================
# draw_atomic for Makie.MeshScatter
# =============================================================================
#
# Architecture (mirrors GLMakie's plot-primitives.jl pattern):
#
#   register_computation!(:marker        → :trace_marker_mesh)
#   register_computation!(:positions, :rotation, :markersize → :trace_transforms)
#   register_computation!(:positions     → :n_instances)
#   register_computation!(:color, :n_instances → :trace_materials)
#   register_computation!(:trace_marker_mesh, :trace_transforms, :trace_materials
#                         → :trace_renderobject)
#
# `:trace_renderobject` delegates to two helpers:
#   meshscatter_create!(hikari_scene, state, args)             — first frame / rebuild
#   meshscatter_update!(hikari_scene, state, robj, args, changed) — incremental
#
# `:trace_transforms` always returns the SAME mutable buffer object so that
# ComputePipeline's `is_same` check produces `same_object=true → dirty=true`,
# guaranteeing downstream re-trigger when positions/rotation/markersize change.
#
# Backend agnosticism: ALL transform math runs through `pos_rot_scale_to_mat3x4!`
# (defined below), which is just a `broadcast` over `build_4x3_pervec`.
# CPU `Vector{Point3f}` runs the broadcast as a CPU loop; GPU `LavaArray{Point3f, 1}`
# runs the GPUArrays broadcast kernel. Same source, no `isa LavaArray` checks.

# -----------------------------------------------------------------------------
# Marker → mesh
# -----------------------------------------------------------------------------

meshscatter_marker_mesh(marker::GeometryBasics.Mesh) = marker
meshscatter_marker_mesh(marker::GeometryBasics.GeometryPrimitive) =
    GeometryBasics.normal_mesh(marker)
meshscatter_marker_mesh(::Makie.Automatic) =
    GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1.0f0))
function meshscatter_marker_mesh(marker::Symbol)
    marker === :Sphere &&
        return GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1.0f0))
    return GeometryBasics.normal_mesh(Makie.default_marker_map()[marker])
end

# -----------------------------------------------------------------------------
# Rotation / markersize normalization (multiple dispatch, no isa branching)
# -----------------------------------------------------------------------------

# Returns either Vec4f (scalar rotation) or AbstractVector{Vec4f} (per-instance).
# Both forms are accepted by `pos_rot_scale_to_mat3x4!` below.
normalize_rotation(r::Vec4f) = r
normalize_rotation(r::Quaternionf) = Vec4f(r.data[1], r.data[2], r.data[3], r.data[4])
normalize_rotation(r::AbstractVector{Vec4f}) = r
normalize_rotation(r::AbstractVector{<:Quaternionf}) =
    map(q -> Vec4f(q.data[1], q.data[2], q.data[3], q.data[4]), r)
normalize_rotation(r::AbstractVector) =
    map(x -> (q = Makie.to_rotation(x); Vec4f(q.data[1], q.data[2], q.data[3], q.data[4])), r)
function normalize_rotation(r)
    q = Makie.to_rotation(r)
    Vec4f(q.data[1], q.data[2], q.data[3], q.data[4])
end

# Returns Float32 (uniform), Vec3f (per-axis scalar), or AbstractVector{Vec3f}
# (per-instance per-axis). Consumed by `pos_rot_scale_to_mat3x4!`.
normalize_markersize(s::Float32) = s
normalize_markersize(s::Number) = Float32(s)
normalize_markersize(s::Vec3f) = s
normalize_markersize(s::AbstractVector{Vec3f}) = s
normalize_markersize(s::AbstractVector) =
    error("meshscatter: per-instance markersize must have eltype Vec3f, got $(eltype(s))")
normalize_markersize(s) =
    error("meshscatter: unsupported markersize $(typeof(s)). Use Number, Vec3f, or AbstractVector{Vec3f}.")

# -----------------------------------------------------------------------------
# Mat3x4f → Mat4f (Vulkan-style row-major 3×4 to homogeneous 4×4)
# -----------------------------------------------------------------------------
#
# Mat3x4f = SMatrix{4,3,Float32,12} — Julia rows correspond to the Vulkan
# matrix's columns (matrix[3][4] is row-major in C). The 4th Julia row holds
# translations (tx, ty, tz). To produce a homogeneous Mat4f we transpose the
# rotation block and append [0,0,0,1] in the bottom row.
function mat3x4_to_mat4(t::Mantle.Mat3x4f)
    Mat4f(t[1,1], t[1,2], t[1,3], 0f0,
          t[2,1], t[2,2], t[2,3], 0f0,
          t[3,1], t[3,2], t[3,3], 0f0,
          t[4,1], t[4,2], t[4,3], 1f0)
end

# -----------------------------------------------------------------------------
# pos_rot_scale_to_mat3x4! — broadcast over Lava primitives
# -----------------------------------------------------------------------------
#
# This used to be six hand-written `@kernel`s in Lava (each combination of
# scalar/per-instance rotation × Float32/Vec3f/per-instance scale).  All of
# that collapses to one broadcast over (`quat_to_rot3x3`, `build_4x3_pervec`,
# wrap as Mat3x4f).  Broadcast itself dispatches per-backend (Vector → CPU
# loop, LavaArray → GPU broadcast kernel) — no code from us.
#
# Vec3f / Vec4f scalars need a Ref wrapper so broadcast doesn't iterate them
# as Float32 element arrays.  Numbers and AbstractArrays pass through.

# Vec3f and Vec4f are SVectors so broadcast would otherwise iterate them as
# Float32 element arrays. Wrap them in a Ref to pin them as scalars; Number
# scalars and AbstractArrays pass through.
bcast_scalar(x::Union{Vec3f, Vec4f}) = Ref(x)
bcast_scalar(x)                       = x

@inline as_vec3(s::Float32) = Vec3f(s, s, s)
@inline as_vec3(s::Vec3f)   = s

@inline function build_instance_mat3x4(p::Point3f, q::Vec4f, s)
    Mantle.Mat3x4f(Mantle.build_4x3_pervec(Mantle.quat_to_rot3x3(q), as_vec3(s), p)...)
end

# `transforms` and `positions` must be the same length and on the same
# backend.  We own the buffer in trace_transforms (allocated via
# `similar(positions, Mantle.Mat3x4f)`), so this is enforced upstream.
function pos_rot_scale_to_mat3x4!(transforms, positions, rotation, scale)
    transforms .= build_instance_mat3x4.(positions,
                                         bcast_scalar(rotation),
                                         bcast_scalar(scale))
    return transforms
end

# -----------------------------------------------------------------------------
# Material extraction
# -----------------------------------------------------------------------------

function extract_meshscatter_materials(plot::Makie.MeshScatter, n_instances::Int)
    color = to_value(plot.color)
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material_template = has_material ? to_value(plot.material) : nothing

    # A material with no user-set colour is used as given. This is the same rule
    # `extract_material` applies on the mesh path, and it was missing here: every
    # branch below merges a colour over the template unconditionally, so
    # `meshscatter!(...; material = Diffuse(Kd = red))` rendered in the cycler's
    # palette colour instead. "Not set" is `:cycled`, not `nothing` — Makie's
    # `resolve_cycled!` writes that symbol into every cycled attribute the user
    # did not assign, which is why a `!== nothing` test cannot tell the two
    # apart. Found by rendering it and looking: the state assertions all passed.
    if material_template isa Hikari.Material && !color_was_set(plot)
        return map(_ -> material_template, 1:n_instances)
    end

    # Per-instance colors: use Makie's compute_colors to resolve colormapping
    if color isa AbstractVector && length(color) == n_instances
        computed = Makie.compute_colors(plot.attributes)
        if computed isa AbstractVector{<:Colorant}
            return map(c -> create_material_with_color(to_color(c), material_template), computed)
        end
    end

    # Uniform color: replicate the same material for all instances
    base_color = if color isa Colorant
        to_color(color)
    elseif color isa Union{String, Symbol}
        to_color(color)
    elseif color isa AbstractVector{<:Colorant} && !isempty(color)
        to_color(first(color))
    else
        computed = Makie.compute_colors(plot.attributes)
        if computed isa AbstractVector{<:Colorant} && !isempty(computed)
            to_color(first(computed))
        elseif computed isa Colorant
            to_color(computed)
        else
            RGBAf(0.8, 0.8, 0.8, 1.0)
        end
    end

    return map(_ -> create_material_with_color(base_color, material_template), 1:n_instances)
end

# -----------------------------------------------------------------------------
# Create / Update render object
# -----------------------------------------------------------------------------

# Returns the NamedTuple stored in :trace_renderobject.
# Always shaped as (handles, n_instances, materials, mi_indices) so the
# update path can rely on a single field set.
function meshscatter_create!(hikari_scene, state, args)
    n = length(args.trace_transforms)
    if n == 0
        state.needs_film_clear = true
        return (handles = Hikari.SceneHandle[],
                n_instances = 0,
                materials = args.trace_materials,
                mi_indices = UInt32[])
    end

    transforms_mat4 = map(mat3x4_to_mat4, Array(args.trace_transforms))
    materials = Vector(args.trace_materials)
    handles = push!(hikari_scene, args.trace_marker_mesh, materials, transforms_mat4)
    state.needs_film_clear = true
    return (handles = handles,
            n_instances = n,
            materials = materials,
            mi_indices = map(h -> h.interface, handles))
end

function meshscatter_update!(hikari_scene, state, robj, args, changed)
    n = length(args.trace_transforms)

    # Marker mesh OR instance count changed → full rebuild.
    # Reuse mi_indices to keep scene.materials a fixed size up to the high
    # water mark of N (avoids unbounded MultiTypeSet growth on per-frame rebuilds).
    if changed.trace_marker_mesh || n != robj.n_instances
        delete_trace_handles!(hikari_scene, robj)
        if n == 0
            state.needs_film_clear = true
            return (handles = Hikari.SceneHandle[],
                    n_instances = 0,
                    materials = args.trace_materials,
                    mi_indices = UInt32[])
        end
        transforms_mat4 = map(mat3x4_to_mat4, Array(args.trace_transforms))
        materials = Vector(args.trace_materials)
        reuse = isempty(robj.mi_indices) ? nothing : robj.mi_indices
        handles = push!(hikari_scene, args.trace_marker_mesh, materials, transforms_mat4;
                        reuse_mi_indices = reuse)
        state.needs_film_clear = true
        return (handles = handles,
                n_instances = n,
                materials = materials,
                mi_indices = map(h -> h.interface, handles))
    end

    # In-place updates — no BLAS rebuild, no scene.materials growth.
    if changed.trace_transforms
        Raycore.update_transforms!(hikari_scene.accel,
                                    robj.handles[1].geometry,
                                    args.trace_transforms)
        state.needs_film_clear = true
    end
    if changed.trace_materials
        foreach((h, m) -> Hikari.update_material!(hikari_scene, h.interface, m),
                robj.handles, args.trace_materials)
        state.needs_film_clear = true
        # Carry the new materials on the record too. The scene update above is
        # what the renderer reads, so leaving this stale rendered CORRECTLY and
        # only lied to anyone inspecting the renderobject — which is exactly how
        # a test asserting the stored material can fail while the image is right.
        # Mirrors what `mesh_trace_update!` does for the single-material case.
        robj = merge(robj, (materials = args.trace_materials,))
    end
    return robj
end

# =============================================================================
# draw_atomic — separated computations
# =============================================================================

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.MeshScatter)
    attr = plot.attributes
    state = screen.state
    hikari_scene = state.hikari_scene

    # 1. Marker → GB.Mesh
    register_computation!(attr, [:marker], [:trace_marker_mesh]) do args, changed, last
        return (meshscatter_marker_mesh(args.marker),)
    end

    # 2. Instance count (cheap derived value — used by trace_materials so it
    #    only refires when length actually changes, not on data updates).
    register_computation!(attr, [:positions], [:n_instances]) do args, changed, last
        return (length(args.positions),)
    end

    # 3. Per-instance transforms as Mat3x4f. Backend-agnostic: positions on
    #    CPU → Vector{Mat3x4f}; positions on GPU → LavaArray{Mat3x4f, 1}.
    #    Same buffer object returned each frame → is_same returns false → dirty.
    #    A fresh buffer is allocated only if the length OR backend changes
    #    (e.g. positions swap from a CPU Vector to a GPU LavaArray).
    register_computation!(attr, [:positions, :rotation, :markersize],
                          [:trace_transforms]) do args, changed, last
        positions = args.positions
        n = length(positions)
        n == 0 && return (Mantle.Mat3x4f[],)

        rot = normalize_rotation(args.rotation)
        scale = normalize_markersize(args.markersize)

        backend = KernelAbstractions.get_backend(positions)
        buf = if isnothing(last) || length(last.trace_transforms) != n ||
                 typeof(KernelAbstractions.get_backend(last.trace_transforms)) !== typeof(backend)
            similar(positions, Mantle.Mat3x4f)
        else
            last.trace_transforms
        end
        pos_rot_scale_to_mat3x4!(buf, positions, rot, scale)
        return (buf,)
    end

    # 4. Per-instance materials.
    #
    # `:material` MUST be an input even though the body reads `plot.material`
    # rather than `args.material`: the compute graph re-runs a node only when a
    # declared input changes, so with just `[:color, :n_instances]` a
    # `plot.material = ...` assignment invalidated nothing and the swap never
    # reached the scene. The value was read correctly and the node simply never
    # ran. Conditional because `:material` is only present when the user gave
    # one — same shape as image.jl's `:model_f32c` handling.
    material_deps = haskey(attr, :material) ? [:color, :n_instances, :material] :
                                              [:color, :n_instances]
    register_computation!(attr, material_deps,
                          [:trace_materials]) do args, changed, last
        return (extract_meshscatter_materials(plot, max(args.n_instances, 1)),)
    end

    # 5. Render object — single dispatch point: create on first frame, update otherwise.
    register_computation!(attr,
        [:trace_marker_mesh, :trace_transforms, :trace_materials],
        [:trace_renderobject]) do args, changed, last
        if isnothing(last) || isnothing(last.trace_renderobject) ||
           !hasproperty(last.trace_renderobject, :handles)
            return (meshscatter_create!(hikari_scene, state, args),)
        end
        return (meshscatter_update!(hikari_scene, state, last.trace_renderobject,
                                     args, changed),)
    end
end
