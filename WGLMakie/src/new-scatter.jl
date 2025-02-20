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

function assemble_scatter_robj(attr)
    needs_mapping = !(attr._colorrange[] isa Nothing)
    dfield = attr.sdf_marker_shape[] === Cint(Makie.DISTANCEFIELD)
    atlas = attr.atlas_1024_32[]
    distancefield = dfield ? NoDataTextureAtlas(size(atlas.data)) : false
    color_norm = needs_mapping ? attr._colorrange[] : false

    uniform_dict = Dict(
        :pos => attr.positions_transformed_f32c[],
        :colormap => needs_mapping ? Sampler(attr.colormap[]) : false,
        :color => attr.color[],
        :colorrange => Vec2f(color_norm),
        :highclip => attr._highclip[],
        :lowclip => attr._lowclip[],
        :nan_color => attr.nan_color[],

        :rotation => attr.rotation[],

        :marker_offset => Vec3f(0),
        :markersize => attr.quad_scale[],
        :quad_offset => attr.quad_offset[],
        :uv_offset_width => attr.sdf_uv[],
        :shape_type => attr.sdf_marker_shape[],
        :transparency => Observable(attr.transparency[]),

        :distancefield => distancefield,

        # Camera will be set in JS
        :resolution => Vec2f(0),
        # :projection => Mat4f(I),
        # :projectionview => Mat4f(I),
        :preprojection => Mat4f(I),
        # :view => Mat4f(I),
        :model => Mat4f(I),
        :atlas_texture_size => Float32(size(atlas.data, 2)),

        :image => isnothing(attr.image[]) ? false : attr.image[],
        :px_per_unit => 0f0,
        :picking => false,
        :object_id => UInt32(0),

        :strokewidth => attr.strokewidth[],
        :strokecolor => attr.strokecolor[],
        :glowwidth => attr.glowwidth[],
        :glowcolor => attr.glowcolor[],
        :billboard => attr.rotation[] isa Billboard,
        :depth_shift => attr.depth_shift[],
        :transform_marker => false,
    )

    instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1.0f0, 1.0f0))

    per_instance_keys = (
        :pos, :rotation, :markersize, :color, :intensity, :uv_offset_width, :quad_offset, :marker_offset
    )
    per_instance = filter(uniform_dict) do (k, v)
        return k in per_instance_keys && !(Makie.isscalar(v))
    end
    filter!(uniform_dict) do (k, v)
        return !(k in per_instance_keys && !(Makie.isscalar(v)))
    end

    handle_color_getter!(uniform_dict, per_instance)

    if haskey(uniform_dict, :color) && haskey(per_instance, :color)
        to_value(uniform_dict[:color]) isa Bool && delete!(uniform_dict, :color)
        to_value(per_instance[:color]) isa Bool && delete!(per_instance, :color)
    end
    _, arr = first(per_instance)
    if any(v -> length(arr) != length(v), values(per_instance))
        lens = [k => length(v) for (k, v) in per_instance]
        error("Not all have the same length: $(lens)")
    end


    return InstancedProgram(
        WebGL(),
        lasset("sprites.vert"),
        lasset("sprites.frag"),
        instance,
        VertexArray(; per_instance...),
        uniform_dict,
    )
end

const SCATTER_INPUTS = [
    :positions_transformed_f32c,
    :color,
    :colormap,
    :_colorrange,
    :rotation,
    :quad_scale,
    :quad_offset,
    :sdf_uv,
    :sdf_marker_shape,
    :transparency,
    :image,
    :strokewidth,
    :strokecolor,
    :glowwidth,
    :glowcolor,
    :depth_shift,
    :atlas_1024_32,
    :markerspace,
    :nan_color,
    :_highclip,
    :_lowclip,
    :visible
]

function create_robj(args, changed, last)
    r = Dict(
        :quad_scale => :markersize,
        :positions_transformed_f32c => :pos,
        :sdf_uv => :uv_offset_width,
        :sdf_marker_shape => :shape_type,
        :model_f32c => :model,
    )
    if isnothing(last)
        program = assemble_scatter_robj(args)
        return (program, Observable([]))
    else
        updater = last[2][]
        update_values!(updater, plot_updates(args, changed, r))
        return nothing
    end
end

function create_shader(::Scene, plot::Scatter)
    attr = plot.args[1]
    Makie.all_marker_computations!(attr, 1024, 32)
    register_computation!(create_robj, attr, SCATTER_INPUTS, [:wgl_renderobject, :wgl_update_obs])
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end


function serialize_three(scene::Scene, plot::Scatter)
    program = create_shader(scene, plot)
    mesh = serialize_three(plot, program)
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:plot_type] = "Mesh"
    mesh[:visible] = Observable(plot.visible[])
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.args[1][:wgl_update_obs][]

    mesh[:overdraw] = Observable(plot.overdraw[])
    mesh[:transparency] = Observable(plot.transparency[])

    mesh[:cam_space] = plot.markerspace[]
    mesh[:space] = Observable(plot.space[])
    mesh[:uniforms][:clip_planes] = serialize_three([Vec4f(0, 0, 0, -1e9) for _ in 1:8])
    mesh[:uniforms][:num_clip_planes] = serialize_three(0)
    mesh[:markerspace] = Observable(plot.markerspace[])

    delete!(mesh, :uniform_updater)
    return mesh
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
    uniforms = Dict(
        :color => false,
        :uniform_color => Sampler(attr.image[]),
        :colorrange => Vec2f(attr.scaled_colorrange[]),
        :colormap => Sampler(attr.colormap[]),
        :highclip => attr._highclip[],
        :lowclip => attr._lowclip[],
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
    :colormap,
    :scaled_colorrange,
    :model,
    :transparency,
    :depth_shift,
    :nan_color,
    :_highclip,
    :_lowclip,
    :visible,
]

function create_shader(::Scene, plot::Image)
    attr = plot.args[1]
    add_uv_mesh!(attr)
    register_computation!(attr, IMAGE_INPUTS, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict(
            :image => :uniform_color,
            :scaled_colorrange => :colorrange,
            :_highclip => :highclip,
            :_lowclip => :lowclip,
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


function serialize_three(scene::Scene, plot::Image)
    program = create_shader(scene, plot)
    mesh = serialize_three(plot, program)
    mesh[:plot_type] = "Mesh"
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = Observable(plot.visible[])
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.args[1][:wgl_update_obs][]

    mesh[:overdraw] = Observable(plot.overdraw[])
    mesh[:transparency] = Observable(plot.transparency[])
    mesh[:cam_space] = plot.space[]
    mesh[:space] = Observable(plot.space[])
    mesh[:uniforms][:clip_planes] = serialize_three([Vec4f(0, 0, 0, -1e9) for _ in 1:8])
    mesh[:uniforms][:num_clip_planes] = serialize_three(0)

    delete!(mesh, :uniform_updater)
    return mesh
end
