function AbstractPlotting.scatter!(la::LayoutedAxis, args...; kwargs...)
    plot = scatter!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.lines!(la::LayoutedAxis, args...; kwargs...)
    plot = lines!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.image!(la::LayoutedAxis, args...; kwargs...)
    plot = image!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.poly!(la::LayoutedAxis, args...; kwargs...)
    plot = poly!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
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
    newwidths = bb.widths .* (1f0 .+ margins)
    diffs = newwidths .- bb.widths
    neworigin = bb.origin .- (0.5f0 .* diffs)
    FRect2D(neworigin, newwidths)
end

function limitunion(lims1, lims2)
    (min(lims1..., lims2...), max(lims1..., lims2...))
end

function expandlimits(lims, fractionalmargin)
    w = lims[2] - lims[1]
    d = w * fractionalmargin
    (lims[1] - 0.5f0 * d, lims[2] + 0.5f0 * d)
end

function getlimits(la::LayoutedAxis, dim)
    lim = if length(la.plots) > 0
        bbox = BBox(boundingbox(la.plots[1]))
        templim = (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim])
        for p in la.plots[2:end]
            bbox = BBox(boundingbox(p))
            templim = limitunion(templim, (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim]))
        end
        templim
    else
        nothing
    end
end

getxlimits(la::LayoutedAxis) = getlimits(la, 1)
getylimits(la::LayoutedAxis) = getlimits(la, 2)


function autolimits!(la::LayoutedAxis)

    xlims = getxlimits(la)
    for link in la.xaxislinks
        if isnothing(xlims)
            xlims = getxlimits(link)
        else
            newxlims = getxlimits(link)
            if !isnothing(newxlims)
                xlims = limitunion(xlims, newxlims)
            end
        end
    end
    if isnothing(xlims)
        xlims = (0f0, 1f0)
    else
        xlims = expandlimits(xlims, la.attributes.autolimitmargin[][1])
    end

    ylims = getylimits(la)
    for link in la.yaxislinks
        if isnothing(ylims)
            ylims = getylimits(link)
        else
            newylims = getylimits(link)
            if !isnothing(newylims)
                ylims = limitunion(ylims, newylims)
            end
        end
    end
    if isnothing(ylims)
        ylims = (0f0, 1f0)
    else
        ylims = expandlimits(ylims, la.attributes.autolimitmargin[][2])
    end

    bbox = BBox(xlims[1], xlims[2], ylims[2], ylims[1])
    la.limits[] = bbox
end
