using Makie, GeometryTypes, Colors
scene = Scene()



x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)

l = Makie.legend(x, ["attribute $i" for i in 1:4])
io = VideoStream(scene, homedir()*"/Desktop")
record(io) = (for i = 1:35; recordframe!(io); sleep(1/30); end);
l[:position] = (0, 1)
record(io)
l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
record(io)
l[:strokecolor] = RGB(0.8, 0.8, 0.8)
record(io)
l[:gap] = 30
record(io)
l[:textsize] = 19
record(io)
l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
record(io)
l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
record(io)
l[:markersize] = 2f0
record(io)
finish(io, "mp4")

using Makie, Colors, GeometryTypes
GLAbstraction.DummyCamera <: GLAbstraction.Camera
scene = Scene()
cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
l = Makie.legend(cmap, 1:4)
l[:position] = (1.0,1.0)

l[:textcolor] = :blue
l[:strokecolor] = :black
l[:strokewidth] = 1
l[:textsize] = 15
l[:textgap] = 5

using Makie
scene = Scene(resolution = (500, 500))
x = [0, 1, 2, 0]
y = [0, 0, 1, 2]
z = [0, 2, 0, 1]
color = [:red, :green, :blue, :yellow]
i = [0, 0, 0, 1]
j = [1, 2, 3, 2]
k = [2, 3, 1, 3]
indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
m = mesh(x, y, z, indices, color = color)
m[:color] = [:blue, :red, :blue, :red]

using Makie, GeometryTypes

scene = Scene()
sub = Scene(scene, offset = Vec3f0(1, 2, 0))
scatter(sub, rand(10), rand(10), camera = :orthographic)
sub[:camera]
lines(sub, rand(10), rand(10), camera = :orthographic)
axis(linspace(0, 2, 4), linspace(0, 2, 4))
center!(scene)
sub[:offset] = Vec3f0(0, 0, 0)


using Makie, GeometryTypes

scene = Scene()

# create a subscene from which the next scenes you will plot
# `inherit` attributes. Need to add the attribute you care about,
# in this case the rotation
sub = Scene(scene, rotation = Vec4f0(0, 0, 0, 1))

meshscatter(sub, rand(30) + 1.0, rand(30), rand(30))
meshscatter(sub, rand(30), rand(30), rand(30) .+ 1.0)

axis = Vec3f0(0, 0, 1)
for angle = linspace(0, 2pi, 100)
    sub[:rotation] = Makie.qrotation(axis, angle)
    sleep(0.1)
end
