module FakeInteraction

using Makie
using GLMakie
using Makie.Animations

export interaction_record
export MouseTo
export LeftClick
export LeftDown
export LeftUp
export Lazy
export Wait
export relative_pos

@recipe(Cursor) do scene
    Theme(
        color = :black,
        strokecolor = :white,
        strokewidth = 1,
        width = 10,
        notch = 2,
        shaftwidth = 2.5,
        shaftlength = 4,
        headlength = 12,
        multiplier = 1,
    )
end

function Makie.plot!(p::Cursor)
    poly = lift(p.width, p.notch, p.shaftwidth, p.shaftlength, p.headlength) do w, draw, wshaft, lshaft, lhead
        ps = Point2f[
            (0, 0),
            (-w/2, -lhead),
            (-wshaft/2, -lhead+draw),
            (-wshaft/2, -lhead-lshaft),
            (wshaft/2, -lhead-lshaft),
            (wshaft/2, -lhead+draw),
            (w/2, -lhead),
        ]

        angle = asin((-w/2) / (-lhead))

        Makie.Polygon(map(ps) do point
            Makie.Mat2f(cos(angle), sin(angle), -sin(angle), cos(angle)) * point
        end)
    end

    scatter!(p, p[1], marker = poly, markersize = p.multiplier, color = p.color, strokecolor = p.strokecolor, strokewidth = p.strokewidth,
        glowcolor = (:black, 0.10), glowwidth = 2, transform_marker = true)
    
    return p
end

struct Lazy
    f::Function
end

struct MouseTo{T}
    target::T
    duration::Union{Nothing,Float64}
end

MouseTo(target) = MouseTo(target, nothing)

function mousepositions_frame(m::MouseTo, startpos, t)

    dur = duration(m, startpos)

    keyframe_from = Animations.Keyframe(0.0, Point2f(startpos))
    keyframe_to = Animations.Keyframe(dur, Point2f(m.target))

    pos = Animations.interpolate(saccadic(2), t, keyframe_from, keyframe_to)
    [pos]
end
function mousepositions_end(m::MouseTo, startpos)
    [m.target]
end


duration(mouseto::MouseTo, prev_position) = mouseto.duration === nothing ? automatic_duration(mouseto, prev_position) : mouseto.duration
function automatic_duration(mouseto::MouseTo, prev_position)
    dist = sqrt(+(((mouseto.target .- prev_position) .^ 2)...))
    0.6 + dist / 1000 * 0.5
end

struct Wait
    duration::Float64
end

duration(w::Wait, prev_position) = w.duration

struct LeftClick end

duration(::LeftClick, _) = 0.15
mouseevents_start(l::LeftClick) = [Makie.MouseButtonEvent(Mouse.left, Mouse.press)]
mouseevents_end(l::LeftClick) = [Makie.MouseButtonEvent(Mouse.left, Mouse.release)]

struct LeftDown end

duration(::LeftDown, _) = 0.0
mouseevents_start(l::LeftDown) = [Makie.MouseButtonEvent(Mouse.left, Mouse.press)]

struct LeftUp end

duration(::LeftUp, _) = 0.0
mouseevents_start(l::LeftUp) = [Makie.MouseButtonEvent(Mouse.left, Mouse.release)]

mouseevents_start(obj) = []
mouseevents_end(obj) = []
mouseevents_frame(obj, t) = []
mousepositions_start(obj, startpos) = []
mousepositions_end(obj, startpos) = []
mousepositions_frame(obj, startpos, t) = []


function interaction_record(func, figlike, filepath, events::AbstractVector; fps = 60, update = true, kwargs...)
    content_scene = Makie.get_scene(figlike)
    sz = content_scene.viewport[].widths
    composite_scene = Scene(; camera = campixel!, size = sz)
    scr = display(GLMakie.Screen(), composite_scene)
    img = Observable(zeros(RGBAf, sz...))
    image!(composite_scene, 0..sz[1], 0..sz[2], img)
    cursor_position = Observable(sz ./ 2)
    content_scene.events.mouseposition[] = tuple(cursor_position[]...)
    curs = cursor!(composite_scene, cursor_position)
    if update
        Makie.update_state_before_display!(figlike)
    end

    if isempty(events)
        error("Event list is empty")
    end

    record(composite_scene, filepath; framerate = fps, kwargs...) do io
        t = 0.0
        t_event = 0.0
        current_duration = 0.0

        i_event = 1
        i_frame = 1
        event_startposition = Point2f(content_scene.events.mouseposition[])

        while i_event <= length(events)
            event = events[i_event]
            if event isa Lazy
                event = event.f(figlike)
            end

            t_event += current_duration # from previous
            event_startposition = Point2f(content_scene.events.mouseposition[])
            current_duration = duration(event, event_startposition)

            mouseevents = mouseevents_start(event)
            for mouseevent in mouseevents
                content_scene.events.mousebutton[] = mouseevent
            end
            mousepositions = mousepositions_start(event, event_startposition)
            for mouseposition in mousepositions
                content_scene.events.mouseposition[] = tuple(mouseposition...)
                cursor_position[] = mouseposition
            end

            while t < t_event + current_duration
                mouseevents = mouseevents_frame(event, t - t_event)
                for mouseevent in mouseevents
                    content_scene.events.mousebutton[] = mouseevent
                end
                mousepositions = mousepositions_frame(event, event_startposition, t - t_event)
                for mouseposition in mousepositions
                    content_scene.events.mouseposition[] = tuple(mouseposition...)
                    cursor_position[] = mouseposition
                end

                func(i_frame, t)
                img[] = rotr90(Makie.colorbuffer(figlike, update = false))
                if content_scene.events.mousebutton[].action === Makie.Mouse.press
                    curs.multiplier = 0.8
                else
                    curs.multiplier = 1.0
                end

                recordframe!(io)

                i_frame += 1
                t = i_frame / fps
            end

            mouseevents = mouseevents_end(event)
            for mouseevent in mouseevents
                content_scene.events.mousebutton[] = mouseevent
            end
            mousepositions = mousepositions_end(event, event_startposition)
            for mouseposition in mousepositions
                content_scene.events.mouseposition[] = tuple(mouseposition...)
                cursor_position[] = mouseposition
            end

            i_event += 1
        end
        return
    end
    close(scr)
    return
end

interaction_record(figlike, filepath, events::AbstractVector; kwargs...) = interaction_record((args...,) -> nothing, figlike, filepath, events; kwargs...)

relative_pos(block, rel) = Point2f(block.layoutobservables.computedbbox[].origin .+ rel .* block.layoutobservables.computedbbox[].widths)

end