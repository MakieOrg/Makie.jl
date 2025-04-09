"""
    bracket(x1, y1, x2, y2; kwargs...)
    bracket(x1s, y1s, x2s, y2s; kwargs...)
    bracket(point1, point2; kwargs...)
    bracket(vec_of_point_tuples; kwargs...)

Draws a bracket between each pair of points (x1, y1) and (x2, y2) with a text label at the midpoint.

By default each label is rotated parallel to the line between the bracket points.
"""
@recipe Bracket begin
    "The offset of the bracket perpendicular to the line from start to end point in screen units.
    The direction depends on the `orientation` attribute."
    offset = 0
    """
    The width of the bracket (perpendicularly away from the line from start to end point) in screen units.
    """
    width = 15
    text = ""
    font = @inherit font
    "Which way the bracket extends relative to the line from start to end point. Can be `:up` or `:down`."
    orientation = :up
    align = (:center, :center)
    textoffset = automatic
    fontsize = @inherit fontsize
    rotation = automatic
    color = @inherit linecolor
    textcolor = @inherit textcolor
    linewidth = @inherit linewidth
    linestyle = :solid
    linecap = @inherit linecap
    joinstyle = @inherit joinstyle
    miter_limit = @inherit miter_limit
    justification = automatic
    style = :curly
end

function convert_arguments(::Type{<:Bracket}, point1::VecTypes{2, T1}, point2::VecTypes{2, T2}) where {T1, T2}
    return ([(Point2{float_type(T1)}(point1), Point2{float_type(T2)}(point2))],)
end
function convert_arguments(::Type{<:Bracket}, x1::Real, y1::Real, x2::Real, y2::Real)
    return ([(Point2{float_type(x1, y1)}(x1, y1), Point2{float_type(x2, y2)}(x2, y2))],)
end
function convert_arguments(::Type{<:Bracket}, x1::AbstractVector{<:Real}, y1::AbstractVector{<:Real}, x2::AbstractVector{<:Real}, y2::AbstractVector{<:Real})
    T1 = float_type(x1, y1); T2 = float_type(x2, y2)
    points = broadcast(x1, y1, x2, y2) do x1, y1, x2, y2
        (Point2{T1}(x1, y1), Point2{T2}(x2, y2))
    end
    return (points,)
end

function plot!(pl::Bracket)

    points = pl[1]

    scene = parent_scene(pl)

    textoffset_vec = Observable(Vec2f[])
    bp = Observable(BezierPath[])
    text_tuples = Observable(Tuple{Any,Point2f}[])

    realtextoffset = lift(pl, pl.textoffset, pl.fontsize) do to, fs
        return to === automatic ? Float32.(0.75 .* fs) : Float32.(to)
    end

    onany(pl, points, scene.camera.projectionview, pl.model, transform_func(pl),
          scene.viewport, pl.offset, pl.width, pl.orientation, realtextoffset,
          pl.style, pl.text) do points, _, _, _, _, offset, width, orientation, textoff, style, text

        empty!(bp[])
        empty!(textoffset_vec[])
        empty!(text_tuples[])

        broadcast_foreach(points, offset, width, orientation, textoff, style, text) do (_p1, _p2), offset, width, orientation, textoff, style, text
            p1 = plot_to_screen(pl, _p1)
            p2 = plot_to_screen(pl, _p2)

            v = p2 - p1
            d1 = normalize(v)
            d2 = Point2(-d1[2], d1[1])
            orientation in (:up, :down) || error("Orientation must be :up or :down but is $(repr(orientation)).")
            if (orientation == :up) != (d2[2] >= 0)
                d2 = -d2
            end

            off = offset * d2

            push!(textoffset_vec[], d2 * textoff)

            b, textpoint = bracket_bezierpath(style, p1 + off, p2 + off, d2, width)
            push!(text_tuples[], (text, textpoint))
            push!(bp[], b)
        end

        notify(bp)
        notify(text_tuples)
    end

    notify(points)

    autorotations = lift(pl, pl.rotation, textoffset_vec) do rot, tv
        rots = Quaternionf[]
        broadcast_foreach(rot, tv) do rot, tv
            r = if rot === automatic
                to_rotation(tv[2] >= 0 ? tv : -tv)
            else
                to_rotation(rot)
            end
            push!(rots, r)
        end
        return rots
    end

    # Avoid scale!() / translate!() / rotate!() to affect these
    series!(pl, bp; space = :pixel, solid_color = pl.color, linewidth = pl.linewidth,
        linestyle = pl.linestyle, linecap = pl.linecap, joinstyle = pl.joinstyle,
        miter_limit = pl.miter_limit, transformation = Transformation())
    text!(pl, text_tuples, space = :pixel, align = pl.align, offset = textoffset_vec,
        fontsize = pl.fontsize, font = pl.font, rotation = autorotations, color = pl.textcolor,
        justification = pl.justification, model = Mat4f(I))
    pl
end

data_limits(pl::Bracket) = mapreduce(ps -> Rect3d([ps...]), union, pl[1][])
boundingbox(pl::Bracket, space::Symbol = :data) = apply_transform_and_model(pl, data_limits(pl))

bracket_bezierpath(style::Symbol, args...) = bracket_bezierpath(Val(style), args...)

function bracket_bezierpath(::Val{:curly}, p1, p2, d, width)
    p12 = 0.5 * (p1 + p2) + width * d

    c1 = p1 + width * d
    c2 = p12 - width * d
    c3 = p2 + width * d

    b = BezierPath([
        MoveTo(p1),
        CurveTo(c1, c2, p12),
        CurveTo(c2, c3, p2),
    ])
    return b, p12
end

function bracket_bezierpath(::Val{:square}, p1, p2, d, width)
    p12 = 0.5 * (p1 + p2) + width * d

    c1 = p1 + width * d
    c2 = p2 + width * d

    b = BezierPath([
        MoveTo(p1),
        LineTo(c1),
        LineTo(c2),
        LineTo(p2),
    ])
    return b, p12
end
