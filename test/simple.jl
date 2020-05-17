using AbstractPlotting
using GLMakie
using GeometryBasics
using Observables
using GeometryBasics: Pyramid
using PlotUtils
using MeshIO, FileIO

## Some helpers
data_2d = AbstractPlotting.peaks()
args_2d = (-10..10, -10..10, data_2d)

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

## Scatter

scatter(1:4, color=:red)
scatter(1:4, marker='☼')
scatter(1:4, marker=['☼', '◒', '◑', '◐'])
scatter(1:4, marker="☼◒◑◐")
scatter(1:4, marker=rand(RGBf0, 10, 10), markersize=20px) |> display
# TODO rotation with markersize=px
scatter(1:4, marker='▲', markersize=0.3, rotations=LinRange(0, pi, 4)) |> display

## Meshscatter
meshscatter(1:4, color=1:4) |> display

meshscatter(1:4, color=rand(RGBAf0, 4))
meshscatter(1:4, color=rand(RGBf0, 4))
meshscatter(1:4, color=:red)
meshscatter(rand(Point3f0, 10), color=rand(RGBf0, 10))
meshscatter(rand(Point3f0, 10), marker=Pyramid(Point3f0(0), 1f0, 1f0)) |> display

## Lines
positions = Point2f0.([1:4; NaN; 1:4], [1:4; NaN; 2:5])
lines(positions)
lines(positions, linestyle=:dot)
lines(positions, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
lines(positions, color=1:9)
lines(positions, color=rand(RGBf0, 9), linewidth=4)

## Linesegments
linesegments(1:4)
linesegments(1:4, linestyle=:dot)
linesegments(1:4, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
linesegments(1:4, color=1:4)
linesegments(1:4, color=rand(RGBf0, 4), linewidth=4)


## Surface
surface(args_2d...)
surface(args_2d..., color=rand(size(data_2d)...))
surface(args_2d..., color=rand(RGBf0, size(data_2d)...))
surface(args_2d..., colormap=:magma, colorrange=(-3.0, 4.0))
surface(args_2d..., shading=false); wireframe!(args_2d..., linewidth=0.5)
surface(1:30, 1:31, rand(30, 31))
n = 20
θ = [0;(0.5:n-0.5)/n;1]
φ = [(0:2n-2)*2/(2n-1);2]
x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
z = [cospi(θ) for θ in θ, φ in φ]
surface(x, y, z)
## Polygons
poly(decompose(Point2f0, Circle(Point2f0(0), 1f0)))

## Image like!
image(rand(10, 10))
heatmap(rand(10, 10))

## Volumes
volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso) |> display
volume(rand(4, 4, 4), algorithm=:mip)
volume(rand(4, 4, 4), algorithm=:absorption)
volume(rand(4, 4, 4), algorithm=Int32(5)) |> display

volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba)
contour(rand(4, 4, 4)) |> display

## Meshes
cat = load(GLMakie.assetpath("cat.obj"))
tex = load(GLMakie.assetpath("diffusemap.tga"));
scren = mesh(cat, color=tex)

m = mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
     shading = false) |> display

meshes = GeometryBasics.normal_mesh.([Sphere(Point3f0(0.5), 1), Rect(Vec3f0(1, 0, 0), Vec3f0(1))])
mesh(meshes, color=[1, 2])

## Axis
scene = lines(IRect(Vec2f0(0), Vec2f0(1)))
axis = scene[Axis]
axis.ticks.ranges = ([0.1, 0.2, 0.9], [0.1, 0.2, 0.9])
axis.ticks.labels = (["😸", "♡", "𝕴"], ["β ÷ δ", "22", "≙"])
scene


## Text
x = text("heyllo") |> display


## Colormaps
cmap = cgrad(:RdYlBu; categorical=true);
heatmap(args_2d...; colormap=cgrad(:RdYlBu; categorical=true), interpolate=true)

image(args_2d...; colormap=cgrad(:RdYlBu; categorical=true), interpolate=true)

s = heatmap(args_2d...; colorrange=(-4.0, 3.0), colormap=cmap, highclip=:green, lowclip=:pink, interpolate=true)
surface(args_2d...; colorrange=(-4.0, 3.0), highclip=:green, lowclip=:pink)

## Animations

annotations(n_times(i-> map(j-> ("$j", Point2f0(j*30, 0)), 1:i)), textsize=20, limits=FRect2D(30, 0, 320, 50))
scatter(n_times(i-> Point2f0.((1:i).*30, 0)), limits=FRect2D(30, 0, 320, 50), markersize=20px)
linesegments(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50), markersize=20px)
lines(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50), markersize=20px)


# Set up sliders to control lighting attributes
s1, ambient = textslider(0f0:0.01f0:1f0, "ambient", start = 0.55f0)
s2, diffuse = textslider(0f0:0.025f0:2f0, "diffuse", start = 0.4f0)
s3, specular = textslider(0f0:0.025f0:2f0, "specular", start = 0.2f0)
s4, shininess = textslider(2f0.^(2f0:8f0), "shininess", start = 32f0)

# Set up (r, θ, ϕ) for lightposition
s5, radius = textslider(2f0.^(0.5f0:0.25f0:20f0), "light pos r", start = 2f0)
s6, theta = textslider(0:5:180, "light pos theta", start = 30f0)
s7, phi = textslider(0:5:360, "light pos phi", start = 45f0)

# transform signals into required types
la = map(Vec3f0, ambient)
ld = map(Vec3f0, diffuse)
ls = map(Vec3f0, specular)
lp = map(radius, theta, phi) do r, theta, phi
    r * Vec3f0(
        cosd(phi) * sind(theta),
        sind(phi) * sind(theta),
        cosd(theta)
    )
end

scene = Scene()
surface!(scene, args_2d...; ambient = la, diffuse = ld, specular = ls, shininess = shininess,lightposition = lp)
scatter!(scene, map(v -> [v], lp), color=:yellow, markersize=0.2f0)

vbox(hbox(s4, s3, s2, s1, s7, s6, s5), scene) |> display

# Scaling
scene = Scene(transform_func=(identity, log10))
linesegments!(1:4, color=:black, linewidth=20, transparency=true)
scatter!(1:4, color=rand(RGBf0, 4), markersize=20px)
lines!(1:4, color=rand(RGBf0, 4)) |> display


# Views
x = Point2f0[(1, 1), (2, 2), (3, 2), (4, 4)]
points = connect(x, LineFace{Int}[(1, 2), (2, 3), (3, 4)])
linesegments(points)
scatter(x)
p4 = heatmap(rand(100, 100))

# Interpolation
heatmap(data_2d, interpolate=true)
image(data_2d, interpolate=false)


# Categorical

barplot(["hi", "ima", "string"], rand(3))
