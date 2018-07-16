using Makie, Reactive, GeometryTypes
using Makie: loadasset
function lorenz(t0, a, b, c, h)
    Point3f0(
        t0[1] + h * a * (t0[2] - t0[1]),
        t0[2] + h * (t0[1] * (b - t0[3]) - t0[2]),
        t0[3] + h * (t0[1] * t0[2] - c * t0[3]),
    )
end
# step through the `time`
function lorenz(array::Vector, a = 5.0 ,b = 2.0, c = 6.0, d = 0.01)
    t0 = Point3f0(0.1, 0, 0)
    for i = eachindex(array)
        t0 = lorenz(t0, a,b,c,d)
        array[i] = t0
    end
    array
end

# primitives = GLNormalMesh[
#     loadasset("cat.obj"),
#     Sphere(Point3f0(0), 1f0),
#     Pyramid(Point3f0(0), 1f0, 1f0),
#     HyperRectangle(Vec3f0(0), Vec3f0(1))
# ]
#
# w = Pair[
#     :a => 24f0,
#     :b => 10f0,
#     :c => 6.0f0,
#     :d => 0.01f0,
#     :scale => 0.4,
#
#     :colora => RGBA(0.7f0, 1f0, 0.5f0, 1f0),
#     :colorb => RGBA(1f0, 0f0, 0f0, 1f0),
#     :colornorm => Vec2f0(0, 1.2),
#
#     :primitive => primitives
# ]
#
# editarea, viewarea = x_partition_abs(window.area, 60mm)
# editscreen = Screen(
#     window, area = editarea,
#     color = RGBA{Float32}(0.98, 0.98, 1, 1)
# )
# viewscreen = Screen(window, area = viewarea)
# menu, w = GLVisualize.extract_edit_menu(w, editscreen, true)
# _view(menu, editscreen, camera = :fixed_pixel)

n1, n2 = 18, 30
N = n1*n2
# args = map(value, (w[:a], w[:b], w[:c], w[:d]))
scene = Scene(resolution = (1150, 840))
ui_scene = Scene(scene, lift(x-> IRect(0, 0, widths(x)[1], 50), pixelarea(scene)))
plot_scene = Scene(scene, lift(x-> IRect(0, 50, widths(x) .- Vec(0, 50)), pixelarea(scene)))

theme(ui_scene)[:plot] = NT(raw = true)
campixel!(ui_scene)

a = slider!(ui_scene, 0f0:50f0)[end]
b = slider!(ui_scene, -20f0:20f0)[end]
c = slider!(ui_scene, 0f0:20f0)[end]
d = slider!(ui_scene, linspace(0f0, 0.1f0, 100))[end]

AbstractPlotting.vbox(ui_scene.plots)

args_n = getindex.((a, b, c, d), :value)
args = (24f0, 6f0, 10f0, 0.01f0)
v0 = lorenz(zeros(Point3f0, N), args...)
positions = foldp(lorenz, v0, args_n...)
scales = node(:scale, 0.4f0)
rotations = lift(diff, positions)
rotations = lift(x-> push!(x, x[end]), rotations)
cmap = [:green, :red]

plot = meshscatter!(
    plot_scene,
    positions,
    marker = Makie.loadasset("cat.obj"),
    markersize = scales, rotation = rotations,
    intensity = collect(linspace(0f0, 1f0, length(positions[]))),
    colormap = cmap, colorrange = (0, 1)
)
scene
