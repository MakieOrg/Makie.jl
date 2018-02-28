include("Makie2.jl")
using .Makie2
using GeometryTypes
scene = Scene()
screen = Screen(scene)

lolo = scatter(scene, rand(10), rand(10))
loli = insert!(screen, scene, lolo)

yolo = lines(scene, rand(10), rand(10), color = :white)
loli = insert!(screen, scene, yolo)
yolo.attributes[:color][] = :red

scene.theme[:scatter][:color][] = :red


update_cam!(scene, FRect(0, 0, 1.6, 1.0))

cam = cam2d!(scene)

screenw = widths(scene.px_area[])
camw = widths(scene.area[])

screen_r = screenw ./ screenw[1]
camw_r = camw ./ camw[1]
r = (screen_r ./ camw_r)
r = r ./ maximum(r)

update_cam!(scene, FRect(minimum(scene.area[]), r .* camw))
