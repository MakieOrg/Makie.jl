using Makie.ComputePipeline

function assemble_scatter_robj(atlas, marker, space, markerspace,
                               scene, screen,
                               positions,
                               colormap, color, colornorm,
                               marker_shape, uv_offset_width, quad_scale, quad_offset,
                               transparency)
    camera = scene[].camera
    needs_mapping = !(colornorm[] isa Nothing)
    fast_pixel = marker isa FastPixel
    pspace = fast_pixel ? space : markerspace
    distancefield = marker_shape[] === Cint(DISTANCEFIELD) ? get_texture!(atlas) : nothing
    _color = needs_mapping ? nothing : color[]
    intensity = needs_mapping ? color[] : nothing

    data = Dict(:vertex => positions[],
                :color_map => needs_mapping ? colormap[] : nothing,
                :color => _color,
                :intensity => intensity,
                :color_norm => colornorm[],
                :scale => quad_scale[],
                :quad_offset => quad_offset[],
                :uv_offset_width => uv_offset_width[],
                :marker_shape => marker_shape[],
                :transparency => transparency[],
                :resolution => Makie.get_ppu_resolution(camera, screen[].px_per_unit[]),
                :projection => Makie.get_projection(camera, pspace),
                :projectionview => Makie.get_projectionview(camera, pspace),
                :preprojection => Makie.get_preprojection(camera, space, markerspace),
                :view => Makie.get_view(camera, pspace),
                :model => Mat4f(I),
                :markerspace => Cint(0),
                :distancefield => distancefield, :px_per_unit => screen[].px_per_unit,
                :upvector => Vec3f(0),
                :ssao => false)
    return draw_scatter(screen[], (marker_shape[], positions[]), data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Scatter)
    screen_name = Symbol(string(objectid(screen)))
    attr = plot.args[1]
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed
    atlas = gl_texture_atlas()
    register_computation!(attr, Symbol[], [screen_name]) do args, changed, last
        return (screen,)
    end
    register_computation!(attr, [:uv_offset_width, :marker, :font],
                          [:sdf_marker_shape, :sdf_uv]) do (uv_off, m, f), changed, last
        new_mf = changed[2] || changed[3]
        uv = new_mf ? Makie.primitive_uv_offset_width(atlas, m[], f[]) : nothing
        marker = changed[1] ? Makie.marker_to_sdf_shape(m[]) : nothing
        return (marker, uv)
    end

    scene_name = Symbol(string(objectid(scene)))
    register_computation!(attr, Symbol[], [scene_name]) do args, changed, last
        return (scene,)
    end
    inputs = [scene_name, screen_name,
              :positions_transformed_f32c, :colormap, :color, :_colorrange,
              :sdf_marker_shape, :sdf_uv, :quad_scale, :quad_offset,
              :transparency]
    gl_names = [:vertex, :color_map, :color, :color_norm, :shape, :uv_offset_width, :scale, :quad_offset,
                :transparency]
    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        robj = if isnothing(last)
            robj = assemble_scatter_robj(atlas, attr.marker[], attr.space[], attr.markerspace[], args...)
        else
            robj = last[1][]
            for (name, arg, has_changed) in zip(gl_names, args[3:end], changed[3:end])
                if has_changed
                    if haskey(robj.uniforms, name)
                        robj.uniforms[name] = arg[]
                    elseif haskey(robj.vertexarray.buffers, string(name))
                        update!(robj.vertexarray.buffers[string(name)], arg[])
                    end
                end
            end
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
