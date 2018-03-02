using Makie
using GeometryTypes
function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    screen = Screen(scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    nothing
end
scene = Scene()
cam = Makie.cam2d!(scene)
# screen = Screen(scene)
a = text!(scene, "Hellooo", color = :white, textsize = 0.1, position = (0.5, 0.5))
b = scatter!(scene, rand(10), rand(10))
c = lines!(scene, rand(10), rand(10), color = :white)
d = meshscatter!(scene, rand(10), rand(10), rand(10))
scene
# update_cam!(scene, FRect(0, 0, 1, 2))

# cam = Makie.cam2d!(scene)

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
