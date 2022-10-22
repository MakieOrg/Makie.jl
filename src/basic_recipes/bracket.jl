@recipe(Bracket) do scene
    Theme(
        offset = 0,
        width = 15,
        strength = 1,
        text = "",
        font = theme(scene, :font),
        flip = false,
        align = (:center, :bottom),
        textoffset = 0,
        fontsize = 16,
    )
end

function plot!(pl::Bracket)

    points = pl[1]

    scene = parent_scene(pl)

    function poly3(t, p0, p1, p2, p3)
        Point2f((1-t)^3 .* p0 .+ t*p1*(3*(1-t)^2) + p2*(3*(1-t)*t^2) .+ p3*t^3)
    end

    textoffset = Observable(Vec2f(0, 0))
    bp = Observable(BezierPath([]))
    
    onany(points, scene.camera.projectionview, pl.offset, pl.width, pl.strength, pl.flip, pl.textoffset) do points, pv, offset, width, strength, flip, textoff

        (p1, p2) = scene_to_screen(points, scene)
        
        v = p2 - p1
        d1 = normalize(v)
        d2 = [0 -1; 1 0] * d1
        if flip
            d2 = -d2
        end

        textoffset[] = d2 * textoff

        p12 = 0.5 * (p1 + p2) + width * d2

        c1 = p1 + width * d2 * strength
        c2 = p12 - width * d2 * strength
        c3 = p2 + width * d2 * strength

        off = offset * d2

        part1 = [poly3(t, p1, c1, c2, p12) + off for t in range(0, 1, length = 30)]
        part2 = [poly3(t, p12, c2, c3, p2) + off for t in range(0, 1, length = 30)]

        bp[] = BezierPath([
            MoveTo(p1 + off),
            CurveTo(c1 + off, c2 + off, p12 + off),
            CurveTo(c2 + off, c3 + off, p2 + off),
        ])
    end

    notify(points)

    p = @lift $bp.commands[2].p

    lines!(pl, bp, space = :pixel)
    text!(pl, p, text = pl.text, space = :pixel, align = pl.align, offset = textoffset, textsize = pl.fontsize, font = pl.font)
    pl
end

data_limits(pl::Bracket) = Rect3f()