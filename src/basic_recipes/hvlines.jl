@recipe(HVLines, origin, radius, start_angle, stop_angle) do scene
    attr = Attributes(;
        default_theme(scene, Lines)...,
        direction = :horizontal,
        axmin = 0.0,
        axmax = 1.0
    )
end

function plot!(p::HVLines)
    attr = Attributes(p)
    direction = pop!(attr, :direction)
    axmin = pop!(p, :axmin)
    axmax = pop!(p, :axmax)
    
    attr[:space] = map(direction) do dir
        dir in (:vertical, :y) ? (:data, :relative) : (:relative, :data)
    end
    attr[:xautolimits] = map(dir -> dir in (:horizontal, :x), direction)
    attr[:yautolimits] = map(dir -> dir in (:vertical, :y), direction)

    positions = map(direction, p[1], axmin, axmax) do dir, datavals, axmins, axmaxs
        segs = broadcast(datavals, axmins, axmaxs) do dataval, axmin, axmax
            if dir in (:horizontal, :x)
                (Point2f(axmin, dataval), Point2f(axmax, dataval))
            elseif dir in (:vertical, :y)
                (Point2f(dataval, axmin), Point2f(dataval, axmax))
            else
                error("direction must be :vertical or :horizontal.")
            end
        end
        # handle case that none of the inputs is an array, but we need an array for linesegments!
        if segs isa Tuple
            segs = [segs]
        end
        segs
    end

    linesegments!(p, Attributes(p), positions)
end

vlines(args...; kwargs...) = hvlines(args..., direction = :vertical; kwargs...)
hlines(args...; kwargs...) = hvlines(args..., direction = :horizontal; kwargs...)

"""
    vlines!(ax::Axis, xs; ymin = 0.0, ymax = 1.0, attrs...)

Create vertical lines across `ax` at `xs` in data coordinates and `ymin` to `ymax`
in axis coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.
"""
vlines!(args...; kwargs...) = hvlines!(args..., direction = :vertical; kwargs...)

"""
    hlines!(ax::Axis, ys; xmin = 0.0, xmax = 1.0, attrs...)

Create horizontal lines across `ax` at `ys` in data coordinates and `xmin` to `xmax`
in axis coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.
"""
hlines!(args...; kwargs...) = hvlines!(args..., direction = :horizontal; kwargs...)

export vlines, vlines!, hlines, hlines!