
function assemble_scatter_robj(
    atlas,
    marker,
    space,
    markerspace,
    scene,
    screen,
    positions,
    colormap,
    color,
    colornorm,
    marker_shape,
    uv_offset_width,
    quad_scale,
    quad_offset,
    transparency,
)
    needs_mapping = !(colornorm[] isa Nothing)
    fast_pixel = marker isa FastPixel
    pspace = fast_pixel ? space : markerspace
    distancefield = marker_shape[] === Cint(DISTANCEFIELD) ? NoDataTextureAtlas(size(atlas.data)) : nothing
    _color = needs_mapping ? nothing : color[]
    intensity = needs_mapping ? color[] : nothing

    uniform_dict = Dict(
        :pos => positions[],
        :color_map => needs_mapping ? colormap[] : nothing,
        :color => _color,
        :intensity => intensity,
        :color_norm => colornorm[],

        :markersize => quad_scale[],
        :quad_offset => quad_offset[],
        :uv_offset_width => uv_offset_width[],
        :shape_type => marker_shape[],
        :transparency => transparency[],
        # Camera will be set in JS
        :resolution => Vec2f(0),
        :projection => Mat4f(I),
        :projectionview => Mat4f(I),
        :preprojection => Mat4f(I),
        :view => Mat4f(I),
        :model => Mat4f(I),

        :markerspace => Cint(0),
        :distancefield => distancefield,
        :px_per_unit => 0f0,
    )
    instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1.0f0, 1.0f0))
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
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed
    atlas = wgl_texture_atlas()
    register_sdf_computations!(attr, atlas)

    inputs = [
        :positions_transformed_f32c,
        :colormap,
        :color,
        :_colorrange,
        :sdf_marker_shape,
        :sdf_uv,
        :quad_scale,
        :quad_offset,
        :transparency,
    ]

    gl_names = [
        :pos,
        :color_map,
        :color,
        :color_norm,
        :shape,
        :uv_offset_width,
        :markersize,
        :quad_offset,
        :transparency,
    ]

    register_computation!(attr, inputs, [:wgl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        robj = if isnothing(last)
            robj = assemble_scatter_robj(atlas, attr.marker[], attr.space[], attr.markerspace[], args...)
        else
            robj = last[1][]
            update_robjs!(robj, args[3:end], changed[3:end], gl_names)
        end
        screen.requires_update = true
        return (robj,)
    end

    return robj
end
