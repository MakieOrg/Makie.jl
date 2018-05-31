using Makie
scatter(
    Point3f0[(1,0,0), (0,1,0), (0,0,1)],
    marker = [:x, :circle, :cross]
)

meshscatter(rand(100), rand(100), rand(100))

heatmap(rand(100, 100))

scene = contour(-1..1, -1..1, rand(100, 100))

function draw_all(screen, scene::Scene)
    Makie.center!(scene)
    for elem in scene.plots
        Makie.CairoBackend.cairo_draw(screen, elem)
    end
    foreach(x->draw_all(screen, x), scene.children)
    Makie.CairoBackend.cairo_finish(screen)
end

cs = Makie.CairoBackend.CairoScreen(wf, joinpath(homedir(), "Desktop", "test.svg"))
draw_all(cs, wf)

surface(rand(100, 100))
surface(-1..1, -1..1, rand(100, 100))
surface(linspace(-1, 1, 100), linspace(-1, 1, 100) .+ (rand(100) .* 0.1), rand(100, 100))
N = 40
r = linspace(-1, 1, N)
x = map(hcat(repeated(r, N)...)) do x
   x + (rand() * 0.01)
end
y = vcat(repeated(r', N)...)
surface(x, y, rand(N, N))
surface(x, y, rand(N, N) * 0.1, color = rand(RGBAf0, N, N))


wf = wireframe(linspace(-1, 1, 100), linspace(-1, 1, 100) .+ (rand(100) .* 0.1), rand(100, 100))
wf = wireframe(-1..1, -1..1, rand(100, 100))
wf = wireframe(Sphere(Point3f0(0), 1f0))
wf = wireframe(x, y, rand(N, N))

scene = Scene()
x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegments!(scene, linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter!(scene, linspace(1, 5, 100), rand(100), rand(100)))
scene

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
r = linspace(-2, 2, 4)
Makie.axis(r, r, r)
center!(scene)

axis = Vec3f0(0, 0, 1)
io = VideoStream(scene, homedir()*"/Desktop/", "rotation")
for angle = linspace(0, 2pi, 100)
    sub[:rotation] = Makie.qrotation(axis, angle)
    recordframe!(io)
    sleep(1/15)
end
finish(io, "gif")

keys = (
    :lol, :pos, :test
)
positions, pos, test = get.(attributes, keys, scene)


function myvisual(scene, args, attributes)
    keys = (
        :positions, :color, :blah, shared...,
    )
    Scene(zip(keys, getindex.(attributes, keys))

end


using Makie, GeometryTypes


function plot(scene::S, A::AbstractMatrix{T}) where {T <: AbstractFloat, S <: Scene}
    N, M = size(A)
    sub = Scene(scene, scale = Vec3f0(1))
    attributes = Dict{Symbol, Any}()

    plots = map(1:M) do i
        lines(sub, 1:N, A[:, i])
    end
    labels = get(attributes, :labels) do
        map(i-> "y $i", 1:M)
    end

    lift_node(to_node(A), to_node(Makie.getscreen(scene).area)) do a, area
        xlims = (1, size(A, 1))
        ylims = extrema(A)
        stretch = Makie.to_nd(fit_ratio(area, (xlims, ylims)), Val{3}, 1)
        sub[:scale] = stretch
    end
    l = legend(scene, plots, labels)
    # Only create one axis per scene
    xlims = linspace(1, size(A, 1), min(N, 10))
    ylims = linspace(extrema(A)..., 5)
    a = get(scene, :axis) do
        xlims = (1, size(A, 1))
        ylims = extrema(A)
        area = Reactive.value(Makie.getscreen(scene).area)
        stretch = Makie.to_nd(fit_ratio(area, (xlims, ylims)), Val{3}, 1)
        axis(linspace((xlims .* stretch[1])..., 4), linspace((ylims .* stretch[2])..., 4))
    end
    center!(scene)
end

using Makie, GeometryTypes

scene = Scene()

x = (0.5rel, 0.5rel)

x .* Point2f0(0.5, 0.5)
StaticArrays.similar_type(NTuple{2, Float32}, Int)


Makie.VecTypes{3, Float32}
Makie.Units.to_absolute(scene, x)
to_positions(scene, (rand(10) .* rel, rand(10) .* rel))

convert(Relative{Float64}, 1)

convert(NTuple{2, Relative{Float64}}, Tuple(Relative.(widths(scene))))

plot(scene, rand(11, 2))
