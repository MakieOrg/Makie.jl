module Ann

    module Paths

        struct Line end
        struct Corner end
        struct Arc
            height::Float64 # positive numbers are arcs going up then down, negative down then up, 1 is half circle
        end

    end

    module Arrows

        using ...Makie

        auto(x::Makie.Automatic, default) = default
        auto(x, default) = x
        Base.@kwdef struct Line3
            length = Makie.automatic
            angle::Float64 = deg2rad(60)
            color = Makie.automatic
            linewidth::Union{Makie.Automatic,Float64} = Makie.automatic
        end

        Base.@kwdef struct Head
            length = Makie.automatic
            angle::Float64 = deg2rad(60)
            color = Makie.automatic
            notch::Float64 = 0 # 0 to 1
        end

        shrinksize(::Nothing; arrowsize) = 0
        shrinksize(l::Line3; arrowsize) = 0
        function shrinksize(l::Head; arrowsize)
            s = auto(l.length, arrowsize)
            s * (1 - l.notch)
        end

        function plotspecs(l::Line3, pos; rotation, arrowsize, color, linewidth)
            color = auto(l.color, color)
            linewidth = auto(l.linewidth, linewidth)
            len = auto(l.length, arrowsize)
            sidelen = len / cos(l.angle/2)
            dir1 = Point2(-cos(l.angle/2 + rotation), -sin(l.angle/2 + rotation))
            dir2 = Point2(-cos(-l.angle/2 + rotation), -sin(-l.angle/2 + rotation))
            p1 = pos + dir1 * sidelen
            p2 = pos + dir2 * sidelen
            [
                Makie.PlotSpec(:Lines, [p1, pos, p2]; space = :pixel, color, linewidth)
            ]
        end

        function plotspecs(h::Head, pos; rotation, arrowsize, color, linewidth)
            color = auto(h.color, color)
            len = auto(h.length, arrowsize)
            L = 1 / cos(h.angle/2)
            p1 = L * Point2(-cos(h.angle/2), -sin(h.angle/2))
            p2 = Point2(-(1 - h.notch), 0)
            p3 = L * Point2(-cos(-h.angle/2), -sin(-h.angle/2))

            marker = BezierPath([MoveTo(0, 0), LineTo(p1), LineTo(p2), LineTo(p3), ClosePath()])
            [
                Makie.PlotSpec(:Scatter, pos; space = :pixel, rotation, color, marker, markersize = len)
            ]
        end

    end

    module Styles

        using ..Arrows: Arrows

        struct Line end

        Base.@kwdef struct LineArrow4
            head = Arrows.Line3()
            tail = nothing
        end

    end
end

using .Ann

@recipe(Annotate) do scene
    Theme(
        textcolor = :black,
        color = :black,
        text = "",
        connection = Ann.Paths.Line(),
        shrink = (5.0, 7.0),
        clipstart = automatic,
        align = (:center, :center),
        style = automatic,
        maxiter = 100,
        linewidth = 1.0,
        arrowsize = 12,
    )
end

function closest_point_on_rectangle(r::Rect2, p)
    x1, y1 = r.origin
    x2, y2 = x1 + r.widths[1], y1 + r.widths[2]
    px, py = p

    clamped_x = clamp(px, x1, x2)
    clamped_y = clamp(py, y1, y2)

    if px in (x1, x2) || py in (y1, y2)
        return Point2(clamped_x, clamped_y)
    end

    candidates = [
        Point2(clamped_x, y1),
        Point2(clamped_x, y2),
        Point2(x1, clamped_y),
        Point2(x2, clamped_y)
    ]
    
    return argmin(c -> norm(c - p), candidates)
end

function Makie.convert_arguments(::Type{<:Annotate}, x::Real, y::Real)
    return ([Vec4d(x, y, NaN, NaN)],)
end

function Makie.convert_arguments(::Type{<:Annotate}, x::Real, y::Real, x2::Real, y2::Real)
    return ([Vec4d(x, y, x2, y2)],)
end

function Makie.convert_arguments(::Type{<:Annotate}, v::AbstractVector{<:VecTypes{2}})
    return (Vec4d.(getindex.(v, 1), getindex.(v, 2), NaN, NaN),)
end

function Makie.plot!(p::Annotate{<:Tuple{<:AbstractVector{<:Vec4}}})
    scene = Makie.get_scene(p)

    textpositions = lift(p[1]) do vecs
        Point2d.(getindex.(vecs, 1), getindex.(vecs, 2))
    end

    txt = text!(p, textpositions; text = p.text, align = p.align, offset = zeros(Vec2d, length(textpositions[])), color = p.textcolor)

    # points = lift(p, scene.camera.projectionview, p.model, Makie.transform_func(p),
    #       scene.viewport, p[1], p[2]) do _, _, _, _, p1, p2

    #     return Makie.project.(Ref(scene), (Point2d(p1), Point2d(p2)))
    # end

    screenpoints_target = Ref{Vector{Point2f}}()
    screenpoints_label = Ref{Vector{Point2f}}()

    glyphcolls = txt.plots[1][1]
    text_bbs = lift(p, glyphcolls, scene.camera.projectionview) do glyphcolls, _
        points = Makie.project.(Ref(scene), textpositions[])
        screenpoints_target[] = points
        screenpoints_label[] = Makie.project.(Ref(scene), Point2d.(getindex.(p[1][], 3), getindex.(p[1][], 4)))
        [Rect2f(unchecked_boundingbox(gc, Point3f(point..., 0), Makie.to_rotation(0))) for (gc, point) in zip(glyphcolls, points)]
    end

    on(text_bbs; update = true) do text_bbs
        calculate_best_offsets!(txt.offset[], screenpoints_target[], screenpoints_label[], text_bbs, Rect2d((0, 0), scene.viewport[].widths); maxiter = p.maxiter[])
        notify(txt.offset)
    end

    plotspecs = lift(
            p,
            text_bbs,
            p.connection,
            p.clipstart,
            p.shrink,
            p.style,
            p.color,
            p.linewidth,
            p.arrowsize,
        ) do text_bbs, conn, clipstart, shrink, style, color, linewidth, arrowsize
        specs = PlotSpec[]
        broadcast_foreach(text_bbs, screenpoints_target[], conn, clipstart, txt.offset[]) do text_bb, p2, conn, clipstart, offset
            offset_bb = text_bb + offset

            p2 in offset_bb && return
            p1 = startpoint(conn, offset_bb, p2)
            path = connection_path(conn, p1, p2)

            clipstart = if clipstart === automatic
                offset_bb
            else
                clipstart
            end
            clipped_path = clip_path_from_start(path, clipstart)

            shrunk_path = shrink_path(clipped_path, shrink)

            append!(specs, annotation_style_plotspecs(style, shrunk_path, p1, p2; color, linewidth, arrowsize))
        end
        return specs
    end

    plotlist!(p, plotspecs)
    return p
end

function distance_point_outside_rect(p::Point2, rect::Rect2)
    px, py = p
    ((rl, rb), (rr, rt)) = extrema(rect)

    dx = if px <= rl
        px - rl
    elseif px >= rr
        px - rr
    else
       zero(px)
    end

    dy = if py < rb
        py - rb
    elseif py > rt
        py - rt
    else
        zero(py)
    end

    return Vec2d(dx, dy)
end

function distance_point_inside_rect(p::Point2, rect::Rect2)
    px, py = p
    ((rl, rb), (rr, rt)) = extrema(rect)

    dx = if px <= rl || px >= rr
        zero(px)
    else
        argmin(abs, (px - rl, px - rr))
    end

    dy = if py <= rb || py >= rt
        zero(py)
    else
        argmin(abs, (py - rb, py - rt))
    end

    return Vec2d(dx, dy)
end

function calculate_best_offsets!(offsets::Vector{<:Vec2}, textpositions::Vector{<:Point2}, textpositions_offset::Vector{<:Point2}, text_bbs::Vector{<:Rect2}, bbox::Rect2;
        repel_strength=0.25,
        attract_strength=0.25,
        maxiter::Int
    )

    if all(!isnan, textpositions_offset)
        offsets .= textpositions_offset .- textpositions
        return
    end
    # TODO: make it so some positions can be fixed and others are not (NaNs)

    # Initialize velocities and forces for the offsets
    velocities = zeros(Vec2d, length(offsets))
    forces = zeros(Vec2d, length(offsets))
    damping = 0.9
    threshold = 1e-2

    padding = Vec2d(4, 2)
    # padding = Vec2d(0, 0)
    padded_bbs = map(text_bbs) do bb
        Rect2(bb.origin .- padding, bb.widths .+ 2padding)
    end
    offset_bbs = copy(padded_bbs)

    # offsets .= 30 .* randn.(Vec2d)

    for _ in 1:maxiter
        offset_bbs .= padded_bbs .+ offsets

        # Compute repulsive forces between bounding boxes
        for i in 1:length(offset_bbs)
            for j in i+1:length(offset_bbs)
                bb1 = offset_bbs[i]
                bb2 = offset_bbs[j]
                overlap = repel_strength * rect_overlap(bb1, bb2)
                # @show i, j, overlap
                offsets[i] -= overlap
                offsets[j] += overlap
            end
        end
        # @show offsets

        # Compute attractive forces towards their own text positions
        for i in 1:length(text_bbs)
            bb = offset_bbs[i]
            target_pos = textpositions[i]
            # println(i)
            # @show target_pos
            # @show bb
            diff = distance_point_outside_rect(target_pos, bb)
            # @show diff
            # println()
            offsets[i] += attract_strength * diff
        end

        # Compute repulsive forces from their own text positions
        for i in 1:length(text_bbs)
            for j in 1:length(textpositions)
                bb = offset_bbs[i]
                target_pos = textpositions[j]
                # println(i)
                # @show target_pos
                # @show bb
                diff = distance_point_inside_rect(target_pos, bb)
                # @show diff
                # println()
                offsets[i] += repel_strength * diff
            end
        end
       
        # Keep text boundingboxes inside the axis boundingbox
        let
            ((l, b), (r, t)) = extrema(bbox)
            for i in 1:length(text_bbs)
                ((pl, pb), (pr, pt)) = extrema(padded_bbs[i])
                ox, oy = offsets[i]
                if pl + ox < l
                    offsets[i] = Vec(l - pl, oy)
                elseif pr + ox > r
                    offsets[i] = Vec(r - pr, oy)
                end
                if pb + oy < b
                    offsets[i] = Vec(ox, b - pb)
                elseif pt + oy > t
                    offsets[i] = Vec(ox, t - pt)
                end
            end
        end
    end
    return
end

function interval_overlap(al, ar, bl, br)
    a_is_left = al < bl
    (ll, lr, rl, rr) = a_is_left ? (al, ar, bl, br) : (bl, br, al, ar)
    vl = if lr <= rl # l completely left of r
        zero(al)
    elseif lr < rr # l intersects r partially
        lr - rl
    else # r contained in l
        if rl - ll > lr - rr # r is further left
            rr - rl
        else
            -(rr - rl)
        end
    end
    a_is_left ? vl : -vl
end

function rect_overlap(r1, r2)
    (r1l, r1b), (r1r, r1t) = extrema(r1)
    (r2l, r2b), (r2r, r2t) = extrema(r2)
    
    x = interval_overlap(r1l, r1r, r2l, r2r)
    y = interval_overlap(r1b, r1t, r2b, r2t)

    if x == 0 || y == 0
        return Vec2d(0, 0)
    else
        return Vec2d(x, y)
    end
end

startpoint(::Ann.Paths.Line, text_bb, p2) = text_bb.origin + 0.5 * text_bb.widths

function startpoint(::Ann.Paths.Corner, text_bb, p2)
    l = left(text_bb)
    r = right(text_bb)
    b = bottom(text_bb)
    t = top(text_bb)
    dir = p2 - (text_bb.origin + 0.5 * text_bb.widths)
    if abs(dir[1]) < abs(dir[2])
        x = dir[1] > 0 ? r : l
        y = (t + b) / 2
    else
        x = (l + r) / 2
        y = dir[2] > 0 ? t : b
    end
    return Point2d(x, y)
end

Makie.data_limits(p::Annotate) = Rect3f(Rect2f(Vec2f.(p[1][])))
Makie.boundingbox(p::Annotate, space::Symbol = :data) = Makie.apply_transform_and_model(p, Makie.data_limits(p))

function connection_path(::Ann.Paths.Line, p1, p2)
    BezierPath([
        MoveTo(p1),
        LineTo(p2),
    ])
end

function connection_path(::Ann.Paths.Corner, p1, p2)
    dir = p2 - p1
    if abs(dir[1]) > abs(dir[2])
        BezierPath([
            MoveTo(p1),
            LineTo(p1[1], p2[2]),
            LineTo(p2),
        ])
    else
        BezierPath([
            MoveTo(p1),
            LineTo(p2[1], p1[2]),
            LineTo(p2),
        ])
    end
end

function startpoint(::Ann.Paths.Arc, text_bb, p2)
    center(text_bb)
end

function circle_centers(p1::Point2, p2::Point2, r)
    d = norm(p2 - p1)
    if d > 2r
        return nothing  # No circle possible
    end

    m = (p1 + p2) / 2
    h = sqrt(r^2 - (d/2)^2)

    # Perpendicular direction
    dir = p2 - p1
    perp = Point2(-dir[2], dir[1]) / d  # Normalized

    c1 = m + h * perp
    c2 = m - h * perp
    return c1, c2
end


function arc_center_radius(p1::Point2, p2::Point2, x::Real)
    xabs = abs(x)
    chord = p2 - p1
    mid = Point2((p1[1] + p2[1]) / 2, (p1[2] + p2[2]) / 2)
    len = norm(chord)
    height = xabs * len / 2
    if height == 0
        error("Height x must be non-zero for a valid arc.")
    end
    # Radius from chord length and height
    r = (len^2) / (8height) + height / 2
    # Unit perpendicular vector to chord
    perp = normalize(Point2(-chord[2], chord[1]))
    # Center lies along perpendicular from midpoint, distance (r - x)

    direction = sign(x) * chord[1] > 0 ? -1 : 1

    center = mid + direction * perp * (r - height)
    return r, center
end

function connection_path(ca::Ann.Paths.Arc, p1, p2)
    radius, center = arc_center_radius(p1, p2, ca.height)
    BezierPath([MoveTo(p1), EllipticalArc(center, radius, radius, 0.0, atan(reverse(p1 - center)...), atan(reverse(p2 - center)...))])
end

function shrink_path(path, shrink)
    start::MoveTo = path.commands[1]
    stop = endpoint(path.commands[end])

    if length(path.commands) < 2
        return path
    end

    if shrink[1] > 0
        for i in 2:length(path.commands)
            p_prev = endpoint(path.commands[i-1])
            intersects, moveto, newcommand = circle_intersection(start.p, shrink[1], p_prev, path.commands[i])
            if !intersects # should mean that the command is contained in the circle because we start at its center
                if i == length(path.commands)
                    # path is completely contained
                    return BezierPath(path.commands[1:1]) # empty BezierPath doesn't work currently because of bbox
                end
                continue
            else
                path = BezierPath([
                    moveto;
                    newcommand;
                    @view(path.commands[i+1:end])
                ])
                break
            end
        end
    end

    if shrink[2] > 0
        for i in length(path.commands):-1:2
            p_prev = endpoint(path.commands[i-1])
            p_end, reversed = reversed_command(p_prev, path.commands[i])
            intersects, moveto, newcommand = circle_intersection(stop, shrink[2], p_end, reversed)
            if !intersects
                if i == 2
                    # path is completely contained
                    return BezierPath(path.commands[1:1]) # empty BezierPath doesn't work currently because of bbox
                end
                continue
            else
                _, new_reversed = reversed_command(moveto.p, newcommand)
                path = BezierPath([
                    @view(path.commands[1:i-1]);
                    new_reversed
                ])
                break
            end
        end
    end

    return path
end

function reversed_command(p_prev, l::LineTo)
    return l.p, LineTo(p_prev)
end

function reversed_command(p_prev, e::EllipticalArc)
    # assumed that p_prev is at the start of e, otherwise there's a linesegment additionally but we can't deal with that here
    return endpoint(e), EllipticalArc(e.c, e.r1, e.r2, e.angle, e.a2, e.a1)
end

function circle_intersection(center::Point2, r, p1::Point2, command::LineTo)
    p2 = command.p
    # Unpack points
    x1, y1 = p1
    x2, y2 = p2
    cx, cy = center
    
    # Translate points so the circle center is at the origin
    x1 -= cx; y1 -= cy
    x2 -= cx; y2 -= cy
    
    # Line direction
    dx = x2 - x1
    dy = y2 - y1
    
    # Quadratic equation coefficients
    a = dx^2 + dy^2
    b = 2 * (x1 * dx + y1 * dy)
    c = x1^2 + y1^2 - r^2
    
    # Discriminant
    discriminant = b^2 - 4*a*c
    
    if discriminant < 0
        return false, nothing, nothing
    end
    
    # Two solutions for t
    sqrt_discriminant = sqrt(discriminant)
    t1 = (-b - sqrt_discriminant) / (2*a)
    t2 = (-b + sqrt_discriminant) / (2*a)
    
    # Check if the solutions are within the segment
    t = if 0 <= t2 <= 1
        t2
    elseif 0 <= t1 <= 1
        t1
    else
        return false, nothing, nothing
    end
    
    # Intersection point in translated coordinates
    ix = x1 + t * dx
    iy = y1 + t * dy
    
    # Translate back to original coordinates
    ix += cx
    iy += cy
    
    return true, MoveTo(Point2d(ix, iy)), command
end

function circle_intersection(center::Point2, r, p1::Point2, command::EllipticalArc)
    if command.r1 == command.r2
        # special case circular arc
        # Unpack points
        cx, cy = center
        px, py = p1
        r_a = command.r1
        angle1 = command.a1
        angle2 = command.a2

        # Translate the arc center to the origin
        arc_center = command.c
        arc_center_translated = arc_center - center

        # Compute the distance between the circle center and the arc center
        d = norm(arc_center_translated)

        # Check if the circle and arc intersect
        if d > r + r_a || d < abs(r - r_a)
            return false, nothing, nothing
        end

        # Compute the intersection points
        a = (r^2 - r_a^2 + d^2) / (2 * d)
        h = sqrt(r^2 - a^2)
        p = center + a * normalize(arc_center_translated)
        perp = Point2(-arc_center_translated[2], arc_center_translated[1]) / d
        intersection1 = p + h * perp
        intersection2 = p - h * perp

        # Check if the intersection points lie on the arc
        angle_intersection1 = atan(intersection1[2] - arc_center[2], intersection1[1] - arc_center[1])
        angle_intersection2 = atan(intersection2[2] - arc_center[2], intersection2[1] - arc_center[1])

        between_1 = is_between(angle_intersection1, angle1, angle2)
        between_2 = is_between(angle_intersection2, angle1, angle2)

        if between_1 && between_2
            # TODO: which one to pick?
            return true, MoveTo(intersection1), EllipticalArc(arc_center, r_a, r_a, 0.0, angle_intersection1, angle2)
        elseif between_1
            return true, MoveTo(intersection1), EllipticalArc(arc_center, r_a, r_a, 0.0, angle_intersection1, angle2)
        elseif between_2
            return true, MoveTo(intersection2), EllipticalArc(arc_center, r_a, r_a, 0.0, angle_intersection2, angle2)
        end
        #     return false, nothing, nothing
        # end
        return false, nothing, nothing
    else
        error("Not implemented for ellipses")
    end
end

function is_between(x, a, b)
    a, b = min(a, b), max(a, b)
    return a <= x <= b
end

function clip_path_from_start(path::BezierPath, bbox::Rect2)
    
    if length(path.commands) < 2
        return path
    end

    for i in 2:length(path.commands)
        p_prev = endpoint(path.commands[i-1])
        is_contained = bbox_containment(bbox, p_prev, path.commands[i])
        is_contained && continue
        intersects, moveto, newcommand = bbox_intersection(bbox, p_prev, path.commands[i])
        if intersects
            path = BezierPath([
                moveto;
                newcommand;
                @view(path.commands[i+1:end])
            ])
            break
        end
    end
    
    return path
end

function bbox_containment(bbox::Rect2, p_prev::Point2, comm::LineTo)
    return p_prev in bbox && comm.p in bbox
end

function bbox_containment(bbox::Rect2, p_prev::Point2, comm::EllipticalArc)
    return false # TODO: implement
end

function bbox_intersection(bbox::Rect2, p_prev::Point2, comm::LineTo)
    intersects, pt = line_rectangle_intersection(p_prev, comm.p, bbox)
    if intersects
        return intersects, MoveTo(pt), comm
    else
        return intersects, nothing, nothing
    end
end

function bbox_intersection(bbox::Rect2, p_prev::Point2, comm::EllipticalArc)
    if comm.r1 == comm.r2
        # circular arc
        r = comm.r1
        # Analytical circular arc intersection with bounding box
        cx, cy = comm.c
        r = comm.r1
        angle1, angle2 = comm.a1, comm.a2

        # Define the four edges of the bounding box
        edges = [
            (Point2d(bbox.origin[1], bbox.origin[2]), Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2])),           # Bottom edge
            (Point2d(bbox.origin[1], bbox.origin[2]), Point2d(bbox.origin[1], bbox.origin[2] + bbox.widths[2])),           # Left edge
            (Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2]), Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2] + bbox.widths[2])), # Right edge
            (Point2d(bbox.origin[1], bbox.origin[2] + bbox.widths[2]), Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2] + bbox.widths[2]))  # Top edge
        ]

        for (p1, p2) in edges
            # Find intersection of the circle with the line segment
            intersects, t1, t2 = circle_line_intersection(cx, cy, r, p1, p2)
            if intersects
                for t in (t1, t2)
                    if 0 <= t <= 1
                        intersection = p1 + t * (p2 - p1)
                        angle = atan(intersection[2] - cy, intersection[1] - cx)
                        if is_between(angle, angle1, angle2)
                            return true, MoveTo(intersection), EllipticalArc(comm.c, comm.r1, comm.r2, comm.angle, angle, comm.a2)
                        end
                    end
                end
            end
        end

        return false, nothing, nothing
    else
        error("Not implemented for ellipses")
    end
end

function circle_line_intersection(cx, cy, r, p1::Point2, p2::Point2)
    x1, y1 = p1
    x2, y2 = p2

    # Translate line to circle's center
    dx, dy = x2 - x1, y2 - y1
    fx, fy = x1 - cx, y1 - cy

    a = dx^2 + dy^2
    b = 2 * (fx * dx + fy * dy)
    c = fx^2 + fy^2 - r^2

    discriminant = b^2 - 4 * a * c
    if discriminant < 0
    return false, nothing, nothing
    end

    sqrt_discriminant = sqrt(discriminant)
    t1 = (-b - sqrt_discriminant) / (2 * a)
    t2 = (-b + sqrt_discriminant) / (2 * a)

    return true, t1, t2
end

function line_rectangle_intersection(p1::Point2, p2::Point2, rect::Rect2)
    # Unpack points and rectangle properties
    x1, y1 = p1
    x2, y2 = p2
    (rx, ry) = rect.origin
    (rw, rh) = rect.widths
    
    # List of rectangle edges (each edge is represented as a pair of points)
    edges = [
        (Point2d(rx, ry), Point2d(rx + rw, ry)),           # Bottom edge
        (Point2d(rx, ry), Point2d(rx, ry + rh)),           # Left edge
        (Point2d(rx + rw, ry), Point2d(rx + rw, ry + rh)), # Right edge
        (Point2d(rx, ry + rh), Point2d(rx + rw, ry + rh))  # Top edge
    ]
    
    # Helper function to find intersection of two line segments
    function segment_intersection(p1::Point2, p2::Point2, q1::Point2, q2::Point2)
        x1, y1 = p1
        x2, y2 = p2
        x3, y3 = q1
        x4, y4 = q2
        
        denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
        if denom == 0.0
            return (false, nothing)  # Parallel lines
        end
        
        ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
        ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom
        
        if 0.0 <= ua <= 1.0 && 0.0 <= ub <= 1.0
            ix = x1 + ua * (x2 - x1)
            iy = y1 + ua * (y2 - y1)
            return (true, Point2d(ix, iy))
        else
            return (false, nothing)  # Intersection not within the segments
        end
    end
    
    closest_intersection = nothing
    min_distance = Inf
    
    # Check intersection with each edge
    for (q1, q2) in edges
        intersects, point = segment_intersection(p1, p2, q1, q2)
        if intersects
            # Calculate distance to p2
            distance = hypot(point[1] - p2[1], point[2] - p2[2])
            if distance < min_distance
                min_distance = distance
                closest_intersection = point
            end
        end
    end
    
    if isnothing(closest_intersection)
        return (false, nothing)
    else
        return (true, closest_intersection)
    end
end

annotation_style_plotspecs(::Makie.Automatic, path, p1, p2; kwargs...) = annotation_style_plotspecs(Ann.Styles.Line(), path, p1, p2; kwargs...)

function annotation_style_plotspecs(l::Ann.Styles.LineArrow4, path::BezierPath, p1, p2; color, linewidth, arrowsize)
    length(path.commands) < 2 && return PlotSpec[]
    p_head = endpoint(path.commands[end])

    _startpoint(c::MoveTo) = c.p

    p_tail = _startpoint(path.commands[1])

    shrink_for_head = Ann.Arrows.shrinksize(l.head; arrowsize)
    shrink_for_tail = Ann.Arrows.shrinksize(l.tail; arrowsize)

    shortened_path = shrink_path(path, (shrink_for_tail, shrink_for_head))
    length(shortened_path.commands) < 2 && return PlotSpec[]

    head_dir = normalize(p2 - endpoint(shortened_path.commands[end]))
    head_rotation = atan(head_dir[2], head_dir[1])
    tail_dir = normalize(p1 - _startpoint(shortened_path.commands[1]))
    tail_rotation = atan(tail_dir[2], tail_dir[1])


    specs = [
        PlotSpec(:Lines, shortened_path; color, space = :pixel, linewidth);
        # PlotSpec(:Scatter, p; rotation, color, marker = BezierPath([MoveTo(0, 0), LineTo(-1, 0.5), LineTo(-1, -0.5), ClosePath()]), space = :pixel, markersize),
    ]
    if l.head !== nothing
        append!(specs, Ann.Arrows.plotspecs(l.head, p_head; rotation = head_rotation, arrowsize, color, linewidth))
    end
    if l.tail !== nothing
        append!(specs, Ann.Arrows.plotspecs(l.tail, p_tail; rotation = tail_rotation, arrowsize, color, linewidth))
    end
    return specs
end

function annotation_style_plotspecs(::Ann.Styles.Line, path::BezierPath, p1, p2; color, linewidth, arrowsize)
    [
        PlotSpec(:Lines, path; color, linewidth, space = :pixel),
    ]
end
