"""
    bracket(x1, y1, x2, y2; kwargs...)
    bracket(x1s, y1s, x2s, y2s; kwargs...)
    bracket(point1, point2; kwargs...)
    bracket(vec_of_point_tuples; kwargs...)

Draws a bracket between each pair of points (x1, y1) and (x2, y2) with a text label at the midpoint.

By default each label is rotated parallel to the line between the bracket points.
"""
@recipe Bracket (positions,) begin
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
    space = :data
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

    map!(pl, [:textoffset, :fontsize], :realtextoffset) do to, fs
        to === automatic ? Float32.(0.75 .* fs) : Float32.(to)
    end

    # TODO: Should we change convert_arguments or is that breaking?
    map!(pairs -> first.(pairs), pl, :positions, :startpoints)
    map!(pairs -> last.(pairs), pl, :positions, :endpoints)

    # TODO: Don't throw away z, that pins z to 0
    register_projected_positions!(pl, Point2f, input_name = :startpoints, output_space = :pixel)
    register_projected_positions!(pl, Point2f, input_name = :endpoints, output_space = :pixel)

    map!(pl, [:pixel_startpoints, :pixel_endpoints, :orientation], :pixel_directions) do startpoints, endpoints, orientation
        return broadcast(startpoints, endpoints, orientation) do p1, p2, orientation
            orientation in (:up, :down) || error("Orientation must be :up or :down but is $(repr(orientation)).")
            v = p2 - p1
            d1 = normalize(v)
            d2 = Vec2f(-d1[2], d1[1])
            if (orientation === :up) != (d2[2] >= 0)
                d2 = -d2
            end
            return d2
        end
    end

    map!((a, b) -> a .* b, pl, [:pixel_directions, :realtextoffset], :finaltextoffset)

    map!(
        pl,
        [:pixel_startpoints, :pixel_endpoints, :pixel_directions, :offset, :width, :style, :text],
        [:bp, :text_tuples]
    ) do startpoints, endpoints, directions, offset, width, style, text

        # TODO: add a broadcast/map version of broadcast_foreach doing this:
        bps = BezierPath[]
        text_pos = Tuple{String, Point2f}[]

        broadcast_foreach(startpoints, endpoints, directions, offset, width, style, text) do p1, p2, dir, offset, width, style, str
            off = offset * dir
            b, textpoint = bracket_bezierpath(style, p1 + off, p2 + off, dir, width)
            push!(text_pos, (str, textpoint))
            push!(bps, b)
            return
        end
        return bps, text_pos
    end

    map!(pl, [:rotation, :pixel_directions], :autorotations) do rots, dirs
        return makie_broadcast(rots, dirs) do rot, dir
            if rot === automatic
                return to_rotation(ifelse(dir[2] >= 0, dir, -dir))
            else
                return to_rotation(rot)
            end
        end
    end

    # Avoid scale!() / translate!() / rotate!() to affect these
    series!(
        pl, pl.bp; space = :pixel, solid_color = pl.color, linewidth = pl.linewidth,
        linestyle = pl.linestyle, linecap = pl.linecap, joinstyle = pl.joinstyle,
        miter_limit = pl.miter_limit, transformation = :nothing
    )
    text!(
        pl, pl.text_tuples, space = :pixel, align = pl.align, offset = pl.finaltextoffset,
        fontsize = pl.fontsize, font = pl.font, rotation = pl.autorotations, color = pl.textcolor,
        justification = pl.justification, transformation = :nothing
    )
    return pl
end

function data_limits(pl::Bracket)
    map!(pl, [:startpoints, :endpoints], :data_limits) do startpoints, endpoints
        return update_boundingbox(Rect3d(startpoints), Rect3d(endpoints))
    end
    return pl.data_limits[]
end
boundingbox(pl::Bracket, space::Symbol = :data) = apply_transform_and_model(pl, data_limits(pl))

bracket_bezierpath(style::Symbol, args...) = bracket_bezierpath(Val(style), args...)

function bracket_bezierpath(::Val{:curly}, p1, p2, d, width)
    p12 = 0.5 * (p1 + p2) + width * d

    c1 = p1 + width * d
    c2 = p12 - width * d
    c3 = p2 + width * d

    b = BezierPath(
        [
            MoveTo(p1),
            CurveTo(c1, c2, p12),
            CurveTo(c2, c3, p2),
        ]
    )
    return b, p12
end

function bracket_bezierpath(::Val{:square}, p1, p2, d, width)
    p12 = 0.5 * (p1 + p2) + width * d

    c1 = p1 + width * d
    c2 = p2 + width * d

    b = BezierPath(
        [
            MoveTo(p1),
            LineTo(c1),
            LineTo(c2),
            LineTo(p2),
        ]
    )
    return b, p12
end
