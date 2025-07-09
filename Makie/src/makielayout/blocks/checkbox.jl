function initialize_block!(c::Checkbox)

    scene = c.blockscene

    ischecked = lift(identity, scene, c.checked)
    ishovered = Observable(false)

    checkboxrect = lift(scene, c.layoutobservables.computedbbox, c.size) do bbox, size
        Rect2f(
            bbox.origin + 0.5 .* bbox.widths .- 0.5 .* size,
            Vec2d(size)
        )
    end

    shape = lift(c.size, c.roundness) do size, roundness
        r = Float64(roundness * size / 2)
        roundedrectpath(Float64.((size, size)), (r, r, r, r))
    end

    strokecolor = lift(scene, ischecked, c.checkboxstrokecolor_unchecked, c.checkboxstrokecolor_checked) do checked, color_uc, color_c
        Makie.to_color(checked ? color_c : color_uc)
    end

    polycolor = lift(scene, ischecked, c.checkboxcolor_unchecked, c.checkboxcolor_checked) do checked, color_uc, color_c
        Makie.to_color(checked ? color_c : color_uc)
    end

    checkmarkcolor = lift(scene, ischecked, c.checkmarkcolor_unchecked, c.checkmarkcolor_checked) do checked, color_uc, color_c
        Makie.to_color(checked ? color_c : color_uc)
    end

    shp = poly!(
        scene,
        shape,
        color = polycolor,
        strokewidth = c.checkboxstrokewidth,
        strokecolor = strokecolor,
    )

    on(checkboxrect, update = true) do rect
        translate!(shp, (rect.origin .+ 0.5 .* rect.widths)..., 0)
    end

    markerpos = lift(checkboxrect) do rect
        rect.origin .+ 0.5 .* rect.widths
    end

    sc = scatter!(
        scene,
        markerpos,
        marker = c.checkmark,
        markersize = @lift($(c.size) * $(c.checkmarksize)),
        color = checkmarkcolor,
        visible = @lift($ischecked || $ishovered),
    )

    mouseevents = addmouseevents!(scene, checkboxrect)

    onmouseleftclick(mouseevents) do _
        newstatus = c.onchange[](c.checked[])
        if newstatus != c.checked[]
            c.checked[] = newstatus
        end
    end
    onmouseover(mouseevents) do _
        ishovered[] = true
    end
    onmouseout(mouseevents) do _
        ishovered[] = false
    end

    on(scene, c.size; update = true) do sz
        c.layoutobservables.autosize[] = Float64.((sz, sz))
    end

    return
end

function roundedrectpath(size, radii)
    # radii go top right, bottom right, bottom left, top left
    rw, rh = size ./ 2
    return BezierPath(
        [
            MoveTo(rw, rh - radii[1]),
            LineTo(rw, -rh + radii[2]),
            EllipticalArc(Point(rw - radii[2], -rh + radii[2]), radii[2], radii[2], 0, 0, -pi / 2),
            LineTo(-rw + radii[3], -rh),
            EllipticalArc(Point(-rw + radii[3], -rh + radii[3]), radii[3], radii[3], 0, -pi / 2, -pi),
            LineTo(-rw, rh - radii[4]),
            EllipticalArc(Point(-rw + radii[4], rh - radii[4]), radii[4], radii[4], 0, -pi, -3pi / 2),
            LineTo(rw - radii[1], rh),
            EllipticalArc(Point(rw - radii[1], rh - radii[1]), radii[1], radii[1], 0, -3pi / 2, -2pi),
            ClosePath(),
        ]
    )
end
