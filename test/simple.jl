using AbstractPlotting
using GLMakie
using GeometryBasics
using Observables
using FileIO
using GeometryBasics: Pyramid

scatter(1:4, color=rand(RGBf0, 4)) |> display
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
using MeshIO, FileIO
cat = load(GLMakie.assetpath("cat.obj"))
tex = load(GLMakie.assetpath("diffusemap.tga"));
scren = mesh(cat, color=tex)

m = mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
     shading = false) |> display

meshes = GeometryBasics.normal_mesh.([Sphere(Point3f0(0.5), 1), Rect(Vec3f0(1, 0, 0), Vec3f0(1))])
mesh(meshes, color=[1, 2])

# Axis
scene = lines(IRect(Vec2f0(0), Vec2f0(1)))
axis = scene[Axis]
axis.ticks.ranges = ([0.1, 0.2, 0.9], [0.1, 0.2, 0.9])
axis.ticks.labels = (["😸", "♡", "𝕴"], ["β ÷ δ", "22", "≙"])
scene


# Text
x = text("heyllo") |> display


# Animations
function n_times(f, n=10, interval=0.05)
    obs = Observable(f(1))
    @async for i in 2:n
        try
            obs[] = f(i)
            sleep(interval)
        catch e
            @warn "Error!" exception=CapturedException(e, Base.catch_backtrace())
        end
    end
    return obs
end

annotations(n_times(i-> map(j-> ("$j", Point2f0(j*30, 0)), 1:i)), textsize=20, limits=FRect2D(30, 0, 320, 50))
scatter(n_times(i-> Point2f0.((1:i).*30, 0)), limits=FRect2D(30, 0, 320, 50), markersize=20px)
linesegments(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50), markersize=20px)
lines(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50), markersize=20px)
