using Makie
using GeometryTypes
scene = Scene()
screen = Screen(scene)

lolo = text(scene, "Hellooo", color = :white)
loli = insert!(screen, scene, lolo)


lolo = scatter(scene, rand(10), rand(10))

lolo = scatter(scene, rand(10), rand(10))
scene.theme[:scatter][:color][] = :red
loli = insert!(screen, scene, lolo)

yolo = lines(scene, rand(10), rand(10), color = :white)
loli = insert!(screen, scene, yolo)
lolo = meshscatter(scene, rand(10), rand(10), rand(10))
loli = insert!(screen, scene, lolo)
yolo.attributes[:color][] = :red

update_cam!(scene, FRect(0, 0, 1.6, 1.0))

cam = cam2d!(scene)

screenw = widths(scene.px_area[])
camw = widths(scene.area[])

screen_r = screenw ./ screenw[1]
camw_r = camw ./ camw[1]
r = (screen_r ./ camw_r)
r = r ./ maximum(r)

update_cam!(scene, FRect(minimum(scene.area[]), r .* camw))
