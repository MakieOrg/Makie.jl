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
x = lines!(scene, FRect(0, 0, 0.5, 0.5), linestyle = :dot)
x[:positions] = FRect(0, 0, 1.0, 0.5)
x[:visible] = true
x.attributes

# screen = Screen(scene)
a = text!(scene, "Hellooo", color = :white, textsize = 0.1, position = (0.5, 0.5))
b = Makie.scatter!(scene, rand(10), rand(10))
c = Makie.plot!(scene, rand(10), rand(10), color = :white)
d = meshscatter!(scene, rand(10), rand(10), rand(10));
scene2 = Scene()
a = text!(scene2, "Hellooo", color = :white, textsize = 0.1, position = (0.5, 0.5))
b = Makie.scatter!(scene2, rand(10), rand(10))
c = Makie.plot!(scene2, rand(10), rand(10), color = :white)
d = meshscatter!(rand(10), rand(10), rand(10));

lolz = Makie.plot(rand(10), rand(10))
meshscatter!(rand(10), rand(10), rand(10));

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
