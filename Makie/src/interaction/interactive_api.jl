export mouseover, mouseposition, hovered_scene
export select_rectangle, select_line, select_point

# for debug/test tracking of pick
const PICK_TRACKING = Ref(false)
const _PICK_COUNTER = Ref(0)

"""
    mouseover(fig/ax/scene, plots::AbstractPlot...)

Returns true if the mouse currently hovers any of `plots`.
"""
mouseover(x, plots::AbstractPlot...) = mouseover(get_scene(x), plots...)
function mouseover(scene::Scene, plots::AbstractPlot...)
    p, idx = pick(scene)
    return p in collect_atomic_plots(plots)
end

"""
    onpick(f, fig/ax/scene, plots::AbstractPlot...)

Calls `f(plot, idx)` whenever the mouse is over any of `plots`.
`idx` is an index, e.g. when over a scatter plot, it will be the index of the
hovered element
"""
onpick(f, x, plots::AbstractPlot...; range = 1) = onpick(f, get_scene(x), plots..., range = range)
function onpick(f, scene::Scene, plots::AbstractPlot...; range = 1)
    fplots = collect_atomic_plots(plots)
    args = range == 1 ? (scene,) : (scene, range)
    return on(events(scene).mouseposition) do mp
        p, idx = pick(args...)
        (p in fplots) && f(p, idx)
        return Consume(false)
    end
end

"""
    mouse_in_scene(fig/ax/scene[, priority = 0])

Returns a new observable that is true whenever the cursor is inside the given scene.

See also: [`is_mouseinside`](@ref)
"""
function mouse_in_scene(scene::Scene; priority = 0)
    p = rootparent(scene)
    output = Observable(Vec2(0.0))
    on(events(scene).mouseposition, priority = priority) do mp
        output[] = Vec(mp) .- minimum(viewport(scene)[])
        return Consume(false)
    end
    return output
end


"""
    pick(fig/ax/scene, x, y[, range])
    pick(fig/ax/scene, xy::VecLike[, range])

Returns the plot and element index under the given pixel position `xy = Vec(x, y)`.
If `range` is given, the nearest plot up to a distance of `range` is returned instead.

The `plot` returned by this function is always a primitive plot, i.e. one that
is not composed of other plot types.

The index returned relates to the main input of the respective primitive plot.
- For `scatter` and `meshscatter` it is an index into the positions given to the plot.
- For `text` it is an index into the merged character array.
- For `lines` and `linesegments` it is the end position of the selected line segment.
- For `image`, `heatmap` and `surface` it is the linear index into the matrix argument of the plot (i.e. the given image, value or z-value matrix) that is closest to the selected position.
- For `voxels` it is the linear index into the given 3D Array.
- For `mesh` it is the largest vertex index of the picked triangle face.
- For `volume` it is always 0.

See also: `pick_sorted`
"""
pick(obj, x::Number, y::Number) = pick(get_scene(obj), x, y)
function pick(scene::Scene, x::Number, y::Number)
    return pick(scene, Vec{2, Float64}(x, y))
end


pick(obj) = pick(get_scene(obj), events(obj).mouseposition[])
pick(obj, xy::VecTypes{2}) = pick(get_scene(obj), xy)
function pick(scene::Scene, xy::VecTypes{2})
    PICK_TRACKING[] && (_PICK_COUNTER[] += 1)
    screen = getscreen(scene)
    screen === nothing && return (nothing, 0)
    return pick(scene, screen, Vec{2, Float64}(xy))
end

pick(obj, range::Real) = pick(get_scene(obj), events(obj).mouseposition[], range)
pick(obj, xy::VecTypes{2}, range::Real) = pick(get_scene(obj), xy, range)
pick(obj, x::Real, y::Real, range::Real) = pick(get_scene(obj), Vec2(x, y), range)
function pick(scene::Scene, xy::VecTypes{2}, range::Real)
    PICK_TRACKING[] && (_PICK_COUNTER[] += 1)
    screen = getscreen(scene)
    screen === nothing && return (nothing, 0)
    if PICK_TRACKING[]
        # if the Makie implementation is used we'd double count if we just increment here
        last = _PICK_COUNTER[]
        result = pick_closest(scene, screen, xy, range)
        _PICK_COUNTER[] = last
        return result
    else
        return pick_closest(scene, screen, xy, range)
    end
end

# The backend may handle this more optimally
function pick_closest(scene::SceneLike, screen, xy, range)
    PICK_TRACKING[] && (_PICK_COUNTER[] += 1)
    w, h = widths(screen)
    ((1.0 <= xy[1] <= w) && (1.0 <= xy[2] <= h)) || return (nothing, 0)
    x0, y0 = max.(1, floor.(Int, xy .- range))
    x1, y1 = min.([w, h], floor.(Int, xy .+ range))
    dx = x1 - x0; dy = y1 - y0

    picks = pick(scene, screen, Rect2i(x0, y0, dx, dy))

    min_dist = range^2
    selected = (0, 0)
    x, y = xy .+ 1 .- Vec2f(x0, y0)
    for i in 1:dx, j in 1:dy
        d = (x - i)^2 + (y - j)^2
        if (d < min_dist) && (picks[i, j][1] !== nothing)
            min_dist = d
            selected = (i, j)
        end
    end

    return selected == (0, 0) ? (nothing, 0) : picks[selected[1], selected[2]]
end

using InteractiveUtils

"""
    pick_sorted(fig/ax/scene, xy::VecLike, range)

Return all `(plot, index)` pairs in a `(xy .- range, xy .+ range)` region
sorted by distance to `xy`. See [`pick`](@ref) for more details.
"""
function pick_sorted(scene::Scene, xy, range)
    PICK_TRACKING[] && (_PICK_COUNTER[] += 1)
    screen = getscreen(scene)
    screen === nothing && return Tuple{AbstractPlot, Int}[]
    if PICK_TRACKING[]
        # if the Makie implementation is used we'd double count if we just increment here
        last = _PICK_COUNTER[]
        result = pick_sorted(scene, screen, xy, range)
        _PICK_COUNTER[] = last
        return result
    else
        return pick_sorted(scene, screen, xy, range)
    end
    return pick_sorted(scene, screen, xy, range)
end

function pick_sorted(scene::Scene, screen, xy, range)
    PICK_TRACKING[] && (_PICK_COUNTER[] += 1)
    w, h = size(scene)
    if !((1.0 <= xy[1] <= w) && (1.0 <= xy[2] <= h))
        return Tuple{AbstractPlot, Int}[]
    end
    x0, y0 = max.(1, floor.(Int, xy .- range))
    x1, y1 = min.([w, h], floor.(Int, xy .+ range))
    dx = x1 - x0; dy = y1 - y0

    picks = pick(scene, screen, Rect2i(x0, y0, dx, dy))

    selected = filter(x -> x[1] !== nothing, unique(vec(picks)))
    distances = [range^2 for _ in selected]
    x, y = xy .+ 1 .- Vec2f(x0, y0)
    for i in 1:dx, j in 1:dy
        if picks[i, j][1] !== nothing
            d = (x - i)^2 + (y - j)^2
            i = findfirst(isequal(picks[i, j]), selected)::Int
            if distances[i] > d
                distances[i] = d
            end
        end
    end

    idxs = sortperm(distances)
    permute!(selected, idxs)
    return selected
end

"""
    pick(scene::Scene, rect::Rect2i)

Return all `(plot, index)` pairs within the given rect. The rect must be within
screen boundaries.
"""
pick(x, rect::Rect2i) = pick(get_scene(x), rect)
function pick(scene::Scene, rect::Rect2i)
    PICK_TRACKING[] && (_PICK_COUNTER[] += 1)
    screen = getscreen(scene)
    screen === nothing && return Tuple{AbstractPlot, Int}[]
    return pick(scene, screen, rect)
end

"""
    screen_relative(scene, pos)

Normalizes mouse position `pos` relative to the screen rectangle.
"""
screen_relative(x, mpos) = screen_relative(get_scene(x), mpos)
function screen_relative(scene::Scene, mpos)
    return Point2f(mpos) .- Point2f(minimum(viewport(scene)[]))
end

"""
    mouseposition(scene = hovered_scene())

Return the current position of the mouse in _data coordinates_ of the
given `scene`.

By default uses the `scene` that the mouse is currently hovering over.
"""
mouseposition(x) = mouseposition(get_scene(x))

function mouseposition(scene::Scene = hovered_scene())
    return to_world(scene, mouseposition_px(scene))
end

mouseposition_px(x) = mouseposition_px(get_scene(x))
function mouseposition_px(scene::Scene = hovered_scene())
    return screen_relative(scene, events(scene).mouseposition[])
end

"""
    hovered_scene()

Returns the `scene` that the mouse is currently hovering over.

Properly identifies the scene for a plot with multiple sub-plots.
"""
hovered_scene() = error("hoevered_scene is not implemented yet.")


"""
    select_rectangle(scene; kwargs...) -> rect

Interactively select a rectangle on a 2D `scene` by clicking the left mouse button,
dragging and then un-clicking. The function returns an **observable** `rect` whose
value corresponds to the selected rectangle on the scene. In addition the function
_plots_ the selected rectangle on the scene as the user clicks and moves the mouse
around. When the button is not clicked any more, the plotted rectangle disappears.

The value of the returned observable is updated **only** when the user un-clicks
(i.e. when the final value of the rectangle has been decided) and only if the
rectangle has area > 0.

The `kwargs...` are propagated into `lines!` which plots the selected rectangle.
"""
function select_rectangle(scene; blocking = false, priority = 2, strokewidth = 3.0, kwargs...)
    key = Mouse.left
    waspressed = Observable(false)
    rect = Observable(Rectf(0, 0, 1, 1)) # plotted rectangle
    rect_ret = Observable(Rectf(0, 0, 1, 1)) # returned rectangle

    # Create an initially hidden rectangle
    plotted_rect = poly!(
        scene, rect, visible = false, color = RGBAf(0, 0, 0, 0), strokecolor = RGBAf(0.1, 0.1, 0.8, 0.5), strokewidth = strokewidth, kwargs...,
    )

    on(events(scene).mousebutton, priority = priority) do event
        if event.button == key
            if event.action == Mouse.press && is_mouseinside(scene)
                mp = mouseposition(scene)
                waspressed[] = true
                plotted_rect[:visible] = true # start displaying
                rect[] = Rectf(mp, 0.0, 0.0)
                return Consume(blocking)
            end
        end
        if !(event.button == key && event.action == Mouse.press)
            if waspressed[] # User has selected the rectangle
                waspressed[] = false
                r = absrect(rect[])
                w, h = widths(r)
                if w > 0.0 && h > 0.0 # Ensure that the rectangle has non0 size.
                    rect_ret[] = r
                end
            end
            # always hide if not the right key is pressed
            plotted_rect[:visible] = false # make the plotted rectangle invisible
            return Consume(blocking)
        end

        return Consume(false)
    end
    on(events(scene).mouseposition, priority = priority) do event
        if waspressed[]
            mp = mouseposition(scene)
            mini = minimum(rect[])
            rect[] = Rectf(mini, mp - mini)
            return Consume(blocking)
        end
        return Consume(false)
    end

    return rect_ret
end

"""
    select_line(scene; kwargs...) -> line

Interactively select a line (typically an arrow) on a 2D `scene` by clicking the left mouse button,
dragging and then un-clicking. Return an **observable** whose value corresponds
to the selected line on the scene. In addition the function
_plots_ the line on the scene as the user clicks and moves the mouse
around. When the button is not clicked any more, the plotted line disappears.

The value of the returned line is updated **only** when the user un-clicks
and only if the selected line has non-zero length.

The `kwargs...` are propagated into `lines!` which plots the selected line.
"""
function select_line(scene; blocking = false, priority = 2, kwargs...)
    key = Mouse.left
    waspressed = Observable(false)
    line = Observable([Point2f(0, 0), Point2f(1, 1)])
    line_ret = Observable([Point2f(0, 0), Point2f(1, 1)])
    # Create an initially hidden  arrow
    plotted_line = lines!(
        scene, line; visible = false, color = RGBAf(0.1, 0.1, 0.8, 0.5),
        linewidth = 4, kwargs...,
    )

    on(events(scene).mousebutton, priority = priority) do event
        if event.button == key && is_mouseinside(scene)
            mp = mouseposition(scene)
            if event.action == Mouse.press
                waspressed[] = true
                plotted_line[:visible] = true  # start displaying
                line[][1] = mp
                line[][2] = mp
                line[] = line[]
                return Consume(blocking)
            end
        end
        if !(event.button == key && event.action == Mouse.press)
            if waspressed[] # User has selected the rectangle
                waspressed[] = false
                if line[][1] != line[][2]
                    line_ret[] = copy(line[])
                end
            end
            plotted_line[:visible] = false
            return Consume(blocking)
        end
        return Consume(false)
    end
    on(events(scene).mouseposition, priority = priority) do event
        if waspressed[]
            mp = mouseposition(scene)
            line[][2] = mp
            line[] = line[] # actually update observable
            return Consume(blocking)
        end
        return Consume(false)
    end

    return line_ret
end

"""
    select_point(scene; kwargs...) -> point

Interactively select a point on a 2D `scene` by clicking the left mouse button,
dragging and then un-clicking. Return an **observable** whose value corresponds
to the selected point on the scene. In addition the function
_plots_ the point on the scene as the user clicks and moves the mouse
around. When the button is not clicked any more, the plotted point disappears.

The value of the returned point is updated **only** when the user un-clicks.

The `kwargs...` are propagated into `scatter!` which plots the selected point.
"""
function select_point(scene; blocking = false, priority = 2, kwargs...)
    key = Mouse.left
    waspressed = Observable(false)
    point = Observable([Point2f(0, 0)])
    point_ret = Observable(Point2f(0, 0))
    # Create an initially hidden  arrow
    plotted_point = scatter!(
        scene, point; visible = false, marker = Circle, markersize = 20px,
        color = RGBAf(0.1, 0.1, 0.8, 0.5), kwargs...,
    )

    on(events(scene).mousebutton, priority = priority) do event
        if event.button == key && is_mouseinside(scene)
            mp = mouseposition(scene)
            if event.action == Mouse.press
                waspressed[] = true
                plotted_point[:visible] = true  # start displaying
                point[][1] = mp
                point[] = point[]
                return Consume(blocking)
            end
        end
        if !(event.button == key && event.action == Mouse.press)
            if waspressed[] # User has selected the rectangle
                waspressed[] = false
                point_ret[] = copy(point[][1])
            end
            plotted_point[:visible] = false
            return Consume(blocking)
        end
        return Consume(false)
    end
    on(events(scene).mouseposition, priority = priority) do event
        if waspressed[]
            mp = mouseposition(scene)
            point[][1] = mp
            point[] = point[] # actually update observable
            return Consume(blocking)
        end
        return Consume(false)
    end

    return point_ret
end
