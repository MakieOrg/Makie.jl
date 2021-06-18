using GLMakie, GLMakie.FileIO; using LinearAlgebra: norm
set_window_config!(pause_rendering = true)
AbstractPlotting.inline!(true)
using DelimitedFiles



let
    f = Figure(resolution = (1400, 1000), font = "Helvetica")

    airports = readdlm(raw"C:\Users\Krumbiegel\Downloads\airportlocations.csv")
    airports_rep = repeat(airports, 100_000_000 ÷ size(airports, 1), 1) .+ randn.()
    scatter(f[1, 1], airports_rep, color = (:black, 0.01), markersize = 0.5, strokewidth = 0,
        axis = (title = "Airports (100 Million points)", limits = (-200, 200, -70, 80)))

    r = LinRange(-5, 5, 100)
    volume = [sin(x) + sin(y) + 0.1z^2 for x = r, y = r, z = r]
    ax, c = contour(f[2, 1][1, 1], volume, levels = 8, colormap = :viridis,
        axis = (type = Axis3, viewmode = :stretch, title = "3D contour"))
    Colorbar(f[2, 1][1, 2], c, label = "intensity")

    function mandelbrot(x, y)
        z = c = x + y*im
        for i in 1:30.0; abs(z) > 2 && return i; z = z^2 + c; end; 0
    end

    ax2, hm = heatmap(f[1:2, 2][1, 2], -2:0.005:1, -1.1:0.005:1.1, mandelbrot,
        interpolate = true, colormap = Reverse(:deep), axis = (title = "Mandelbrot set",))
    hidedecorations!(ax2)
    Colorbar(f[1:2, 2][1, 1], hm, flipaxis = false, label = "Iterations", height = 300)

    Axis3(f[1:2, 2][2, 1:2], aspect = :data, title = "Brain mesh")
    brain = load(assetpath("brain.stl"))
    color = [-norm(tri[1] .- Point3f0(-40, 10, 45)) for tri in brain for i in 1:3]
    m = mesh!(brain, color = color, colormap = :thermal)

    Label(f[0, :], "Makie.jl Example Figure")

    save("paper_example.png", f)
    nothing
end