"""
    barplot(x, y; kwargs...)

Plots a barplot; `y` defines the height.  `x` and `y` should be 1 dimensional.

## Attributes
$(ATTRIBUTES)
"""
@recipe(BarPlot, x, y) do scene
    Attributes(;
        fillto = 0.0,
        color = theme(scene, :color),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        marker = Rect,
        strokewidth = 0,
        strokecolor = :white,
        width = automatic,
        direction = :y,
        visible = theme(scene, :visible),
    )
end

conversion_trait(::Type{<: BarPlot}) = PointBased()

function bar_rectangle(xy, width, fillto)
    x, y = xy
    # y could be smaller than fillto...
    ymin = min(fillto, y)
    ymax = max(fillto, y)
    w = abs(width)
    return FRect(x - (w / 2f0), ymin, w, ymax - ymin)
end

flip(r::Rect2D) = Rect2D(reverse(origin(r)), reverse(widths(r)))

function AbstractPlotting.plot!(p::BarPlot)

    in_y_direction = lift(p.direction) do dir
        if dir == :y
            true
        elseif dir == :x
            false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    bars = lift(p[1], p.fillto, p.width, in_y_direction) do xy, fillto, width, in_y_direction
        # compute half-width of bars
        if width === automatic
            # times 0.8 for default gap
            width = mean(diff(first.(xy))) * 0.8
            width = ifelse(isfinite(width), width, 0.8)
        end

        rects = bar_rectangle.(xy, width, fillto)
        return in_y_direction ? rects : flip.(rects)
    end

    poly!(
        p, bars, color = p.color, colormap = p.colormap, colorrange = p.colorrange,
        strokewidth = p.strokewidth, strokecolor = p.strokecolor, visible = p.visible
    )
end
