using WGLMakie, AbstractPlotting
using AbstractPlotting: hbox, vbox
using FileIO, Images
contour(rand(Float32, 10, 10, 10)) |> display


scene = scatter(rand(4))
scene[end].color = :green

scene = mesh(
    [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
    shading = false
)
scene[end].color = [:green, :yellow, :blue]
