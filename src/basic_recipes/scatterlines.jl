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
        colorrange = get(l_theme.attributes, :colorrange, automatic),
        linestyle = l_theme.linestyle,
        markercolor = s_theme.color,
        markercolormap = s_theme.colormap,
        markercolorrange = get(s_theme.attributes, :colorrange, automatic),
        markersize = s_theme.markersize,
        strokecolor = s_theme.strokecolor,
        marker = s_theme.marker,
    )
end


function plot!(p::Combined{scatterlines, <:NTuple{N, Any}}) where N
    lines!(p, p[1:N]...;
        color = p.color,
        linestyle = p.linestyle,
        colormap = p.colormap,
        colorrange = p.colorrange,
    )
    scatter!(p, p[1:N]...;
        color = p.markercolor,
        strokecolor = p.strokecolor,
        marker = p.marker,
        markersize = p.markersize,
        colormap = p.markercolormap,
        colorrange = p.markercolorrange,
    )
end
