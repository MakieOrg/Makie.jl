using Makie
using GeometryTypes

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    isempty(scene.current_screens) || return
    screen = Screen(scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    return
end
function Base.show(io::IO, m::MIME"text/plain", plot::Makie.AbstractPlot)
    show(io, m, Makie.parent(plot)[])
    nothing
end
scene = Scene()

scene.px_area[] = IRect(0, 0, 1920, 1080)
cam = cam2d!(scene)
cam.area[] = FRect(0, 0, normalize(widths(scene.px_area[])) * 3)
update_cam!(scene, cam)
s = scatter!(scene, [0, 0, 1, 1], [0, 1, 0, 1])
s = lines!(scene, [0, 0, 1, 1], [0, 1, 0, 1])
xy = linspace(0, 2pi, 100)
s = contour!(scene, xy, xy, ((x, y)-> sin(x) + cos(y)).(xy, xy'))


# screen = Screen(scene)
a = text!(scene, "Hellooo", color = :white, textsize = 0.1, position = (0.5, 0.5))
b = scatter!(scene, rand(10), rand(10))
b = linesegments!(scene, rand(10), rand(10))
c = plot!(scene, rand(10), rand(10), color = :white)
d = meshscatter!(scene, rand(10), rand(10), rand(10));


scene = Scene()
scene.px_area[] = IRect(0, 0, 1920, 1080)
cam = cam2d!(scene)
cam.area[] = FRect(0, 0, normalize(widths(scene.px_area[])) * 3)
update_cam!(scene, cam)
scatter!(scene, FRect(0, 0, 1, 1), scale_plot = false, linewidth = 5)
h = heatmap!(scene, linspace(0, 1, 50), linspace(0, 1, 50), rand(50, 50))
scene
# cam.rotationspeed[] = 0.1
# cam.pan_button[] = Mouse.right
# scene.events.window_dpi[]

# screenw = widths(scene.px_area[])
# camw = widths(scene.area[])
#
# screen_r = screenw ./ screenw[1]
# camw_r = camw ./ camw[1]
# r = (screen_r ./ camw_r)
# r = r ./ maximum(r)
#
# update_cam!(scene, FRect(minimum(scene.area[]), r .* camw))
