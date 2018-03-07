# using GLAbstraction, Makie, GeometryTypes
using GLAbstraction: orthographicprojection, translationmatrix
using StaticArrays

struct Camera2D
    area::Node{FRect2D}
    zoomspeed::Node{Float32}
    zoombutton::Node{ButtonTypes}
    panbutton::Node{ButtonTypes}
    padding::Node{Float32}
end


function cam2d!(scene::Scene; kw_args...)
    cam_attributes, rest = merged_get!(:cam2d, scene, Attributes(kw_args)) do
        Theme(
            area = FRect(0, 0, 1, 1),
            zoomspeed = 0.10f0,
            zoombutton = nothing,
            panbutton = Mouse.right,
            padding = 0.001
        )
    end
    camera = from_dict(Camera2D, cam_attributes)
    # remove previously connected camera
    disconnect!(scene.camera)
    add_zoom!(scene, camera)
    add_pan!(scene, camera)
    map(scene.camera, scene.px_area) do area
        screenw = widths(area)
        camw = widths(camera.area[])
        ratio = camw ./ screenw
        if !(ratio[1] ≈ ratio[2])
            screen_r = screenw ./ screenw[1]
            camw_r = camw ./ camw[1]
            r = (screen_r ./ camw_r)
            r = r ./ minimum(r)
            camera.area[] = FRect(minimum(camera.area[]), r .* camw)
            update_cam!(scene, camera)
        end
        return
    end
    cam_attributes
end
wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

function update_cam!(scene::Scene, camera::Camera2D)
    x, y = minimum(camera.area[])
    w, h = widths(camera.area[]) ./ 2f0
    # These nodes should be final, no one should do map(cam.projection),
    # so we don't push! and just update the value in place
    view = translationmatrix(Vec3f0(-x - w, -y - h, 0))
    projection = orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0)
    set_value!(scene.camera.view, view)
    set_value!(scene.camera.projection, projection)
    set_value!(scene.camera.projectionview, projection * view)
    return
end

function add_pan!(scene::Scene, camera::Camera2D)
    startpos = RefValue((0.0, 0.0))
    events = scene.events
    panbutton = camera.panbutton
    map(scene.camera, events.mouseposition, events.mousedrag) do mp, dragging
        @getfields camera (panbutton, area)
        if ispressed(scene, panbutton)
            window_area = scene.px_area[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, panbutton)
                diff = startpos[] .- mp
                startpos[] = mp
                diff = Vec(diff) .* wscale(window_area, area)
                camera.area[] = FRect(minimum(area) .+ diff, widths(area))
                update_cam!(scene, camera)
            end
        end
        return
    end
end

function add_zoom!(scene::Scene, camera::Camera2D)
    events = scene.events
    map(scene.camera, events.scroll) do x
        @getfields camera (zoomspeed, zoombutton, area)
        zoom = Float32(x[2])
        if zoom != 0 && ispressed(scene, zoombutton)
            z = 1f0 + (zoom * zoomspeed)
            mp = Vec2f0(events.mouseposition[])
            mp = (mp .* wscale(scene.px_area[], area)) + minimum(area)
            p1, p2 = minimum(area), maximum(area)
            p1, p2 = p1 - mp, p2 - mp # translate to mouse position
            p1, p2 = z * p1, z * p2
            p1, p2 = p1 + mp, p2 + mp
            camera.area[] = FRect(p1, p2 - p1)
            update_cam!(scene, camera)
        end
        return
    end
end

function camspace(scene::Scene, camera::Camera2D, point)
    point = point .* wscale(scene.px_area[], camera.area[])
    point .+ minimum(camera.area[])
end

function selection_rect(
        scene, cam,
        key = Mouse.left,
        button = Set([Keyboard.left_control, Keyboard.space])
    )
    rect = RefValue(FRect(0, 0, 0, 0))
    lw = 2f0
    rect_vis = lines(
        scene,
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
            mp = camspace(scene, camera, mp)

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
