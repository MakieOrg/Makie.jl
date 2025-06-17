"""
    MoveTo(p::VecTypes)
    MoveTo(x::Real, y::Real)

A path command for use within a `BezierPath` which starts a new subpath at the given point.
"""
struct MoveTo
    p::Point2d
end

MoveTo(x, y) = MoveTo(Point2d(x, y))

"""
    LineTo(p::VecTypes)
    LineTo(x::Real, y::Real)

A path command for use within a `BezierPath` which continues the current subpath with a line
to the given point.
"""
struct LineTo
    p::Point2d
end

LineTo(x, y) = LineTo(Point2d(x, y))

"""
    CurveTo(c1::VecTypes, c2::VecTypes, p::VecTypes)
    CurveTo(cx1::Real, cy1::Real, cx2::Real, cy2::Real, px::Real, py::Real)

A path command for use within a `BezierPath` which continues the current subpath with a cubic
bezier curve to point `p`, with the first control point `c1` and the second control point `c2`.
"""
struct CurveTo
    c1::Point2d
    c2::Point2d
    p::Point2d
end

CurveTo(cx1, cy1, cx2, cy2, p1, p2) = CurveTo(
    Point2d(cx1, cy1), Point2d(cx2, cy2), Point2d(p1, p2)
)

"""
    quadratic_curve_to(x0::Real, y0::Real, cx1::Real, cy1::Real, p1::Real, p2::Real)

A path command for use within a `BezierPath` which continues the current subpath with a quadratic
bezier curve to point `p`, with the control point `c`. The curve is converted into a cubic bezier
curve internally.
"""
quadratic_curve_to(x0, y0, cx1, cy1, p1, p2) = CurveTo(
    x0 + 2 / 3 * (cx1 - x0), y0 + 2 / 3 * (cy1 - y0),
    p1 + 2 / 3 * (cx1 - p1), p2 + 2 / 3 * (cy1 - p2),
    p1, p2
)

"""
    EllipticalArc(c::VecTypes, r1::Real, r2::Real, angle::Real, a1::Real, a2::Real)
    EllipticalArc(cx::Real, cy::Real, r1::Real, r2::Real, angle::Real, a1::Real, a2::Real)

A path command for use within a `BezierPath` which continues the current subpath with an
elliptical arc. The ellipse is centered at `c` and has two radii, `r1` and `r2`, the orientation
of which depends on `angle`.

If `angle == 0`, `r1` goes in x direction and `r2` in y direction.
A positive `angle` in radians rotates the ellipse counterclockwise, and a negative `angle` clockwise.

The angles `a1` and `a2` are the start and stop positions of the arc on the ellipse. A value of
`0` is where the radius `r1` points to, `pi/2` is where the radius `r2` points to, and so on.
If `a2 > a1`, the arc turns counterclockwise. If `a1 > a2`, it turns clockwise.

If the last position of the subpath does not equal the start of the arc,
the resulting path will have an implicit line segment between the two.
"""
struct EllipticalArc
    c::Point2d
    r1::Float64
    r2::Float64
    angle::Float64
    a1::Float64
    a2::Float64
end

EllipticalArc(cx, cy, r1, r2, angle, a1, a2) = EllipticalArc(
    Point2d(cx, cy),
    r1, r2, angle, a1, a2
)

"""
    ClosePath()

A path command for use within a `BezierPath` which closes the current subpath. The resulting
path will have an implicit line segment between the last point and the first point if they
do not match.
"""
struct ClosePath end
const PathCommand = Union{MoveTo, LineTo, CurveTo, EllipticalArc, ClosePath}

# For hashing with crc32c
function Base.write(io::IO, command::PathCommand)
    return write(io, Ref(command))
end

function bbox(commands::Vector{PathCommand})
    if length(commands) == 1
        c = only(commands)
        if !(c isa MoveTo)
            error("Can currently only handle single-command paths with a MoveTo, not $c")
        end
        return Rect(c.p, zero(c.p))
    end
    prev = commands[1]
    bb = nothing
    for comm in @view(commands[2:end])
        if comm isa MoveTo || comm isa ClosePath
            continue
        else
            endp = endpoint(prev)
            _bb = cleanup_bbox(bbox(endp, comm))
            bb = bb === nothing ? _bb : union(bb, _bb)
        end
        prev = comm
    end
    return bb
end

function elliptical_arc_to_beziers(arc::EllipticalArc)
    delta_a = abs(arc.a2 - arc.a1)
    n_beziers = ceil(Int, delta_a / 0.5pi)
    angles = range(arc.a1, arc.a2; length = n_beziers + 1)

    startpoint = Point2d(cos(arc.a1), sin(arc.a1))
    curves = map(angles[1:(end - 1)], angles[2:end]) do start, stop
        theta = stop - start
        kappa = 4 / 3 * tan(theta / 4)
        c1 = Point2d(cos(start) - kappa * sin(start), sin(start) + kappa * cos(start))
        c2 = Point2d(cos(stop) + kappa * sin(stop), sin(stop) - kappa * cos(stop))
        b = Point2d(cos(stop), sin(stop))
        return CurveTo(c1, c2, b)
    end

    path = BezierPath([LineTo(startpoint), curves...])
    path = scale(path, Vec2d(arc.r1, arc.r2))
    path = rotate(path, arc.angle)
    return translate(path, arc.c)
end

bbox(p, x::Union{LineTo, CurveTo}) = bbox(segment(p, x))
function bbox(p, e::EllipticalArc)
    return bbox(elliptical_arc_to_beziers(e))
end

endpoint(m::MoveTo) = m.p
endpoint(l::LineTo) = l.p
endpoint(c::CurveTo) = c.p
function endpoint(e::EllipticalArc)
    return point_at_angle(e, e.a2)
end

function point_at_angle(e::EllipticalArc, theta)
    M = abs(e.r1) * cos(theta)
    N = abs(e.r2) * sin(theta)
    return Point2d(
        e.c[1] + cos(e.angle) * M - sin(e.angle) * N,
        e.c[2] + sin(e.angle) * M + cos(e.angle) * N
    )
end

function cleanup_bbox(bb::Rect2)
    if any(x -> x < 0, bb.widths)
        p = bb.origin .+ (bb.widths .< 0) .* bb.widths
        return Rect2d(p, abs.(bb.widths))
    end
    return bb
end

"""
    BezierPath(commands::Vector)

Construct a `BezierPath` with a vector of path commands.
The available path commands are
- `MoveTo`
- `LineTo`
- `CurveTo`
- `EllipticalArc`
- `ClosePath`

A `BezierPath` can be used in certain places in Makie as an alternative
to a polygon or a collection of lines, for example as an input to `poly` or `lines`,
or as a `marker` for `scatter`.

The benefit of using a `BezierPath` is that curves do not need to be converted into
a vector of vertices by the user. CairoMakie can use the path commands directly when
it writes vector graphics which is more efficient and uses less space than approximating
them visually using line segments.
"""
struct BezierPath
    commands::Vector{PathCommand}
    boundingbox::Rect2d
    hash::UInt32
    function BezierPath(commands::Vector)
        c = convert(Vector{PathCommand}, commands)
        return new(c, bbox(c), hash_crc32(c))
    end
end
bbox(x::BezierPath) = x.boundingbox
fast_stable_hash(x::BezierPath) = x.hash


# so that the same bezierpath with a different instance of a vector hashes the same
# and we don't create the same texture atlas entry twice
Base.:(==)(b1::BezierPath, b2::BezierPath) = b1.commands == b2.commands
Base.broadcastable(b::BezierPath) = Ref(b)

function Base.:+(pc::P, p::Point2) where {P <: PathCommand}
    fnames = fieldnames(P)
    return P(map(f -> getfield(pc, f) + p, fnames)...)
end

scale(bp::BezierPath, s::Real) = BezierPath([scale(x, Vec2d(s, s)) for x in bp.commands])
scale(bp::BezierPath, v::VecTypes{2}) = BezierPath([scale(x, v) for x in bp.commands])
translate(bp::BezierPath, v::VecTypes{2}) = BezierPath([translate(x, v) for x in bp.commands])

translate(m::MoveTo, v::VecTypes{2}) = MoveTo(m.p .+ v)
translate(l::LineTo, v::VecTypes{2}) = LineTo(l.p .+ v)
translate(c::CurveTo, v::VecTypes{2}) = CurveTo(c.c1 .+ v, c.c2 .+ v, c.p .+ v)
translate(e::EllipticalArc, v::VecTypes{2}) = EllipticalArc(e.c .+ v, e.r1, e.r2, e.angle, e.a1, e.a2)
translate(c::ClosePath, v::VecTypes{2}) = c

scale(m::MoveTo, v::VecTypes{2}) = MoveTo(m.p .* v)
scale(l::LineTo, v::VecTypes{2}) = LineTo(l.p .* v)
scale(c::CurveTo, v::VecTypes{2}) = CurveTo(c.c1 .* v, c.c2 .* v, c.p .* v)
scale(c::ClosePath, v::VecTypes{2}) = c
function scale(e::EllipticalArc, v::VecTypes{2})
    x, y = v
    if abs(x) != abs(y)
        throw(ArgumentError("Currently you can only scale EllipticalArc such that abs(x) == abs(y) if the angle != 0"))
    end
    ang, a1, a2 = if x > 0 && y > 0
        e.angle, e.a1, e.a2
    elseif x < 0 && y < 0
        e.angle + pi, e.a1, e.a2
    elseif x < 0 && y > 0
        pi - e.angle, -e.a1, -e.a2
    else
        pi - e.angle, pi - e.a1, pi - e.a2
    end
    return EllipticalArc(e.c .* v, e.r1 * abs(x), e.r2 * abs(y), ang, a1, a2)
end

rotmatrix2d(a) = Mat2(cos(a), sin(a), -sin(a), cos(a))
rotate(m::MoveTo, a) = MoveTo(rotmatrix2d(a) * m.p)
rotate(c::ClosePath, a) = c
rotate(l::LineTo, a) = LineTo(rotmatrix2d(a) * l.p)
function rotate(c::CurveTo, a)
    m = rotmatrix2d(a)
    return CurveTo(m * c.c1, m * c.c2, m * c.p)
end
function rotate(e::EllipticalArc, a)
    m = rotmatrix2d(a)
    newc = m * e.c
    newangle = e.angle + a
    return EllipticalArc(newc, e.r1, e.r2, newangle, e.a1, e.a2)
end
rotate(b::BezierPath, a) = BezierPath(PathCommand[rotate(c::PathCommand, a) for c in b.commands])

function fit_to_bbox(b::BezierPath, bb_target::Rect2; keep_aspect = true)
    bb_path = bbox(b)
    ws_path = widths(bb_path)
    ws_target = widths(bb_target)

    center_target = origin(bb_target) + 0.5 * widths(bb_target)
    center_path = origin(bb_path) + 0.5 * widths(bb_path)

    scale_factor = ws_target ./ ws_path
    scale_factor_aspect = if keep_aspect
        min.(scale_factor, minimum(scale_factor))
    else
        scale_factor
    end

    return translate(scale(translate(b, -center_path), scale_factor_aspect), center_target)
end

function fit_to_unit_square(b::BezierPath, keep_aspect = true)
    return fit_to_bbox(b, Rect2((0.0, 0.0), (1.0, 1.0)), keep_aspect = keep_aspect)
end

Base.:+(pc::EllipticalArc, p::Point2) = EllipticalArc(pc.c + p, pc.r1, pc.r2, pc.angle, pc.a1, pc.a2)
Base.:+(pc::ClosePath, p::Point2) = pc
Base.:+(bp::BezierPath, p::Point2) = BezierPath(bp.commands .+ Ref(p))

# markers that fit into a square with sidelength 1 centered on (0, 0)


function bezier_ngon(n, radius, angle)
    points = [
        radius * Point2d(cos(a + angle), sin(a + angle))
            for a in range(0, 2pi, length = n + 1)[1:(end - 1)]
    ]
    return BezierPath(
        [
            MoveTo(points[1]);
            LineTo.(@view points[2:end]);
            ClosePath()
        ]
    )
end

function bezier_star(n, inner_radius, outer_radius, angle)
    points = [
        (isodd(i) ? outer_radius : inner_radius) *
            Point2d(cos(a + angle), sin(a + angle))
            for (i, a) in enumerate(range(0, 2pi, length = 2n + 1)[1:(end - 1)])
    ]
    return BezierPath(
        [
            MoveTo(points[1]);
            LineTo.(points[2:end]);
            ClosePath()
        ]
    )
end

function BezierPath(poly::Polygon{N, T}) where {N, T}
    commands = Makie.PathCommand[]
    points = reinterpret(Point{N, T}, poly.exterior)
    ext_direction = sign(area(points)) #signed area gives us clockwise / anti-clockwise
    push!(commands, MoveTo(points[1]))
    for i in 2:length(points)
        push!(commands, LineTo(points[i]))
    end

    for inter in poly.interiors
        points = reinterpret(Point{N, T}, inter)
        # holes, in bezierpath, always need to have the opposite winding order
        if sign(area(points)) == ext_direction
            points = reverse(points)
        end
        push!(commands, MoveTo(points[1]))
        for i in 2:length(points)
            push!(commands, LineTo(points[i]))
        end
    end
    push!(commands, ClosePath())
    return BezierPath(commands)
end

"""
    BezierPath(svg::AbstractString; fit = false, bbox = nothing, flipy = false, flipx = false, keep_aspect = true)

Construct a `BezierPath` using a string of [SVG path commands](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#path_commands).
The commands will be parsed first into `MoveTo`, `LineTo`, `CurveTo`, `EllipticalArc` and `ClosePath` objects
which are then passed to the `BezierPath` constructor.

If `fit === true`, the path will be scaled to fit into a square of width 1 centered on the origin.
If, additionally, `bbox` is set to some `Rect`, the path will be fit into this rectangle instead.
If you want to use a path as a scatter marker, it is usually good to fit it so that it's centered
and of a comparable size relative to other scatter markers.

If `flipy === true` or `flipx === true`, the respective dimensions of the path will be flipped.
Makie uses a coordinate system where y=0 is at the bottom and y increases upwards while in SVG, y=0 is at the
top and y increases downwards, so for most SVG paths `flipy = true` will be needed.

If `keep_aspect === true`, the path will be fit into the bounding box such that its longer dimension fits and
the other one is scaled to retain the original aspect ratio. If you set `keep_aspect = false`, the new
boundingbox of the path will be the one it is fit to, but note that this can result in a squished appearance.

## Example

Construct a triangular `BezierPath` out of a path command string and use it as a scatter marker:

```julia
str = "M 0,0 L 10,0 L 5,10 z"
bp = BezierPath(str, fit = true)
scatter(1:10, marker = bp, markersize = 20)
```
"""
@noconstprop function BezierPath(svg::AbstractString; fit = false, bbox = nothing, flipy = false, flipx = false, keep_aspect = true)
    BezierPath(svg, fit, bbox, flipy, flipx, keep_aspect)
end

@noconstprop function BezierPath(svg::AbstractString, fit::Bool, bbox, flipy::Bool, flipx::Bool, keep_aspect::Bool)
    commands = parse_bezier_commands(svg)
    p = BezierPath(commands)
    if flipy
        p = scale(p, Vec2{Float64}(1, -1))
    end
    if flipx
        p = scale(p, Vec2{Float64}(-1, 1))
    end
    if fit
        if bbox === nothing
            p = fit_to_bbox(p, Rect2d((-0.5, -0.5), (1.0, 1.0)), keep_aspect = keep_aspect)
        else
            p = fit_to_bbox(p, bbox, keep_aspect = keep_aspect)
        end
    end
    p
end

function parse_bezier_commands(svg)
    # args = [e.match for e in eachmatch(r"([a-zA-Z])|(\-?\d*\.?\d+)", svg)]
    args = [e.match for e in eachmatch(r"(?:0(?=\d))|(?:[a-zA-Z])|(?:\-?\d*\.?\d+)", svg)]

    i = 1

    commands = PathCommand[]
    lastcomm = nothing
    function lastp()
        return if isnothing(lastcomm)
            Point2d(0, 0)
        else
            c = commands[end]
            if c isa ClosePath
                r = reverse(commands)
                backto = findlast(x -> !(x isa ClosePath), r)
                if isnothing(backto)
                    error("No point to go back to")
                end
                r[backto].p
            elseif c isa EllipticalArc
                let
                    ϕ = c.angle
                    a2 = c.a2
                    rx = c.r1
                    ry = c.r2
                    m = Mat2(cos(ϕ), sin(ϕ), -sin(ϕ), cos(ϕ))
                    return m * Point2d(rx * cos(a2), ry * sin(a2)) + c.c
                end
            else
                return c.p
            end
        end
    end

    while i <= length(args)

        comm = args[i]

        # command letter is omitted, use last command
        if isnothing(match(r"[a-zA-Z]", comm))
            comm = lastcomm
            i -= 1
        end

        if comm == "M"
            x, y = parse.(Float64, args[(i + 1):(i + 2)])
            push!(commands, MoveTo(Point2d(x, y)))
            i += 3
        elseif comm == "m"
            x, y = parse.(Float64, args[(i + 1):(i + 2)])
            push!(commands, MoveTo(Point2d(x, y) + lastp()))
            i += 3
        elseif comm == "L"
            x, y = parse.(Float64, args[(i + 1):(i + 2)])
            push!(commands, LineTo(Point2d(x, y)))
            i += 3
        elseif comm == "l"
            x, y = parse.(Float64, args[(i + 1):(i + 2)])
            push!(commands, LineTo(Point2d(x, y) + lastp()))
            i += 3
        elseif comm == "H"
            x = parse(Float64, args[i + 1])
            push!(commands, LineTo(Point2d(x, lastp()[2])))
            i += 2
        elseif comm == "h"
            x = parse(Float64, args[i + 1])
            push!(commands, LineTo(Point2d(x, 0) + lastp()))
            i += 2
        elseif comm == "Z"
            push!(commands, ClosePath())
            i += 1
        elseif comm == "z"
            push!(commands, ClosePath())
            i += 1
        elseif comm == "C"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[(i + 1):(i + 6)])
            push!(commands, CurveTo(Point2d(x1, y1), Point2d(x2, y2), Point2d(x3, y3)))
            i += 7
        elseif comm == "c"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[(i + 1):(i + 6)])
            l = lastp()
            push!(commands, CurveTo(Point2d(x1, y1) + l, Point2d(x2, y2) + l, Point2d(x3, y3) + l))
            i += 7
        elseif comm == "S"
            x1, y1, x2, y2 = parse.(Float64, args[(i + 1):(i + 4)])
            prev = commands[end]
            reflected = prev.p + (prev.p - prev.c2)
            push!(commands, CurveTo(reflected, Point2d(x1, y1), Point2d(x2, y2)))
            i += 5
        elseif comm == "s"
            x1, y1, x2, y2 = parse.(Float64, args[(i + 1):(i + 4)])
            prev = commands[end]
            reflected = prev.p + (prev.p - prev.c2)
            l = lastp()
            push!(commands, CurveTo(reflected, Point2d(x1, y1) + l, Point2d(x2, y2) + l))
            i += 5
        elseif comm == "A"
            args[(i + 1):(i + 7)]
            r1, r2 = parse.(Float64, args[(i + 1):(i + 2)])
            angle = parse(Float64, args[i + 3])
            large_arc_flag, sweep_flag = parse.(Bool, args[(i + 4):(i + 5)])
            x2, y2 = parse.(Float64, args[(i + 6):(i + 7)])
            x1, y1 = lastp()

            push!(
                commands, EllipticalArc(
                    x1, y1, x2, y2, r1, r2,
                    angle, large_arc_flag, sweep_flag
                )
            )
            i += 8
        elseif comm == "a"
            r1, r2 = parse.(Float64, args[(i + 1):(i + 2)])
            angle = parse(Float64, args[i + 3])
            large_arc_flag, sweep_flag = parse.(Bool, args[(i + 4):(i + 5)])
            x1, y1 = lastp()
            x2, y2 = parse.(Float64, args[(i + 6):(i + 7)]) .+ (x1, y1)

            push!(
                commands, EllipticalArc(
                    x1, y1, x2, y2, r1, r2,
                    angle, large_arc_flag, sweep_flag
                )
            )
            i += 8
        elseif comm == "v"
            dy = parse(Float64, args[i + 1])
            l = lastp()
            push!(commands, LineTo(Point2d(l[1], l[2] + dy)))
            i += 2
        elseif comm == "V"
            y = parse(Float64, args[i + 1])
            l = lastp()
            push!(commands, LineTo(Point2d(l[1], y)))
            i += 2
        elseif comm == "Q"
            x0, y0 = lastp()
            x1, y1, x2, y2 = parse.(Float64, args[(i + 1):(i + 4)])
            push!(commands, quadratic_curve_to(x0, y0, x1, y1, x2, y2))
            i += 5
        elseif comm == "q"
            x0, y0 = lastp()
            x1, y1, x2, y2 = parse.(Float64, args[(i + 1):(i + 4)])
            push!(commands, quadratic_curve_to(x0, y0, x1 + x0, y1 + y0, x2 + x0, y2 + y0))
            i += 5
        else
            for c in commands
                println(c)
            end
            error("Parsing $comm not implemented.")
        end

        lastcomm = comm

    end

    return commands
end

"""
    EllipticalArc(x1::Real, y1::Real, x2::Real, y2::Real, rx::Real, ry::Real, ϕ::Real, largearc::Bool, sweepflag::Bool)

Construct an `EllipticalArc` using the endpoint parameterization.

`x1, y1` is the starting point and `x2, y2` the end point, `rx` and `ry` are the two
ellipse radii. `ϕ` is the angle of `rx` vs the x axis.

Usually, four arcs can be constructed between two points given these ellipse parameters.
One of them is chosen using two boolean flags:

If `largearc === true`, the arc will be longer than 180 degrees.
If `sweepflag === true`, the arc will sweep through increasing angles.
"""
function EllipticalArc(x1, y1, x2, y2, rx, ry, ϕ, largearc::Bool, sweepflag::Bool)
    # https://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes

    p1 = Point2d(x1, y1)
    p2 = Point2d(x2, y2)

    m1 = Mat2(cos(ϕ), -sin(ϕ), sin(ϕ), cos(ϕ))
    x1′, y1′ = m1 * (0.5 * (p1 - p2))

    tempsqrt = (rx^2 * ry^2 - rx^2 * y1′^2 - ry^2 * x1′^2) /
        (rx^2 * y1′^2 + ry^2 * x1′^2)

    c′ = (largearc == sweepflag ? -1 : 1) *
        sqrt(tempsqrt) * Point2d(rx * y1′ / ry, -ry * x1′ / rx)

    c = Mat2(cos(ϕ), sin(ϕ), -sin(ϕ), cos(ϕ)) * c′ + 0.5 * (p1 + p2)

    vecangle(u, v) = sign(u[1] * v[2] - u[2] * v[1]) *
        acos(dot(u, v) / (norm(u) * norm(v)))

    px(sign) = Point2d((sign * x1′ - c′[1]) / rx, (sign * y1′ - c′[2]) / rx)

    θ1 = vecangle(Point2d(1.0, 0.0), px(1))
    Δθ_pre = mod(vecangle(px(1), px(-1)), 2pi)
    Δθ = if Δθ_pre > 0 && !sweepflag
        Δθ_pre - 2pi
    elseif Δθ_pre < 0 && sweepflag
        Δθ_pre + 2pi
    else
        Δθ_pre
    end

    return EllipticalArc(c, rx, ry, ϕ, θ1, θ1 + Δθ)
end

###################################################
# Freetype rendering of paths for GLMakie sprites #
###################################################

function make_outline(path)
    n_contours::FT_Int = 0
    n_points::FT_UInt = 0
    points = FT_Vector[]
    tags = Int8[]
    contours = Int16[]
    for command in path.commands
        new_contour, n_newpoints, newpoints, newtags = convert_command(command)
        if new_contour
            n_contours += 1
            if n_contours > 1
                push!(contours, n_points - 1) # -1 because of C zero-based indexing
            end
        end
        n_points += n_newpoints
        append!(points, newpoints)
        append!(tags, newtags)
    end
    push!(contours, n_points - 1)
    @assert n_points == length(points) == length(tags)
    @assert n_contours == length(contours)
    push!(contours, n_points)
    # Manually create outline, since FT_Outline_New seems to be problematic on windows somehow
    outline = FT_Outline(
        n_contours,
        n_points,
        pointer(points),
        pointer(tags),
        pointer(contours),
        0
    )
    # Return Ref + arrays that went into outline, so the GC doesn't abandon them
    return (Ref(outline), points, tags, contours)
end

ftvec(p) = FT_Vector(round(Int, p[1]), round(Int, p[2]))

function convert_command(m::MoveTo)
    return true, 1, ftvec.([m.p]), [FT_Curve_Tag_On]
end

function convert_command(l::LineTo)
    return false, 1, ftvec.([l.p]), [FT_Curve_Tag_On]
end

function convert_command(c::CurveTo)
    return false, 3, ftvec.([c.c1, c.c2, c.p]), [FT_Curve_Tag_Cubic, FT_Curve_Tag_Cubic, FT_Curve_Tag_On]
end

function render_path(path, bitmap_size_px = 256)
    # in the outline, 1 unit = 1/64px
    scale_factor = bitmap_size_px * 64

    # We transform the path into a rectangle of size (aspect, 1) or (1, aspect)
    # such that aspect ≤ 1. We then scale that rectangle up to a size of 4096 by
    # 4096 * aspect, which results in at most a 64px by 64px bitmap

    # freetype has no ClosePath and EllipticalArc, so those need to be replaced
    path_replaced = replace_nonfreetype_commands(path)

    # Minimal size that becomes integer when multiplying by 64 (target size for
    # atlas). This adds padding to avoid blurring/scaling factors from rounding
    # during sdf generation
    path_size = widths(bbox(path)) / maximum(widths(bbox(path)))
    w = ceil(Int, 64 * path_size[1])
    h = ceil(Int, 64 * path_size[2])
    path_size = Vec2d(w, h) / 64.0

    path_unit_rect = fit_to_bbox(path_replaced, Rect2d(Point2d(0), path_size))

    path_transformed = Makie.scale(path_unit_rect, scale_factor)

    outline_ref = make_outline(path_transformed)

    # Adjust bitmap size to match path size
    w = ceil(Int, bitmap_size_px * path_size[1])
    h = ceil(Int, bitmap_size_px * path_size[2])

    pitch = w * 1 # 8 bit gray
    pixelbuffer = zeros(UInt8, h * pitch)
    bitmap_ref = Ref{FT_Bitmap}()
    GC.@preserve pixelbuffer outline_ref begin
        bitmap_ref[] = FT_Bitmap(
            h,
            w,
            pitch,
            pointer(pixelbuffer),
            256,
            FT_PIXEL_MODE_GRAY,
            C_NULL,
            C_NULL
        )
        lib = FreeTypeAbstraction.FREE_FONT_LIBRARY[]
        @assert lib != C_NULL
        err = FT_Outline_Get_Bitmap(
            FreeTypeAbstraction.FREE_FONT_LIBRARY[],
            outline_ref[1],
            bitmap_ref,
        )
        @assert err == 0
        return reshape(pixelbuffer, (w, h))
    end
end

# FreeType can only handle lines and cubic / conic beziers so ClosePath
# and EllipticalArc need to be replaced
function replace_nonfreetype_commands(path)
    newpath = BezierPath(copy(path.commands))
    last_move_to = nothing
    i = 1
    while i <= length(newpath.commands)
        c = newpath.commands[i]
        if c isa MoveTo
            last_move_to = c
        elseif c isa EllipticalArc
            bp = elliptical_arc_to_beziers(c)
            splice!(newpath.commands, i, bp.commands)
        elseif c isa ClosePath
            if last_move_to === nothing
                error("Got ClosePath but no previous MoveTo")
            end
            newpath.commands[i] = LineTo(last_move_to.p)
        end
        i += 1
    end
    return newpath
end


Makie.convert_attribute(b::BezierPath, ::key"marker", ::key"scatter") = b
Makie.convert_attribute(ab::AbstractVector{<:BezierPath}, ::key"marker", ::key"scatter") = ab

struct BezierSegment
    from::Point2d
    c1::Point2d
    c2::Point2d
    to::Point2d
end

struct LineSegment
    from::Point2d
    to::Point2d
end


function bbox(ls::LineSegment)
    return Rect2d(ls.from, ls.to - ls.from)
end

function bbox(b::BezierSegment)
    p0 = b.from
    p1 = b.c1
    p2 = b.c2
    p3 = b.to

    mi = [min.(p0, p3)...]
    ma = [max.(p0, p3)...]

    c = -p0 + p1
    b = p0 - 2p1 + p2
    a = -p0 + 3p1 - 3p2 + 1p3

    h = [(b .* b - a .* c)...]

    if h[1] > 0
        h[1] = sqrt(h[1])
        t = (-b[1] - h[1]) / a[1]
        if t > 0 && t < 1
            s = 1.0 - t
            q = s * s * s * p0[1] + 3.0 * s * s * t * p1[1] + 3.0 * s * t * t * p2[1] + t * t * t * p3[1]
            mi[1] = min(mi[1], q)
            ma[1] = max(ma[1], q)
        end
        t = (-b[1] + h[1]) / a[1]
        if t > 0 && t < 1
            s = 1.0 - t
            q = s * s * s * p0[1] + 3.0 * s * s * t * p1[1] + 3.0 * s * t * t * p2[1] + t * t * t * p3[1]
            mi[1] = min(mi[1], q)
            ma[1] = max(ma[1], q)
        end
    end

    if h[2] > 0.0
        h[2] = sqrt(h[2])
        t = (-b[2] - h[2]) / a[2]
        if t > 0.0 && t < 1.0
            s = 1.0 - t
            q = s * s * s * p0[2] + 3.0 * s * s * t * p1[2] + 3.0 * s * t * t * p2[2] + t * t * t * p3[2]
            mi[2] = min(mi[2], q)
            ma[2] = max(ma[2], q)
        end
        t = (-b[2] + h[2]) / a[2]
        if t > 0.0 && t < 1.0
            s = 1.0 - t
            q = s * s * s * p0[2] + 3.0 * s * s * t * p1[2] + 3.0 * s * t * t * p2[2] + t * t * t * p3[2]
            mi[2] = min(mi[2], q)
            ma[2] = max(ma[2], q)
        end
    end

    return Rect2d(Point(mi...), Point(ma...) - Point(mi...))
end

segment(p, l::LineTo) = LineSegment(p, l.p)
segment(p, c::CurveTo) = BezierSegment(p, c.c1, c.c2, c.p)


const BezierCircle = let
    r = 0.47 # sqrt(1/pi)
    BezierPath(
        [
            MoveTo(Point(r, 0.0)),
            EllipticalArc(Point(0.0, 0), r, r, 0.0, 0.0, 2pi),
            ClosePath(),
        ]
    )
end

const BezierUTriangle = let
    aspect = 1
    h = 0.97 # sqrt(aspect) * sqrt(2)
    w = 0.97 # 1/sqrt(aspect) * sqrt(2)
    # r = Float32(sqrt(1 / (3 * sqrt(3) / 4)))
    p1 = Point(0, h / 2)
    p2 = Point2d(-w / 2, -h / 2)
    p3 = Point2d(w / 2, -h / 2)
    centroid = (p1 + p2 + p3) / 3
    bp = BezierPath(
        [
            MoveTo(p1 - centroid),
            LineTo(p2 - centroid),
            LineTo(p3 - centroid),
            ClosePath(),
        ]
    )
end

const BezierLTriangle = rotate(BezierUTriangle, pi / 2)
const BezierDTriangle = rotate(BezierUTriangle, pi)
const BezierRTriangle = rotate(BezierUTriangle, 3pi / 2)

const BezierSquare = let
    r = 0.95 * sqrt(pi) / 2 / 2 # this gives a little less area as the r=0.5 circle
    BezierPath(
        [
            MoveTo(Point2d(r, -r)),
            LineTo(Point2d(r, r)),
            LineTo(Point2d(-r, r)),
            LineTo(Point2d(-r, -r)),
            ClosePath(),
        ]
    )
end

const BezierCross = let
    cutfraction = 2 / 3
    r = 0.5 # 1/(2 * sqrt(1 - cutfraction^2))
    ri = 0.166 #r * (1 - cutfraction)

    first_three = Point2d[(r, ri), (ri, ri), (ri, r)]
    all = (x -> reduce(vcat, x))(
        map(0:(pi / 2):(3pi / 2)) do a
            m = Mat2d(sin(a), cos(a), cos(a), -sin(a))
            return Ref(m) .* first_three
        end
    )

    BezierPath(
        [
            MoveTo(all[1]),
            LineTo.(all[2:end])...,
            ClosePath(),
        ]
    )
end

const BezierX = rotate(BezierCross, pi / 4)
