using Makie, GeometryTypes, Colors

scene = Scene()
x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)
l = Makie.legend(x, ["attribute $i" for i in 1:4])
l[:backgroundcolor] = RGBA(0.98, 0.98, 0.98, 0.2)
l[:strokecolor] = RGB(0.8, 0.8, 0.8)
l[:stroke] = 2
