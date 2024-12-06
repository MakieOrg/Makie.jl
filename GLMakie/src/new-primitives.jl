using Makie.ComputePipeline

function assemble_scatter_robj(
        atlas, marker,
        space, markerspace, # TODO: feels incomplete to me... Do matrices react correctly? What about markerspace with FastPixel?
        scene, screen,
        positions, # TODO: can probably be avoided by rewriting draw_scatter()
        colormap, color, colornorm,
        marker_shape
    )

    camera = scene[].camera
    fast_pixel = marker isa FastPixel
    pspace = fast_pixel ? space : markerspace
    distancefield = marker_shape[] === Cint(DISTANCEFIELD) ? get_texture!(atlas) : nothing
    data = Dict(
        :vertex => positions[],
        :preprojection => Makie.get_preprojection(camera, space, markerspace),
        :markerspace => Cint(0), # TODO: should be dynamic
        :distancefield => distancefield,
        :px_per_unit => screen[].px_per_unit,   # technically not const?
        :upvector => Vec3f(0),
        :ssao => false,                         # shader compilation const
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
    add_input!(attr, :gl_screen, screen) # TODO: how do we clean this up?

    register_computation!(
        attr, [:uv_offset_width, :marker, :font], [:sdf_marker_shape, :sdf_uv]
    ) do (uv_off, m, f), changed, last
        new_mf = changed[2] || changed[3]
        uv = new_mf ? Makie.primitive_uv_offset_width(atlas, m[], f[]) : nothing
        # TODO: maybe we should just add a glconvert(x::Enum) = Cint(x)?
        marker = changed[1] ? Cint(Makie.marker_to_sdf_shape(m[])) : nothing
        return (marker, uv)
    end

    # TODO:
    # - depthsorting
    # - colorrange, lowclip, highclip cannot be changed from autoamtic
    # - rotation -> billboard missing
    # - px_per_unit (that can update dynamically via record, right?)
    # - fxaa
    # - intensity_convert

    inputs = [
        # Special
        :scene, :gl_screen,
        # Needs explicit handling
        :positions_transformed_f32c,
        :colormap, :color, :_colorrange,
        :sdf_marker_shape,
        # Simple forwards
        :sdf_uv,
        :quad_scale, :quad_offset,
        :transparency,
        :strokecolor, :strokewidth,
        :glowcolor, :glowwidth,
        :model_f32c, :rotation,
        :transform_marker,
        :_lowclip, :_highclip, :nan_color,
    ]

    # To take the human error out of the bookkeeping of two lists
    # Could also consider using this in computation since Dict lookups are
    # O(1) and only takes ~4ns
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :position,
        :colormap => :color_map, :_colorrange => :color_norm,
        :sdf_marker_shape => :shape, :sdf_uv => :uv_offset_width,
        :quad_scale => :scale,
        :strokecolor => :stroke_color, :strokewidth => :stroke_width,
        :glowcolor => :glow_color, :glowwidth => :glow_width,
        :model_f32c => :model, :transform_marker => :scale_primitive,
        :_lowclip => :lowclip, :_highclip => :highclip,
    )
    gl_names = Symbol[]

    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        if isnothing(last)

            # Generate complex defaults
            robj = assemble_scatter_robj(atlas, attr.outputs[:marker][],
                attr.outputs[:space][], attr.outputs[:markerspace][], args[1:7]...)

            # Generate name mapping
            haskey(robj.vertexarray.buffers, "intensity") && (input2glname[:color] = :intensity)
            gl_names = get.(Ref(input2glname), inputs, inputs)

            # Simple defaults
            foreach(8:length(args)) do idx
                robj.uniforms[gl_names[idx]] = args[idx][]
            end

        else

            robj = last[1][]
            if changed[3] # position
                haskey(robj.uniforms, :len) && (robj.uniforms[:len][] = length(args[3][]))
                robj.vertexarray.bufferlength = length(args[3][])
                robj.vertexarray.indices[] = length(args[3][])
            end
            update_robjs!(robj, args[3:end], changed[3:end], gl_names[3:end])

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
        :vertex,
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
            update_robjs!(robj, args[4:end], changed[4:end], gl_names)
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
