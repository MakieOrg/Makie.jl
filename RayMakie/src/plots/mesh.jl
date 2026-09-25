# =============================================================================
# draw_atomic for Makie.Mesh
# =============================================================================
#
# A Mesh has two render paths, each with its own node, chosen per frame by
# `screen.rasterize` and `should_raytrace(scene, plot)`:
#
#   - :trace_renderobject   pushed to the Hikari scene and traced; a NamedTuple
#                           (handle, mat_idx, material, instance_idx).
#   - :raster_renderobject  drawn through the port of GLMakie's mesh shader in
#                           overlay/mesh.jl, dispatched on the material; a
#                           RenderObject.

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Mesh)
    attr = plot.attributes
    state = screen.state
    hikari_scene = state.hikari_scene

    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # TWO slots, one per renderer, and each concretely typed.
    #
    # There used to be one — `trace_renderobject` — holding either a Hikari
    # handle or a raster `RenderObject`, and consumers sniffed which by asking
    # `isa RenderObject`. That works only as long as a plot never changes path,
    # which was true while the path came from the camera type: cameras do not
    # change type. The moment a switch exists it breaks, because a compute
    # node's output slot takes its type from the first value it holds and the
    # second kind cannot be stored in it.
    #
    # Separate slots also mean flipping back and forth costs nothing: neither
    # renderer's object is torn down when the other is showing.
    haskey(attr, :rasterize) || add_input!(attr, :rasterize, screen.rasterize)

    register_computation!(attr,
        [:mesh, :positions_transformed_f32c, :faces, :normals,
         :texturecoordinates, :trace_color_tex, :model_f32c, :material, :rasterize],
        [:trace_renderobject]) do args, changed, last
        # `nothing` when this plot is not being traced — the slot still exists,
        # so its type never changes, and the collectors skip a `nothing`.
        (args.rasterize || !should_raytrace(scene, plot) || isnothing(hikari_scene)) &&
            return (nothing,)
        last_robj = isnothing(last) ? nothing : last.trace_renderobject
        return (mesh_trace_dispatch!(hikari_scene, state, plot, args, changed, last, last_robj),)
    end

    haskey(attr, :raster_uv_transform) ||
        Makie.ComputePipeline.alias!(attr, :pattern_uv_transform, :raster_uv_transform)
    register_raster_renderobject!(screen, scene, plot)
end

# The `:raster_renderobject` node of a plot drawn by the mesh shader: `mesh!`, and
# `surface!` through Makie's `surface_as_mesh`. The plot provides whichever nodes
# of `RASTER_MESH_DEPS` Makie does not register for it.
#
# The camera is in that list and not the trace one: a raster object bakes it into
# its arguments, so a camera move has to re-run the node, while the tracer reads
# the camera per sample from the scene state.
function register_raster_renderobject!(screen, scene, plot)
    hikari_scene = screen.state.hikari_scene
    register_raster_mesh_nodes!(plot)
    register_computation!(plot.attributes, RASTER_MESH_DEPS, [:raster_renderobject]) do args, changed, last
        israster = args.rasterize || !should_raytrace(scene, plot) || isnothing(hikari_scene)
        israster || return (nothing,)
        last_robj = isnothing(last) ? nothing : last.raster_renderobject
        return (mesh_overlay_dispatch!(screen, scene, plot, args, changed, last_robj),)
    end
    return
end

# -----------------------------------------------------------------------------
# Trace path
# -----------------------------------------------------------------------------

# Returns true if `robj` was produced by the trace path (has a Hikari handle).
is_trace_robj(robj) = robj !== nothing && hasproperty(robj, :handle)

function mesh_trace_dispatch!(hikari_scene, state, plot, args, changed, last, last_robj)
    # Geometry only. `trace_color_tex` was in this set, so recolouring a mesh
    # tore down its BLAS and rebuilt it — the colour never reaches the geometry,
    # it only ever feeds `extract_material` in `push_to_scene_simple`.
    needs_rebuild = !is_trace_robj(last_robj) ||
                    changed.mesh || changed.positions_transformed_f32c ||
                    changed.faces || changed.normals ||
                    changed.texturecoordinates

    # A colour change is a material swap, with one catch: `MultiTypeSet.update!`
    # replaces in place and so requires the same CONCRETE type. Recolouring can
    # change it — a scalar `Kd` gives `Diffuse{RGBSpectrum}` where a texture
    # gives `Diffuse{Texture{...}}` — and that case still needs the re-push.
    # Decided here rather than in `mesh_trace_update!` because only this function
    # can fall back to a rebuild.
    recolor_material = nothing
    if !needs_rebuild && changed.trace_color_tex
        recolor_material = trace_material_for_color(plot, args)
        if recolor_material === nothing ||
                typeof(recolor_material) !== typeof(last_robj.material)
            needs_rebuild = true
        end
    end

    if needs_rebuild
        # Classify BEFORE rebuilding, and only for a mesh that already had a
        # BLAS — the first build is not something a refit could have avoided.
        if is_trace_robj(last_robj)
            # `changed.mesh` is deliberately NOT consulted: `:mesh` is the
            # container `register_mesh_decomposition!` decomposes, so replacing
            # `arg1` dirties it whatever the new mesh contains. The decomposed
            # nodes are the topology signal, and they are accurate — a mesh
            # rebuilt with equal faces reports `faces = false`.
            #
            # One trap in reading them: `ComputePipeline.is_same(::Array, ::Array)`
            # reports the SAME array object as CHANGED, because in-place mutation
            # between resolves is undetectable, and only compares by `isequal`
            # when the pointers differ. So handing back the identical `faces`
            # vector marks it dirty while handing back a copy does not.
            if (changed.positions_transformed_f32c || changed.normals) &&
                    !(changed.faces || changed.texturecoordinates)
                state.refit_eligible_rebuilds += 1
            else
                state.topology_rebuilds += 1
            end
        end
        # Drop the previous trace handle (if any) before rebuilding so
        # scene.materials / scene.media_interfaces stay bounded.
        is_trace_robj(last_robj) && delete_trace_handles!(hikari_scene, last_robj)
        reuse_mat_idx = reusable_material_idx(last)
        return mesh_trace_create!(hikari_scene, state, plot, args, reuse_mat_idx)
    end

    return mesh_trace_update!(hikari_scene, state, last_robj, args, changed, recolor_material)
end

"""
    trace_material_for_color(plot, args) -> Hikari.Material or nothing

The material `push_to_scene_simple` would build for the current colour, without
touching the geometry. `nothing` means "cannot be done without a rebuild".

Per-vertex colours are the reason this can fail: they are baked into a texture
against the mesh's vertex count, so `build_vertex_color_texture` needs the mesh.
`args.mesh` is a `MetaMesh` for glTF/OBJ content, whose embedded per-face
materials `push_to_scene` resolves through a different path entirely — that one
is left to the rebuild rather than reimplemented here.
"""
function trace_material_for_color(plot, args)
    color_tex = args.trace_color_tex
    if color_tex isa AbstractVector{<:Colorant}
        mesh_val = args.mesh
        mesh_val isa GeometryBasics.Mesh || return nothing
        color_tex = build_vertex_color_texture(color_tex, mesh_val)
    end
    return extract_material(plot, color_tex)
end

function mesh_trace_create!(hikari_scene, state, plot, args, reuse_mat_idx)
    transform = Mat4f(args.model_f32c)
    robj = push_to_scene(args.mesh, hikari_scene, plot, args.trace_color_tex,
                         args.positions_transformed_f32c, args.faces,
                         args.normals, args.texturecoordinates, transform,
                         reuse_mat_idx)
    state.needs_film_clear = true
    return robj
end

function mesh_trace_update!(hikari_scene, state, robj, args, changed, recolor_material = nothing)
    if changed.model_f32c
        update_trace_transform!(hikari_scene, state, robj, Mat4f(args.model_f32c))
    end
    if recolor_material !== nothing
        # Type-checked against the stored material by the caller, so this is the
        # in-place `MultiTypeSet.update!` and the BLAS is untouched. The robj
        # carries the material forward so the next colour change compares
        # against what is actually stored.
        update_trace_material!(hikari_scene, state, robj, recolor_material)
        robj = merge(robj, (material = recolor_material,))
    end
    if changed.material
        # Pass args.material raw (NOT through extract_material again).
        # extract_material can wrap Kr/Kt/index into `Texture{...}` when
        # Makie has since populated plot.color with a default, but the
        # initial push stored the material unwrapped.  MultiTypeSet.update!
        # requires matching concrete types, so we must preserve whatever
        # structure the user passed.
        update_trace_material!(hikari_scene, state, robj, args.material)
    end
    return robj
end

# -----------------------------------------------------------------------------
# Overlay path (2D mesh, rasterized via graphics pipeline)
# -----------------------------------------------------------------------------

"""
    plot_clip_matrix(plot) -> Mat4f

The projection that takes `plot`'s vertices to clip space: its OWN scene's
camera, for the SPACE the plot declares.

Its own scene, and that is not the one `draw_atomic` is handed. A block's
contents live in sub-scenes — a `Menu`'s dropdown is a `Scene` of its own,
translated in z and given an absolute pixel camera over its own viewport — and
projecting its vertices through the enclosing scene's camera puts them somewhere
else entirely. What that looked like: an open dropdown drew its LABELS (which
read the plot's own matrix) in the right place and its option BACKGROUNDS
nowhere at all, so the panel underneath showed through the menu.

`scene.camera.projectionview` is the data-space one and was used for every plot
regardless. A plot with `space = :pixel` — Makie's rectangle-zoom rubber band is
one — then had its pixel coordinates fed to clip space through a matrix that is
the identity for that space, putting every vertex hundreds of units outside the
[-1, 1] volume, so it rasterised nothing. Dragging a zoom rectangle applied the
right limits on release and drew no rectangle on the way, which is what "the
zoom rectangle does nothing" looked like.

`Makie.space_to_clip` is the accessor that answers this and it was used nowhere
in this backend; the four coordinate spaces are not a special case to branch on,
they are what the attribute means.
"""
plot_clip_matrix(plot) =
    Mat4f(Makie.space_to_clip(Makie.parent_scene(plot).camera,
                              Makie.to_value(get(plot, :space, :data))))

"""
    mesh_overlay_dispatch!(screen, scene, plot, args, changed, last_robj)

The RASTER path for a mesh, dispatched ON THE MATERIAL.

This is the raster counterpart of what the trace path does with `get_bxdf`: the
material decides how the thing is drawn. A `Hikari.FEMMaterial` carries curved
elements, so on this side it selects a MESH SHADER that subdivides them, the
same way it selects procedural geometry on the other — one type, one decision,
two paths. Everything else draws the triangles it was given.
"""
mesh_overlay_dispatch!(screen, scene, plot, args, changed, last_robj) =
    mesh_overlay_dispatch!(overlay_material(plot), screen, scene, plot, args, changed, last_robj)

"""The material a plot draws with on the raster path, or `nothing`."""
function overlay_material(plot)
    haskey(plot, :material) || return nothing
    return to_value(plot.material)
end

function mesh_overlay_dispatch!(::Any, screen, scene, plot, args, changed, last_robj)
    return mesh_raster!(screen, plot, args, changed, last_robj)
end

# -----------------------------------------------------------------------------
# Raster path: the ported GLMakie mesh shader (overlay/mesh.jl)
# -----------------------------------------------------------------------------

"""
Everything the raster node reads. The plot's own nodes, the four GLMakie also
registers per mesh (normal matrices, packed stroke data, clip planes), and the
scene's lights as plot inputs, so a light change re-runs the node.

`:raster_uv_transform` is the plot's own: a mesh's `pattern_uv_transform`, and
for a surface that composed with the shift to texel centres.
"""
const RASTER_MESH_DEPS = [
    :positions_transformed_f32c, :faces, :normals, :texturecoordinates, :model_f32c,
    :material, :rasterize,
    :scaled_color, :alpha_colormap, :scaled_colorrange, :color_mapping_type,
    :lowclip_color, :highclip_color, :nan_color, :interpolate_in_fragment_shader,
    :interpolate, :raster_uv_transform, :fetch_pixel, :matcap,
    :shading, :diffuse, :specular, :shininess, :backlight, :depth_shift,
    :world_normalmatrix, :view_normalmatrix,
    :strokewidth, :strokecolor, :stroke_data_packed,
    :uniform_clip_planes, :uniform_num_clip_planes,
    :view, :projection, :eyeposition, :resolution, :viewport,
    :raster_ambient, :raster_light_color, :raster_light_direction,
    :raster_N_lights, :raster_light_types, :raster_light_colors, :raster_light_parameters,
    :raster_env_sh, :raster_has_env,
]

# Plot input => scene node. Prefixed, not GLMakie's `:ambient`, `:light_types`, …:
# GLMakie force-deletes those on a plot it displays, and with them every node
# that depends on them, so a figure shown by both backends would lose this one.
const RASTER_LIGHT_NODES = (
    :raster_ambient => :ambient_color, :raster_light_color => :dirlight_color,
    :raster_light_direction => :dirlight_final_direction,
    :raster_N_lights => :N_lights, :raster_light_types => :light_types,
    :raster_light_colors => :light_colors, :raster_light_parameters => :light_parameters,
    :raster_env_sh => :raster_env_sh, :raster_has_env => :raster_has_env,
)

function register_raster_mesh_nodes!(plot)
    attr = plot.attributes
    haskey(attr, :world_normalmatrix) || Makie.register_world_normalmatrix!(attr)
    haskey(attr, :view_normalmatrix) || Makie.register_view_normalmatrix!(attr)
    Makie.register_stroke_data!(attr)
    haskey(attr, :uniform_clip_planes) || Makie.add_computation!(attr, Val(:uniform_clip_planes))
    scene = Makie.parent_scene(plot)
    register_raster_lights!(scene)
    for (plotkey, scenekey) in RASTER_LIGHT_NODES
        haskey(attr, plotkey) || add_input!(attr, plotkey, scene.compute[scenekey])
    end
    return
end

function register_raster_lights!(scene)
    graph = scene.compute
    # GLMakie's defaults for `max_lights` and `max_light_parameters`.
    haskey(graph, :N_lights) || Makie.register_multi_light_computation(scene, 64, 5 * 64)
    haskey(graph, :raster_env_sh) ||
        Makie.ComputePipeline.map!(environment_sh, graph, :lights, [:raster_env_sh, :raster_has_env])
    return
end

"""
    environment_sh(lights) -> (Mat{3,9,Float32}, Int32)

The scene's `EnvironmentLight`s as nine spherical-harmonic coefficients of their
irradiance over π, which is what `env_irradiance` in overlay/mesh.jl evaluates.

The map is read the way the tracer reads it (`Hikari.EnvironmentMap`: equal-area
square, a 2:1 image converted), and each texel of that square covers the same
solid angle, so the projection is a plain sum. The radiance is `intensity *
image`, Makie's meaning: a white map of intensity 1 lights a white surface to 1.
"""
function environment_sh(lights)
    sh = zeros(Float32, 3, 9)
    has = false
    for light in lights
        light isa Makie.EnvironmentLight || continue
        has = true
        project_environment!(sh, light)
    end
    # The clamped cosine's band weights, π, 2π/3 and π/4, over π.
    sh[:, 2:4] .*= 2f0 / 3f0
    sh[:, 5:9] .*= 0.25f0
    return (Mat{3, 9, Float32}(sh), Int32(has))
end

function project_environment!(sh, light::Makie.EnvironmentLight)
    data = map(c -> Hikari.RGBSpectrum(Float32(red(c)), Float32(green(c)), Float32(blue(c))), light.image)
    env = Hikari.EnvironmentMap(data, Hikari.rotation_matrix(light.rotation_angle, light.rotation_axis))
    n = size(env.data, 1)
    dω = Float32(4π) / Float32(n * n)
    scale = Float32(light.intensity) * dω
    for j in 1:n, i in 1:n
        d = Hikari.uv_to_direction_equal_area(Point2f((i - 0.5f0) / n, (j - 0.5f0) / n), env.rotation)
        c = env.data[j, i].c
        x, y, z = d[1], d[2], d[3]
        basis = (0.282095f0, 0.488603f0 * y, 0.488603f0 * z, 0.488603f0 * x,
                 1.092548f0 * x * y, 1.092548f0 * y * z, 0.315392f0 * (3f0 * z * z - 1f0),
                 1.092548f0 * x * z, 0.546274f0 * (x * x - y * y))
        for k in 1:9, ch in 1:3
            sh[ch, k] += scale * c[ch] * basis[k]
        end
    end
    return sh
end

"""
    raster_geometry(material, args) -> NamedTuple

What the raster path draws: the plot's own triangles, or a `GeneratedGeometry`'s
tessellation.
"""
function raster_geometry(::Any, args)
    return (positions = map(p -> Vec3f(Makie.to_ndim(Point3f, p, 0f0)), args.positions_transformed_f32c),
            faces = args.faces, normals = args.normals, uvs = args.texturecoordinates,
            color = args.scaled_color)
end

function raster_geometry(material::Hikari.GeneratedGeometry, args)
    mesh = Hikari.tessellate(material)
    return (positions = map(p -> Vec3f(p[1], p[2], p[3]), GeometryBasics.coordinates(mesh)),
            faces = GeometryBasics.faces(mesh),
            normals = hasproperty(mesh, :normal) ? mesh.normal : nothing,
            uvs = hasproperty(mesh, :uv) ? mesh.uv : nothing,
            color = hasproperty(mesh, :color) ? mesh.color : args.scaled_color)
end

# Makie's packed stroke data describes the plot's own triangles, not generated ones.
raster_strokes(::Any) = true
raster_strokes(::Hikari.GeneratedGeometry) = false

rgba4(c) = (c = RGBA{Float32}(c); Vec4f(c.r, c.g, c.b, c.alpha))

"""
Where the colour comes from, as GLMakie's `add_mesh_color_attributes!` decides
it, and what that needs uploaded.
"""
function raster_color(color, args, npositions)
    none = Vec4f(0, 0, 0, 1)
    if args.matcap !== nothing
        return (source = COLOR_MATCAP, uniform = none, texture = texeldata(args.matcap), wrap = :clamp)
    elseif color isa Colorant
        return (source = COLOR_UNIFORM, uniform = rgba4(color), texture = nothing, wrap = :clamp)
    elseif color isa Makie.ShaderAbstractions.Sampler || color isa AbstractMatrix{<:Colorant}
        img = color isa Makie.ShaderAbstractions.Sampler ? color.data : color
        pattern = args.fetch_pixel::Bool
        return (source = pattern ? COLOR_PATTERN : COLOR_IMAGE, uniform = none,
                texture = texeldata(img), wrap = pattern ? :repeat : :clamp)
    elseif color isa AbstractVector{<:Colorant}
        length(color) == npositions || throw(ArgumentError(
            "mesh: $(length(color)) colours for $npositions vertices; RASTER mode needs one per vertex"))
        return (source = COLOR_VERTEX, uniform = none, texture = nothing, wrap = :clamp)
    elseif color isa AbstractMatrix{<:Real}
        return (source = COLOR_IMAGE_CMAP, uniform = none,
                texture = map(v -> (Float32(v), 0f0, 0f0, 1f0), color), wrap = :clamp)
    elseif color isa AbstractArray{<:Real, 3}
        throw(ArgumentError("mesh: a 3D texture colour is not supported in RASTER mode"))
    elseif color isa AbstractVector{<:Real}
        return (source = args.interpolate_in_fragment_shader ? COLOR_VERTEX_CMAP_FRAG : COLOR_VERTEX_CMAP,
                uniform = none, texture = nothing, wrap = :clamp)
    elseif color isa Real
        c = get_color_from_cmap(Float32(color), raster_colormap(args), Vec2f(args.scaled_colorrange),
                                Int32(args.color_mapping_type === Makie.continuous),
                                rgba4(args.lowclip_color), rgba4(args.highclip_color), rgba4(args.nan_color))
        return (source = COLOR_UNIFORM, uniform = c, texture = nothing, wrap = :clamp)
    end
    throw(ArgumentError("mesh: RASTER mode cannot draw a colour of type $(typeof(color))"))
end

raster_colormap(args) = args.alpha_colormap === nothing ? Vec4f[Vec4f(0, 0, 0, 1)] : rgba4.(args.alpha_colormap)

# A buffer the stage indexes must exist even when nothing reads it.
nonempty(v::AbstractVector{T}) where {T} = isempty(v) ? T[zero(T)] : v

function raster_faces(faces)
    out = Vector{UInt32}(undef, 3 * length(faces))
    @inbounds for (i, f) in enumerate(faces), j in 1:3
        out[3 * (i - 1) + j] = UInt32(Base.to_index(f[j]))
    end
    return out
end

raster_uv_transform(t::Mat{2, 3}) = Mat{2, 3, Float32}(t)
raster_uv_transform(t::Mat{3, 3}) = Mat{2, 3, Float32}(t[1], t[2], t[4], t[5], t[7], t[8])
raster_uv_transform(::Nothing) = Mat{2, 3, Float32}(1, 0, 0, 1, 0, 0)

function shading_code(mode)
    mode === Makie.FastShading && return SHADING_FAST
    mode === Makie.MultiLightShading && return SHADING_MULTI
    return SHADING_NONE
end

"""
    raster_shading(screen, plot, args) -> (uniforms, buffers)

The lighting, film mapping and stroke state every lit raster surface is shaded
with. A material that draws its own geometry (a mesh stage) passes these to the
same `illuminate` and `apply_stroke` the mesh shader calls.
"""
function raster_shading(screen, plot, args)
    config = screen.config
    ambient = RGBf(args.raster_ambient)
    lc = RGBf(args.raster_light_color)
    uniforms = (
        eyeposition = Vec3f(args.eyeposition),
        shading_mode = shading_code(Makie.get_shading_mode(plot)),
        ambient = Vec3f(ambient.r, ambient.g, ambient.b),
        light_color = Vec3f(lc.r, lc.g, lc.b),
        light_direction = Vec3f(args.raster_light_direction),
        N_lights = Int32(args.raster_N_lights),
        has_env = args.raster_has_env,
        env_sh = args.raster_env_sh,
        diffuse = Vec3f(args.diffuse), specular = Vec3f(args.specular),
        shininess = Float32(args.shininess), backlight = Float32(args.backlight),
        exposure = Float32(config.exposure),
        tonemap = Int32(Hikari.tonemap_code(config.tonemap)),
        white_point = 4f0,  # Hikari.postprocess!'s default, which RayMakie does not set
        inv_gamma = config.gamma === nothing ? 1f0 : 1f0 / Float32(config.gamma),
        apply_gamma = Int32(config.gamma !== nothing),
        strokewidth = Float32(args.strokewidth), strokecolor = rgba4(args.strokecolor),
        resolution = Vec2f(args.resolution), px_per_unit = Float32(screen.px_per_unit),
    )
    buffers = (
        light_types = nonempty(Vector{Int32}(args.raster_light_types)),
        light_colors = nonempty(Vec3f[Vec3f(c.r, c.g, c.b) for c in args.raster_light_colors]),
        light_parameters = nonempty(Vector{Float32}(args.raster_light_parameters)),
    )
    return uniforms, buffers
end

"""
    mesh_raster!(screen, plot, args, changed, last_robj) -> RenderObject

A `mesh` in RASTER mode, through the ported GLMakie mesh shader. Each buffer is
re-uploaded only when the nodes it is made from changed, so a camera move sets
uniforms and uploads nothing.
"""
function mesh_raster!(screen, plot, args, changed, last_robj)
    fresh = !(last_robj isa RenderObject)
    geometry_dirty = fresh || changed.positions_transformed_f32c || changed.faces ||
                     changed.normals || changed.texturecoordinates || changed.material
    color_dirty = geometry_dirty || changed.scaled_color || changed.alpha_colormap ||
                  changed.matcap || changed.fetch_pixel || changed.interpolate ||
                  changed.interpolate_in_fragment_shader || changed.scaled_colorrange ||
                  changed.color_mapping_type || changed.lowclip_color ||
                  changed.highclip_color || changed.nan_color

    shading, lightbuffers = raster_shading(screen, plot, args)
    uniforms = merge((
        model = Mat4f(args.model_f32c), view = Mat4f(args.view), projection = Mat4f(args.projection),
        world_normalmatrix = Mat3f(args.world_normalmatrix),
        view_normalmatrix = Mat3f(args.view_normalmatrix),
        depth_shift = Float32(args.depth_shift),
        uv_transform = raster_uv_transform(args.raster_uv_transform),
        colorrange = args.scaled_colorrange === nothing ? Vec2f(0, 1) : Vec2f(args.scaled_colorrange),
        colormap_linear = Int32(args.color_mapping_type === Makie.continuous),
        lowclip = rgba4(args.lowclip_color), highclip = rgba4(args.highclip_color),
        nan_color = rgba4(args.nan_color),
        viewport_origin = Vec2f(GeometryBasics.origin(args.viewport)),
        num_clip_planes = Int32(args.uniform_num_clip_planes),
    ), shading)

    buffers = Dict{Symbol, Any}()
    local colorinfo
    if color_dirty
        geometry = raster_geometry(overlay_material(plot), args)
        colorinfo = raster_color(geometry.color, args, length(geometry.positions))
        textured = colorinfo.texture !== nothing
        fresh |= !fresh && last_robj.pipeline !== get_mesh_pipeline!(screen, textured)
        uniforms = merge(uniforms, (
            has_normals = Int32(geometry.normals !== nothing),
            has_uvs = Int32(geometry.uvs isa AbstractVector{<:VecTypes{2}}),
            color_source = colorinfo.source, uniform_color = colorinfo.uniform,
        ))
        vertex_count = 3 * length(geometry.faces)
        if fresh || geometry_dirty
            buffers[:raster_positions] = nonempty(geometry.positions)
            buffers[:raster_faces] = nonempty(raster_faces(geometry.faces))
            buffers[:raster_normals] = geometry.normals === nothing ? Vec3f[Vec3f(0)] :
                                       nonempty(Vector{Vec3f}(geometry.normals))
            buffers[:raster_uvs] = uniforms.has_uvs != 0 ? nonempty(Vec2f.(geometry.uvs)) : Vec2f[Vec2f(0)]
        end
        buffers[:raster_vertex_color] = colorinfo.source == COLOR_VERTEX ?
            rgba4.(geometry.color) : Vec4f[Vec4f(0)]
        buffers[:raster_vertex_value] = colorinfo.source in (COLOR_VERTEX_CMAP, COLOR_VERTEX_CMAP_FRAG) ?
            nonempty(Vector{Float32}(geometry.color)) : Float32[0f0]
        buffers[:raster_colormap] = raster_colormap(args)
    end
    if fresh || changed.stroke_data_packed || geometry_dirty
        buffers[:stroke_data] = nonempty(Vector{Vec4f}(args.stroke_data_packed))
    end
    if fresh || changed.uniform_clip_planes
        buffers[:clip_planes] = nonempty(Vector{Vec4f}(args.uniform_clip_planes))
    end
    if fresh || changed.raster_light_types || changed.raster_light_colors || changed.raster_light_parameters
        for (name, value) in pairs(lightbuffers)
            buffers[name] = value
        end
    end

    robj = if fresh
        backend = screen.config.device
        RenderObject(get_mesh_pipeline!(screen, colorinfo.texture !== nothing);
            backend,
            fxaa = plot_fxaa(plot),
            arg_names = MESH_ARG_NAMES,
            buffers = Dict{Symbol, AbstractGPUArray}(name => Mantle.devicearray(backend, value)
                                                     for (name, value) in buffers),
            uniforms = Dict{Symbol, Any}(),
            vertex_count = 0,
            instances = 1,
        )
    else
        for (name, value) in buffers
            update_buffer!(last_robj, name, value)
        end
        last_robj
    end
    for (name, value) in pairs(uniforms)
        robj.uniforms[name] = value
    end
    raster_strokes(overlay_material(plot)) || (robj.uniforms[:strokewidth] = 0f0)
    color_dirty && (robj.vertex_count = vertex_count)
    if color_dirty && colorinfo.texture !== nothing
        update_texture!(robj, colorinfo.texture;
                        filter = args.interpolate ? :linear : :nearest, wrap = colorinfo.wrap)
    end
    robj.visible = true
    return robj
end

# =============================================================================
# Material helpers — in-place swap on existing handle
# =============================================================================

"""
Swap the material of an existing mesh scene handle in place — no BLAS/HWTLAS
rebuild.  For a `MediumInterface`, unpack to surface + inside updates.
"""
function update_trace_material!(hikari_scene, state, robj, new_material)
    hikari_scene === nothing && return
    robj === nothing && return
    h = hasproperty(robj, :handle) ? robj.handle : return
    interface_idx = h isa Hikari.SceneHandle ? h.interface :
                    hasproperty(robj, :mat_idx) ? robj.mat_idx : return
    if new_material isa Hikari.MediumInterface
        Hikari.update_material!(hikari_scene, interface_idx, new_material.material)
        new_material.inside !== nothing &&
            Hikari.update_material!(hikari_scene, interface_idx, new_material.inside)
    elseif new_material isa Hikari.Material
        Hikari.update_material!(hikari_scene, interface_idx, new_material)
    end
    state.needs_film_clear = true
    return nothing
end

# =============================================================================
# push_to_scene dispatch
# =============================================================================

# Extract diffuse texture from a GLTF material dict
function extract_glb_diffuse_texture(mat_dict::Dict{String, Any})
    if haskey(mat_dict, "diffuse map")
        diffuse_map = mat_dict["diffuse map"]
        if haskey(diffuse_map, "image")
            return Hikari.Texture(to_spectrum(diffuse_map["image"]))
        end
    end
    diffuse = get(mat_dict, "diffuse", Vec3f(1, 1, 1))
    return Hikari.ConstTexture(to_spectrum(RGBf(diffuse[1], diffuse[2], diffuse[3])))
end

# Does the prior trace_renderobject carry a `mat_idx` we can recycle?
# Every rebuild that takes this path keeps `scene.materials` /
# `scene.media_interfaces` a fixed size, letting `Raycore.update!` re-use the
# backing GPU texture slot rather than growing it each frame.
function reusable_material_idx(last)
    last === nothing && return nothing
    last_robj = last.trace_renderobject
    last_robj === nothing && return nothing
    hasproperty(last_robj, :mat_idx) || return nothing
    return UInt32(last_robj.mat_idx)
end

# MetaMesh: multi-material.  Per-face materials don't currently share a slot
# with the prior render object (multi-mat rebuilds are rare), so the
# `reuse_mat_idx` argument is ignored — the normal push path runs.
function push_to_scene(mesh_val::GeometryBasics.MetaMesh, hikari_scene, plot, color_tex,
                       positions, faces, normals, uv, transform,
                       reuse_mat_idx::Union{Nothing, UInt32})
    has_embedded = haskey(mesh_val, :material_names) && haskey(mesh_val, :materials)
    if !has_embedded
        return push_to_scene_simple(mesh_val.mesh, hikari_scene, plot, color_tex, transform,
                                     reuse_mat_idx)
    end

    user_material = haskey(plot, :material) && !isnothing(to_value(plot.material)) ?
        to_value(plot.material) : nothing

    inner = mesh_val.mesh
    views = inner.views
    mat_names = mesh_val[:material_names]
    materials_dict = mesh_val[:materials]
    gb_faces = GeometryBasics.faces(inner)
    n_faces = length(gb_faces)

    per_face_materials = Vector{Hikari.Material}(undef, n_faces)
    mat_cache = Dict{String, Hikari.Material}()
    for (view_range, name) in zip(views, mat_names)
        mat = get!(mat_cache, name) do
            if haskey(materials_dict, name)
                mat_entry = materials_dict[name]
                if mat_entry isa Hikari.Material
                    mat_entry
                elseif !isnothing(user_material)
                    tex = extract_glb_diffuse_texture(mat_entry)
                    merge_color_with_material(tex, user_material)
                else
                    result = glb_material_to_hikari(mat_entry)
                    m = result.material
                    if !isnothing(result.emission)
                        m = Hikari.MediumInterface(m; emission=result.emission)
                    end
                    m
                end
            else
                extract_material(plot, color_tex)
            end
        end
        for fi in view_range
            per_face_materials[fi] = mat
        end
    end

    handle = push!(hikari_scene, inner, per_face_materials; transform=transform)
    return (handle=handle, instance_idx=Raycore.n_instances(hikari_scene.accel))
end

# Plain mesh: single material
function push_to_scene(mesh_val, hikari_scene, plot, color_tex,
                       positions, faces, normals_arg, uv, transform,
                       reuse_mat_idx::Union{Nothing, UInt32})
    push_to_scene_simple(mesh_val, hikari_scene, plot, color_tex, transform,
                          reuse_mat_idx;
                          positions=positions, faces=faces, normals=normals_arg, uv=uv)
end

# Internal: build GB.Mesh from decomposed data and push with single material.
# When `reuse_mat_idx` is given, the pre-existing material slot is refreshed
# via `Hikari.update_material!` and the mesh is pushed with that same idx,
# keeping `scene.materials` / `scene.media_interfaces` a fixed size across
# rebuilds.  `update_material!` reuses the GPU texture buffer through the
# `Raycore.update_item` / `Raycore.copyto_texture!` dispatch chain.
function push_to_scene_simple(mesh_val, hikari_scene, plot, color_tex, transform,
                               reuse_mat_idx::Union{Nothing, UInt32};
                               positions=nothing, faces=nothing, normals=nothing, uv=nothing)
    gb_mesh = if mesh_val isa GeometryBasics.Mesh
        mesh_val
    else
        kwargs = Dict{Symbol, Any}()
        !isnothing(normals) && (kwargs[:normal] = Vec3f.(normals))
        !isnothing(uv) && (kwargs[:uv] = Vec2f.(uv))
        m = GeometryBasics.Mesh(Point3f.(positions), faces; kwargs...)
        isnothing(normals) ? GeometryBasics.normal_mesh(m) : m
    end

    if color_tex isa AbstractVector{<:Colorant}
        color_tex = build_vertex_color_texture(color_tex, gb_mesh)
    end

    mat = extract_material(plot, color_tex)
    handle = if reuse_mat_idx === nothing
        push!(hikari_scene, gb_mesh, mat; transform=transform)
    else
        Hikari.update_material!(hikari_scene, reuse_mat_idx, mat)
        push!(hikari_scene, gb_mesh, reuse_mat_idx, mat; transform=transform)
    end
    state_instance_idx = Raycore.n_instances(hikari_scene.accel)
    return (handle=handle, mat_idx=handle.interface, material=mat, instance_idx=state_instance_idx)
end

# =============================================================================
# Handle management
# =============================================================================

function delete_trace_handles!(hikari_scene, robj)
    tlas = hikari_scene.accel
    if hasproperty(robj, :handles)
        for h in robj.handles
            actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
            delete!(tlas, actual_handle)
        end
    elseif hasproperty(robj, :handle)
        h = robj.handle
        actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
        delete!(tlas, actual_handle)
    end
end

function update_trace_transform!(hikari_scene, state, robj, transform)
    tlas = hikari_scene.accel

    # `update_transform!(accel, handle, transform)` for BOTH shapes. The single
    # -handle branch used to take the index-based
    # `update_instance_transforms!(tlas, transforms, 1, idx)`, which only
    # `Raycore.TLAS` implements — `Mantle.HWTLAS` is batch/handle-addressed and has
    # no such method. So under `hw_accel = true` (the default) moving a `mesh!`
    # threw a MethodError that `poll_all_plots` logged and swallowed, and the
    # transform silently never applied. The multi-handle branch was already on
    # the handle API and worked, which is why meshscatter moved and mesh did not.
    #
    # A single mesh is a batch of one, and `update_transform!` sets every
    # instance in the batch, so this is the same operation without the
    # per-update `allocate` + `fill!` the index path needed.
    handles = hasproperty(robj, :handles) ? robj.handles : (robj.handle,)
    for h in handles
        actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
        Raycore.update_transform!(tlas, actual_handle, transform)
    end
    state.needs_film_clear = true
end
