using Makie, GeometryTypes, Colors
scene = Scene()
scatter(
    Point3f0[(1,0,0), (0,1,0), (0,0,1)],
    marker = [:x, :circle, :cross]
)

GLVisualize.visualize(("helo", rand(Point3f0, length("helo"))))

scene[:theme][:scatter][:marker] = :cross
center!(scene)

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


Makie.VecLike{3, Float32}
Makie.Units.to_absolute(scene, x)
to_positions(scene, (rand(10) .* rel, rand(10) .* rel))

convert(Relative{Float64}, 1)

convert(NTuple{2, Relative{Float64}}, Tuple(Relative.(widths(scene))))

plot(scene, rand(11, 2))

using VisualRegressionTests


function test1(fn)
    srand(1234)
    scene = Scene(resolution = (500, 500))
    scatter(rand(10), rand(10))
    center!(scene)
    save(fn, scene)
end

cd(@__DIR__)

test1("test.png")

result = test_images(VisualTest(test1, "test.png"))


using Makie, GeometryTypes
scene = Makie.Scene()
linesloc = [rand(Point2f0) => rand(Point2f0) for k = 1:2]
colloc = [Colors.RGBA{Float32}(1, 0, 0), Colors.RGBA{Float32}(0, 0, 0), Colors.RGBA{Float32}(1, 1, 0), Colors.RGBA{Float32}(0, 1, 0)]
Makie.linesegment(scene, linesloc, color = colloc, linewidth = 20)
Makie.center!(scene)

using Makie, GLVisualize, GLWindow, Colors, Reactive, GeometryTypes
using GLVisualize: play_slider
using Makie: to_signal
scene = Scene()

editarea, viewarea = y_partition(to_signal(scene[:window_area]), 10) # 10% of the area
edit_screen = Scene(scene, editarea, color = RGBA(0.99f0, 0.99f0, 0.99f0, 1f0))
viewscreen = Scene(scene, viewarea)

function xy_data(x,y,i, N)
    x = ((x/N)-0.5f0)*i
    y = ((y/N)-0.5f0)*i
    r = sqrt(x*x + y*y)
    Float32(sin(r)/r)
end
surf(i, N) = Float32[xy_data(x, y, i, N) for x=1:N, y=1:N]


play_viz, slider_value = play_slider(
    edit_screen[:screen], 20, linspace(1f0, 50f0, 100),
    slider_length = widths(value(editarea))[1] .* 0.8
)

# startstop is not needed here, since the slider value will start and stop
my_animation = lift_node(to_node(slider_value)) do t
    surf(t, 128)
end
surface(viewscreen, -2:2, -2:2, my_animation, colornorm = (0f0, 1f0))
_view(play_viz, edit_screen[:screen], camera = :fixed_pixel)
