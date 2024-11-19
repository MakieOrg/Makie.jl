"""
    scatterlines(xs, ys, [zs]; kwargs...)

Plots `scatter` markers and `lines` between them.
"""
@recipe ScatterLines begin
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
    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
    cycle = [:color]
end

conversion_trait(::Type{<: ScatterLines}) = PointBased()


function plot!(p::Plot{scatterlines, <:NTuple{N, Any}}) where N

    # markercolor is the same as linecolor if left automatic
    real_markercolor = Observable{Any}()
    lift!(p, real_markercolor, p.color, p.markercolor) do col, mcol
        if mcol === automatic
            return to_color(col)
        else
            return to_color(mcol)
        end
    end

    real_markercolormap = Observable{Any}()
    lift!(p, real_markercolormap, p.colormap, p.markercolormap) do col, mcol
        mcol === automatic ? col : mcol
    end

    real_markercolorrange = Observable{Any}()
    lift!(p, real_markercolorrange, p.colorrange, p.markercolorrange) do col, mcol
        mcol === automatic ? col : mcol
    end

    lines!(p, p[1:N]...;
        color = p.color,
        linestyle = p.linestyle,
        linewidth = p.linewidth,
        linecap = p.linecap,
        joinstyle = p.joinstyle,
        miter_limit = p.miter_limit,
        colormap = p.colormap,
        colorscale = p.colorscale,
        colorrange = p.colorrange,
        inspectable = p.inspectable
    )
    scatter!(p, p[1:N]...;
        color = real_markercolor,
        strokecolor = p.strokecolor,
        strokewidth = p.strokewidth,
        marker = p.marker,
        markersize = p.markersize,
        colormap = real_markercolormap,
        colorscale = p.colorscale,
        colorrange = real_markercolorrange,
        inspectable = p.inspectable
    )
end
