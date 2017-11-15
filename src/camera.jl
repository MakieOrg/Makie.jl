using Makie, GeometryTypes, GLAbstraction
using Makie: to_signal, add_pan, add_zoom, add_mousebuttons, add_mousedrag, selection_rect
using Base: RefValue

scene = Scene()


add_mousebuttons(scene)
add_mousedrag(scene)
scene[:keyboardbuttons] = lift_node(scene[:buttons_pressed]) do x
    map(Keyboard.Button, x)
end

cam = Scene(
    :area => lift_node(FRect, scene[:window_area]),
    :projection => eye(Mat4f0),
    :view => eye(Mat4f0)
)
Makie.update_cam!(cam, to_value(cam, :area))
add_zoom(cam, scene)
add_pan(cam, scene)

projview = lift_node(*, cam[:projection], cam[:view])

x = scatter(rand(100) .* 500f0, rand(100) .* 500f0, markersize = 20)


scene[:screen].renderlist[1][1][:view] = to_signal(cam[:view])
scene[:screen].renderlist[1][1][:projection] = to_signal(cam[:projection])
scene[:screen].renderlist[1][1][:projectionview] = to_signal(projview)

rectviz, rect = selection_rect(scene, cam)

scene[:screen].renderlist[2][1][:view] = to_signal(cam[:view])
scene[:screen].renderlist[2][1][:projection] = to_signal(cam[:projection])
scene[:screen].renderlist[2][1][:projectionview] = to_signal(projview)