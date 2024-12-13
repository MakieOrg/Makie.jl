
function assemble_scatter_robj(attr)
    needs_mapping = !(attr.colornorm[] isa Nothing)
    dfield = attr.sdf_marker_shape[] === Cint(DISTANCEFIELD)
    atlas = attr.atlas_1024_32
    distancefield = dfield ? NoDataTextureAtlas(size(atlas.data)) : nothing
    _color = needs_mapping ? nothing : attr.color[]
    intensity = needs_mapping ? attr.color[] : nothing

    uniform_dict = Dict(
        :pos => attr.positions_transformed_f32c[],
        :color_map => needs_mapping ? attr.colormap[] : nothing,
        :color => _color,
        :intensity => intensity,
        :color_norm => attr.colornorm[],

        :rotation => attr.rotation[],

        :marker_offset => Vec3f(0),
        :markersize => attr.quad_scale[],
        :quad_offset => attr.quad_offset[],
        :uv_offset_width => attr.uv_offset_width[],
        :shape_type => attr.marker_shape[],
        :transparency => attr.transparency[],

        :distancefield => distancefield,

        # Camera will be set in JS
        :resolution => Vec2f(0),
        :projection => Mat4f(I),
        :projectionview => Mat4f(I),
        :preprojection => Mat4f(I),
        :view => Mat4f(I),
        :model => Mat4f(I),

        :markerspace => Cint(0),
        :image => attr.image[],
        :px_per_unit => 0f0,
        :picking => false,
        :object_id => UInt32(0),

        :strokewidth => attr.strokewidth[],
        :strokecolor => attr.strokecolor[],
        :glowwidth => attr.glowwidth[],
        :glowcolor => attr.glowcolor[],
        :billboard => attr.rotation[] isa Billboard,
        :depth_shift => attr.depth_shift[],
    )

    instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1.0f0, 1.0f0))

    per_instance_keys = (
        :pos, :rotation, :markersize, :color, :intensity, :uv_offset_width, :quad_offset, :marker_offset
    )
    per_instance = filter(uniform_dict) do (k, v)
        return k in per_instance_keys && !(Makie.isscalar(v))
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

function create_shader(scene::Scene, plot::Scatter)
    attr = plot.args[1]
    Makie.all_marker_computations!(attr, 1024, 32)
    inputs = [
        :positions_transformed_f32c,
        :colormap,
        :colornorm,
        :rotation,
        :quad_scale,
        :quad_offset,
        :uv_offset_width,
        :marker_shape,
        :transparency,
        :image,
        :strokewidth,
        :strokecolor,
        :glowwidth,
        :glowcolor,
        :depth_shift,
    ]

    register_computation!(attr, inputs, [:wgl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        robj = if isnothing(last)
            robj = assemble_scatter_robj(attr)
        else
            robj = last[1][]
            update_robjs!(robj, args[3:end], changed[3:end], gl_names)
        end
        screen.requires_update = true
        return (robj,)
    end

    return robj
end
