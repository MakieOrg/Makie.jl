using Makie: register_computation!

function plot_updates(args, changed, name_map)
    new_values = []
    for (name, value) in pairs(args)
        if changed[name]
            name = get(name_map, name, name)
            push!(new_values, [name, serialize_three(value[])])
        end
    end
    return new_values
end

function update_values!(updater, values::Bonito.LargeUpdate)
    isempty(values.data) && return
    updater[] = values
    return
end

function update_values!(updater, values)
    isempty(values) && return
    updater[] = values
    return
end


function assemble_particle_robj!(attr, data)
    @show attr.scaled_colorrange[]
    needs_mapping = !(attr.scaled_colorrange[] isa Nothing)
    color_norm = needs_mapping ? Vec2f(attr.scaled_colorrange[]) : false

    data[:positions_transformed_f32c] = attr.positions_transformed_f32c[]
    data[:colormap] = needs_mapping ? Sampler(attr.alpha_colormap[]) : false
    data[:color] = attr.scaled_color[]
    data[:colorrange] = color_norm
    data[:highclip] = attr.highclip_color[]
    data[:lowclip] = attr.lowclip_color[]
    data[:nan_color] = attr.nan_color[]

    data[:rotation] = attr.rotation[]

    # Camera will be set in JS
    data[:model] = Mat4f(I)
    data[:px_per_unit] = 0f0
    data[:picking] = false
    data[:object_id] = UInt32(0)

    data[:depth_shift] = attr.depth_shift[]
    data[:transform_marker] = attr.transform_marker[]

    per_instance_keys = (
        :positions_transformed_f32c, :rotation, :markersize, :color, :intensity, :uv_offset_width, :quad_offset, :marker_offset
    )
    per_instance = filter(data) do (k, v)
        return k in per_instance_keys && !(Makie.isscalar(v))
    end
    filter!(data) do (k, v)
        return !(k in per_instance_keys && !(Makie.isscalar(v)))
    end

    handle_color_getter!(data, per_instance)

    if haskey(data, :color) && haskey(per_instance, :color)
        to_value(data[:color]) isa Bool && delete!(data, :color)
        to_value(per_instance[:color]) isa Bool && delete!(per_instance, :color)
    end
    _, arr = first(per_instance)
    if any(v -> length(arr) != length(v), values(per_instance))
        lens = [k => length(v) for (k, v) in per_instance]
        error("Not all have the same length: $(lens)")
    end

    return VertexArray(; per_instance...), data
end

const SCATTER_INPUTS = [
    :positions_transformed_f32c,
    :scaled_color,
    :alpha_colormap,
    :scaled_colorrange,
    :rotation,
    :quad_scale,
    :quad_offset,
    :sdf_uv,
    :sdf_marker_shape,
    :image,
    :strokewidth,
    :strokecolor,
    :glowwidth,
    :glowcolor,
    :depth_shift,
    :atlas_1024_32,
    :markerspace,
    :nan_color,
    :highclip_color,
    :lowclip_color,
    :visible,
    :transform_marker
]

function scatter_program(attr, changed, last)
    r = Dict(
        :quad_scale => :markersize,
        :sdf_uv => :uv_offset_width,
        :sdf_marker_shape => :shape_type,
        :model_f32c => :model,
    )
    if isnothing(last)
        dfield = attr.sdf_marker_shape[] === Cint(Makie.DISTANCEFIELD)
        atlas = attr.atlas_1024_32[]
        distancefield = dfield ? NoDataTextureAtlas(size(atlas.data)) : false
        data = Dict(
            :marker_offset => Vec3f(0),
            :markersize => attr.quad_scale[],
            :quad_offset => attr.quad_offset[],
            :uv_offset_width => attr.sdf_uv[],
            :shape_type => attr.sdf_marker_shape[],
            :distancefield => distancefield,
            :image => isnothing(attr.image[]) ? false : attr.image[],
            :resolution => Vec2f(0),
            :preprojection => Mat4f(I),
            :billboard => attr.rotation[] isa Billboard,
            :atlas_texture_size => Float32(size(atlas.data, 2)),
            :shape_type => attr.sdf_marker_shape[],
            :strokewidth => attr.strokewidth[],
            :strokecolor => attr.strokecolor[],
            :glowwidth => attr.glowwidth[],
            :glowcolor => attr.glowcolor[],
        )
        per_instance, uniforms = assemble_particle_robj!(attr, data)
        instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1.0f0, 1.0f0))
        program = InstancedProgram(
            WebGL(),
            lasset("sprites.vert"),
            lasset("sprites.frag"),
            instance,
            per_instance,
            uniforms,
        )
        return (program, Observable([]))
    else
        updater = last[2][]
        update_values!(updater, plot_updates(attr, changed, r))
        return nothing
    end
end

function create_shader(::Scene, plot::Scatter)
    attr = plot.args[1]
    Makie.all_marker_computations!(attr, 1024, 32)
    register_computation!(scatter_program, attr, SCATTER_INPUTS, [:wgl_renderobject, :wgl_update_obs])
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end

function meshscatter_program(args, changed, last)
    r = Dict(
        :quad_scale => :markersize,
        :sdf_uv => :uv_offset_width,
        :sdf_marker_shape => :shape_type,
        :model_f32c => :model,
    )
    if isnothing(last)
        instance = args.marker[]
        data = Dict{Symbol, Any}(
            :ambient => Vec3f(0.5),
            :diffuse => args.diffuse[],
            :specular => args.specular[],
            :shininess => args.shininess[],
            :pattern => false,
            :uniform_color => false,
            :uv_transform => Mat3f(I),
            :light_direction => Vec3f(1),
            :light_color => Vec3f(1),
            :PICKING_INDEX_FROM_UV => false,
            :shading => args.shading[] != NoShading,
            :backlight => args.backlight[],
            :interpolate_in_fragment_shader => false,
            :markersize => args.markersize[],
            :f32c_scale => args.f32c_scale[],
            :uv => Vec2f(0)
        )
        per_instance, uniforms = assemble_particle_robj!(args, data)
        program = InstancedProgram(
            WebGL(), lasset("particles.vert"), lasset("mesh.frag"),
            instance, per_instance, uniforms
        )
        return (program, Observable([]))
    else
        updater = last[2][]
        update_values!(updater, plot_updates(args, changed, r))
        return nothing
    end
end


function create_shader(scene::Scene, plot::MeshScatter)
    attr = plot.args[1]
    # generate_clip_planes!(attr, scene)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))
    Makie.add_computation!(attr, scene, Val(:uv_transform_packing), :pattern_uv_transform)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    Makie.register_world_normalmatrix!(attr)


    inputs = [
        # Special
        :space,
        :alpha_colormap, :scaled_color, :scaled_colorrange,
        :packed_uv_transform,
        :positions_transformed_f32c, :markersize, :rotation, :f32c_scale,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :fetch_pixel, :model_f32c,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :transform_marker, :marker, :shading, :depth_shift
    ]
    register_computation!(meshscatter_program, attr, inputs, [:wgl_renderobject, :wgl_update_obs])
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end


function add_uv_mesh!(attr)
    register_computation!(attr, [:data_limits], [:data_limit_points]) do (rect,), changed, last
        return (decompose(Point2f, Rect2f(rect[])),)
    end
    register_computation!(
        attr, [:data_limit_points, :f32c, :transform_func, :space], [:data_limit_points_transformed]
    ) do (points, f32c, func, space), changed, last
        return (apply_transform(func[], points[], space[]),)
    end
end

function create_image_mesh(attr)
    i = Vec(1, 2, 3)
    M = convert_attribute(:rotl90, Makie.Key{:uv_transform}(), Makie.Key{:image}())
    uv_transform = Mat3f(0, 1, 0, 1, 0, 0, 0, 0, 1) * Mat3f(M[1], M[2], 0, M[3], M[4], 0, M[5], M[6], 1)
    colorrange = attr.scaled_colorrange[]
    interp = attr.interpolate[] ? :linear : :nearest
    uniforms = Dict(
        :color => false,
        :uniform_color => Sampler(attr.image[], minfilter=interp),
        :colorrange => colorrange === nothing ? Vec2f(0,1) : Vec2f(colorrange),
        :colormap => Sampler(attr.colormap[]),
        :highclip => attr.highclip_color[],
        :lowclip => attr.lowclip_color[],
        :nan_color => attr.nan_color[],
        :pattern => false,

        :normal => Vec3f(0),
        :shading => false,
        :diffuse => Vec3f(0),
        :specular => Vec3f(0),
        :shininess => 0.0f0,
        :backlight => 0.0f0,
        :model => Mat4f(attr.model[]),
        :PICKING_INDEX_FROM_UV => true,
        :uv_transform => uv_transform,
        :depth_shift => attr.depth_shift[],
        :normalmatrix => Mat3f(transpose(inv(attr.model[][i, i]))),
        :shading => false,
        :ambient => Vec3f(1),
        :light_direction => Vec3f(1),
        :light_color => Vec3f(1),
        :interpolate_in_fragment_shader => true
    )
    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniforms[:picking] = false
    uniforms[:object_id] = UInt32(0)
    rect = Rect2f(0, 0, 1, 1)
    faces = decompose(GLTriangleFace, rect)
    uv = decompose_uv(rect)

    mesh = GeometryBasics.Mesh(attr.data_limit_points_transformed[], faces; uv=uv)
    return Program(WebGL(), lasset("mesh.vert"), lasset("mesh.frag"), mesh, uniforms)
end


const IMAGE_INPUTS = [
    :data_limit_points_transformed,
    :image,
    :interpolate,
    :colormap,
    :scaled_colorrange,
    :model,
    :transparency,
    :depth_shift,
    :nan_color,
    :highclip_color,
    :lowclip_color,
    :visible,
]

function create_shader(::Scene, plot::Heatmap)
    attr = plot.args[1]
    add_uv_mesh!(attr)
    register_computation!(attr, IMAGE_INPUTS, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict(
            :image => :uniform_color,
            :scaled_colorrange => :colorrange,
            :highclip_color => :highclip,
            :lowclip_color => :lowclip,
            :data_limit_points_transformed => :position,
        )
        if isnothing(last)
            program = create_image_mesh(args)
            return (program, Observable{Any}([]))
        else
            updater = last[2][]
            update_values!(updater, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end

function create_shader(::Scene, plot::Image)
    attr = plot.args[1]
    add_uv_mesh!(attr)
    register_computation!(attr, IMAGE_INPUTS, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict(
            :image => :uniform_color,
            :scaled_colorrange => :colorrange,
            :highclip_color => :highclip,
            :lowclip_color => :lowclip,
            :data_limit_points_transformed => :position,
        )
        if isnothing(last)
            program = create_image_mesh(args)
            return (program, Observable{Any}([]))
        else
            updater = last[2][]
            update_values!(updater, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end


function serialize_three(scene::Scene, plot::Makie.ComputePlots)
    program = create_shader(scene, plot)
    mesh = serialize_three(plot, program)
    mesh[:plot_type] = "Mesh"
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = Observable(plot.visible[])
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.args[1][:wgl_update_obs][]

    mesh[:overdraw] = Observable(plot.overdraw[])
    mesh[:transparency] = Observable(plot.transparency[])

    mesh[:space] = Observable(plot.space[])
    if haskey(plot, :markerspace)
        mesh[:markerspace] = Observable(plot.markerspace[])
        mesh[:cam_space] = plot.markerspace[]
    else
        mesh[:cam_space] = plot.space[]
    end

    mesh[:uniforms][:clip_planes] = serialize_three([Vec4f(0, 0, 0, -1e9) for _ in 1:8])
    mesh[:uniforms][:num_clip_planes] = serialize_three(0)

    delete!(mesh, :uniform_updater)
    return mesh
end


const MESH_INPUTS = [
    # Special
    :space,
    # Needs explicit handling
    :alpha_colormap, :scaled_color, :scaled_colorrange,
    :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
    :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
    :pattern_uv_transform, :fetch_pixel, :shading,
    :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
]

function to_3x3(mat::Mat{2, 3})::Mat{3, 3}
    return Mat3f(mat[1, 1], mat[1, 2], 0, mat[2, 1], mat[2, 2], 0, 0, 0, 1)
end

function _create_mesh(attr)
    i = Vec(1, 2, 3)
    uv_transform = to_3x3(attr.pattern_uv_transform[])
    colorrange = attr.scaled_colorrange[]
    uniform_color = if attr.scaled_color[] isa AbstractMatrix
        Sampler(attr.scaled_color[])
    else
        false
    end
    color = if attr.scaled_color[] isa AbstractVector
        Buffer(attr.scaled_color[])
    elseif attr.scaled_color[] isa AbstractMatrix
        false
    else
        attr.scaled_color[]
    end
    uniforms = Dict(
        :color => color,
        :uniform_color => uniform_color,
        :colorrange => colorrange === nothing ? false : Vec2f(colorrange),
        :colormap => colorrange === nothing ? false : Sampler(attr.alpha_colormap[]),

        :highclip => attr.highclip_color[],
        :lowclip => attr.lowclip_color[],
        :nan_color => attr.nan_color[],
        :pattern => false,

        :shading => attr.shading[] != NoShading,
        :diffuse => attr.diffuse[],
        :specular => attr.specular[],
        :shininess => attr.shininess[],
        :backlight => attr.backlight[],
        :model => Mat4f(attr.model_f32c[]),
        :PICKING_INDEX_FROM_UV => true,
        :uv_transform => Mat3f(I),
        :depth_shift => attr.depth_shift[],
        :normalmatrix => Mat3f(transpose(inv(attr.model_f32c[][i, i]))),
        :ambient => Vec3f(1),
        :light_direction => Vec3f(1),
        :light_color => Vec3f(1),
        :interpolate_in_fragment_shader => true
    )
    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniforms[:picking] = false
    uniforms[:object_id] = UInt32(0)
    meshattr = Dict{Symbol, Any}()
    if !isnothing(attr.normals[])
        meshattr[:normal] = attr.normals[]
    else
        meshattr[:normal] = fill(Vec3f(0), length(attr.positions_transformed_f32c[]))
    end
    if !isnothing(attr.texturecoordinates[])
        meshattr[:uv] = attr.texturecoordinates[]
    else
        meshattr[:uv] = fill(Vec2f(0), length(attr.positions_transformed_f32c[]))
    end
    mesh = GeometryBasics.Mesh(attr.positions_transformed_f32c[], attr.faces[]; meshattr...)
    return Program(WebGL(), lasset("mesh.vert"), lasset("mesh.frag"), mesh, uniforms)
end


function create_shader(scene::Scene, plot::Makie.Mesh)
    attr = plot.args[1]
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform); colorname = :mesh_color)
    register_computation!(attr, MESH_INPUTS, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict(
            :image => :uniform_color,
            :scaled_colorrange => :colorrange,
            :highclip_color => :highclip,
            :lowclip_color => :lowclip,
            :positions_transformed_f32c => :position,
        )
        if isnothing(last)
            program = _create_mesh(args)
            return (program, Observable{Any}([]))
        else
            updater = last[2][]
            update_values!(updater, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end


# This adjusts uvs (compared to decompose_uv) so texture sampling starts at
# the center of a texture pixel rather than the edge, fixing
# https://github.com/MakieOrg/Makie.jl/pull/2598#discussion_r1152552196
function _surface_uvs(nx, ny)
    if (nx, ny) == (2, 2)
        return Vec2f[(0,1), (1,1), (1,0), (0,0)]
    else
        f = Vec2f(1 / nx, 1 / ny)
        return [f .* Vec2f(0.5 + i, 0.5 + j) for j in ny-1:-1:0 for i in 0:nx-1]
    end
end

function surface2mesh_computation!(attr)
    register_computation!(attr, [:x, :y, :z], [:positions]) do (x, y, z), changed, last
        return (Makie.matrix_grid(identity, x[], y[], z[]),)
    end
    Makie.register_position_transforms!(attr)
    register_computation!(attr, [:z], [:_faces, :texturecoordinates, :z_size]) do (z,), changed, last
        last_size = isnothing(last) ? size(z[]) : last[3][]
        new_size = size(z[])
        !isnothing(last) && last_size == new_size && return nothing
        rect = Tessellation(Rect2(0f0, 0f0, 1f0, 1f0), new_size)
        return (decompose(QuadFace{Int}, rect), _surface_uvs(new_size...), new_size)
    end
    register_computation!(attr, [:_faces, :positions_transformed_f32c], [:faces]) do (_fs, _ps), changed, last
        fs = _fs[]
        ps = _ps[]
        return (filter(f -> !any(i -> (i > length(ps)) || isnan(ps[i]), f), fs),)
    end
    register_computation!(attr, [:positions_transformed_f32c, :faces, :invert_normals], [:normals]) do (ps, fs, invert_normals), changed, last
        # TODO only recalculate normals if changed
        ns = Makie.nan_aware_normals(ps[], fs[])
        return (invert_normals[] ? -ns : ns,)
    end
end


function create_shader(scene::Scene, plot::Surface)
    attr = plot.args[1]
    # Makie.add_computation!(attr, scene, Val(:surface_transform))
    surface2mesh_computation!(attr)
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))

    register_computation!(attr, MESH_INPUTS, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict(
            :image => :uniform_color,
            :scaled_colorrange => :colorrange,
            :highclip_color => :highclip,
            :lowclip_color => :lowclip,
            :positions_transformed_f32c => :position,
        )
        if isnothing(last)
            program = _create_mesh(args)
            return (program, Observable{Any}([]))
        else
            updater = last[2][]
            update_values!(updater, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end
