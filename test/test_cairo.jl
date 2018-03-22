using Colors, Cairo
using Makie
using GeometryTypes

scene = Scene()
scene.px_area[] = IRect(0, 0, 800, 600)
cam = Makie.cam2d!(scene)
a = text!(scene, "Hellooo", color = :white, textsize = 20, position = (0.5, 0.5))
b = scatter!(scene, rand(10), rand(10), color = :blue, strokecolor = :black)
c = lines!(scene, rand(10), rand(10), color = :red)
# d = heatmap!(scene, rand(10, 10))
# f = meshscatter!(scene, rand(10), rand(10), rand(10))
screen = CairoScreen(scene, "circles.svg")
for elem in scene.plots
    Makie.cairo_draw(screen, elem)
end
Makie.cairo_finish(screen)
