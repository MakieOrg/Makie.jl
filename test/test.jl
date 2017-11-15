using Makie, GeometryTypes

s = Scene()

io = Makie.TextBuffer(Point3f0(0))

a = axis(ntuple(x-> linspace(0, 1, 4), 3)...)
