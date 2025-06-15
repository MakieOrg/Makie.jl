function initialize_block!(box::Box)
    blockscene = box.blockscene

    strokecolor_with_visibility = lift(blockscene, box.strokecolor, box.strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
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


function attribute_examples(::Type{Box})
    return Dict(
        :color => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], color = :red)
                Box(fig[1, 2], color = (:red, 0.5))
                Box(fig[2, 1], color = RGBf(0.2, 0.5, 0.7))
                Box(fig[2, 2], color = RGBAf(0.2, 0.5, 0.7, 0.5))
                fig
                """
            ),
        ],
        :strokecolor => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], strokecolor = :red)
                Box(fig[1, 2], strokecolor = (:red, 0.5))
                Box(fig[2, 1], strokecolor = RGBf(0.2, 0.5, 0.7))
                Box(fig[2, 2], strokecolor = RGBAf(0.2, 0.5, 0.7, 0.5))
                fig
                """
            ),
        ],
        :strokewidth => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], strokewidth = 1)
                Box(fig[1, 2], strokewidth = 10)
                Box(fig[1, 3], strokewidth = 0)
                fig
                """
            ),
        ],
        :linestyle => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], linestyle = :solid)
                Box(fig[1, 2], linestyle = :dot)
                Box(fig[1, 3], linestyle = :dash)
                fig
                """
            ),
        ],
        :cornerradius => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], cornerradius = 0)
                Box(fig[1, 2], cornerradius = 20)
                Box(fig[1, 3], cornerradius = (0, 10, 20, 30))
                fig
                """
            ),
        ],
    )
end
