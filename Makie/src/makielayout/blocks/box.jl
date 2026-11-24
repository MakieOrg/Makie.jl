function initialize_block!(box::Box)
    blockscene = box.blockscene

    strokecolor_with_visibility = lift(blockscene, box.strokecolor, box.strokevisible) do col, vis
        vis ? to_color(col) : RGBAf(0, 0, 0, 0)
    end

    path = lift(blockscene, box.layoutobservables.computedbbox, box.cornerradius) do bbox, r
        if r == 0
            BezierPath(
                [
                    MoveTo(topright(bbox)),
                    LineTo(topleft(bbox)),
                    LineTo(bottomleft(bbox)),
                    LineTo(bottomright(bbox)),
                    ClosePath(),
                ]
            )
        else
            w, h = widths(bbox)
            _max = min(w / 2, h / 2)
            r1, r2, r3, r4 = r isa NTuple{4, Real} ? r : r isa Real ? (r, r, r, r) : throw(ArgumentError("Invalid cornerradius value $r. Must be a `Real` or a tuple with 4 `Real`s."))

            r1, r2, r3, r4 = min.(_max, (r1, r2, r3, r4))
            BezierPath(
                [
                    MoveTo(bbox.origin + Point(w, h / 2)),
                    EllipticalArc(topright(bbox) - Point2f(r1, r1), r1, r1, 0.0, 0, pi / 2),
                    EllipticalArc(topleft(bbox) + Point2f(r4, -r4), r4, r4, 0.0, pi / 2, pi),
                    EllipticalArc(bottomleft(bbox) + Point2f(r3, r3), r3, r3, 0.0, pi, 3 / 2 * pi),
                    EllipticalArc(bottomright(bbox) + Point2f(-r2, r2), r2, r2, 0.0, 3 / 2 * pi, 2pi),
                    ClosePath(),
                ]
            )
        end
    end


    plt = poly!(
        blockscene, path, color = box.color, visible = box.visible,
        strokecolor = strokecolor_with_visibility, strokewidth = box.strokewidth,
        inspectable = false, linestyle = box.linestyle
    )

    on(z -> translate!(plt, 0, 0, z), plt, box.z, update = true)

    # trigger bbox
    box.layoutobservables.suggestedbbox[] = box.layoutobservables.suggestedbbox[]

    return
end
