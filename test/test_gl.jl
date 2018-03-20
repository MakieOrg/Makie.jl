using Makie
using GeometryTypes, IntervalSets
using Makie: LinesegmentBuffer, start!, finish!

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    isempty(scene.current_screens) || return
    screen = Screen(scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    return
end

function Base.show(io::IO, m::MIME"text/plain", plot::Makie.AbstractPlot)
    show(io, m, Makie.parent(plot)[])
    display(TextDisplay(io), m, plot.attributes)
    nothing
end


# screen = Screen(scene)
using Makie: Theme
scene = Scene(resolution = (600, 300))
cam2d!(scene)
update_cam!(scene, FRect(0, 0, 1, 1))
scatter!(scene, rand(10), rand(10),
    markersize = 0.01,
    show_axis = true, scale_plot = true,
)
scene.scale[] = Vec3f0(1, 1, 1)
scene.scale[]
scene
# a = text!(scene, "Hellooo", color = :black, textsize = 0.1, position = (0.5, 0.5))
# a = text!(scene, "Hellooo", color = :black, textsize = 0.1, position = ps)
tb = Makie.TextBuffer(scene)
start!(tb)
append!(tb, ["Hello there"], Point2f0[(0.5, 0.5)], textsize = 0.1, color = :black, rotation = 0.0, font = "default")
append!(tb, ["General Kenobi!"], Point2f0[(0.0, 0.0)])
finish!(tb)



tb
scene = Scene()
cam = cam2d!(scene)
cam.area[] = FRect(0, 0, normalize(widths(scene.px_area[])) * 3)
update_cam!(scene, cam)
lsb = LinesegmentBuffer(Point2f0)
start!(lsb)
append!(lsb, Point2f0[(1, 1), (0, 0)], RGBAf0(0,0,0,1), 1f0)


s = scatter!(scene, [0, 0, 1, 1], [0, 1.5, 0, 1.5])
s = lines!(scene, FRect(0, 0, 1, 1.5), color = :black, show_axis = true)
xy = linspace(0, 2pi, 100)
f(x, y) = sin(x) + cos(y)
z = f.(xy, xy')
s1 = heatmap!(scene, 0.1 .. 0.9, 0.1 .. 0.44, z)
# TODO linewidth varies and comes out quite different compared to `lines`,
# because it is actually in defined in gradients of z (at least for opengl)
# Can user deal with this or does this need to be changed?
s2 = contour!(scene, 0.1 .. 0.9, 0.46 .. 0.9, z, linewidth = 0.1, fillrange = true)
s2 = contour!(scene, 0.1 .. 0.9, 0.91 .. 1.4, z, linewidth = 2)

# screen = Screen(scene)
scene = Scene()
a = text!(scene, "Hellooo", color = :black, textsize = 0.1, position = (0.5, 0.5))

b = scatter!(scene, rand(10), rand(10))
b = linesegments!(scene, rand(10), rand(10))
c = plot!(scene, rand(10), rand(10), color = :white)
d = meshscatter!(scene, rand(10), rand(10), rand(10), show_axis = true);
cam = cam2d!(scene)
cam.area[] = FRect(0, 0, normalize(widths(scene.px_area[])) * 3)
update_cam!(scene, cam)
scene

scene = Scene()
scene.px_area[] = IRect(0, 0, 1920, 1080)
cam = cam2d!(scene)
cam.area[] = FRect(0, 0, normalize(widths(scene.px_area[])) * 3)
update_cam!(scene, cam)
scatter!(scene, FRect(0, 0, 1, 1), scale_plot = false, linewidth = 5)
h = heatmap!(scene, linspace(0, 1, 50), linspace(0, 1, 50), rand(50, 50))
scene
# cam.rotationspeed[] = 0.1
# cam.pan_button[] = Mouse.right
# scene.events.window_dpi[]

# screenw = widths(scene.px_area[])
# camw = widths(scene.area[])
#
# screen_r = screenw ./ screenw[1]
# camw_r = camw ./ camw[1]
# r = (screen_r ./ camw_r)
# r = r ./ maximum(r)
#
# update_cam!(scene, FRect(minimum(scene.area[]), r .* camw))
using Makie

scene = Scene()
m = GLVisualize.loadasset("cat.obj")
mesh!(scene, m)
Makie.cam3d!(scene)
scene


using Makie, GeometryTypes
scene = Scene()
scene.px_area[] = IRect(0, 0, 1920, 1080)
cam = cam2d!(scene)
points = decompose(Point2f0, Circle(Point2f0(0), 500f0))
poly!(
    scene, points,
    color = :gray, linewidth = 10, linecolor = :black
)
scene

pol[:positions] = Circle(Point2f0(250), 500f0)
pol[:linewidth] = 2
# Optimized forms
y = poly([Circle(Point2f0(600+i, i), 50f0) for i = 1:150:800])
x = poly([Rectangle{Float32}(600+i, i, 100, 100) for i = 1:150:800], strokewidth = 10, strokecolor = :black)
x = linesegment([Point2f0(600+i, i) => Point2f0(i + 700, i + 100)
