

# this is a simplification which will only really work with non-rotated or
# scaled scene transformations
# but for Cairo's 2D paradigm that is the only likely mode of transformation
# and this way we can use the z-value as a means to shift the drawing order
# by translating e.g. the axis spines forward so they are not obscured halfway
# by heatmaps or images
zvalue(x) = 0.0f0#AbstractPlotting.translation(x)[][3] + zvalue(x.parent)
zvalue(::Nothing) = 0.0f0

function get_all_plots(scene, plots = AbstractPlot[])
    append!(plots, scene.plots)
    for c in scene.children
        get_all_plots(c, plots)
    end
    plots
end

function clear(screen::CairoScreen)
    ctx = screen.ctx
    Cairo.save(ctx)
    Cairo.set_operator(ctx, Cairo.OPERATOR_SOURCE)
    Cairo.set_source_rgba(ctx, rgbatuple(screen.scene[:backgroundcolor])...)
    Cairo.paint(ctx)
    Cairo.restore(ctx)
end


function draw_background(screen::CairoScreen, scene::Scene)
    cr = screen.context
    Cairo.save(cr)
    if scene.clear_background
        Cairo.set_source_rgba(cr, rgbatuple(scene.backgroundcolor)...)
        r = scene.screen_area
        Cairo.rectangle(cr, origin(r)..., widths(r)...) # background
        fill(cr)
    end
    Cairo.restore(cr)
    foreach(child_scene -> draw_background(screen, child_scene), scene.children)
end

# The main entry point into the drawing pipeline
function cairo_draw(screen::CairoScreen, scene::Scene)
    draw_background(screen, scene)
    allplots = get_all_plots(scene)
    sort!(allplots, by = zvalue)

    last_scene = scene

    Cairo.save(screen.context)
    for plot in allplots
        plot.visible || continue
        # only prepare for scene when it changes
        # this should reduce the number of unnecessary clipping masks etc.
        if plot.parent != last_scene
            Cairo.restore(screen.context)
            Cairo.save(screen.context)
            prepare_for_scene(screen, plot.parent)
            last_scene = plot.parent
        end
        Cairo.save(screen.context)
        draw_plot(screen, plot)
        Cairo.restore(screen.context)
    end
    return
end

function prepare_for_scene(screen::CairoScreen, scene::Scene)

    # get the root area to correct for its pixel size when translating
    root_area = root(scene).screen_area

    root_area_height = widths(root_area)[2]
    scene_area = scene.screen_area
    scene_height = widths(scene_area)[2]
    scene_x_origin, scene_y_origin = scene_area.origin

    # we need to translate x by the origin, so distance from the left
    # but y by the distance from the top, which is not the origin, but can
    # be calculated using the parent's height, the scene's height and the y origin
    # this is because y goes downwards in Cairo and upwards in AbstractPlotting

    top_offset = root_area_height - scene_height - scene_y_origin
    Cairo.translate(screen.context, scene_x_origin, top_offset)

    # clip the scene to its pixelarea
    Cairo.rectangle(screen.context, 0, 0, widths(scene_area)...)
    Cairo.clip(screen.context)
    return
end

function draw_marker(ctx, m, pos, scale, strokecolor, strokewidth, marker_offset)

    marker_offset = marker_offset + scale / 2

    pos += Point2f(marker_offset[1], -marker_offset[2])

    # Cairo.scale(ctx, scale...)
    Cairo.move_to(ctx, pos[1] + scale[1] / 2, pos[2])
    Cairo.arc(ctx, pos[1], pos[2], scale[1] / 2, 0, 2 * pi)
    Cairo.fill_preserve(ctx)

    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.stroke(ctx)
end

function draw_plot(screen::CairoScreen, p::Scatter)
    ctx = screen.context
    model = p.transformation.model[]
    isempty(p.positions) && return
    size_model = p.transform_marker ? model : Mat4f(I)

    # if we give size in pixels, the size is always equal to that value
    is_pixelspace = p.markerspace == Pixel
    broadcast_foreach(
        p.positions,
        p.color,
        p.markersize,
        p.strokecolor,
        p.strokewidth,
        p.marker,
        p.markeroffset,
    ) do point, col, markersize, strokecolor, strokewidth, marker, mo

        scale = if is_pixelspace
            to_2d_scale(markersize)
        else
            # otherwise calculate a scaled size
            project_scale(p, markersize, size_model)
        end
        offset = if is_pixelspace
            to_2d_scale(mo)
        else
            project_scale(p, mo, size_model)
        end

        pos = project_position(p, point, model)
        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        draw_marker(ctx, marker, pos, scale, strokecolor, strokewidth, offset)
    end
    nothing
end
