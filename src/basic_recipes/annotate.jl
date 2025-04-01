struct ConnectionLine end
struct ConnectionArc

end

@recipe(Annotate) do scene
    Theme(
        color = :black,
        text = "Some text",
        connection = ConnectionLine(),
        shrink = (5.0, 5.0),
        clipstart = automatic,
        align = (:left, :bottom),
        arrow = automatic,
    )
end


function Makie.plot!(p::Annotate)
    scene = Makie.get_scene(p)

    txt = text!(p, p[1], text = p.text, align = p.align)

    points = lift(p, scene.camera.projectionview, p.model, Makie.transform_func(p),
          scene.viewport, p[1], p[2]) do _, _, _, _, p1, p2

        return Makie.project.(Ref(scene), (Point2d(p1), Point2d(p2)))
    end

    base_path = lift(p, points, p.connection) do (p1, p2), conn
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

Makie.data_limits(p::Annotate) = Rect3f(Rect2f([p[1][], p[2][]]))
Makie.boundingbox(p::Annotate, space::Symbol = :data) = Makie.apply_transform_and_model(p, Makie.data_limits(p))

function connection_path(::ConnectionLine, p1, p2)
    BezierPath([
        MoveTo(p1),
        LineTo(p2),
    ])
end

function connection_path(::ConnectionArc, p1, p2)
    len = Makie.norm(p2 - p1)
    arc = EllipticalArc(
        p1...,
        p2...,
        len/1.3,
        len/1.3,
        0,
        false,
        false,
    )
    BezierPath([
        MoveTo(p1),
        arc,
    ])
end

function shrink_path(path, shrink)
    shrink == (0, 0) && return path
    start::MoveTo = path.commands[1]

    if length(path.commands) < 2
        return path
    end

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

    return path
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
    dir = path_direction(endpoint(path.commands[end-1]), path.commands[end])
    rotation = atan(dir[2], dir[1])
    [
        PlotSpec(:Lines, replace_nonfreetype_commands(path); color, space = :pixel),
        PlotSpec(:Scatter, p; rotation, color, marker = BezierPath([MoveTo(0, 0), LineTo(-1, 0.5), LineTo(-0.8, 0), LineTo(-1, -0.5), ClosePath()]), space = :pixel, markersize = 10),
    ]
end

function path_direction(p, l::LineTo)
    return normalize(l.p - p)
end

function path_direction(p, a::EllipticalArc)
    # Compute tangent vector at angle a1
    dx = -a.r1 * sin(a.a1) * cos(a.angle) - a.r2 * cos(a.a1) * sin(a.angle)
    dy = -a.r1 * sin(a.a1) * sin(a.angle) + a.r2 * cos(a.a1) * cos(a.angle)

    # Normalize the vector
    return normalize(Point2d(-dy, dx))
end