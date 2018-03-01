# using GLAbstraction, Makie, GeometryTypes
using GLAbstraction: orthographicprojection, translationmatrix
using StaticArrays
include("old/plotutils/layout.jl")
# @default function camera2d(scene, kw_args)
#     translationspeed = to_float(1)
#     eyeposition = Vec3f0(3)
#     lookat = Vec3f0(0)
#     upvector = Vec3f0((0, 0, 1))
#     near = to_float(10_000)
#     far = to_float(-10_000)
# end

wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

set_value!(x::Node, value) = (x.value = value)
function update_cam!(cam::Scene, area)
    x, y = minimum(area)
    w, h = widths(area) ./ 2f0
    # These nodes should be final, no one should do map(cam.projection),
    # so we don't push! and just update the value in place
    set_value!(cam.area, area)
    set_value!(cam.projection, orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0))
    set_value!(cam.view, translationmatrix(Vec3f0(-x - w, -y - h, 0)))
    return
end


function camspace(cam_area, screen_area, point)
    point = point .* wscale(screen_area, cam_area)
    point .+ minimum(cam_area)
end

function selection_rect(
        scene, cam,
        key = Mouse.left,
        button = Set([Keyboard.left_control, Keyboard.space])
    )
    rect = RefValue(FRect(0, 0, 0, 0))
    lw = 2f0
    rect_vis = lines(
        Scene(scene, camera = :pixel),
        rect[],
        linestyle = :dot,
        thickness = 1f0,
        color = (:black, 0.4),
        drawover = true
    )
    waspressed = RefValue(false)
    dragged_rect = map(scene.events.mousedrag) do drag
        if ispressed(scene, key) && ispressed(scene, button)
            screen_area = to_value(scene, :window_area)
            cam_area = to_value(cam, :area)
            mp = to_value(scene, :mouseposition)
            mp = camspace(cam_area, screen_area, mp)

            if drag == Mouse.down
                waspressed[] = true
                rect_vis[:visible] = true # start displaying
                rect[] = FRect(mp, 0, 0)
                rect_vis[:positions] = rect[]
            elseif drag == Mouse.pressed
                mini = minimum(rect[])
                rect[] = FRect(mini, mp - mini)
                # mini, maxi = min(mini, mp), max(mini, mp)
                rect_vis[:positions] = rect[]
            end
        else
            if drag == Mouse.up && waspressed[]
                waspressed[] = false
                update_cam!(cam, rect[])
            end
            rect[] = FRect(0, 0, 0, 0)
            rect_vis[:positions] = rect[]
            # always hide if not the right key is pressed
            rect_vis[:visible] = false # hide
        end
        return rect[]
    end
    rect_vis, dragged_rect
end


function add_pan!(scene, attributes)
    startpos = RefValue((0.0, 0.0))
    events = scene.events
    panbutton = attributes[:panbutton]
    foreach(events.mouseposition, events.mousedrag) do mp, dragging
        if ispressed(scene, panbutton[])
            window_area = scene.px_area[]
            cam_area = scene.area[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, panbutton[])
                diff = startpos[] .- mp
                startpos[] = mp
                diff = Vec(diff) .* wscale(window_area, cam_area)
                update_cam!(scene, FRect(minimum(cam_area) .+ diff, widths(cam_area)))
            end
        end
        return
    end
end

function add_zoom!(scene, attributes)
    events = scene.events
    zoomspeed, zoombutton = getindex.(attributes, (:zoomspeed, :zoombutton))

    foreach(events.scroll) do x
        zoom = Float32(x[2])
        if zoom != 0 && (zoombutton[] == nothing || ispressed(scene, zoombutton[]))
            a = scene.area[]
            z = 1f0 + (zoom * zoomspeed[])
            mp = Vec2f0(events.mouseposition[])
            mp = (mp .* wscale(scene.px_area[], a)) + minimum(a)
            p1, p2 = minimum(a), maximum(a)
            p1, p2 = p1 - mp, p2 - mp # translate to mouse position
            p1, p2 = z * p1, z * p2
            p1, p2 = p1 + mp, p2 + mp
            update_cam!(scene, FRect(p1, p2 - p1))
            z
        end
        return
    end
end

function reset!(cam, boundingbox, preserveratio = true)
    w1 = widths(boundingbox)
    if preserveratio
        w2 = widths(cam[Screen][Area])
        ratio = w2 ./ w1
        w1 = if ratio[1] > ratio[2]
            s = w2[1] ./ w2[2]
            Vec2f0(s * w1[2], w1[2])
        else
            s = w2[2] ./ w2[1]
            Vec2f0(w1[1], s * w1[1])
        end
    end
    p = minimum(w1) .* 0.001 # 2mm padding
    update_cam!(cam, FRect(-p, -p, w1 .+ 2p))
    return
end


lerp{T}(a::T, b::T, val::AbstractFloat) = (a .+ (val * (b .- a)))

function add_restriction!(cam, window, rarea::SimpleRectangle, minwidths::Vec)
    area_ref = Base.RefValue(cam[Area])
    restrict_action = paused_action(1.0) do t
        o = lerp(origin(area_ref[]), origin(cam[Area]), t)
        wh = lerp(widths(area_ref[]), widths(cam[Area]), t)
        update_cam!(cam, FRect(o, wh))
    end
    on(window, Mouse.Drag) do drag
        if drag == Mouse.up && !isplaying(restrict_action)
            area = cam[Area]
            o = origin(area)
            maxi = maximum(area)
            newo = max.(o, origin(rarea))
            newmax = min.(maxi, maximum(rarea))
            maxi = maxi - newmax
            newo = newo - maxi
            newwh = newmax - newo
            scale = 1f0
            for (w1, w2) in zip(minwidths, newwh)
                stmp = w1 > w2 ? w1 / w2 : 1f0
                scale = max(scale, stmp)
            end
            newwh = newwh * scale
            area_ref[] = FRect(newo, newwh)
            if area_ref[] != cam[Area]
                play!(restrict_action)
            end
        end
        return
    end
    restrict_action
end


function cam2d!(scene; kw_args...)
    cam_attributes, rest = merged_get!(:cam2d, scene, Attributes(kw_args)) do
        Theme(
            zoomspeed = 0.10f0,
            zoombutton = nothing,
            panbutton = Mouse.middle,
            padding = 0.001
        )
    end
    add_zoom!(scene, cam_attributes)
    add_pan!(scene, cam_attributes)
    foreach(scene.px_area) do area
        screenw = widths(area)
        camw = widths(scene.area[])
        ratio = camw ./ screenw
        if !(ratio[1] ≈ ratio[2])
            screen_r = screenw ./ screenw[1]
            camw_r = camw ./ camw[1]
            r = (screen_r ./ camw_r)
            r = r ./ minimum(r)
            update_cam!(scene, FRect(minimum(scene.area[]), r .* camw))
        end
        return
    end
    cam_attributes
end
