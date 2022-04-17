function initialize_block!(po::PolarAxis2)
    cb = po.layoutobservables.computedbbox

    square = lift(cb) do cb
        ws = widths(cb)
        new_ws = min.(minimum(ws), ws)
        diff = ws - new_ws
        new_o = cb.origin + 0.5diff
        Rect(round.(Int, new_o), round.(Int, new_ws))
    end

    scene = Scene(po.blockscene, square, camera = campixel!)

    onany(po.limits, square) do lims, square
        scene.transformation.transform_func[] = Makie.PointTrans{2}(function(p::Point2)
            c = widths(square) / 2
            r_outer = widths(square)[1] / 2
            ang = p[1]
            r = p[2]

            r_actual = (r - lims[1]) / (lims[2] - lims[1]) * r_outer

            Point2f(c + Point2f(cos(ang) * r_actual, sin(ang) * r_actual))
        end)
    end
    notify(po.limits)

    lines!(po.blockscene, lift(square) do sq
        Circle(center(sq), widths(sq)[1] / 2)
    end)

    lines!(po.blockscene, lift(square) do sq
        Circle(center(sq), widths(sq)[1] / 4)
    end)

    po.scene = scene

    return
end


function Makie.plot!(
    po::PolarAxis2, P::Makie.PlotFunc,
    attributes::Makie.Attributes, args...;
    kw_attributes...)

    allattrs = merge(attributes, Attributes(kw_attributes))

    # cycle = get_cycle_for_plottype(allattrs, P)
    # add_cycle_attributes!(allattrs, P, cycle, po.cycler, po.palette)

    plot = Makie.plot!(po.scene, P, allattrs, args...)

    # # some area-like plots basically always look better if they cover the whole plot area.
    # # adjust the limit margins in those cases automatically.
    # needs_tight_limits(plot) && tightlimits!(po)

    # reset_limits!(po)
    plot
end