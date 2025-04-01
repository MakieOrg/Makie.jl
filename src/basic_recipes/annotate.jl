struct ConnectionLine end
struct ConnectionCorner end

@recipe(Annotate) do scene
    Theme(
        color = :black,
        text = "Label",
        connection = ConnectionLine(),
        shrink = (5.0, 10.0),
        clipstart = automatic,
        align = (:left, :bottom),
        arrow = automatic,
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

function Makie.plot!(p::Annotate)
    scene = Makie.get_scene(p)

    txt = text!(p, p[1], text = p.text, align = p.align)

    points = lift(p, scene.camera.projectionview, p.model, Makie.transform_func(p),
          scene.viewport, p[1], p[2]) do _, _, _, _, p1, p2

        return Makie.project.(Ref(scene), (Point2d(p1), Point2d(p2)))
    end

    glyphcolls = txt.plots[1][1]
    text_bb = lift(p, glyphcolls, scene.camera.projectionview) do glyphcolls, _
        point = Makie.project(scene, (Point2d(p[1][])))
        Rect2f(unchecked_boundingbox(only(glyphcolls), Point3f(point..., 0), Makie.to_rotation(0)))
    end

    base_path = lift(p, points, text_bb, p.connection) do (_, p2), text_bb, conn
        # p1 = closest_point_on_rectangle(text_bb, p2)
        p1 = startpoint(conn, text_bb, p2)
        path = connection_path(conn, p1, p2)
        start = path.commands[1]
        if !(start isa MoveTo)
            error("Connection path should start with MoveTo, started with $(start)")
        else
            if start.p != p1
                error("Connection path did not start with p1 = $p1 but with $(start.p)")
            end
        end
        stop = endpoint(path.commands[end])
        if !(stop ≈ p2)
            error("Connection path did not stop with p2 = $p2 but with $(stop)")
        end
        return path
    end

    clipped_path = lift(base_path, p.clipstart) do path, clipstart
        clipstart = if clipstart === automatic
            Rect2f(boundingbox(txt.plots[1], :pixel))
        else
            clipstart
        end
        clip_path_from_start(path, clipstart)
    end

    shrunk_path = lift(clipped_path, p.shrink) do base_path, shrink
        shrink_path(base_path, shrink)
    end

    plotspec = lift(shrunk_path, p.arrow, p.color) do path, arrowspec, color
        annotation_arrow_plotspecs(arrowspec, path; color)
    end

    plotlist!(p, plotspec)
    return p
end

startpoint(::ConnectionLine, text_bb, p2) = text_bb.origin + 0.5 * text_bb.widths

function startpoint(::ConnectionCorner, text_bb, p2)
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

Makie.data_limits(p::Annotate) = Rect3f(Rect2f([p[1][], p[2][]]))
Makie.boundingbox(p::Annotate, space::Symbol = :data) = Makie.apply_transform_and_model(p, Makie.data_limits(p))

function connection_path(::ConnectionLine, p1, p2)
    BezierPath([
        MoveTo(p1),
        LineTo(p2),
    ])
end

function connection_path(::ConnectionCorner, p1, p2)
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
    return false, nothing, nothing # TODO: implement
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
    return false, nothing, nothing # TODO: implement
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

function annotation_arrow_plotspecs(::Automatic, path::BezierPath; color)
    p = endpoint(path.commands[end])
    markersize = 10
    dir = path_direction(endpoint(path.commands[end-1]), path.commands[end], markersize)
    rotation = atan(dir[2], dir[1])
    shortened_path = shrink_path(path, (0, markersize))
    [
        PlotSpec(:Lines, shortened_path; color, space = :pixel),
        PlotSpec(:Scatter, p; rotation, color, marker = BezierPath([MoveTo(0, 0), LineTo(-1, 0.5), LineTo(-1, -0.5), ClosePath()]), space = :pixel, markersize),
    ]
end

function path_direction(p, l::LineTo, _)
    return normalize(l.p - p)
end

struct PolyArrow end

function annotation_arrow_plotspecs(::PolyArrow, path::BezierPath; color)
    @assert length(path.commands) == 2
    p1 = (path.commands[1]::MoveTo).p
    p2 = (path.commands[2]::LineTo).p
    
    dir = p2 - p1
    len = norm(dir)
    w = len / 1.68

    vl = normalize(dir)
    vw = Vec2(-vl[2], vl[1])

    points = [
        p1 + w/2 * vw,
        p2,
        p1 - w/2 * vw,
    ]

    [
        PlotSpec(:Poly, points; color, space = :pixel),
        PlotSpec(:Text, (p1 + p2) / 2; text = "arrow", align = (:center, :center), rotation = mod(atan(dir[2], dir[1]), pi), space = :pixel)
    ]
end