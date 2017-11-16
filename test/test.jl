using Makie, GeometryTypes

s = Scene()

io = Makie.TextBuffer(Point3f0(0))

a = axis(ntuple(x-> linspace(0, 1, 4), 3)...)


scene = Scene()
x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)
l = Makie.legend(x, ["attribute $i" for i in 1:4])

l[:position] = (0.089, 0.75)
l[:gap] = 20
l[:textgap] = 20
l[:padding] = 20
