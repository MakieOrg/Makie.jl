using WGLMakie, AbstractPlotting
using AbstractPlotting: hbox, vbox
using FileIO, Images
contour(rand(Float32, 10, 10, 10)) |> display
