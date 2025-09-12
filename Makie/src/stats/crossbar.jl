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
    "Sets the color of the drawn boxes. These can be values for colormapping."
    color = @inherit patchcolor

    "Orientation of box (`:vertical` or `:horizontal`)."
    orientation = :vertical

    # box and dodging
    "(Unscaled) width of the box."
    width = automatic
    """
    Dodge can be used to separate crossbars drawn at the same `x` positions. For this
    each crossbar is given an integer value corresponding to its position relative to
    the given `positions`. E.g. with `positions = [1, 1, 1, 2, 2, 2]` we have
    3 crossbars at each position which can be separated by `dodge = [1, 2, 3, 1, 2, 3]`.
    """
    dodge = automatic
    """
    Sets the maximum integer for `dodge`. This sets how many crossbars can be placed
    at a given position, controlling their width.
    """
    n_dodge = automatic
    "Size of the gap between crossbars. The modified width is `width * (1 - gap)`."
    gap = 0.2
    "Sets the gap between dodged crossbars relative to the size of them."
    dodge_gap = 0.03

    "Sets the outline linewidth of crossbars."
    strokewidth = @inherit patchstrokewidth
    "Sets the outline color of crossbars."
    strokecolor = @inherit patchstrokecolor

    # notch
    "Whether to draw the notch, which refers to a narrowed region around the midline/`y`."
    show_notch = false
    "Lower limit of the notch. These are given per position."
    notchmin = automatic
    "Upper limit of the notch. These are given per position."
    notchmax = automatic
    "Multiplier of `width` for narrowest width of notch at the midline/`y`."
    notchwidth = 0.5

    # median line
    "Shows the midline."
    show_midline = true
    "Sets the color of the midline."
    midlinecolor = automatic
    "Sets the width of the midline."
    midlinewidth = @inherit linewidth

    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color => :patchcolor]

    mixin_colormap_attributes()...
    mixin_generic_plot_attributes()...
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
    poly!(plot, Attributes(plot), plot.boxes)

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
