using AbstractPlotting
using GLMakie
using GeometryBasics
using Observables
using FileIO
using MakieGallery

using GeometryBasics: Pyramid

scatter(1:4, color=1:4)

scatter(1:4, color=rand(RGBAf0, 4))
scatter(1:4, color=rand(RGBf0, 4))
scatter(1:4, color=:red)

scatter(1:4, marker='☼')
scatter(1:4, marker=['☼', '◒', '◑', '◐'])
scatter(1:4, marker="☼◒◑◐")
scatter(1:4, marker=rand(RGBf0, 10, 10), markersize=20px) |> display
# TODO rotation with markersize=px
scatter(1:4, marker='▲', markersize=0.3, rotations=LinRange(0, pi, 4)) |> display

# Meshscatter
meshscatter(1:4, color=1:4) |> display

meshscatter(1:4, color=rand(RGBAf0, 4))
meshscatter(1:4, color=rand(RGBf0, 4))
meshscatter(1:4, color=:red)
meshscatter(rand(Point3f0, 10), color=rand(RGBf0, 10))
meshscatter(rand(Point3f0, 10), marker=Pyramid(Point3f0(0), 1f0, 1f0)) |> display

# Lines
positions = Point2f0.([1:4; NaN; 1:4], [1:4; NaN; 2:5])
lines(positions)
lines(positions, linestyle=:dot)
lines(positions, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
lines(positions, color=1:9)
lines(positions, color=rand(RGBf0, 9), linewidth=4)

# Linesegments
linesegments(1:4)
linesegments(1:4, linestyle=:dot)
linesegments(1:4, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
linesegments(1:4, color=1:4)
linesegments(1:4, color=rand(RGBf0, 4), linewidth=4)
x = Point2f0[(1, 1), (2, 2), (3, 2), (4, 4)]
points = connect(x, LineFace{Int}[(1, 2), (2, 3), (3, 4)])
x = linesegments(points)

# Surface
data = AbstractPlotting.peaks()
surface(-10..10, -10..10, data)
surface(-10..10, -10..10, data, color=rand(size(data)...)) |> display
surface(-10..10, -10..10, data, color=rand(RGBf0, size(data)...))
surface(-10..10, -10..10, data, colormap=:magma, colorrange=(0.0, 2.0))

# Polygons
poly(decompose(Point2f0, Circle(Point2f0(0), 1f0))) |> display

# Image like!
image(rand(10, 10))
heatmap(rand(10, 10))

# Volumes
volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso) |> display
volume(rand(4, 4, 4), algorithm=:mip)
volume(rand(4, 4, 4), algorithm=:absorption)
volume(rand(4, 4, 4), algorithm=Int32(5)) |> display

volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba)
contour(rand(4, 4, 4)) |> display

# Meshes
cat = load(GLMakie.assetpath("cat.obj"))
tex = load(GLMakie.assetpath("diffusemap.tga"))
scren = mesh(cat, color=tex)

m = mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
     shading = false) |> display

# Axis
scene = lines(IRect(Vec2f0(0), Vec2f0(1)))
axis = scene[Axis]
axis.ticks.ranges = ([0.1, 0.2, 0.9], [0.1, 0.2, 0.9])
axis.ticks.labels = (["😸", "♡", "𝕴"], ["β ÷ δ", "22", "≙"])
scene


# Text
x = text("heyllo")

using GLMakie.GLAbstraction: gpu_data
scren = annotations(string.(collect("heybrobr")), Point2f0.(LinRange(1, 100, 8)), show_axis=false, scale_plot=false) |> display

robj = scren.renderlist[1][3]

scales = gpu_data(robj.uniforms[:scale])
position = gpu_data(robj.uniforms[:position])
offset = robj.uniforms[:offset][]

scren = text("bro", scale_plot=false, show_axis=false) |> display
robj = scren.renderlist[1][3]

scales = gpu_data(robj.uniforms[:scale])
position = gpu_data(robj.uniforms[:position])
offset = robj.uniforms[:offset][]
uv_offset_width = gpu_data(robj.uniforms[:uv_offset_width])

scatter!(position, marker=Rect, marker_offset=offset, markersize=scales, raw=true, color=(:blue, 0.3), transform_marker=false)

atlas = AbstractPlotting.get_texture_atlas()

scatter(position,
    marker="bro", marker_offset=offset,
    markersize=scales, scale_plot=false, show_axis=false,
    color=(:blue, 0.3), uv_offset_width = uv_offset_width,
    transform_marker=false)

posstart = Vec2(round.(Int, uv_offset_width[3][1:2] .* size(atlas.data)))
posstop = Vec2(round.(Int, uv_offset_width[3][3:4] .* size(atlas.data)))

f = AbstractPlotting.defaultfont()

using FreeTypeAbstraction

FreeTypeAbstraction.get_pixelsize(f)

rm(AbstractPlotting.get_cache_path())
xx = IRect2D(posstart, posstop .- posstart)
atlas.data[xx]

heatmap(atlas.data[xx])
