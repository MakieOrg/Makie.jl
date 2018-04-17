using Colors, Cairo
using Makie
using GeometryTypes
# d = heatmap!(scene, rand(10, 10))
# f = meshscatter!(scene, rand(10), rand(10), rand(10))
function draw_all(screen, scene::Scene)
    for elem in scene.plots
        Makie.CairoBackend.cairo_draw(screen, elem)
    end
    foreach(x->draw_all(screen, x), scene.children)
    Makie.CairoBackend.cairo_finish(screen)
end

srand(1)
scene = Scene()
s = scatter!(scene, 1:10, rand(10))
s2 = lines!(scene, -1:8, rand(10) .+ 1, color = :black)
update_cam!(scene, FRect(-4, -2, 17, 4))
nothing
scene
screen = Makie.CairoBackend.CairoScreen(scene, joinpath(homedir(), "Desktop", "test.svg"))
draw_all(screen, scene)
