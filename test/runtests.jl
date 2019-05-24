using WGLMakie, AbstractPlotting

using FileIO, Images
img = RGBAf0.(load(joinpath(homedir(), "Desktop", "profile.jpg")))
img = restrict(restrict(img))
heatmap(img) |> display
lines(rand(4), color = (:red, 0.1), linewidth = 10)
contour(rand(10, 10)) |> display


using AbstractPlotting
using AbstractPlotting: hbox, vbox
using AbstractPlotting
using WGLMakie

N = 10
x = LinRange(-0.3, 1, N)
y = LinRange(-1, 0.5, N)
z = x .* y'
hbox(
    vbox(
        contour(x, y, z, levels = 20, linewidth =3),
        contour(x, y, z, levels = 0, linewidth = 0, fillrange = true),
        heatmap(x, y, z),
    ),
    vbox(
        image(x, y, z, colormap = :viridis),
        surface(x, y, fill(0f0, N, N), color = z, shading = false),
        image(-0.3..1, -1..0.5, AbstractPlotting.logo())
    )
)
