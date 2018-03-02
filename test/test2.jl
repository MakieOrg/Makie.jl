using Makie
using GeometryTypes
scene = Scene()
screen = Screen(scene)

lolo = text(scene, "Hellooo", color = :white, textsize = 0.1, position = (0.5, 0.5))
loli = insert!(screen, scene, lolo)

holo = scatter(scene, rand(10), rand(10))
loli = insert!(screen, scene, holo)
lolo = scatter(scene, rand(10), rand(10))
scene.theme[:scatter][:color][] = :red
loli = insert!(screen, scene, lolo)

yolo = lines(scene, rand(10), rand(10), color = :white)
loli = insert!(screen, scene, yolo)
lolo = meshscatter(scene, rand(10), rand(10), rand(10))
loli = insert!(screen, scene, lolo)
yolo.attributes[:color][] = :red

# update_cam!(scene, FRect(0, 0, 1, 2))

# cam = Makie.cam2d!(scene)
cam = Makie.cam3d!(scene)
cam.rotationspeed[] = 0.1
cam.pan_button[] = Mouse.right
# screenw = widths(scene.px_area[])
# camw = widths(scene.area[])
#
# screen_r = screenw ./ screenw[1]
# camw_r = camw ./ camw[1]
# r = (screen_r ./ camw_r)
# r = r ./ maximum(r)
#
# update_cam!(scene, FRect(minimum(scene.area[]), r .* camw))
