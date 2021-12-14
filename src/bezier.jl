struct MoveTo
    p::Point2{Float64}
end

MoveTo(x, y) = MoveTo(Point(x, y))

struct LineTo
    p::Point2{Float64}
end

LineTo(x, y) = LineTo(Point(x, y))

struct CurveTo
    c1::Point2{Float64}
    c2::Point2{Float64}
    p::Point2{Float64}
end

CurveTo(cx1, cy1, cx2, cy2, p1, p2) = CurveTo(
    Point(cx1, cy1), Point(cx2, cy2), Point(p1, p1)
)

struct EllipticalArc
    c::Point2{Float64}
    r1::Float64
    r2::Float64
    angle::Float64
    a1::Float64
    a2::Float64
end

EllipticalArc(cx, cy, r1, r2, angle, a1, a2) = EllipticalArc(Point(cx, cy),
    r1, r2, angle, a1, a2)

struct ClosePath end

const PathCommand = Union{MoveTo, LineTo, CurveTo, EllipticalArc, ClosePath}

struct BezierPath
    commands::Vector{PathCommand}
end

function Base.:+(pc::P, p::Point2) where P <: PathCommand
    fnames = fieldnames(P)
    P(map(f -> getfield(pc, f) + p, fnames)...)
end

scale(bp::BezierPath, s::Real) = BezierPath([scale(x, Vec(s, s)) for x in bp.commands])
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
scale(e::EllipticalArc, v::VecTypes{2}) = EllipticalArc(e.c .* v, e.r1, e.r2, e.angle, e.a1, e.a2)
scale(c::ClosePath, v::VecTypes{2}) = c

rotmatrix2d(a) = SMatrix{2, 2, Float64}(cos(a), sin(a), -sin(a), cos(a))
rotate(m::MoveTo, a) = MoveTo(rotmatrix2d(a) * m.p)
rotate(c::ClosePath, a) = c
rotate(l::LineTo, a) = LineTo(rotmatrix2d(a) * l.p)
function rotate(c::CurveTo, a)
    m = rotmatrix2d(a)
    CurveTo(m * c.c1, m * c.c2, m *c.p)
end
function rotate(e::EllipticalArc, a)
    m = rotmatrix2d(a)
    newc = m * e.c
    newangle = e.angle + a
    EllipticalArc(newc, e.r1, e.r2, newangle, e.a1, e.a2)
end
rotate(b::BezierPath, a) = BezierPath(PathCommand[rotate(c::PathCommand, a) for c in b.commands])

function fit_to_base_square(b::BezierPath)
    bb = bbox(b)
    w, h = widths(bb)
    bb_t = translate(b, -(bb.origin + 0.5 * widths(bb)))
    scale(bb_t, 2 / (max(w, h)))
end

Base.:+(pc::EllipticalArc, p::Point2) = EllipticalArc(pc.c + p, pc.r1, pc.r2, pc.angle, pc.a1, pc.a2)
Base.:+(pc::ClosePath, p::Point2) = pc
Base.:+(bp::BezierPath, p::Point2) = BezierPath(bp.commands .+ Ref(p))

# markers with unit area

BezierCircle = let
    r = sqrt(1/pi)
    BezierPath([
        MoveTo(Point(r, 0.0)),
        EllipticalArc(Point(0.0, 0), r, r, 0.0, 0.0, 2pi),
        ClosePath(),
    ])
end

BezierUTriangle = let
    aspect = 1
    h = sqrt(aspect) * sqrt(2)
    w = 1/sqrt(aspect) * sqrt(2)
    # r = Float32(sqrt(1 / (3 * sqrt(3) / 4)))
    p1 = Point(0, h/2)
    p2 = Point2(-w/2, -h/2)
    p3 = Point2(w/2, -h/2)
    centroid = (p1 + p2 + p3) / 3
    bp = BezierPath([
        MoveTo(p1 - centroid),
        LineTo(p2 - centroid),
        LineTo(p3 - centroid),
        ClosePath()
    ])
end

BezierLTriangle = rotate(BezierUTriangle, pi/2)
BezierDTriangle = rotate(BezierUTriangle, pi)
BezierRTriangle = rotate(BezierUTriangle, 3pi/2)


BezierSquare = let
    BezierPath([
        MoveTo(Point2(0.5, -0.5)),
        LineTo(Point2(0.5, 0.5)),
        LineTo(Point2(-0.5, 0.5)),
        LineTo(Point2(-0.5, -0.5)),
        ClosePath()
    ])
end

BezierCross = let
    cutfraction = 2/3
    # 1 = (2r)^2 - 4 * (r * c) ^ 2
    # c^2 - 1 != 0, r = 1/(2 sqrt(1 - c^2))
    # 
    r = 1/(2 * sqrt(1 - cutfraction^2))
    # test: (2r)^2 - 4 * (r * cutfraction) ^ 2 ≈ 1
    ri = r * (1 - cutfraction)
    
    first_three = Point2[(r, ri), (ri, ri), (ri, r)]
    all = map(0:pi/2:3pi/2) do a
        m = Mat2f0(sin(a), cos(a), cos(a), -sin(a))
        Ref(m) .* first_three
    end |> x -> reduce(vcat, x)

    BezierPath([
        MoveTo(all[1]),
        LineTo.(all[2:end])...,
        ClosePath()
    ])
end


function BezierPath(svg::AbstractString; fit = false, bbox = nothing, flipy = false)
    commands = parse_bezier_commands(svg)
    p = BezierPath(commands)
    if fit
        if bbox === nothing
            p = fit_to_base_square(p)
        else
            error("Unkown bbox parameter $bbox")
        end
    end
    if flipy
        p = scale(p, Vec(1, -1))
    end
end

function parse_bezier_commands(svg)

    # args = [e.match for e in eachmatch(r"([a-zA-Z])|(\-?\d*\.?\d+)", svg)]
    args = [e.match for e in eachmatch(r"(?:0(?=\d))|(?:[a-zA-Z])|(?:\-?\d*\.?\d+)", svg)]

    i = 1

    commands = PathCommand[]
    lastcomm = nothing
    function lastp()
        c = commands[end]
        if isnothing(lastcomm)
            Point(0, 0)
        elseif c isa ClosePath
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
                m * Point(rx * cos(a2), ry * sin(a2)) + c.c
            end
        else
            c.p
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
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, MoveTo(Point2(x, y)))
            i += 3
        elseif comm == "m"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, MoveTo(Point2(x, y) + lastp()))
            i += 3
        elseif comm == "L"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, LineTo(Point2(x, y)))
            i += 3
        elseif comm == "l"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, LineTo(Point2(x, y) + lastp()))
            i += 3
        elseif comm == "H"
            x = parse(Float64, args[i+1])
            push!(commands, LineTo(Point2(x, lastp()[2])))
            i += 2
        elseif comm == "h"
            x = parse(Float64, args[i+1])
            push!(commands, LineTo(X(x) + lastp()))
            i += 2
        elseif comm == "Z"
            push!(commands, ClosePath())
            i += 1
        elseif comm == "z"
            push!(commands, ClosePath())
            i += 1
        elseif comm == "C"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[i+1:i+6])
            push!(commands, CurveTo(Point2(x1, y1), Point2(x2, y2), Point2(x3, y3)))
            i += 7
        elseif comm == "c"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[i+1:i+6])
            l = lastp()
            push!(commands, CurveTo(Point2(x1, y1) + l, Point2(x2, y2) + l, Point2(x3, y3) + l))
            i += 7
        elseif comm == "S"
            x1, y1, x2, y2 = parse.(Float64, args[i+1:i+4])
            prev = commands[end]
            reflected = prev.p + (prev.p - prev.c2)
            push!(commands, CurveTo(reflected, Point2(x1, y1), Point2(x2, y2)))
            i += 5
        elseif comm == "s"
            x1, y1, x2, y2 = parse.(Float64, args[i+1:i+4])
            prev = commands[end]
            reflected = prev.p + (prev.p - prev.c2)
            l = lastp()
            push!(commands, CurveTo(reflected, Point2(x1, y1) + l, Point2(x2, y2) + l))
            i += 5
        elseif comm == "A"
            args[i+1:i+7]
            r1, r2 = parse.(Float64, args[i+1:i+2])
            angle = parse(Float64, args[i+3])
            large_arc_flag, sweep_flag = parse.(Bool, args[i+4:i+5])
            x2, y2 = parse.(Float64, args[i+6:i+7])
            x1, y1 = lastp()

            push!(commands, EllipticalArc(x1, y1, x2, y2, r1, r2,
                angle, large_arc_flag, sweep_flag))
            i += 8
        elseif comm == "a"
            r1, r2 = parse.(Float64, args[i+1:i+2])
            angle = parse(Float64, args[i+3])
            large_arc_flag, sweep_flag = parse.(Bool, args[i+4:i+5])
            x1, y1 = lastp()
            x2, y2 = parse.(Float64, args[i+6:i+7]) .+ (x1, y1)

            push!(commands, EllipticalArc(x1, y1, x2, y2, r1, r2,
                angle, large_arc_flag, sweep_flag))
            i += 8
        elseif comm == "v"
            dy = parse(Float64, args[i+1])
            l = lastp()
            push!(commands, LineTo(Point2(l[1], l[2] + dy)))
            i += 2
        else
            for c in commands
                println(c)
            end
            error("Parsing $comm not implemented.")
        end

        lastcomm = comm

    end

    commands
end

function EllipticalArc(x1, y1, x2, y2, rx, ry, ϕ, largearc::Bool, sweepflag::Bool)
    # https://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes

    p1 = Point(x1, y1)
    p2 = Point(x2, y2)

    m1 = Mat2(cos(ϕ), -sin(ϕ), sin(ϕ), cos(ϕ))
    x1′, y1′ = m1 * (0.5 * (p1 - p2))

    tempsqrt = (rx^2 * ry^2 - rx^2 * y1′^2 - ry^2 * x1′^2) /
        (rx^2 * y1′^2 + ry^2 * x1′^2)

    c′ = (largearc == sweepflag ? -1 : 1) *
        sqrt(tempsqrt) * Point(rx * y1′ / ry, -ry * x1′ / rx)

    c = Mat2(cos(ϕ), sin(ϕ), -sin(ϕ), cos(ϕ)) * c′ + 0.5 * (p1 + p2)

    vecangle(u, v) = sign(u[1] * v[2] - u[2] * v[1]) *
        acos(dot(u, v) / (norm(u) * norm(v)))

    px(sign) = Point((sign * x1′ - c′[1]) / rx, (sign * y1′ - c′[2]) / rx)

    θ1 = vecangle(Point(1.0, 0.0), px(1))
    Δθ_pre = mod(vecangle(px(1), px(-1)), 2pi)
    Δθ = if Δθ_pre > 0 && !sweepflag
        Δθ_pre - 2pi
    elseif Δθ_pre < 0 && sweepflag
        Δθ_pre + 2pi
    else
        Δθ_pre
    end

    EllipticalArc(c, rx, ry, ϕ, θ1, θ1 + Δθ)
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
    flags = Int32(0)
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

    outline_ref = Ref{FT_Outline}()
    finalizer(outline_ref) do r
        FT_Outline_Done(Makie.FreeTypeAbstraction.FREE_FONT_LIBRARY[], outline_ref)
    end
    
    FT_Outline_New(
        Makie.FreeTypeAbstraction.FREE_FONT_LIBRARY[],
        n_points,
        n_contours,
        outline_ref
    )

    for i in 1:length(points)
        unsafe_store!(outline_ref[].points, points[i], i)
    end
    for i in 1:length(tags)
        unsafe_store!(outline_ref[].tags, tags[i], i)
    end
    for i in 1:length(contours)
        unsafe_store!(outline_ref[].contours, contours[i], i)
    end
    outline_ref
end

ftvec(p) = FT_Vector(round(Int, p[1]), round(Int, p[2]))

function convert_command(m::MoveTo)
    true, 1, ftvec.([m.p]), [FT_Curve_Tag_On] 
end

function convert_command(l::LineTo)
    false, 1, ftvec.([l.p]), [FT_Curve_Tag_On] 
end

function convert_command(c::CurveTo)
    false, 3, ftvec.([c.c1, c.c2, c.p]), [FT_Curve_Tag_Cubic, FT_Curve_Tag_Cubic, FT_Curve_Tag_On] 
end


function render_path(path)
    # in the outline, 1 unit = 1/64px, so 64px = 4096 units wide,

    bitmap_size_px = 256
    scale_factor = bitmap_size_px * 64 / 2

    # we assume that the path is already in a -1 to 1 square and we can
    # scale and translate this to a 4096x4096 grid, which is 64px x 64px
    # when rendered to bitmap

    # freetype has no ClosePath and EllipticalArc, so those need to be replaced
    path_replaced = replace_nonfreetype_commands(path)

    path_transformed = Makie.translate(Makie.scale(
        path_replaced,
        scale_factor,
    ), Point2f(scale_factor, scale_factor))


    outline_ref = make_outline(path_transformed)

    w = bitmap_size_px
    h = bitmap_size_px
    pitch = w * 1 # 8 bit gray
    pixelbuffer = zeros(UInt8, h * pitch)
    bitmap_ref = Ref{FT_Bitmap}()
    bitmap_ref[] = FT_Bitmap(
        h,
        w,
        pitch,
        Base.unsafe_convert(Ptr{UInt8}, pixelbuffer),
        256,
        FT_PIXEL_MODE_GRAY,
        C_NULL,
        C_NULL
    )

    FT_Outline_Get_Bitmap(
        Makie.FreeTypeAbstraction.FREE_FONT_LIBRARY[],
        outline_ref,
        bitmap_ref,
    )

    reshape(pixelbuffer, (w, h))
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
    newpath
end


Makie.convert_attribute(b::BezierPath, ::key"marker", ::key"scatter") = b
Makie.convert_attribute(ab::AbstractVector{<:BezierPath}, ::key"marker", ::key"scatter") = ab

struct BezierSegment
    from::Point2f
    c1::Point2f
    c2::Point2f
    to::Point2f
end

struct LineSegment
    from::Point2f
    to::Point2f
end

function bbox(b::BezierPath)
    prev = b.commands[1]
    bb = nothing
    for comm in b.commands[2:end]
        if comm isa MoveTo || comm isa ClosePath
            continue
        else
            endp = endpoint(prev)
            seg = segment(endp, comm)
            bb = bb === nothing ? bbox(seg) : union(bb, bbox(seg))
        end
        prev = comm
    end
    bb
end

segment(p, l::LineTo) = LineSegment(p, l.p)
segment(p, c::CurveTo) = BezierSegment(p, c.c1, c.c2, c.p)

endpoint(m::MoveTo) = m.p
endpoint(l::LineTo) = l.p
endpoint(c::CurveTo) = c.p

function bbox(ls::LineSegment)
    Rect2f(ls.from, ls.to - ls.from)
end

function bbox(b::BezierSegment)

    p0 = b.from
    p1 = b.c1
    p2 = b.c2
    p3 = b.to

    mi = [min.(p0, p3)...]
    ma = [max.(p0, p3)...]

    c = -p0 + p1
    b =  p0 - 2p1 + p2
    a = -p0 + 3p1 - 3p2 + 1p3

    h = [(b.*b - a.*c)...]

    if h[1] > 0
        h[1] = sqrt(h[1])
        t = (-b[1] - h[1]) / a[1]
        if t > 0 && t < 1
            s = 1.0-t
            q = s*s*s*p0[1] + 3.0*s*s*t*p1[1] + 3.0*s*t*t*p2[1] + t*t*t*p3[1]
            mi[1] = min(mi[1],q)
            ma[1] = max(ma[1],q)
        end
        t = (-b[1] + h[1])/a[1]
        if t>0 && t<1
            s = 1.0-t
            q = s*s*s*p0[1] + 3.0*s*s*t*p1[1] + 3.0*s*t*t*p2[1] + t*t*t*p3[1]
            mi[1] = min(mi[1],q)
            ma[1] = max(ma[1],q)
        end
    end

    if h[2]>0.0
        h[2] = sqrt(h[2])
        t = (-b[2] - h[2])/a[2]
        if t>0.0 && t<1.0
            s = 1.0-t
            q = s*s*s*p0[2] + 3.0*s*s*t*p1[2] + 3.0*s*t*t*p2[2] + t*t*t*p3[2]
            mi[2] = min(mi[2],q)
            ma[2] = max(ma[2],q)
        end
        t = (-b[2] + h[2])/a[2]
        if t>0.0 && t<1.0
            s = 1.0-t
            q = s*s*s*p0[2] + 3.0*s*s*t*p1[2] + 3.0*s*t*t*p2[2] + t*t*t*p3[2]
            mi[2] = min(mi[2],q)
            ma[2] = max(ma[2],q)
        end
    end

    Rect2f(Point(mi...), Point(ma...) - Point(mi...))
end


function elliptical_arc_to_beziers(arc::EllipticalArc)
    delta_a = abs(arc.a2 - arc.a1)
    n_beziers = ceil(Int, delta_a / 0.5pi)
    angles = range(arc.a1, arc.a2, length = n_beziers + 1)

    startpoint = Point2f(cos(arc.a1), sin(arc.a1))
    curves = map(angles[1:end-1], angles[2:end]) do start, stop
        theta = stop - start
        kappa = 4/3 * tan(theta/4)

        a = Point2f(cos(start), sin(start))
        c1 = Point2f(cos(start) - kappa * sin(start), sin(start) + kappa * cos(start))
        c2 = Point2f(cos(stop) + kappa * sin(stop), sin(stop) - kappa * cos(stop))
        b = Point2f(cos(stop), sin(stop))
        CurveTo(c1, c2, b)
    end

    path = BezierPath([LineTo(startpoint), curves...])
    path = scale(path, Vec(arc.r1, arc.r2))
    path = rotate(path, arc.angle)
    path = translate(path, arc.c)
end