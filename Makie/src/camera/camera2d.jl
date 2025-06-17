struct Camera2D <: AbstractCamera
    area::Observable{Rect2d}
    zoomspeed::Observable{Float64}
    zoombutton::Observable{IsPressedInputType}
    panbutton::Observable{IsPressedInputType}
    padding::Observable{Float64}
    last_area::Observable{Vec{2, Int}}
    update_limits::Observable{Bool}
end

"""
    cam2d!(scene::SceneLike, kwargs...)

Creates a 2D camera for the given `scene`. The camera implements zooming by
scrolling and translation using mouse drag. It also implements rectangle
selections.

## Keyword Arguments

- `zoomspeed = 0.1` sets the zoom speed.
- `zoombutton = true` sets a button (combination) which needs to be pressed to enable zooming. By default no button needs to be pressed.
- `panbutton = Mouse.right` sets the button used to translate the camera. This must include a mouse button.
- `selectionbutton = (Keyboard.space, Mouse.left)` sets the button used for rectangle selection. This must include a mouse button.
"""
function cam2d!(scene::SceneLike; kw_args...)
    cam_attributes = merged_get!(:cam2d, scene, Attributes(kw_args)) do
        Attributes(
            area = Observable(Rectd(0, 0, 1, 1)),
            zoomspeed = 0.1,
            zoombutton = true,
            panbutton = Mouse.right,
            selectionbutton = (Keyboard.space, Mouse.left),
            padding = 0.001,
            last_area = Vec(size(scene)),
            update_limits = false,
        )
    end
    cam = from_dict(Camera2D, cam_attributes)
    # remove previously connected camera
    disconnect!(camera(scene))
    camera(scene).view_direction[] = Vec3f(0, 0, -1)
    add_zoom!(scene, cam)
    add_pan!(scene, cam)
    correct_ratio!(scene, cam)
    selection_rect!(scene, cam, cam_attributes.selectionbutton)
    cameracontrols!(scene, cam)
    return cam
end

get_space(::Camera2D) = :data
wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)


"""
    update_cam!(scene::SceneLike, area)

Updates the camera for the given `scene` to cover the given `area` in 2d.
"""
function update_cam!(scene::SceneLike, area::Rect)
    return update_cam!(scene, cameracontrols(scene), area)
end
function update_cam!(scene::SceneLike, area::Rect, center::Bool)
    return update_cam!(scene, cameracontrols(scene), area, center)
end


"""
    update_cam!(scene::SceneLike)

Updates the camera for the given `scene` to cover the limits of the `Scene`.
Useful when using the `Observable` pipeline.
"""
update_cam!(scene::SceneLike) = update_cam!(scene, cameracontrols(scene), data_limits(scene))

function update_cam!(scene::Scene, cam::Camera2D, area3d::Rect)
    area = Rect2d(area3d)
    area = positive_widths(area)
    # ignore rects with width almost 0
    any(x -> x ≈ 0.0, widths(area)) && return

    pa = viewport(scene)[]
    px_wh = normalize(widths(pa))
    wh = normalize(widths(area))
    ratio = px_wh ./ wh
    if ratio ≈ Vec(1.0, 1.0)
        cam.area[] = area
    else
        # we only want to make the area bigger, to at least show what was selected
        # so we make the minimum 1.0, and grow in the other dimension
        s = ratio ./ minimum(ratio)
        newwh = s .* widths(area)
        cam.area[] = Rect2d(minimum(area), newwh)
    end
    return update_cam!(scene, cam)
end

function update_cam!(scene::SceneLike, cam::Camera2D)
    x, y = Float64.(minimum(cam.area[]))
    w, h = Float64.(0.5 .* widths(cam.area[]))
    # These observables should be final, no one should do map(cam.projection),
    # so we don't push! and just update the value in place
    view = translationmatrix(Vec3d(-x - w, -y - h, 0))
    projection = orthographicprojection(-w, w, -h, h, -10_000.0, 10_000.0)
    set_proj_view!(camera(scene), projection, view)
    cam.last_area[] = Vec(size(scene))
    return
end

function correct_ratio!(scene, cam)
    return on(camera(scene), viewport(scene)) do area
        neww = widths(area)
        change = neww .- cam.last_area[]
        if !(change ≈ Vec(0.0, 0.0))
            s = 1.0 .+ (change ./ cam.last_area[])
            camrect = Rect2d(minimum(cam.area[]), widths(cam.area[]) .* s)
            cam.area[] = camrect
            update_cam!(scene, cam)
        end
        return
    end
end

function add_pan!(scene::SceneLike, cam::Camera2D)
    startpos = RefValue((0.0, 0.0))
    drag_active = RefValue(false)
    e = events(scene)

    on(
        camera(scene),
        Observable.((scene, cam, startpos, drag_active))...,
        e.mousebutton
    ) do scene, cam, startpos, active, event
        mp = e.mouseposition[]
        if ispressed(scene, cam.panbutton[])
            if event.action == Mouse.press && is_mouseinside(scene) && !active[]
                startpos[] = mp
                active[] = true
                return Consume(true)
            end
        elseif event.action == Mouse.release && active[]
            diff = startpos[] .- mp
            startpos[] = mp
            area = cam.area[]
            diff = Vec(diff) .* wscale(viewport(scene)[], area)
            cam.area[] = Rect2d(minimum(area) .+ diff, widths(area))
            update_cam!(scene, cam)
            active[] = false
            return Consume(true)
        end
        return Consume(false)
    end

    return on(
        camera(scene),
        Observable.((scene, cam, startpos, drag_active))...,
        e.mouseposition
    ) do scene, cam, startpos, active, pos
        if active[] && ispressed(scene, cam.panbutton[])
            diff = startpos[] .- pos
            startpos[] = pos
            area = cam.area[]
            diff = Vec(diff) .* wscale(viewport(scene)[], area)
            cam.area[] = Rect2d(minimum(area) .+ diff, widths(area))
            update_cam!(scene, cam)
            return Consume(true)
        end
        return Consume(false)
    end
end

function add_zoom!(scene::SceneLike, cam::Camera2D)
    e = events(scene)
    return on(camera(scene), e.scroll) do x
        @extractvalue cam (zoomspeed, zoombutton, area)
        zoom = Float64(x[2])
        if zoom != 0 && ispressed(scene, zoombutton) && is_mouseinside(scene)
            pa = viewport(scene)[]
            z = (1.0 - zoomspeed)^zoom
            mp = Vec2d(e.mouseposition[]) - minimum(pa)
            mp = (mp .* wscale(pa, area)) + minimum(area)
            p1, p2 = minimum(area), maximum(area)
            p1, p2 = p1 - mp, p2 - mp # translate to mouse position
            p1, p2 = z * p1, z * p2
            p1, p2 = p1 + mp, p2 + mp
            cam.area[] = Rect2d(p1, p2 - p1)
            update_cam!(scene, cam)
            return Consume(true)
        end
        return Consume(false)
    end
end

function camspace(scene::SceneLike, cam::Camera2D, point)
    point = Vec(point) .* wscale(viewport(scene)[], cam.area[])
    return Vec(point) .+ Vec(minimum(cam.area[]))
end

function absrect(rect::Rect)
    xy, wh = minimum(rect), widths(rect)
    xy = map(xy, wh) do xy, wh
        wh < 0 ? xy + wh : xy
    end
    return Rect2(xy, abs.(wh))
end


function selection_rect!(scene, cam, key)
    rect = RefValue(Rectf(NaN, NaN, NaN, NaN))
    lw = 2.0
    scene_unscaled = Scene(
        scene, transformation = Transformation(),
        cam = copy(camera(scene)), clear = false
    )
    scene_unscaled.clear = false
    rect_vis = lines!(
        scene_unscaled,
        rect[],
        linestyle = :dot,
        linewidth = 2.0f0,
        color = (:black, 0.4),
        visible = false
    )
    waspressed = RefValue(false)
    on(camera(scene), events(scene).mousebutton, key) do event, key
        if ispressed(scene, key) && is_mouseinside(scene)
            mp = camspace(scene, cam, events(scene).mouseposition[])
            if event.action == Mouse.press && !waspressed[]
                waspressed[] = true
                rect_vis[:visible] = true # start displaying
                rect[] = Rectf(mp, 0, 0)
                rect_vis[1] = rect[]
                return Consume(true)
            end
        else
            if event.action == Mouse.release && waspressed[]
                waspressed[] = false
                r = absrect(rect[])
                w, h = widths(r)
                if w > 0.0 && h > 0.0
                    update_cam!(scene, cam, r)
                end
                rect[] = Rectf(NaN, NaN, NaN, NaN)
                rect_vis[1] = rect[]
                return Consume(true)
            end
            # always hide if not the right key is pressed
            rect_vis[:visible] = false # hide
            return
        end
        return Consume(false)
    end

    on(camera(scene), events(scene).mouseposition, key) do mp, key
        # this is only true after a mousebutton update
        if ispressed(scene, key) && is_mouseinside(scene)
            mp = camspace(scene, cam, mp)
            mini = minimum(rect[])
            rect[] = Rectf(mini, mp - mini)
            rect_vis[1] = rect[]
            return Consume(true)
        end
        return Consume(false)
    end

    # TODO: this needs explicit cleanup?
    # why?
    return rect_vis, rect
end

function reset!(cam, boundingbox, preserveratio = true)
    w1 = widths(boundingbox)
    if preserveratio
        w2 = widths(cam[Screen][Area])
        ratio = w2 ./ w1
        w1 = if ratio[1] > ratio[2]
            s = w2[1] ./ w2[2]
            Vec2(s * w1[2], w1[2])
        else
            s = w2[2] ./ w2[1]
            Vec2(w1[1], s * w1[1])
        end
    end
    p = minimum(w1) .* 0.001 # 2mm padding
    update_cam!(cam, Rect(-p, -p, w1 .+ 2p))
    return
end

function add_restriction!(cam, window, rarea::Rect2, minwidths::Vec)
    area_ref = Base.RefValue(cam[Area])
    restrict_action = paused_action(1.0) do t
        o = lerp(origin(area_ref[]), origin(cam[Area]), t)
        wh = lerp(widths(area_ref[]), widths(cam[Area]), t)
        update_cam!(cam, Rect2d(o, wh))
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
            scale = 1.0
            for (w1, w2) in zip(minwidths, newwh)
                stmp = w1 > w2 ? w1 / w2 : 1.0
                scale = max(scale, stmp)
            end
            newwh = newwh * scale
            area_ref[] = Rect2d(newo, newwh)
            if area_ref[] != cam[Area]
                play!(restrict_action)
            end
        end
        return
    end
    return restrict_action
end

struct PixelCamera <: AbstractCamera end
get_space(::PixelCamera) = :pixel


struct UpdatePixelCam
    camera::Camera
    near::Float64
    far::Float64
end

function (cam::UpdatePixelCam)(window_size)
    w, h = Float64.(widths(window_size))
    projection = orthographicprojection(0.0, w, 0.0, h, cam.near, cam.far)
    return set_proj_view!(cam.camera, projection, Mat4d(I))
end

"""
    campixel!(scene; nearclip=-1000.0, farclip=1000.0)

Creates a pixel camera for the given `scene`. This means that the positional
data of a plot will be interpreted in pixel units. This camera does not feature
controls.
"""
function campixel!(scene::Scene; nearclip = -10_000.0, farclip = 10_000.0)
    disconnect!(camera(scene))
    camera(scene).view_direction[] = Vec3f(0, 0, -1)
    update_once = Observable(false)
    closure = UpdatePixelCam(camera(scene), nearclip, farclip)
    on(closure, camera(scene), viewport(scene))
    cam = PixelCamera()
    # update once
    closure(viewport(scene)[])
    cameracontrols!(scene, cam)
    update_once[] = true
    return cam
end

struct RelativeCamera <: AbstractCamera end
get_space(::RelativeCamera) = :relative

"""
    cam_relative!(scene)

Creates a camera for the given `scene` which maps the scene area to a 0..1 by
0..1 range. This camera does not feature controls.
"""
function cam_relative!(scene::Scene; nearclip = -10_000.0, farclip = 10_000.0)
    disconnect!(camera(scene))
    camera(scene).view_direction[] = Vec3f(0, 0, -1)
    projection = orthographicprojection(0.0, 1.0, 0.0, 1.0, nearclip, farclip)
    set_proj_view!(camera(scene), projection, Mat4d(I))
    cam = RelativeCamera()
    cameracontrols!(scene, cam)
    return cam
end

# disconnect!(::Makie.PixelCamera) = nothing
