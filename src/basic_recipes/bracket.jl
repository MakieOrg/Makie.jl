"""
    bracket(x1, y1, x2, y2; kwargs...)
    bracket(x1s, y1s, x2s, y2s; kwargs...)
    bracket(point1, point2; kwargs...)
    bracket(vec_of_point_tuples; kwargs...)

Draws a bracket between each pair of points (x1, y1) and (x2, y2) with a text label at the midpoint.

By default each label is rotated parallel to the line between the bracket points.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Bracket) do scene
    Theme(
        offset = 0,
        width = 15,
        text = "",
        font = theme(scene, :font),
        orientation = :up,
        align = (:center, :center),
        textoffset = automatic,
        fontsize = theme(scene, :fontsize),
        rotation = automatic,
        color = theme(scene, :linecolor),
        textcolor = theme(scene, :textcolor),
        linewidth = theme(scene, :linewidth),
        linestyle = :solid,
        justification = automatic,
        style = :curly,
    )
end

Makie.convert_arguments(::Type{<:Bracket}, point1::VecTypes, point2::VecTypes) = ([(Point2f(point1), Point2f(point2))],)
Makie.convert_arguments(::Type{<:Bracket}, x1::Real, y1::Real, x2::Real, y2::Real) = ([(Point2f(x1, y1), Point2f(x2, y2))],)
function Makie.convert_arguments(::Type{<:Bracket}, x1::AbstractVector{<:Real}, y1::AbstractVector{<:Real}, x2::AbstractVector{<:Real}, y2::AbstractVector{<:Real})
    points = broadcast(x1, y1, x2, y2) do x1, y1, x2, y2
        (Point2f(x1, y1), Point2f(x2, y2))
    end
    (points,)
end

function Makie.plot!(pl::Bracket)

    points = pl[1]

    scene = parent_scene(pl)

    textoffset_vec = Observable(Vec2f[])
    bp = Observable(BezierPath[])
    textpoints = Observable(Point2f[])

    realtextoffset = lift(pl, pl.textoffset, pl.fontsize) do to, fs
        return to === automatic ? Float32.(0.75 .* fs) : Float32.(to)
    end

    onany(pl, points, scene.camera.projectionview, pl.offset, pl.width, pl.orientation, realtextoffset,
          pl.style) do points, pv, offset, width, orientation, textoff, style

        empty!(bp[])
        empty!(textoffset_vec[])
        empty!(textpoints[])

        broadcast_foreach(points, offset, width, orientation, textoff, style) do (_p1, _p2), offset, width, orientation, textoff, style
            p1 = scene_to_screen(_p1, scene)
            p2 = scene_to_screen(_p2, scene)

            v = p2 - p1
            d1 = normalize(v)
            d2 = [0 -1; 1 0] * d1
            orientation in (:up, :down) || error("Orientation must be :up or :down but is $(repr(orientation)).")
            if (orientation == :up) != (d2[2] >= 0)
                d2 = -d2
            end

            off = offset * d2

            push!(textoffset_vec[], d2 * textoff)

            b, textpoint = bracket_bezierpath(style, p1 + off, p2 + off, d2, width)
            push!(textpoints[], textpoint)
            push!(bp[], b)
        end

        notify(bp)
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

    # TODO: this works around `text()` not being happy if text="xyz" comes with one-element vector attributes
    texts = lift(pl, pl.text) do text
        return text isa AbstractString ? [text] : text
    end

    series!(pl, bp; space = :pixel, solid_color = pl.color, linewidth = pl.linewidth, linestyle = pl.linestyle)
    text!(pl, textpoints, text = texts, space = :pixel, align = pl.align, offset = textoffset_vec,
        fontsize = pl.fontsize, font = pl.font, rotation = autorotations, color = pl.textcolor,
        justification = pl.justification)
    pl
end

data_limits(pl::Bracket) = mapreduce(union, pl[1][]) do points
    Rect3f([points...])
end

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
