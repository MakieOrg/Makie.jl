using Makie: register_computation!

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
        :transparency => attr.transparency[],

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
        :transform_marker => false
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

function update_robjs!(robj, args, changed, gl_names)
    for (name, arg, has_changed) in zip(gl_names, args, changed)
        if has_changed
            if haskey(robj.uniforms, name)
                robj.uniforms[name] = arg[]
            elseif haskey(robj.vertexarray.buffers, string(name))
                update!(robj.vertexarray.buffers[string(name)], arg[])
            end
        end
    end
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
]

function create_robj(args, changed, last)
    robj = if isnothing(last)
        robj = assemble_scatter_robj((; zip(SCATTER_INPUTS, args)...))
    else
        robj = last[1][]
    end
    return (robj,)
end

function create_shader(scene::Scene, plot::Scatter)
    attr = plot.args[1]
    Makie.all_marker_computations!(attr, 1024, 32)
    register_computation!(create_robj, attr, SCATTER_INPUTS, [:wgl_renderobject])
    return attr[:wgl_renderobject][]
end
