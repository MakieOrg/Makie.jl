function AbstractPlotting.scatter!(la::LayoutedAxis, args...; kwargs...)
    sc = scatter!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, sc)
    autolimits!(la)
    sc
end

function AbstractPlotting.lines!(la::LayoutedAxis, args...; kwargs...)
    sc = lines!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, sc)
    autolimits!(la)
    sc
end

function AbstractPlotting.image!(la::LayoutedAxis, args...; kwargs...)
    sc = image!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, sc)
    autolimits!(la)
    sc
end

function AbstractPlotting.poly!(la::LayoutedAxis, args...; kwargs...)
    sc = poly!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, sc)
    autolimits!(la)
    sc
end

function bboxunion(bb1, bb2)

    o1 = bb1.origin
    o2 = bb2.origin
    e1 = bb1.origin + bb1.widths
    e2 = bb2.origin + bb2.widths

    o = min.(o1, o2)
    e = max.(e1, e2)

    BBox(o[1], e[1], e[2], o[2])
end

function expandbboxwithfractionalmargins(bb, margins)
    newwidths = bb.widths .* (1 .+ margins)
    diffs = newwidths .- bb.widths
    neworigin = bb.origin .- (0.5 .* diffs)
    FRect2D(neworigin, newwidths)
end

function autolimits!(la::LayoutedAxis)
    bbox = if length(la.plots) > 0
        tempbbox = BBox(boundingbox(la.plots[1]))
        for p in la.plots[2:end]
            tempbbox = bboxunion(tempbbox, BBox(boundingbox(p)))
        end
        tempbbox
    else
        BBox(0, 1, 1, 0)
    end

    withmarginbbox = expandbboxwithfractionalmargins(bbox, la.attributes.autolimitmargin[])
    la.limits[] = withmarginbbox
end
