"""
    scatterlines(xs, ys, [zs]; kwargs...)

Plots `scatter` markers and `lines` between them.

## Attributes
$(ATTRIBUTES)
"""
@recipe(ScatterLines) do scene
    s_theme = default_theme(scene, Scatter)
    l_theme = default_theme(scene, Lines)
    Attributes(
        color = l_theme.color,
        colormap = l_theme.colormap,
        colorscale = l_theme.colorscale,
        colorrange = get(l_theme.attributes, :colorrange, automatic),
        linestyle = l_theme.linestyle,
        linewidth = l_theme.linewidth,
        markercolor = automatic,
        markercolormap = automatic,
        markercolorrange = automatic,
        markersize = s_theme.markersize,
        strokecolor = s_theme.strokecolor,
        strokewidth = s_theme.strokewidth,
        marker = s_theme.marker,
        inspectable = theme(scene, :inspectable),
        cycle = [:color],
    )
end

conversion_trait(::Type{<:ScatterLines}) = PointBased()


function plot!(p::Plot{scatterlines,<:NTuple{N,Any}}) where N

    # markercolor is the same as linecolor if left automatic
    real_markercolor = Observable{Any}()
    map!(real_markercolor, p.color, p.markercolor) do col, mcol
        if mcol === automatic
            return to_color(col)
        else
            return to_color(mcol)
        end
    end

    real_markercolormap = Observable{Any}()
    map!(real_markercolormap, p.colormap, p.markercolormap) do col, mcol
        mcol === automatic ? col : mcol
    end

    real_markercolorrange = Observable{Any}()
    map!(real_markercolorrange, p.colorrange, p.markercolorrange) do col, mcol
        mcol === automatic ? col : mcol
    end

    lines!(p, p[1:N]...;
        color = p.color,
        linestyle = p.linestyle,
        linewidth = p.linewidth,
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
