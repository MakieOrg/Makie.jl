"""
    scatterlines(xs, ys, [zs]; kwargs...)

Plots `lines` between sets of x and y coordinates provided,
as well as plotting those points using `scatter`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(ScatterLines) do scene
    merge(default_theme(scene, Scatter), default_theme(scene, Lines))
end


function plot!(p::Combined{scatterlines, <:NTuple{N, Any}}) where N
    plot!(p, Lines, attributes_from(Lines, p), p[1:N]...)
    plot!(p, Scatter, attributes_from(Scatter, p), p[1:N]...)
end
