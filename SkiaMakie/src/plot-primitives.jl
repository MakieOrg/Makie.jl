####################################################################################################
#                                          Infrastructure                                          #
####################################################################################################

########################################
#           Drawing pipeline           #
########################################

function skia_draw(screen::Screen, scene::Scene)
    sk_canvas_save(screen.canvas)
    draw_background(screen, scene)

    allplots = Makie.collect_atomic_plots(scene; is_atomic_plot = is_skiamakie_atomic_plot)
    sort!(allplots; by = Makie.zvalue2d)

    last_scene = scene

    sk_canvas_save(screen.canvas)
    for p in allplots
        check_parent_plots(p) do plot
            to_value(get(plot, :visible, true))
        end || continue
        pparent = Makie.parent_scene(p)::Scene
        pparent.visible[]::Bool || continue
        if pparent != last_scene
            sk_canvas_restore(screen.canvas)
            sk_canvas_save(screen.canvas)
            prepare_for_scene(screen, pparent)
            last_scene = pparent
        end
        sk_canvas_save(screen.canvas)

        if to_value(get(p, :rasterize, false)) != false && is_vector_backend(screen)
            # TODO: implement rasterize-on-vector
            draw_plot(pparent, screen, p)
        else
            draw_plot(pparent, screen, p)
        end
        sk_canvas_restore(screen.canvas)
    end
    sk_canvas_restore(screen.canvas)
    return
end

is_vector_backend(screen::Screen{RT}) where {RT} = is_vector_backend(RT)

is_skiamakie_atomic_plot(plot::Plot) = Makie.is_atomic_plot(plot) || isempty(plot.plots) || to_value(get(plot, :rasterize, false)) != false

function check_parent_plots(f, plot::Plot)
    if f(plot)
        check_parent_plots(f, parent(plot))
    else
        return false
    end
end
check_parent_plots(f, scene::Scene) = true

function prepare_for_scene(screen::Screen, scene::Scene)
    root_area_height = widths(Makie.root(scene))[2]
    scene_area = viewport(scene)[]
    scene_height = widths(scene_area)[2]
    scene_x_origin, scene_y_origin = scene_area.origin

    top_offset = root_area_height - scene_height - scene_y_origin
    sk_canvas_translate(screen.canvas, Float32(scene_x_origin), Float32(top_offset))

    # clip to scene viewport
    w, h = widths(scene_area)
    clip_rect = Ref(sk_rect_t(0.0f0, 0.0f0, Float32(w), Float32(h)))
    sk_canvas_clip_rect_with_operation(screen.canvas, clip_rect, SK_CLIP_OP_INTERSECT, false)
    return
end

function draw_background(screen::Screen, scene::Scene)
    w, h = Makie.widths(viewport(Makie.root(scene))[])
    return draw_background(screen, scene, h)
end

function draw_background(screen::Screen, scene::Scene, root_h)
    canvas = screen.canvas
    sk_canvas_save(canvas)
    if scene.clear[]
        bg = scene.backgroundcolor[]
        color = to_skia_color(bg)
        r = viewport(scene)[]
        x, y = origin(r); w, h = widths(r)
        paint = new_paint(color = color)
        rect = Ref(sk_rect_t(Float32(x), Float32(root_h - y - h), Float32(x + w), Float32(root_h - y)))
        sk_canvas_draw_rect(canvas, rect, paint)
        sk_paint_delete(paint)
    end
    sk_canvas_restore(canvas)
    return foreach(child_scene -> draw_background(screen, child_scene, root_h), scene.children)
end

function draw_plot(scene::Scene, screen::Screen, primitive::Plot)
    if to_value(get(primitive, :visible, true))
        if is_skiamakie_atomic_plot(primitive)
            sk_canvas_save(screen.canvas)
            draw_atomic(scene, screen, primitive)
            sk_canvas_restore(screen.canvas)
        end
        if !isempty(primitive.plots)
            zvals = Makie.zvalue2d.(primitive.plots)
            for idx in sortperm(zvals)
                draw_plot(scene, screen, primitive.plots[idx])
            end
        end
    end
    return
end

function draw_atomic(::Scene, ::Screen, x::PlotList)
    return nothing
end

function draw_atomic(::Scene, ::Screen, x)
    return @warn "$(typeof(x)) is not supported by SkiaMakie right now"
end
