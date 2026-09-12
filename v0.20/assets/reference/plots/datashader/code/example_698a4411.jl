# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    # Taken from Lazaro Alonso in Beautiful Makie:
# https://beautiful.makie.org/dev/examples/generated/2d/datavis/strange_attractors/?h=cliffo#trajectory
Clifford((x, y), a, b, c, d) = Point2f(sin(a * y) + c * cos(a * x), sin(b * x) + d * cos(b * y))

function trajectory(fn, x0, y0, kargs...; n=1000) #  kargs = a, b, c, d
    xy = zeros(Point2f, n + 1)
    xy[1] = Point2f(x0, y0)
    @inbounds for i in 1:n
        xy[i+1] = fn(xy[i], kargs...)
    end
    return xy
end

cargs = [[0, 0, -1.3, -1.3, -1.8, -1.9],
    [0, 0, -1.4, 1.6, 1.0, 0.7],
    [0, 0, 1.7, 1.7, 0.6, 1.2],
    [0, 0, 1.7, 0.7, 1.4, 2.0],
    [0, 0, -1.7, 1.8, -1.9, -0.4],
    [0, 0, 1.1, -1.32, -1.03, 1.54],
    [0, 0, 0.77, 1.99, -1.31, -1.45],
    [0, 0, -1.9, -1.9, -1.9, -1.0],
    [0, 0, 0.75, 1.34, -1.93, 1.0],
    [0, 0, -1.32, -1.65, 0.74, 1.81],
    [0, 0, -1.6, 1.6, 0.7, -1.0],
    [0, 0, -1.7, 1.5, -0.5, 0.7]
]

fig = Figure(size=(1000, 1000))
fig_grid = CartesianIndices((3, 4))
cmap = to_colormap(:BuPu_9)
cmap[1] = RGBAf(1, 1, 1, 1) # make sure background is white

let
    # locally, one can go pretty high with n_points,
    # e.g. 4*(10^7), but we don't want the docbuild to become too slow.
    n_points = 10^6
    for (i, arg) in enumerate(cargs)
        points = trajectory(Clifford, arg...; n=n_points)
        r, c = Tuple(fig_grid[i])
        ax, plot = datashader(fig[r, c], points;
            colormap=cmap,
            async=false,
            axis=(; type=Axis, title=join(string.(arg), ", ")))
        hidedecorations!(ax)
        hidespines!(ax)
    end
end
rowgap!(fig.layout,5)
colgap!(fig.layout,1)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_698a4411_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_698a4411.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide