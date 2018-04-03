# using GLAbstraction, Makie, GeometryTypes
using GLAbstraction: orthographicprojection, translationmatrix
using StaticArrays

struct Camera2D <: AbstractCamera
    area::Node{FRect2D}
    zoomspeed::Node{Float32}
    zoombutton::Node{ButtonTypes}
    panbutton::Node{ButtonTypes}
    padding::Node{Float32}
end

function cam2d!(scene::Scene; kw_args...)
    cam_attributes, rest = merged_get!(:cam2d, scene, Attributes(kw_args)) do
        Theme(
            area = Signal(FRect(0, 0, 1, 1), name = "area"),
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
    correct_ratio!(scene, camera)
    selection_rect!(scene, camera)
    scene.camera_controls[] = camera
    camera
end

wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

update_cam!(scene::Scene, area) = update_cam!(scene, scene.camera_controls[], area)
update_cam!(scene::Scene) = update_cam!(scene, scene.camera_controls[], scene.limits[])

function update_cam!(scene::Scene, camera::Camera2D, area3d::Rect)
    area = FRect2D(area3d)
    area = positive_widths(area)
    px_wh = normalize(widths(scene.px_area[]))
    wh = normalize(widths(area))
    ratio = px_wh ./ wh
    if ratio ≈ Vec(1.0, 1.0)
        camera.area[] = area
    else
        # we only want to make the area bigger, to at least show what was selected
        # so we make the minimum 1.0, and grow in the other dimension
        s = ratio ./ minimum(ratio)
        newwh = s .* widths(area)
        camera.area[] = FRect(minimum(area), newwh)
    end
    update_cam!(scene, camera)
end
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

function correct_ratio!(scene, camera)
    lastw = RefValue(widths(scene.px_area[]))
    map(scene.camera, scene.px_area) do area
        neww = widths(area)
        change = neww .- lastw[]
        if !(change ≈ Vec(0.0, 0.0))
            s = 1.0 .+ (change ./ lastw[])
            lastw[] = neww
            camrect = FRect(minimum(camera.area[]), widths(camera.area[]) .* s)
            camera.area[] = camrect
            update_cam!(scene, camera)
        end
        return
    end
end
function add_pan!(scene::Scene, camera::Camera2D)
    startpos = RefValue((0.0, 0.0))
    events = scene.events
    map(
        scene.camera,
        Node.((scene, camera, startpos))...,
        events.mouseposition, events.mousedrag
    ) do scene, camera, startpos, mp, dragging

        pan = camera.panbutton[]
        if ispressed(scene, pan)
            window_area = scene.px_area[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, pan)
                diff = startpos[] .- mp
                startpos[] = mp
                area = camera.area[]
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
    point = Vec(point) .* wscale(scene.px_area[], camera.area[])
    Vec(point) .+ Vec(minimum(camera.area[]))
end

function selection_rect!(
        scene, cam,
        key = Mouse.left,
        button = nothing
    )
    rect = RefValue(FRect(0, 0, 0, 0))
    lw = 2f0
    rect_vis = lines!(
        scene,
        rect[],
        linestyle = :dot,
        linewidth = 1f0,
        color = (:black, 0.4),
        visible = false,
        raw = true
        #drawover = true
    )
    waspressed = RefValue(false)
    dragged_rect = map(scene.camera, scene.events.mousedrag) do drag
        if ispressed(scene, key)# && ispressed(scene, button)

            screen_area = scene.px_area[]
            cam_area = cam.area[]
            mp = scene.events.mouseposition[]
            mp = camspace(scene, cam, mp)
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
                update_cam!(scene, cam, rect[])
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
