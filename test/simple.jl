using AbstractPlotting
using GLMakie
using GeometryBasics
using Observables
using GeometryBasics: Pyramid
using PlotUtils
using MeshIO, FileIO
using AbstractPlotting: Pixel

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
cmap = cgrad(:RdYlBu; categorical=true);
line_positions = Point2f0.([1:4; NaN; 1:4], [1:4; NaN; 2:5])
cat = MakieGallery.loadasset("cat.obj")
tex = MakieGallery.loadasset("diffusemap.png")
meshes = GeometryBasics.normal_mesh.([Sphere(Point3f0(0.5), 1), Rect(Vec3f0(1, 0, 0), Vec3f0(1))])
positions = Point2f0[(1, 1), (2, 2), (3, 2), (4, 4)]
positions_connected = connect(positions, LineFace{Int}[(1, 2), (2, 3), (3, 4)])

@block SimonDanisch ["tests"] begin
    ## Scatter
    @cell scatter(1:4, color=:red, markersize=0.3)
    @cell scatter(1:4, color=:red, markersize=10px)
    @cell scatter(1:4, color=:red, markersize=10, markerspace=Pixel)
    @cell scatter(1:4, color=:red, markersize=(1:4).*8, markerspace=Pixel)

    @cell scatter(1:4, marker='☼')
    @cell scatter(1:4, marker=['☼', '◒', '◑', '◐'])
    @cell scatter(1:4, marker="☼◒◑◐")
    @cell scatter(1:4, marker=rand(RGBf0, 10, 10), markersize=20px) |> display
    # TODO rotation with markersize=px
    @cell scatter(1:4, marker='▲', markersize=0.3, rotations=LinRange(0, pi, 4)) |> display

    ## Meshscatter
    @cell meshscatter(1:4, color=1:4) |> display

    @cell meshscatter(1:4, color=rand(RGBAf0, 4))
    @cell meshscatter(1:4, color=rand(RGBf0, 4))
    @cell meshscatter(1:4, color=:red)
    @cell meshscatter(rand(Point3f0, 10), color=rand(RGBf0, 10))
    @cell meshscatter(rand(Point3f0, 10), marker=Pyramid(Point3f0(0), 1f0, 1f0)) |> display

    ## Lines
    @cell lines(line_positions)
    @cell lines(line_positions, linestyle=:dot)
    @cell lines(line_positions, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
    @cell lines(line_positions, color=1:9)
    @cell lines(line_positions, color=rand(RGBf0, 9), linewidth=4)

    ## Linesegments
    @cell linesegments(1:4)
    @cell linesegments(1:4, linestyle=:dot)
    @cell linesegments(1:4, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
    @cell linesegments(1:4, color=1:4)
    @cell linesegments(1:4, color=rand(RGBf0, 4), linewidth=4)


    ## Surface
    @cell surface(args_2d...)
    @cell surface(args_2d..., color=rand(size(data_2d)...))
    @cell surface(args_2d..., color=rand(RGBf0, size(data_2d)...))
    @cell surface(args_2d..., colormap=:magma, colorrange=(-3.0, 4.0))
    @cell surface(args_2d..., shading=false); wireframe!(args_2d..., linewidth=0.5)
    @cell surface(1:30, 1:31, rand(30, 31))
    @cell begin
        n = 20
        θ = [0;(0.5:n-0.5)/n;1]
        φ = [(0:2n-2)*2/(2n-1);2]
        x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
        y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
        z = [cospi(θ) for θ in θ, φ in φ]
        surface(x, y, z)
    end
    ## Polygons
    @cell poly(decompose(Point2f0, Circle(Point2f0(0), 1f0)))

    ## Image like!
    @cell image(rand(10, 10))
    @cell heatmap(rand(10, 10))

    ## Volumes
    @cell volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso) |> display
    @cell volume(rand(4, 4, 4), algorithm=:mip)
    @cell volume(rand(4, 4, 4), algorithm=:absorption)
    @cell volume(rand(4, 4, 4), algorithm=Int32(5)) |> display

    @cell volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba)
    @cell contour(rand(4, 4, 4)) |> display

    ## Meshes

    @cell mesh(cat, color=tex)
    @cell mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
         shading = false)
    @cell mesh(meshes, color=[1, 2])

    ## Axis
    @cell begin
        scene = lines(IRect(Vec2f0(0), Vec2f0(1)))
        axis = scene[Axis]
        axis.ticks.ranges = ([0.1, 0.2, 0.9], [0.1, 0.2, 0.9])
        axis.ticks.labels = (["😸", "♡", "𝕴"], ["β ÷ δ", "22", "≙"])
        scene
    end

    ## Text
    @cell text("heyllo")


    ## Colormaps
    @cell heatmap(args_2d...; colormap=cgrad(:RdYlBu; categorical=true), interpolate=true)
    @cell image(args_2d...; colormap=cgrad(:RdYlBu; categorical=true), interpolate=true)
    @cell heatmap(args_2d...; colorrange=(-4.0, 3.0), colormap=cmap, highclip=:green,
                  lowclip=:pink, interpolate=true)
    @cell surface(args_2d...; colorrange=(-4.0, 3.0), highclip=:green, lowclip=:pink)

    ## Animations

    @cell annotations(n_times(i-> map(j-> ("$j", Point2f0(j*30, 0)), 1:i)), textsize=20,
                      limits=FRect2D(30, 0, 320, 50))
    @cell scatter(n_times(i-> Point2f0.((1:i).*30, 0)), markersize=20px,
                  limits=FRect2D(30, 0, 320, 50))
    @cell linesegments(n_times(i-> Point2f0.((2:2:2i).*30, 0)), markersize=20px,
                       limits=FRect2D(30, 0, 620, 50))
    @cell lines(n_times(i-> Point2f0.((2:2:2i).*30, 0)), markersize=20px,
                limits=FRect2D(30, 0, 620, 50))

    # Scaling
    @cell begin
        scene = Scene(transform_func=(identity, log10))
        linesegments!(1:4, color=:black, linewidth=20, transparency=true)
        scatter!(1:4, color=rand(RGBf0, 4), markersize=20px)
        lines!(1:4, color=rand(RGBf0, 4)) |> display
    end

    # Views
    @cell linesegments(positions)
    @cell scatter(positions_connected)

    # Interpolation
    @cell heatmap(data_2d, interpolate=true)
    @cell image(data_2d, interpolate=false)

    # Categorical
    @cell barplot(["hi", "ima", "string"], rand(3))
end
