####################################################################################################
#                                          Infrastructure                                          #
####################################################################################################

########################################
#           Drawing pipeline           #
########################################

# The main entry point into the drawing pipeline
function cairo_draw(screen::Screen, scene::Scene)
    Cairo.save(screen.context)
    draw_background(screen, scene)

    allplots = Makie.flatten_plots(scene; additional_criteria = should_not_flatten)
    zvals = Makie.zvalue2d.(allplots)
    permute!(allplots, sortperm(zvals))

    # If the backend is not a vector surface (i.e., PNG/ARGB),
    # then there is no point in rasterizing twice.
    should_rasterize = is_vector_backend(screen.surface)

    last_scene = scene

    Cairo.save(screen.context)
    for p in allplots
        check_parent_plots(p) do plot
            to_value(get(plot, :visible, true))
        end || continue
        # only prepare for scene when it changes
        # this should reduce the number of unnecessary clipping masks etc.
        pparent = Makie.parent_scene(p)
        pparent.visible[] || continue
        if pparent != last_scene
            Cairo.restore(screen.context)
            Cairo.save(screen.context)
            prepare_for_scene(screen, pparent)
            last_scene = pparent
        end
        Cairo.save(screen.context)

        # When a plot is too large to save with a reasonable file size on a vector backend, 
        # the user can choose to rasterize it when plotting to vector backends, by using the 
        # `rasterize` keyword argument.  This can be set to a Bool or an Int which describes
        # the density of rasterization (in terms of a direct scaling factor.)
        # TODO: In future, this can also be set to a Tuple{Module, Int} which describes
        # the backend module which should be used to render the scene, and the pixel density
        # at which it should be rendered.
        if to_value(get(p, :rasterize, false)) != false && should_rasterize
            draw_plot_as_image(pparent, screen, p, p[:rasterize][])
        else # draw vector
            draw_plot(pparent, screen, p)
        end
        Cairo.restore(screen.context)
    end
    Cairo.restore(screen.context)
    return
end

"""
    should_not_flatten(plot::Combined)::Bool

Returns whether the plot should be flattened (false) or not (true); for use in `Makie.flatten_plots`.
This is overridden for `Poly`, `Band`, and `Tricontourf` so we can apply 
CairoMakie-specific drawing methods to them.

Plots with children are by default recursed into.  This can be overridden
by defining specific dispatches for `should_flatten` for a given plot type.
"""
function should_not_flatten(plot)
    return false
end

"""
    check_parent_plots(f, plot::Combined)::Bool

Returns whether the plot's parent tree satisfies the predicate `f`.
`f` must return a `Bool` and take a plot as its only argument.
"""
function check_parent_plots(f, plot::Combined)
    if f(plot)
        check_parent_plots(f, parent(plot))
    else
        return false
    end
end

function check_parent_plots(f, scene::Scene)
    return true
end

function prepare_for_scene(screen::Screen, scene::Scene)

    # get the root area to correct for its pixel size when translating
    root_area = Makie.root(scene).px_area[]

    root_area_height = widths(root_area)[2]
    scene_area = pixelarea(scene)[]
    scene_height = widths(scene_area)[2]
    scene_x_origin, scene_y_origin = scene_area.origin

    # we need to translate x by the origin, so distance from the left
    # but y by the distance from the top, which is not the origin, but can
    # be calculated using the parent's height, the scene's height and the y origin
    # this is because y goes downwards in Cairo and upwards in Makie

    top_offset = root_area_height - scene_height - scene_y_origin
    Cairo.translate(screen.context, scene_x_origin, top_offset)

    # clip the scene to its pixelarea
    Cairo.rectangle(screen.context, 0, 0, widths(scene_area)...)
    Cairo.clip(screen.context)

    return
end

function draw_background(screen::Screen, scene::Scene)
    cr = screen.context
    Cairo.save(cr)
    if scene.clear[]
        bg = scene.backgroundcolor[]
        Cairo.set_source_rgba(cr, red(bg), green(bg), blue(bg), alpha(bg));
        r = pixelarea(scene)[]
        Cairo.rectangle(cr, origin(r)..., widths(r)...) # background
        fill(cr)
    end
    Cairo.restore(cr)
    foreach(child_scene-> draw_background(screen, child_scene), scene.children)
end

function draw_plot(scene::Scene, screen::Screen, primitive::Combined)
    if to_value(get(primitive, :visible, true))
        if isempty(primitive.plots)
            Cairo.save(screen.context)
            draw_atomic(scene, screen, primitive)
            Cairo.restore(screen.context)
        else
            zvals = Makie.zvalue2d.(primitive.plots)
            for idx in sortperm(zvals)
                draw_plot(scene, screen, primitive.plots[idx])
            end
        end
    end
    return
end

# Possible improvements for this function:
# - Obtain the bbox of the plot and draw an image which tightly fits that bbox
#   instead of the whole Scene
# - Recognize when a screen is an image surface, and set scale to render the plot
#   at the scale of the device pixel
function draw_plot_as_image(scene::Scene, screen::Screen, primitive::Combined, scale::Number = 1)
    # you can provide `p.rasterize = scale::Int` or `p.rasterize = true`, both of which are numbers

    # Extract scene width in pixels
    w, h = Int.(scene.px_area[].widths)
    # Create a new Screen which renders directly to an image surface,
    # specifically for the plot's parent scene.
    scr = Screen(scene; px_per_unit = scale)
    # Draw the plot to the screen, in the normal way
    draw_plot(scene, scr, primitive)

    # Now, we draw the rasterized plot to the main screen.
    # Since it has already been prepared by `prepare_for_scene`,
    # we can draw directly to the Screen.
    Cairo.rectangle(screen.context, 0, 0, w, h)
    Cairo.save(screen.context)
    Cairo.translate(screen.context, 0, 0)
    # Cairo.scale(screen.context, w / scr.surface.width, h / scr.surface.height)
    Cairo.set_source_surface(screen.context, scr.surface, 0, 0)
    p = Cairo.get_source(scr.context)
    # this is needed to avoid blurry edges
    Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD)
    # Set filter doesn't work!?
    Cairo.pattern_set_filter(p, Cairo.FILTER_BILINEAR)
    Cairo.fill(screen.context)
    Cairo.restore(screen.context)

    return
end

function draw_atomic(::Scene, ::Screen, x)
    @warn "$(typeof(x)) is not supported by cairo right now"
end
