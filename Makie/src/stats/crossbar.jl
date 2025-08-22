#=
S. Axen implementation from https://github.com/MakieOrg/StatsMakie.jl/blob/master/src/recipes/crossbar.jl#L22
The StatMakie.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2018: Pietro Vertechi. =#
"""
    crossbar(x, y, ymin, ymax; kwargs...)
Draw a crossbar. A crossbar represents a range with a (potentially notched) box.
It is most commonly used as part of the `boxplot`.
## Arguments
- `x`: position of the box
- `y`: position of the midline within the box
- `ymin`: lower limit of the box
- `ymax`: upper limit of the box
"""
@recipe CrossBar (x, y, ymin, ymax) begin
    color = @inherit patchcolor
    colormap = @inherit colormap
    colorscale = identity
    colorrange = automatic
    "Orientation of box (`:vertical` or `:horizontal`)."
    orientation = :vertical
    # box and dodging
    "Width of the box before shrinking."
    width = automatic
    dodge = automatic
    n_dodge = automatic
    "Shrinking factor, `width -> width * (1 - gap)`."
    gap = 0.2
    dodge_gap = 0.03
    strokecolor = @inherit patchstrokecolor
    strokewidth = @inherit patchstrokewidth
    # notch
    "Whether to draw the notch."
    show_notch = false
    "Lower limit of the notch."
    notchmin = automatic
    "Upper limit of the notch."
    notchmax = automatic
    "Multiplier of `width` for narrowest width of notch."
    notchwidth = 0.5
    # median line
    "Show midline."
    show_midline = true
    midlinecolor = automatic
    midlinewidth = @inherit linewidth
    inspectable = @inherit inspectable
    cycle = [:color => :patchcolor]
    visible = true
end

function Makie.plot!(plot::CrossBar)
    map!(
        plot, [
            :x, :y, :ymin, :ymax, :width, :dodge, :n_dodge, :gap, :dodge_gap,
            :show_notch, :notchmin, :notchmax, :notchwidth, :orientation,
        ], [:boxes, :midlines]
    ) do x, y, ymin, ymax, width, dodge, n_dodge, gap, dodge_gap, show_notch, nmin, nmax, nw, orientation
        x̂, boxwidth = compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)
        show_notch = show_notch && (nmin !== automatic && nmax !== automatic)

        # for horizontal crossbars just flip all components
        fpoint, frect = Point2f, Rectf
        if orientation === :horizontal
            fpoint, frect = flip_xy ∘ fpoint, flip_xy ∘ frect
        end

        # make the shape
        hw = boxwidth ./ 2 # half box width
        l, m, r = x̂ .- hw, x̂, x̂ .+ hw

        if show_notch && nmin !== automatic && nmax !== automatic
            if any(nmin < ymin || nmax > ymax)
                @warn("Crossbar's notch went outside hinges. Set notch to false.")
            end
            # when notchmin = ymin || notchmax == ymax, fill disappears from
            # half the box. first ∘ StatsBase.rle removes adjacent duplicates.
            boxes = first.(
                StatsBase.rle.(
                    Base.vect.(
                        fpoint.(l, ymin),
                        fpoint.(r, ymin),
                        fpoint.(r, nmin),
                        fpoint.(m .+ nw .* hw, y), # notch right
                        fpoint.(r, nmax),
                        fpoint.(r, ymax),
                        fpoint.(l, ymax),
                        fpoint.(l, nmax),
                        fpoint.(m .- nw .* hw, y), # notch left
                        fpoint.(l, nmin),
                        fpoint.(l, ymin)
                    )
                )
            )
            midlines = Pair.(fpoint.(m .- nw .* hw, y), fpoint.(m .+ nw .* hw, y))
        else
            boxes = frect.(l, ymin, boxwidth, ymax .- ymin)
            midlines = Pair.(fpoint.(l, y), fpoint.(r, y))
        end
        return boxes, midlines
    end
    poly!(
        plot,
        plot.boxes,
        color = plot.color,
        colorrange = plot.colorrange,
        colormap = plot.colormap,
        colorscale = plot.colorscale,
        strokecolor = plot.strokecolor,
        strokewidth = plot.strokewidth,
        inspectable = plot.inspectable,
        visible = plot.visible
    )
    map!(plot, [:midlinecolor, :strokecolor], :linesegmentcolor) do mc, sc
        return mc === automatic ? sc : mc
    end
    linesegments!(
        plot,
        color = plot.linesegmentcolor,
        linewidth = plot.midlinewidth,
        visible = plot.show_midline,
        inspectable = plot.inspectable,
        plot.midlines,
    )
    return plot
end
