"""
    textbackground(text_plot)


"""
@recipe TextBackground begin
    MakieCore.documented_attributes(Poly)...
    "background object to place behind text"
    marker = Rect2f(-1, -1, 2, 2)
    "Limits of background which should be transformed to match the text boundingbox"
    marker_limits = automatic
    "left-right-bottom-top padding"
    pad = Vec4f(2)
    "Should the aspect ratio of the background change?"
    keep_aspect = false

    depth_shift = 1f-5
    fxaa = false
end

function transform_to_bbox(plot::Makie.Text; keep_aspect = false, limits = Rect2d(0,0,1,1), pad = (2,2,2,2))
    scene = Makie.parent_scene(plot)
    while !isempty(plot.plots)
        plot = plot.plots[1]
    end
    translation = Observable(Point3d(0))
    scale = Observable(Vec3d(0))
    onany(
        camera(scene).projectionview, viewport(scene),
        plot.transformation.model, plot.transformation.transform_func,
        plot.position, plot.converted...) do args...

        bbox = boundingbox(plot, plot.markerspace[])
        z = minimum(bbox)[3]
        l, r, b, t = pad
        bbox = Rect2d(minimum(bbox)[Vec(1,2)] .- (l, b), widths(bbox)[Vec(1,2)] .+ (l, b) .+ (r, t))
        s = widths(bbox) ./ widths(limits)
        if keep_aspect
            s = Vec2d(maximum(s))
        end
        scale[] = to_ndim(Vec3d, s, 1)
        # translate center for keep_aspect = true
        translation[] = to_ndim(Point3d, (minimum(bbox) + 0.5 * widths(bbox)) .- s .* (minimum(limits) + 0.5 * widths(limits)), z)
        return Consume(false)
    end

    return translation, scale
end

function convert_arguments(::Type{TextBackground}, plot::Text)
    return ([plot],)
end

function plot!(plot::TextBackground{<: Tuple{<: AbstractVector{<: Text}}})
    @assert length(plot[1][]) < 2 || allequal(p -> p.markerspace[], plot[1][]) "All text plots must have the same markerspace."

    # TODO: multiple plots, multiple glyphcollections
    # TODO: observables
    limits = map((m, l) -> l === automatic ? Rect2d(m) : l, plot, plot.marker, plot.marker_limits)
    translation, scale = transform_to_bbox(plot[1][][1];
        keep_aspect = plot.keep_aspect[], limits = limits[], pad = plot.pad[])

    m = meshscatter!(
        plot,
        translation,
        marker = plot.marker,
        markersize = scale,
        space = plot[1][][1].markerspace[],
        # depth_shift = 1f-3,
        visible = plot.visible,
        shading = plot.shading,
        color = plot.color,
        colormap = plot.colormap,
        colorscale = plot.colorscale,
        colorrange = plot.colorrange,
        lowclip = plot.lowclip,
        highclip = plot.highclip,
        nan_color = plot.nan_color,
        alpha = plot.alpha,
        overdraw = plot.overdraw,
        fxaa = plot.fxaa,
        transparency = plot.transparency,
        inspectable = plot.inspectable,
        depth_shift = plot.depth_shift
    )

    # This translation is only here to affect render order
    translate!(m, 0,0, -1e-8)

    marker_outline = map(to_lines, plot, plot.marker)
    merged_outlines = map(plot, marker_outline, translation, scale) do ps, trans, scale
        # TODO: multiple
        map(p -> scale .* to_ndim(Point3d, p, 0) .+ trans, ps)
    end

    lines!(
        plot, merged_outlines, visible = plot.visible,
        color = plot.strokecolor, linestyle = plot.linestyle, alpha = plot.alpha,
        colormap = plot.strokecolormap,
        linewidth = plot.strokewidth, linecap = plot.linecap,
        joinstyle = plot.joinstyle, miter_limit = plot.miter_limit,
        space = plot[1][][1].markerspace[],
        overdraw = plot.overdraw, transparency = plot.transparency,
        inspectable = plot.inspectable, depth_shift = plot.stroke_depth_shift
    )

    return plot
end
