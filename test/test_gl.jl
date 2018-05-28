using Makie, AbstractPlotting, GeometryTypes

s2 = scatter(-1:8, rand(10) .+ 1, color = :black)


text("halalala")
img = Makie.atlas_texture_cache[] |> Makie.GLAbstraction.gpu_data .|> Colors.Gray;
using FileIO

save("test.png", Images.clamp01nan.(img));

img = GLVisualize.loadasset("doge.png")
GLFW.SetWindowIcon(nw, reinterpret(NTuple{4, UInt8}, img))

using Makie
scene = Scene()
x = linspace(0, 6, 100)
s = surface!(scene, x, x, (x, y)-> sin(x) + cos(y), show_legend = true)
scene

scene = Scene()
x = linspace(0, 6, 100)
s = heatmap!(scene, x, x, (x, y)-> sin(x) + cos(y), show_legend = true)
scene

scene = Scene()
p = plot!(scene, Makie.Attributes(), rand(10, 5))
scene

# Makie.campixel!(scene)
# image!(scene, GLVisualize.loadasset("doge.png"), raw = true)

# Update limits when zooming with cam
# Update limits when subplot changes /new
# 3D  axis + limits
# remaining primitives ()

using GLVisualize, Makie
scene = Scene()
m = mesh!(scene, loadasset("cat.obj"))
scene


r = linspace(-10, 10, 512)
z = ((x, y)-> sin(x) + cos(y)).(r, r')
scene = Scene()
c = heatmap!(scene, r, r, z, levels = 5)
s = scatter!(scene, rand(-10:10, 10), rand(-10:10, 10))
s2 = contour!(scene, r, r, z, levels = 5)
scene


scatter!(cscene, [1, 0, 1, 0], [1, 0, 0, 1],
    markersize = 0.02, color = :black
);



# a = text!(scene, "Hellooo", color = :black, textsize = 0.1, position = (0.5, 0.5))
# a = text!(scene, "Hellooo", color = :black, textsize = 0.1, position = ps)
tb = Makie.TextBuffer(scene)
start!(tb)
append!(tb, ["Hello there"], Point2f0[(0.5, 0.5)], textsize = 0.1, color = :black, rotation = 0.0, font = "default")
append!(tb, ["General Kenobi!"], Point2f0[(0.0, 0.0)])
finish!(tb)


scene = Scene()
lsb = Makie.LinesegmentBuffer(scene, Point2)
start!(lsb)
append!(lsb, Point2f0[(1, 1), (0, 0)], color = RGBAf0(0,0,0,1), linewidth = 1f0)
finish!(lsb)
scene

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

struct Test <: AbstractArray{Float32, 1} end
x = Test()
@which filter(x-> x > 0.5, x)
As[map(f, As)::AbstractArray{Bool}]

using Makie
scene = Scene()
t = text!(
    scene,
    ". This is an annotation!",
    position = (300, 200),
    align = (:center,  :center),
    textsize = 60,
    font = "Comic Sans MS",
    scale_plot = false
)
dlims = Makie.data_limits(t)[]
rect =  FRect(dlims[1], dlims[2] .- dlims[1])
lines!(scene, rect, scale_plot = false)

using Reactive

keys = (:position, :textsize, :font, :align, :rotation, :model)
x = t
args = (value(x.args[1]), value.(getindex.(x.attributes, keys))...)

positions, scale = Makie.layout_text(args...)
scatter!(scene, positions, markersize = 10, color = :red, scale_plot = false)
scatter!(scene, positions .+ scale, markersize = 10, color = :green, scale_plot = false)
rect = Makie.FRect2D(union(AABB(positions .+ scale), AABB(positions)))


ex = extrema(vcat(positions, positions .+ scale))
(last.(ex), first.(ex))


using Transpiler, GeometryTypes


import Transpiler.gli: texelFetch


function image_preprocess(img::AbstractMatrix{NTuple{4, T}}, uv, mini, maxi, kernel, brightness, contrast) where T
    @inbounds begin
        z = 1f0
        val = (z, z, z, 1f0)
        # filter
        for i in 1:3
            for j in 1:3
                tmp = img[Cint(i), Cint(j)] .* kernel[i, j]
                val = val .+ tmp
            end
        end
        # brightness
        val = val .+ brightness
        # contrast
        val = val .- 0.5f0
        val = (contrast .* val)
        val = val .+ 0.5f0
        val = val .- mini
        val = val ./ (maxi - mini)
        # min max
        return clamp.(val, 0f0, 1f0)
    end
end
decl = Transpiler.GLMethod((image_preprocess, (
    Matrix{NTuple{4, Float32}}, Tuple{Int, Int}, Float32, Float32, Mat3f0, Float32, Float32
)))

# image_preprocess(rand(50, 50), ())

source = Sugar.getsource!(decl);
println(source)

deps = reverse(collect(Sugar.dependencies!(decl, true)));
types = filter(Sugar.istype, deps)
Transpiler.is_fixedsize_array(Mat4f0)
funcs = filter(Sugar.isfunction, deps)
io = STDOUT
println(io, "// dependant type declarations")
for typ in types
    if !Sugar.isintrinsic(typ)
        println(io, Sugar.getsource!(typ))
    end
end
# defer printing for the function and types
io2 = GLIO(IOBuffer(), m)
for func in funcs
    if !Sugar.isintrinsic(func)
        println("//", func.signature)
        println(io, Sugar.getsource!(func))
    end
end
