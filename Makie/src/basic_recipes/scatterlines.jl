"""
    scatterlines(xs, ys, [zs]; kwargs...)

Plots `scatter` markers and `lines` between them.
"""
@recipe ScatterLines (positions,) begin
    documented_attributes(Lines)...
    filtered_attributes(
        Scatter, exclude = (
            :color, :colormap, :colorrange, :colorscale, :lowclip, :highclip, :alpha,
            :nan_color,
            :fxaa, :visible, :transparency, :space, :clip_planes, :ssao, :overdraw,
            :cycle, :transformation, :model, :depth_shift,
            :inspector_clear, :inspector_hover, :inspector_label, :inspectable,
        )
    )...
    "The color of the line, and by default also of the scatter markers."
    color = @inherit linecolor
    "Sets the color of scatter markers. These default to `color`"
    markercolor = automatic
    "Sets the colormap for scatter markers. This defaults to `colormap`"
    markercolormap = automatic
    "Sets the colorrange for scatter markers. This defaults to `colorrange`"
    markercolorrange = automatic
end

conversion_trait(::Type{<:ScatterLines}) = PointBased()

function plot!(p::ScatterLines)
    # markercolor is the same as linecolor if left automatic
    map!(p, [:color, :markercolor], :real_markercolor) do color, markercolor
        return to_color(markercolor === automatic ? color : markercolor)
    end

    map!(p, [:colormap, :markercolormap], :real_markercolormap) do colormap, markercolormap
        return markercolormap === automatic ? colormap : markercolormap
    end

    map!(p, [:colorrange, :markercolorrange], :real_markercolorrange) do colorrange, markercolorrange
        return markercolorrange === automatic ? colorrange : markercolorrange
    end

    lines!(p, p.attributes, p.positions)
    scatter!(
        p, p.attributes, p.positions;
        color = p.real_markercolor,
        colormap = p.real_markercolormap,
        colorrange = p.real_markercolorrange,
    )

    return p
end
