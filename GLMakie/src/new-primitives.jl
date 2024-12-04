using Makie.ComputePipeline

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
    camera = scene[].camera
    fast_pixel = marker isa FastPixel
    pspace = fast_pixel ? space : markerspace
    distancefield = marker_shape[] === Cint(DISTANCEFIELD) ? get_texture!(atlas) : nothing
    data = Dict(
        :vertex => positions[],
        :scale => quad_scale[],
        :quad_offset => quad_offset[],
        :uv_offset_width => uv_offset_width[],
        :marker_shape => marker_shape[],
        :transparency => transparency[],
        :preprojection => Makie.get_preprojection(camera, space, markerspace),
        :model => Mat4f(I),
        :markerspace => Cint(0),
        :distancefield => distancefield,
        :px_per_unit => screen[].px_per_unit,
        :upvector => Vec3f(0),
        :ssao => false,
    )
    add_color_attributes!(data, color[], colormap[], colornorm[])
    add_camera_attributes!(data, screen[], camera, pspace)
    return draw_scatter(screen[], (marker_shape[], positions[]), data)
end

function update_robjs!(robj, args, changed, gl_names)
    for (name, arg, has_changed) in zip(gl_names, args, changed)
        if has_changed
            if haskey(robj.uniforms, name)
                robj.uniforms[name] = arg[]
            elseif haskey(robj.vertexarray.buffers, string(name))
                GLAbstraction.update!(robj.vertexarray.buffers[string(name)], arg[])
            else
                # Core.println("Could not update ", name)
            end
        end
    end
end

function draw_atomic(screen::Screen, scene::Scene, plot::Scatter)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed
    atlas = gl_texture_atlas()
    add_input!(attr, :gl_screen, screen)

    register_computation!(
        attr, [:uv_offset_width, :marker, :font], [:sdf_marker_shape, :sdf_uv]
    ) do (uv_off, m, f), changed, last
        new_mf = changed[2] || changed[3]
        uv = new_mf ? Makie.primitive_uv_offset_width(atlas, m[], f[]) : nothing
        marker = changed[1] ? Makie.marker_to_sdf_shape(m[]) : nothing
        return (marker, uv)
    end

    inputs = [
        :scene,
        :gl_screen,
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
        :position,
        :color_map,
        :color,
        :color_norm,
        :shape,
        :uv_offset_width,
        :scale,
        :quad_offset,
        :transparency,
    ]
    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        robj = if isnothing(last)
            robj = assemble_scatter_robj(atlas, attr.outputs[:marker][],
                attr.outputs[:space][], attr.outputs[:markerspace][], args...)
        else
            robj = last[1][]
            if changed[3] # position
                haskey(robj.uniforms, :len) && (robj.uniforms[:len][] = length(args[3][]))
                robj.vertexarray.bufferlength = length(args[3][])
                robj.vertexarray.indices[] = length(args[3][])
            end
            update_robjs!(robj, args[3:end], changed[3:end], gl_names)
            robj
        end
        screen.requires_update = true
        return (robj,)
    end
    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)
    return robj
end

function add_color_attributes!(data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    _color = needs_mapping ? nothing : color
    intensity = needs_mapping ? color : nothing

    data[:color_map] = needs_mapping ? colormap : nothing
    data[:color] = _color
    data[:intensity] = intensity
    data[:color_norm] = colornorm
    return nothing
end

function add_color_attributes_lines!(data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    data[:color_map] = needs_mapping ? colormap : nothing
    data[:color] = color
    data[:color_norm] = colornorm
    return nothing
end

function add_camera_attributes!(data, screen, camera, space)
    data[:resolution] = Makie.get_ppu_resolution(camera, screen.px_per_unit[])
    data[:projection] = Makie.get_projection(camera, space)
    data[:projectionview] = Makie.get_projectionview(camera, space)
    data[:view] = Makie.get_view(camera, space)
    return data
end

function assemble_lines_robj(
    space,
    scene,
    screen,
    positions,
    linestyle,
    scene_origin,
    gl_miter_limit,
    linecap,
    joinstyle,
    color,
    colormap,
    colornorm,
    transparency,
    px_per_unit,
)
    camera = scene[].camera

    data = Dict(
        :linecap => linecap[],
        :joinstyle => joinstyle[],
        :miter_limit => gl_miter_limit[],
        :scene_origin => scene_origin[],
        :transparency => transparency[],
        :model => Mat4f(I),
        :px_per_unit => px_per_unit[],
        :ssao => false,
    )

    if isnothing(linestyle[])
        data[:pattern] = nothing
        data[:fast] = true
    else
        data[:pattern] = linestyle[]
        data[:fast] = false
    end

    add_camera_attributes!(data, screen[], camera, space[])
    add_color_attributes_lines!(data, color[], colormap[], colornorm[])
    return draw_lines(screen[], positions[], data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Lines)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    register_computation!(attr, [:miter_limit], [:gl_miter_limit]) do (miter,), changed, output
        return (Float32(cos(pi - miter[])),)
    end
    add_input!(attr, :screen, screen)
    add_input!(attr, :px_per_unit, screen.px_per_unit[])
    add_input!(attr, :viewport, scene.viewport[])
    register_computation!(
        attr, [:px_per_unit, :viewport], [:scene_origin]
    ) do (ppu, viewport), changed, output
        return (Vec2f(ppu[] * origin(viewport[])),)
    end
    register_computation!(
        attr, [:positions], [:projected_transformed_positions]
    ) do (positions,), changed, output
        Makie.Mat4d(pv) * Makie.f32_convert_matrix(f32c, space) * model
        pvm = lift(
            plot, data[:projectionview], plot.model, f32_conversion_obs(scene), space
        ) do pv, model, f32c, space
            Makie.Mat4d(pv) * Makie.f32_convert_matrix(f32c, space) * model
        end
    end

    linestyle = plot.linestyle[]

    positions = isnothing(linestyle) ? :positions_transformed_f32c : :projected_transformed_positions
    inputs = [
        :space,
        :scene,
        :screen,
        positions,
        :linestyle,
        :scene_origin,
        :gl_miter_limit,
        :linecap,
        :joinstyle,
        :color,
        :colormap,
        :_colorrange,
        :transparency,
        :px_per_unit,
    ]
    gl_names = [
        :pattern,
        :scene_origin,
        :miter_limit,
        :linecap,
        :joinstyle,
        :color,
        :color_map,
        :color_norm,
        :transparency,
        :px_per_unit,
    ]
    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, output
        if isnothing(output)
            robj = assemble_lines_robj(args...)
        else
            robj = output[1][]
            update_robjs!(robj, args[3:end], changed[3:end], gl_names)
        end
        screen.requires_update = true
        return (robj,)
    end

    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)
    return robj
end

function assemble_linesegments_robj(
    space,
    scene,
    screen,
    positions,
    linestyle,
    scene_origin,
    color,
    colormap,
    colornorm,
    transparency,
    px_per_unit,
)
    camera = scene[].camera

    data = Dict(
        :scene_origin => scene_origin[],
        :transparency => transparency[],
        :model => Mat4f(I),
        :px_per_unit => px_per_unit[],
        :ssao => false,
    )

    if isnothing(linestyle[])
        data[:pattern] = nothing
    else
        data[:pattern] = linestyle[]
        data[:fast] = false
    end

    add_camera_attributes!(data, screen[], camera, space[])
    add_color_attributes_lines!(data, color[], colormap[], colornorm[])
    return draw_linesegments(screen[], positions[], data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::LineSegments)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    add_input!(attr, :screen, screen)
    add_input!(attr, :px_per_unit, screen.px_per_unit[])
    add_input!(attr, :viewport, scene.viewport[])
    register_computation!(
        attr, [:px_per_unit, :viewport], [:scene_origin]
    ) do (ppu, viewport), changed, output
        return (Vec2f(ppu[] * origin(viewport[])),)
    end
    if !haskey(attr, :scene)
        add_input!(plot.args[1], :scene, scene)
    end
    inputs = [
        :space,
        :scene,
        :screen,
        :positions_transformed_f32c,
        :linestyle,
        :scene_origin,
        :color,
        :colormap,
        :_colorrange,
        :transparency,
        :px_per_unit,
    ]
    gl_names = [:pattern, :scene_origin, :color, :color_map, :color_norm, :transparency, :px_per_unit]

    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, output
        if isnothing(output)
            robj = assemble_linesegments_robj(args...)
        else
            robj = output[1][]
            update_robjs!(robj, args[3:end], changed[3:end], gl_names)
        end
        screen.requires_update = true
        return (robj,)
    end

    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)
    return robj
end
