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
# One broadcast, and not six hand-written `@kernel`s (each combination of
# scalar/per-instance rotation × Float32/Vec3f/per-instance scale) over
# (`quat_to_rot3x3`, `build_4x3_pervec`,
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
    Mantle.build_4x3_pervec(Mantle.quat_to_rot3x3(q), as_vec3(s), p)
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
    # A texture colour (an image sampled at the marker's uvs) with a material is
    # the raster's picture of that material, as on the mesh path: the tracer
    # draws the material itself. Merged as a "uniform colour" below, a glTF
    # material lost its base colour texture to a 0-d one Hikari cannot sample.
    if material_template isa Hikari.Material && color isa AbstractMatrix
        return fill(material_template, n_instances)
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

    # One material for every instance, not `n_instances` equal ones.
    return fill(create_material_with_color(base_color, material_template), n_instances)
end

# -----------------------------------------------------------------------------
# Create / Update render object
# -----------------------------------------------------------------------------

"Whether any instance's material glows (see `push_emitters!`)."
emissive(materials) = any(m -> Hikari.get_emission_info(Hikari.surface_material(m)) !== nothing, materials)

"""
    push_emitters!(hikari_scene, mesh, materials, transforms, pool = SceneHandle[]) -> Vector{SceneHandle}

Glowing instances, one mesh each with its vertices moved by the instance's
transform. Hikari makes area lights of an emitter's triangles as they are
pushed, so they have to be where the instance is: it refuses emissive
materials on an instanced mesh, and a meshscatter of glowing markers
(fireflies, lit windows) stopped the whole scene from tracing. Instances
scaled to nothing (hidden) are left out.

`pool` holds deleted emitters of the same plot (the last frame's): each new
one takes the material slot and the light slots of the first of them
(`push_reused!`), and what is left in `pool` is still free afterwards.
"""
function push_emitters!(hikari_scene, mesh::GeometryBasics.Mesh, materials, transforms,
                        pool::Vector{Hikari.SceneHandle} = Hikari.SceneHandle[])
    handles = Hikari.SceneHandle[]
    for (m, t) in zip(materials, transforms)
        lin = Mat3f(t[1, 1], t[2, 1], t[3, 1], t[1, 2], t[2, 2], t[3, 2], t[1, 3], t[2, 3], t[3, 3])
        abs(det(lin)) < 1f-12 && continue
        placed = transformed_mesh(mesh, t, lin)
        push!(handles, isempty(pool) ? push!(hikari_scene, placed, m) :
                                       push_reused!(hikari_scene, placed, m, popfirst!(pool)))
    end
    return handles
end

"""
    push_reused!(hikari_scene, placed, material, old::SceneHandle) -> SceneHandle

`placed` (one glowing instance where it is now) pushed into the material slot
and the light slots of `old`, an emitter already deleted from the scene.
Deleting an emitter only switches its lights off (Hikari keeps the slots), so
pushing every moved instance anew grew the light set by the marker's faces
for every instance on every frame: 90 moving sun spots of 96 faces were half a
million lights after 60 frames, each frame slower, and the glass rain films
(s123, NeverendingGame) failed in `trace_renderobject`.
"""
function push_reused!(hikari_scene, placed::GeometryBasics.Mesh, material, old::Hikari.SceneHandle)
    Hikari.update_material!(hikari_scene, old.interface, material)
    return push!(hikari_scene, placed, old.interface, material; area_lights = old.area_lights)
end

"`mesh` with its positions moved by `t` and its normals by the inverse transpose of `lin`, the linear part of `t`."
function transformed_mesh(mesh::GeometryBasics.Mesh, t::Mat4f, lin::Mat3f)
    pos = [Point3f((t * Point4f(p[1], p[2], p[3], 1))[Vec(1, 2, 3)]) for p in GeometryBasics.coordinates(mesh)]
    nm = transpose(inv(lin))
    attrs = Dict{Symbol, Any}()
    hasproperty(mesh, :normal) && (attrs[:normal] = [Vec3f(normalize(nm * Vec3f(n))) for n in mesh.normal])
    hasproperty(mesh, :uv) && (attrs[:uv] = mesh.uv)
    return GeometryBasics.Mesh(pos, GeometryBasics.faces(mesh); attrs...)
end

"""One uv transform and the instances that read the marker's texture through it."""
const UVGroup = Pair{Mat{2, 3, Float32}, Vector{Int}}

"""
    uv_groups(uv_transform, n) -> Vector{UVGroup}

The `n` instances of a meshscatter grouped by the `uv_transform` they read the
marker's texture with (a face card showing one cell of a sheet of expressions
per instance). The tracer samples a marker at its own uvs, so each group is
pushed as a marker of its own with its transform baked in (`traced_uvs`).
Empty when every instance reads the marker's uvs as they are, as almost every
meshscatter does. Without this the tracer ignored `uv_transform` and every
face card showed the whole sheet.
"""
uv_groups(::Nothing, n) = UVGroup[]
uv_groups(t::Mat{2, 3}, n) = t == DEFAULT_UV_TRANSFORM ? UVGroup[] : [UVGroup(t, collect(1:n))]
function uv_groups(ts::AbstractVector, n)
    groups = Dict{Mat{2, 3, Float32}, Vector{Int}}()
    for i in 1:n
        push!(get!(() -> Int[], groups, ts[i]), i)
    end
    keys(groups) == Set((DEFAULT_UV_TRANSFORM,)) && return UVGroup[]
    return sort!([UVGroup(t, idx) for (t, idx) in groups]; by = g -> first(g[2]))
end

"""Instances of one marker into the traced scene; glowing ones as meshes of their own (`push_emitters!`, which takes their slots from `pool`)."""
push_instances!(hikari_scene, mesh, materials, transforms, pool = Hikari.SceneHandle[]) =
    emissive(materials) ? push_emitters!(hikari_scene, mesh, materials, transforms, pool) :
                          push!(hikari_scene, mesh, materials, transforms)

"""
The NamedTuple stored in :trace_renderobject. Always the same field set, so the
update path can rely on it. `groups` (`uv_groups`) are pushed one after the
other: `handles` and `materials` are in group order, `geometries` holds each
group's instanced mesh. `spare` are deleted emitters whose slots the next
rebuild takes first (`push_emitters!`): hidden instances leave some over.
"""
scatter_robj(handles, n, materials; groups = UVGroup[], geometries = Any[], spare = Hikari.SceneHandle[]) =
    (handles = handles, n_instances = n, materials = materials, mi_indices = map(h -> h.interface, handles),
     groups = groups, geometries = geometries, spare = spare)

"""
    emitter_pool(robj) -> Vector{SceneHandle}

The emitters of a glowing meshscatter's last render object, deleted, for the
rebuild to reuse (`push_reused!`). Empty when it glowed not: instanced meshes
share one interface and keep their own path.
"""
function emitter_pool(robj)
    emissive(robj.materials) || return Hikari.SceneHandle[]
    return vcat(robj.handles, hasproperty(robj, :spare) ? robj.spare : Hikari.SceneHandle[])
end

function meshscatter_create!(hikari_scene, state, args; pool::Vector{Hikari.SceneHandle} = Hikari.SceneHandle[])
    n = length(args.trace_transforms)
    state.needs_film_clear = true
    n == 0 && return scatter_robj(Hikari.SceneHandle[], 0, args.trace_materials; spare = pool)

    transforms_mat4 = map(mat3x4_to_mat4, Array(args.trace_transforms))
    materials = Vector(args.trace_materials)
    groups = args.trace_uv_groups
    isempty(groups) && return scatter_robj(push_instances!(hikari_scene, args.trace_marker_mesh, materials, transforms_mat4, pool),
                                           n, materials; spare = pool)
    handles = Hikari.SceneHandle[]
    geometries = Any[]
    for (t, idx) in groups
        hs = push_instances!(hikari_scene, traced_uvs(args.trace_marker_mesh, t), materials[idx], transforms_mat4[idx], pool)
        isempty(hs) || push!(geometries, first(hs).geometry)
        append!(handles, hs)
    end
    return scatter_robj(handles, n, materials[reduce(vcat, last.(groups))]; groups, geometries, spare = pool)
end

function meshscatter_update!(hikari_scene, state, robj, args, changed)
    n = length(args.trace_transforms)

    # Instances read through uv transforms are a marker per transform (`uv_groups`):
    # a new grouping, marker, colour or count pushes them again, a move moves each group.
    if !isempty(robj.groups) || !isempty(args.trace_uv_groups)
        if changed.trace_marker_mesh || changed.trace_uv_groups || changed.trace_materials || n != robj.n_instances ||
           emissive(robj.materials)
            delete_trace_handles!(hikari_scene, robj)
            return meshscatter_create!(hikari_scene, state, args; pool = emitter_pool(robj))
        end
        if changed.trace_transforms
            for (geometry, (_, idx)) in zip(robj.geometries, robj.groups)
                Raycore.update_transforms!(hikari_scene.accel, geometry, args.trace_transforms[idx])
            end
            state.needs_film_clear = true
        end
        return robj
    end

    # Glowing instances are meshes of their own in world space (`push_emitters!`):
    # anything that moves or changes them is a rebuild.
    if emissive(robj.materials) || emissive(args.trace_materials)
        changed.trace_marker_mesh || changed.trace_transforms || changed.trace_materials || n != robj.n_instances ||
            return robj
        delete_trace_handles!(hikari_scene, robj)
        return meshscatter_create!(hikari_scene, state, args; pool = emitter_pool(robj))
    end

    # One material object for every instance is one interface they all share
    # (Hikari's `push_interfaces!`). Different colours for them then need an
    # interface each, which an update in place cannot give.
    mats = args.trace_materials
    unshare = !allunique(robj.mi_indices) && any(m -> m !== first(mats), mats)
    regroup = changed.trace_materials && unshare

    # Marker mesh OR instance count changed, or the instances stop sharing one
    # interface → full rebuild. Otherwise reuse mi_indices to keep
    # scene.materials a fixed size up to the high water mark of N (avoids
    # unbounded MultiTypeSet growth on per-frame rebuilds).
    if changed.trace_marker_mesh || n != robj.n_instances || regroup
        delete_trace_handles!(hikari_scene, robj)
        state.needs_film_clear = true
        n == 0 && return scatter_robj(Hikari.SceneHandle[], 0, args.trace_materials)
        transforms_mat4 = map(mat3x4_to_mat4, Array(args.trace_transforms))
        materials = Vector(args.trace_materials)
        # Shared slots can be reused only by instances that keep sharing them.
        reuse = isempty(robj.mi_indices) || unshare ? nothing : robj.mi_indices
        handles = push!(hikari_scene, args.trace_marker_mesh, materials, transforms_mat4;
                        reuse_mi_indices = reuse)
        return scatter_robj(handles, n, materials)
    end

    # In-place updates — no BLAS rebuild, no scene.materials growth.
    if changed.trace_transforms
        Raycore.update_transforms!(hikari_scene.accel,
                                    robj.handles[1].geometry,
                                    args.trace_transforms)
        state.needs_film_clear = true
    end
    if changed.trace_materials
        Hikari.update_materials!(hikari_scene, robj.mi_indices, args.trace_materials)
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

    # The path, as for a mesh: traced, or the marker mesh drawn once per
    # instance by the raster mesh stage. `setrasterize!` switches it.
    haskey(attr, :raster_path) || add_input!(attr, :raster_path, screen.rasterize)
    israster(args) = args.raster_path || !should_raytrace(scene, plot) || isnothing(hikari_scene)

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
    material_deps = haskey(attr, :material) ? [:color, :n_instances, :material, :raster_path] :
                                              [:color, :n_instances, :raster_path]
    register_computation!(attr, material_deps,
                          [:trace_materials]) do args, changed, last
        # Only the tracer reads them; while rasterising, keep what there is.
        israster(args) && last !== nothing && return nothing
        return (extract_meshscatter_materials(plot, max(args.n_instances, 1)),)
    end

    # 5. Which instances read the marker's texture through which uv transform.
    register_computation!(attr, [:uv_transform, :n_instances], [:trace_uv_groups]) do args, changed, last
        return (uv_groups(args.uv_transform, args.n_instances),)
    end

    # 6. Render object — single dispatch point: create on first frame, update otherwise.
    register_computation!(attr,
        [:trace_marker_mesh, :trace_transforms, :trace_materials, :trace_uv_groups, :raster_path, :visible],
        [:trace_renderobject]) do args, changed, last
        # `nothing` when this plot is not being traced; the slot keeps its type.
        israster(args) && return (nothing,)
        if isnothing(last) || isnothing(last.trace_renderobject) ||
           !hasproperty(last.trace_renderobject, :handles)
            robj = meshscatter_create!(hikari_scene, state, args)
            return (trace_visibility!(hikari_scene, state, robj, args, changed, true),)
        end
        last_robj = last.trace_renderobject
        robj = meshscatter_update!(hikari_scene, state, last_robj, args, changed)
        # A new instance count or marker pushes the instances again, visible.
        fresh = robj.handles !== last_robj.handles
        return (trace_visibility!(hikari_scene, state, robj, args, changed, fresh;
                                  restyled = changed.trace_materials),)
    end

    register_meshscatter_raster!(screen, scene, plot, israster)
end

"""
Everything the raster node of a meshscatter reads: the instances, the marker
mesh decomposed as GLMakie decomposes it, and what a mesh reads for colour,
lighting and the camera (`RASTER_MESH_DEPS`), without the stroke.
"""
const RASTER_MESHSCATTER_DEPS = [
    :positions_transformed_f32c, :rotation, :markersize, :f32c_scale, :transform_marker,
    :raster_uv_transform,
    :vertex_position, :faces, :normal, :uv,
    :model_f32c, :material, :raster_path,
    :scaled_color, :alpha_colormap, :scaled_colorrange, :color_mapping_type,
    :lowclip_color, :highclip_color, :nan_color, :interpolate, :fetch_pixel, :matcap,
    :shading, :diffuse, :specular, :shininess, :backlight, :depth_shift,
    :world_normalmatrix, :view_normalmatrix,
    :uniform_clip_planes, :uniform_num_clip_planes,
    :view, :projection, :eyeposition, :resolution, :viewport,
    first.(RASTER_LIGHT_NODES)...,
]

"""
    register_meshscatter_raster!(screen, scene, plot, israster)

The `:raster_renderobject` of a meshscatter: GLMakie's `draw_atomic(::MeshScatter)`
nodes, then the mesh raster path (`mesh_raster!`) with one instance per position.
"""
function register_meshscatter_raster!(screen, scene, plot, israster)
    attr = plot.attributes
    # The marker as the tracer gets it (a symbol or a primitive becomes a mesh),
    # decomposed as GLMakie decomposes `:marker`.
    haskey(attr, :vertex_position) ||
        Makie.add_computation!(attr, Val(:disassemble_mesh), :trace_marker_mesh)
    haskey(attr, :f32c_scale) || Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    haskey(attr, :raster_uv_transform) ||
        Makie.ComputePipeline.alias!(attr, :pattern_uv_transform, :raster_uv_transform)
    haskey(attr, :material) || add_input!(attr, :material, nothing)
    haskey(attr, :world_normalmatrix) || Makie.register_world_normalmatrix!(attr)
    haskey(attr, :view_normalmatrix) || Makie.register_view_normalmatrix!(attr)
    haskey(attr, :uniform_clip_planes) || Makie.add_computation!(attr, Val(:uniform_clip_planes))
    register_raster_lights!(scene)
    for (plotkey, scenekey) in RASTER_LIGHT_NODES
        haskey(attr, plotkey) || add_input!(attr, plotkey, scene.compute[scenekey])
    end
    register_computation!(attr, RASTER_MESHSCATTER_DEPS, [:raster_renderobject]) do args, changed, last
        israster(args) || return (nothing,)
        last_robj = isnothing(last) ? nothing : last.raster_renderobject
        return (mesh_raster!(screen, plot, args, changed, last_robj),)
    end
    return
end
