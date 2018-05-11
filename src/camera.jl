using Makie, GeometryTypes
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


function addcam(scat, cam)
    for robj in extract_renderable(scat.visual)
        robj[:view] = to_signal(cam[:view])
        robj[:projection] = to_signal(cam[:projection])
        robj[:projectionview] = to_signal(projview)
    end
end

scat = scatter(rand(100) .* 500f0, rand(100) .* 500f0, markersize = 20)
addcam(scat, cam)
scat = scatter(rand(100) .* 500f0, rand(100) .* 500f0, markersize = 20)
addcam(scat, cam)
scat = scatter(rand(100) .* 500f0, rand(100) .* 500f0, markersize = 20)
addcam(scat, cam)
a = axis(linspace(0, 500, 5), linspace(0, 500, 5))
addcam(a, cam)
rectviz, rect = selection_rect(scene, cam)

addcam(rectviz, cam)
extract_renderable(a.visual)

using TextParse
using TextParse: Record, Field, Numeric, tryparsenext

x = assetpath("cat.obj")

obj = readstring(x)

function nv_parse(str, pos, len, opts = nothing)
    str[pos] == 'v' && str[pos + 1] == ' ' || return Nullable{Point3f0}()
    p, pos = tryparsenext(PointSpace, str, pos + 2, len)
    isnull(p) && error("Invalid object")
    Point3f0(get(p)), pos
end
CustomParser(nv_parse, Point)
findnext(obj, '\n', 7)

obj[pos - 1]
p, pos = nv_parse(obj, pos - 1, length(obj))
nv_parse(obj, pos, length(obj))


field = Field(Numeric(Float32), ignore_init_whitespace = false, ignore_end_whitespace = false, delim = ' ')
PointSpace = Record((
        field,
        field,
        Field(Numeric(Float32), eoldelim = true)
))
tryparsenext(PointSpace, str, pos + 1, length(str))


sign, i = TextParse.tryparsenext_sign(str, pos+2, length(str))

c, ii = next(str, i)
TextParse.tryparsenext_base10(Int, str, i, length(str))
str[(pos+1):pos+27]

str = obj
pos = 23
str[pos+1]
str[pos] == 'n' && str[pos + 1] == 'v' && str[pos + 2] == ' '
nv_parse()
