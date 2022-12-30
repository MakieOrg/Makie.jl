"""
    bracket(point1, point2; kwargs...)
    bracket(x1, y1, x2, y2; kwargs...)
    bracket(points; kwargs...)

Draws a bracket between two points with a text label at the midpoint.

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
    )
end

Makie.convert_arguments(::Type{<:Bracket}, point1::VecTypes, point2::VecTypes) = (Point2f[point1, point2],)
Makie.convert_arguments(::Type{<:Bracket}, x1::Real, y1::Real, x2::Real, y2::Real) = ([Point2f(x1, y1), Point2f(x2, y2)],)
Makie.convert_arguments(::Type{<:Bracket}, points::AbstractVector{<:VecTypes{2}}) = (convert(Vector{Point2f}, points),)

function Makie.plot!(pl::Bracket)

    points = pl[1]

    scene = parent_scene(pl)

    function poly3(t, p0, p1, p2, p3)
        Point2f((1-t)^3 .* p0 .+ t*p1*(3*(1-t)^2) + p2*(3*(1-t)*t^2) .+ p3*t^3)
    end

    textoffset_vec = Observable(Vec2f(0, 0))
    bp = Observable(BezierPath([]))

    realtextoffset = @lift($(pl.textoffset) === automatic ? Float32(0.75 * $(pl.fontsize)) : Float32($(pl.textoffset)))
    
    strength = 1.0 # hardcoded for now, maybe other bracket types in the future need different settings
    onany(points, scene.camera.projectionview, pl.offset, pl.width, pl.orientation, realtextoffset) do points, pv, offset, width, orientation, textoff

        (p1, p2) = scene_to_screen(points, scene)
        
        v = p2 - p1
        d1 = normalize(v)
        d2 = [0 -1; 1 0] * d1
        orientation in (:up, :down) || error("Orientation must be :up or :down but is $(repr(orientation)).")
        if (orientation == :up) != (d2[2] >= 0)
            d2 = -d2
        end

        textoffset_vec[] = d2 * textoff

        p12 = 0.5 * (p1 + p2) + width * d2

        c1 = p1 + width * d2 * strength
        c2 = p12 - width * d2 * strength
        c3 = p2 + width * d2 * strength

        off = offset * d2

        bp[] = BezierPath([
            MoveTo(p1 + off),
            CurveTo(c1 + off, c2 + off, p12 + off),
            CurveTo(c2 + off, c3 + off, p2 + off),
        ])
    end

    notify(points)

    p = @lift $bp.commands[2].p

    autorotation = lift(pl.rotation, textoffset_vec) do rot, tv
        if rot === automatic
            to_rotation(tv[2] >= 0 ? tv : -tv)
        else
            to_rotation(rot)
        end
    end

    lines!(pl, bp; space = :pixel, color = pl.color, linewidth = pl.linewidth, linestyle = pl.linestyle)
    text!(pl, p, text = pl.text, space = :pixel, align = pl.align, offset = textoffset_vec,
        fontsize = pl.fontsize, font = pl.font, rotation = autorotation, color = pl.textcolor,
        justification = pl.justification)
    pl
end

data_limits(pl::Bracket) = Rect3f(pl[1][])