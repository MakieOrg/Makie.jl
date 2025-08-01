"""
    scatterlines(xs, ys, [zs]; kwargs...)

Plots `scatter` markers and `lines` between them.
"""
@recipe ScatterLines (positions,) begin
    "The color of the line, and by default also of the scatter markers."
    color = @inherit linecolor
    "Sets the pattern of the line e.g. `:solid`, `:dot`, `:dashdot`. For custom patterns look at `Linestyle(Number[...])`"
    linestyle = nothing
    "Sets the width of the line in screen units"
    linewidth = @inherit linewidth
    linecap = @inherit linecap
    joinstyle = @inherit joinstyle
    miter_limit = @inherit miter_limit
    markercolor = automatic
    markercolormap = automatic
    markercolorrange = automatic
    "Sets the size of the marker."
    markersize = @inherit markersize
    "Sets the color of the outline around a marker."
    strokecolor = @inherit markerstrokecolor
    "Sets the width of the outline around a marker."
    strokewidth = @inherit markerstrokewidth
    "Sets the scatter marker."
    marker = @inherit marker
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    cycle = [:color]
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

    lines!(
        p, p.positions;

        color = p.color,
        linestyle = p.linestyle,
        linewidth = p.linewidth,
        linecap = p.linecap,
        joinstyle = p.joinstyle,
        miter_limit = p.miter_limit,
        colormap = p.colormap,
        colorscale = p.colorscale,
        colorrange = p.colorrange,
        inspectable = p.inspectable,
        clip_planes = p.clip_planes,
    )
    scatter!(
        p, p.positions;

        color = p.real_markercolor,
        strokecolor = p.strokecolor,
        strokewidth = p.strokewidth,
        marker = p.marker,
        markersize = p.markersize,
        colormap = p.real_markercolormap,
        colorscale = p.colorscale,
        colorrange = p.real_markercolorrange,
        inspectable = p.inspectable,
        clip_planes = p.clip_planes,
    )
    return p
end
