using Colors, Cairo
using Makie
using GeometryTypes

scene = Scene()
scene.px_area[] = IRect(0, 0, 800, 600)
cam = Makie.cam2d!(scene)
# screen = Screen(scene)
# a = text!(scene, "Hellooo", color = :white, textsize = 0.1, position = (0.5, 0.5))
# b = scatter!(scene, rand(10), rand(10))
c = lines!(scene, rand(10), rand(10), color = :black)
# d = meshscatter!(scene, rand(10), rand(10), rand(10))
screen = CairoScreen(scene, "circles.svg")
for elem in scene.plots
    Makie.cairo_draw(screen, elem)
end
finish(screen.surface)
