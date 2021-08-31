using GLMakie, GLMakie.FileIO
using LinearAlgebra: norm
using DelimitedFiles
set_window_config!(pause_rendering = true)

f = Figure(resolution = (1400, 1000))

a = readdlm(assetpath("airportlocations.csv"))
# reduce this number if your GPU is not powerful enough
n_points = 100_000_000
a_rep = repeat(a, n_points ÷ size(a, 1), 1) .+ randn.()
scatter(f[1, 1], a_rep, color = (:black, 0.01), markersize = 1.0,
    strokewidth = 0, axis = (title = "Airports (100 Million points)",
    limits = (-200, 200, -70, 80)))

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
    colormap = Reverse(:deep), axis = (title = "Mandelbrot set",))
hidedecorations!(ax2)
Colorbar(f[1:2, 2][1, 1], hm, flipaxis = false,
    label = "Iterations", height = 300)

Axis3(f[1:2, 2][2, 1:2], aspect = :data, title = "Brain mesh")
brain = load(assetpath("brain.stl"))
color = [-norm(x[1] .- Point(-40, 10, 45)) for x in brain for i in 1:3]
mesh!(brain, color = color, colormap = :thermal)

Label(f[0, :], "Makie.jl Example Figure")

save("paper_example.png", f)
