bar_label_formatter(value::Number) = string(round(value; digits = 3))
bar_label_formatter(label::String) = label
bar_label_formatter(label::LaTeXString) = label

"""
    bar_default_fillto(tf, ys, offset)::(ys, offset)

Returns the default y-positions and offset positions for the given transform `tf`.

In order to customize this for your own transformation type, you can dispatch on
`tf`.

Returns a Tuple of new y positions and offset arrays.

## Arguments
- `tf`: `plot.transformation.transform_func[]`.
- `ys`: The y-values passed to `barplot`.
- `offset`: The `offset` parameter passed to `barplot`.
"""
function bar_default_fillto(tf, ys, offset, in_y_direction)
    return ys, offset
end

# `fillto` is related to `y-axis` transformation only, thus we expect `tf::Tuple`
function bar_default_fillto(tf::Tuple, ys, offset, in_y_direction)
    _logT = Union{typeof(log), typeof(log2), typeof(log10), Base.Fix1{typeof(log), <:Real}}
    if in_y_direction && tf[2] isa _logT || (!in_y_direction && tf[1] isa _logT)
        # x-scale log and !(in_y_direction) is equiavlent to y-scale log in_y_direction
        # use the minimal non-zero y divided by 2 as lower bound for log scale
        smart_fillto = minimum(y -> y <= 0 ? oftype(y, Inf) : y, ys) / 2
        return clamp.(ys, smart_fillto, Inf), smart_fillto
    else
        return ys, offset
    end
end

"""
    barplot(positions, heights; kwargs...)

Plots a barplot.
"""
@recipe BarPlot (positions,) begin
    """Controls the baseline of the bars. This is zero in the default `automatic` case unless the barplot is in a log-scaled `Axis`.
    With a log scale, the automatic default is half the minimum value because zero is an invalid value for a log scale.
    """
    fillto = automatic
    offset = 0.0
    color = @inherit patchcolor
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    dodge = automatic
    n_dodge = automatic
    """
    The final width of the bars is calculated as `w * (1 - gap)` where `w` is the width of each bar
    as determined with the `width` attribute.
    """
    gap = 0.2
    dodge_gap = 0.03
    stack = automatic
    strokewidth = @inherit patchstrokewidth
    strokecolor = @inherit patchstrokecolor
    """
    The gapless width of the bars. If `automatic`, the width `w` is calculated as `minimum(diff(sort(unique(positions)))`.
    The actual width of the bars is calculated as `w * (1 - gap)`.
    """
    width = automatic
    "Controls the direction of the bars, can be `:y` (vertical) or `:x` (horizontal)."
    direction = :y
    cycle = [:color => :patchcolor]
    "Labels added at the end of each bar."
    bar_labels = nothing
    flip_labels_at = Inf
    label_rotation = 0π
    label_color = @inherit textcolor
    color_over_background = automatic
    color_over_bar = automatic
    "The distance of the labels from the bar ends in screen units. Does not apply when `label_position = :center`."
    label_offset = 5
    "The font of the bar labels."
    label_font = @inherit font
    "The font size of the bar labels."
    label_size = @inherit fontsize
    label_formatter = bar_label_formatter
    label_align = automatic
    "The position of each bar's label relative to the bar. Possible values are `:end` or `:center`."
    label_position = :end
end

conversion_trait(::Type{<:BarPlot}) = PointBased()

function bar_rectangle(x, y, width, fillto, in_y_direction)
    # y could be smaller than fillto...
    ymin = min(fillto, y)
    ymax = max(fillto, y)
    w = abs(width)
    rect = Rectd(x - (w / 2.0f0), ymin, w, ymax - ymin)
    return in_y_direction ? rect : flip(rect)
end

flip(r::Rect2) = Rect2(reverse(origin(r)), reverse(widths(r)))

function compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)
    width === automatic && (width = 1)
    width *= 1 - gap
    if dodge === automatic
        i_dodge = 1
    elseif eltype(dodge) <: Integer
        i_dodge = dodge
    else
        ArgumentError("The keyword argument `dodge` currently supports only `AbstractVector{<: Integer}`") |> throw
    end
    n_dodge === automatic && (n_dodge = maximum(i_dodge))
    dodge_width = scale_width(dodge_gap, n_dodge)
    shifts = shift_dodge.(i_dodge, dodge_width, dodge_gap)
    return x .+ width .* shifts, width * dodge_width
end

scale_width(dodge_gap, n_dodge) = (1 - (n_dodge - 1) * dodge_gap) / n_dodge

function shift_dodge(i, dodge_width, dodge_gap)
    return (dodge_width - 1) / 2 + (i - 1) * (dodge_width + dodge_gap)
end

function stack_from_to_sorted(y)
    to = cumsum(y)
    from = [0.0; to[firstindex(to):(end - 1)]]

    return (from = from, to = to)
end

function stack_from_to(i_stack, y)
    # save current order
    order = 1:length(y)
    # sort by i_stack
    perm = sortperm(i_stack)
    # restore original order
    inv_perm = sortperm(order[perm])

    from, to = stack_from_to_sorted(view(y, perm))

    return (from = view(from, inv_perm), to = view(to, inv_perm))
end

function stack_grouped_from_to(i_stack, y, grp)
    from = Array{Float64}(undef, length(y))
    to = Array{Float64}(undef, length(y))

    groupby = StructArray((; grp...))
    grps = StructArrays.finduniquesorted(groupby)
    last_pos = map(grps) do (g, inds)
        g => any(y[inds] .> 0) || all(y[inds] .== 0)
    end |> Dict
    is_pos = map(y, groupby) do v, g
        last_pos[g] = iszero(v) ? last_pos[g] : v > 0
    end

    groupby = StructArray((; grp..., is_pos))
    grps = StructArrays.finduniquesorted(groupby)
    for (grp, inds) in grps
        fromto = stack_from_to(i_stack[inds], y[inds])
        from[inds] .= fromto.from
        to[inds] .= fromto.to
    end

    return (from = from, to = to)
end

function calculate_bar_label_align(label_align, label_rotation::Real, in_y_direction::Bool, flip::Bool)
    if label_align == automatic
        return angle2align(-label_rotation - !flip * pi + in_y_direction * pi / 2)
    else
        return to_align(label_align, "Failed to convert `label_align` $label_align.")
    end
end

function text_attributes(
        values, in_y_direction, flip_labels_at, color_over_background, color_over_bar,
        label_offset, label_rotation, label_align, label_position
    )
    aligns = Vec2d[]
    offsets = Vec2d[]
    text_colors = RGBAf[]
    swap(x, y) = in_y_direction ? (x, y) : (y, x)
    geti(x::AbstractArray, i) = x[i]
    geti(x, i) = x
    function flip(k)
        if flip_labels_at isa Number
            return k > flip_labels_at || k < 0
        elseif flip_labels_at isa Tuple{Number, Number}
            return (k > flip_labels_at[2] || k < 0) && k > flip_labels_at[1]
        else
            error("flip_labels_at needs to be a tuple of two numbers (low, high), or a single number (high)")
        end
    end

    for (i, k) in enumerate(values)
        if label_position == :center
            push!(aligns, label_align === automatic ? Vec2d(0.5, 0.5) : to_align(label_align))
            push!(offsets, Vec2d(0, 0))
            push!(text_colors, geti(color_over_bar, i))
        else
            isflipped = flip(k)

            push!(aligns, calculate_bar_label_align(label_align, label_rotation, in_y_direction, isflipped))

            if isflipped
                # plot text inside bar
                push!(offsets, swap(0, -sv_getindex(label_offset, i)))
                push!(text_colors, geti(color_over_bar, i))
            else
                # plot text next to bar
                push!(offsets, swap(0, sv_getindex(label_offset, i)))
                push!(text_colors, geti(color_over_background, i))
            end
        end
    end
    return aligns, offsets, text_colors
end

function barplot_labels(
        xpositions, ypositions, offset, bar_labels, in_y_direction, flip_labels_at,
        color_over_background, color_over_bar, label_formatter, label_offset, label_rotation,
        label_align, label_position, fillto
    )
    if bar_labels isa Symbol && bar_labels in (:x, :y)
        bar_labels = map(xpositions, ypositions) do x, y
            if bar_labels === :x
                x
            else
                y
            end
        end
    end
    return if bar_labels isa AbstractVector
        if length(bar_labels) == length(xpositions)
            attributes = text_attributes(
                ypositions, in_y_direction, flip_labels_at, color_over_background,
                color_over_bar, label_offset, label_rotation, label_align, label_position
            )
            label_pos = broadcast(xpositions, ypositions, offset, bar_labels, label_position, fillto) do x, y, off, l, lpos, fto
                str = string(label_formatter(l))
                p = if in_y_direction
                    if lpos == :end
                        Point2d(x, y + off)
                    else
                        Point2d(x, 0.5 * (y + fto) + off)
                    end
                else
                    if lpos == :end
                        Point2d(y, x + off)
                    else
                        Point2d(0.5 * (y + fto), x + off)
                    end
                end
                return (str, p)
            end
            return (label_pos, attributes...)
        else
            error("Labels and bars need to have same length. Found: $(length(xpositions)) bars with these labels: $(bar_labels)")
        end
    else
        error("Unsupported label type: $(typeof(bar_labels)). Use: :x, :y, or a vector of values that can be converted to strings.")
    end
end

function Makie.plot!(p::BarPlot)
    bar_points = p[1]
    if !(eltype(bar_points[]) <: Point2)
        error("barplot only accepts x/y coordinates. Use `barplot(x, y)` or `barplot(xy::Vector{<:Point2})`. Found: $(bar_points[])")
    end
    labels = Observable(Tuple{Union{String, LaTeXStrings.LaTeXString}, Point2d}[])
    label_aligns = Observable(Vec2d[])
    label_offsets = Observable(Vec2d[])
    label_colors = Observable(RGBAf[])
    function calculate_bars(
            xy, fillto, offset, transformation, width, dodge, n_dodge, gap, dodge_gap, stack,
            dir, bar_labels, flip_labels_at, label_color, color_over_background,
            color_over_bar, label_formatter, label_offset, label_rotation, label_align, label_position
        )

        in_y_direction = get((y = true, x = false), dir) do
            error("Invalid direction $dir. Options are :x and :y.")
        end

        x = first.(xy)
        y = last.(xy)

        # by default, `width` is `minimum(diff(sort(unique(x)))`
        if width === automatic
            x_unique = unique(filter(isfinite, x))
            x_diffs = diff(sort(x_unique))
            width = isempty(x_diffs) ? 1.0 : minimum(x_diffs)
        end

        # compute width of bars and x̂ (horizontal position after dodging)
        x̂, barwidth = compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)

        # --------------------------------
        # ----------- Stacking -----------
        # --------------------------------

        if stack === automatic
            if fillto === automatic
                y, fillto = bar_default_fillto(transformation, y, offset, in_y_direction)
            end
        elseif eltype(stack) <: Integer
            fillto === automatic || @warn "Ignore keyword fillto when keyword stack is provided"
            if !iszero(offset)
                @warn "Ignore keyword offset when keyword stack is provided"
                offset = 0.0
            end
            i_stack = stack

            from, to = stack_grouped_from_to(i_stack, y, (x = x̂,))
            y, fillto = to, from
        else
            ArgumentError("The keyword argument `stack` currently supports only `AbstractVector{<: Integer}`") |> throw
        end

        # --------------------------------
        # ----------- Labels -------------
        # --------------------------------

        if !isnothing(bar_labels)
            oback = color_over_background === automatic ? label_color : color_over_background
            obar = color_over_bar === automatic ? label_color : color_over_bar
            label_args = barplot_labels(
                x̂, y, offset, bar_labels, in_y_direction,
                flip_labels_at, to_color(oback), to_color(obar),
                label_formatter, label_offset, label_rotation, label_align, label_position, fillto
            )
            labels[], label_aligns[], label_offsets[], label_colors[] = label_args
        end

        return bar_rectangle.(x̂, y .+ offset, barwidth, fillto, in_y_direction)
    end

    bars = lift(
        calculate_bars, p, p[1], p.fillto, p.offset, p.transformation.transform_func, p.width, p.dodge, p.n_dodge, p.gap,
        p.dodge_gap, p.stack, p.direction, p.bar_labels, p.flip_labels_at,
        p.label_color, p.color_over_background, p.color_over_bar, p.label_formatter, p.label_offset, p.label_rotation, p.label_align, p.label_position; priority = 1
    )
    poly!(
        p, bars, color = p.color, colormap = p.colormap, colorscale = p.colorscale, colorrange = p.colorrange,
        strokewidth = p.strokewidth, strokecolor = p.strokecolor, visible = p.visible,
        inspectable = p.inspectable, transparency = p.transparency, space = p.space,
        highclip = p.highclip, lowclip = p.lowclip, nan_color = p.nan_color, alpha = p.alpha,
    )

    return if !isnothing(p.bar_labels[])
        text!(p, labels; align = label_aligns, offset = label_offsets, color = label_colors, font = p.label_font, fontsize = p.label_size, rotation = p.label_rotation)
    end
end
