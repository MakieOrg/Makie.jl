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

Plots bars of the given `heights` at the given (scalar) `positions`.
"""
@recipe BarPlot (positions,) begin
    """
    Controls the baseline of the bars. This is zero in the default `automatic` case
    unless the barplot is in a log-scaled `Axis`. With a log scale, the automatic
    default is half the minimum value because zero is an invalid value for a log scale.
    """
    fillto = automatic
    "Offsets all bars by the given real value. Can also be set per-bar."
    offset = 0.0
    "Sets the color of bars."
    color = @inherit patchcolor
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    """
    Dodge can be used to separate bars drawn at the same `position`. For this
    each bar is given an integer value corresponding to its position relative to
    the given `positions`. E.g. with `positions = [1, 1, 1, 2, 2, 2]` we have
    3 bars at each position which can be separated by `dodge = [1, 2, 3, 1, 2, 3]`.
    """
    dodge = automatic
    """
    Sets the maximum integer for `dodge`. This sets how many bars can be placed
    at a given position, controlling their width.
    """
    n_dodge = automatic
    """
    The final width of the bars is calculated as `w * (1 - gap)` where `w` is the width of each bar
    as determined with the `width` attribute. When `dodge` is used the `w` corresponds to the width
    of undodged bars, making this control the gap between groups.
    """
    gap = 0.2
    """
    Sets the gap between dodged bars relative to their size. Can be a single
    number or `n_dodge - 1` numbers to indicate a different gap between
    each dodged element.
    """
    dodge_gap = 0.03
    """
    Similar to `dodge`, this allows bars at the same `positions` to be stacked
    by identifying their stack position with integers. E.g. with
    `positions = [1, 1, 1, 2, 2, 2]` each group of 3 bars can be stacked with
    `stack = [1, 2, 3, 1, 2, 3]`.
    """
    stack = automatic
    "Sets the outline linewidth of bars."
    strokewidth = @inherit patchstrokewidth
    "Sets the outline color of bars."
    strokecolor = @inherit patchstrokecolor
    """
    The gapless width of the bars. If `automatic`, the width `w` is calculated as
    `minimum(diff(sort(unique(positions)))`. The actual width of the bars is calculated as
    `w * (1 - gap)`. When `dodge` is specified, width can be a vector of values, specifying
    the relative width times the total width of each bar in the dodge group: i.e. the total
    width of a dodged group of bars will be `mean(width)`.
    """
    width = automatic
    """
    Controls the direction of the bars. can be `:y` (`height` is vertical) or
    `:x` (`height` is horizontal).
    """
    direction = :y
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color => :patchcolor]
    "Labels added at the end of each bar."
    bar_labels = nothing
    "Sets a `height` value beyond which labels are drawn inside the bar instead of outside."
    flip_labels_at = Inf
    "Sets the text rotation of labels in radians."
    label_rotation = 0π
    "Sets the color of labels."
    label_color = @inherit textcolor
    "Sets the color of labels that are drawn outside of bars. Defaults to `label_color`"
    color_over_background = automatic
    "Sets the color of labels that are drawn inside of/over bars. Defaults to `label_color`"
    color_over_bar = automatic
    "The distance of the labels from the bar ends in screen units. Does not apply when `label_position = :center`."
    label_offset = 5
    "The font of the bar labels."
    label_font = @inherit font
    "The font size of the bar labels."
    label_size = @inherit fontsize
    "Formatting function which is applied to bar labels before they are passed on `text()`"
    label_formatter = bar_label_formatter
    "Sets the text alignment of labels."
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

"""
    compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)

Compute the x positions and widths of a set of elements when using dodge groups. A dodge
group is used to visualize separate elements in the "same" x position. Each dodge group is
offset by a different value from this central, shared x position.

This function is called internally by `boxplot`, `violin`, `barplot` and others. It is not
intended to be used directly by users of Makie but rather for those implementing plot
recipes with a "categorical" x-axis type which aims to support a `dodge` keyword.

## Arguments

- `x` a vector of all x positions of the elements
- `width` the width of elements (in the same units as `x`). Can be `automatic`, one number,
  a vector of length `n_dodge` to indicate the width of each dodge element separately or a
  vector of length `length(x)`. When `length(width) == length(x)` it is expected that dodge
  elements will all be left unspecified. The intended use case is for
  internal calls to a lower level plot function *after* calling `compute_x_and_width` for
  the high-level plot; in this case the low-level plot will be calling `compute_x_and_width`
  on the precomputed x and width values returned by the first call to `compute_x_and_width`.
- `gap`: a number indicating the relative gap size to place between elements (1: entire
  width of elements, 0: no gap) or `automatic`
- `dodge`: the index of the dodge group for each element or `automatic` (implies 1 dodge
  group)
- `n_dodge`: the number of dodge groups; `automatic` defaults to `maximum(dodge)`
- `dodge_gap`: the relative gap between dodge groups; this can `automatic`, one number or
  `n_dodge - 1` numbers to indicate the gap between *each* dodge group. Defaults a gap of
  0.03

## Result

A tuple with the `x` position and `width` of each element in `x`.
"""
function compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)
    width === automatic && (width = 1)
    i_dodge = resolve_dodge(dodge)
    n_dodge = resolve_n_dodge(n_dodge, i_dodge, dodge_gap)
    if length(width) == length(x)
        if n_dodge > 1
            throw(ArgumentError(
                "Cannot specify dodge groups when `width` has the same length as `x`"
            ))
        end
        result = compute_x_and_width_helper.(x, width, i_dodge, n_dodge, dodge_gap)
        return first.(result), last.(result)
    elseif length(width) == n_dodge || length(width) == 1
        dodge_gap = resolve_dodge_gap(width, dodge_gap)
        width = resolve_width(width, gap, dodge_gap)
        return compute_x_and_width_helper(x, width, i_dodge, n_dodge, dodge_gap)
    else
        throw(ArgumentError(
            "`length(width)` must be equal to 1, `n_dodge` or `length(x)`"
        ))
    end
end

function resolve_dodge(dodge)
    if dodge === automatic
        return 1
    elseif eltype(dodge) <: Integer
        if any(<(1), dodge)
            throw(ArgumentError("Dodge values should be integers > 0"))
        end
        return dodge
    else
        throw(ArgumentError(
            "The keyword argument `dodge` currently supports only " * "`AbstractVector{<: Integer}`"
        ))
    end
    return dodge
end

function resolve_n_dodge(n_dodge, i_dodge, dodge_gap)
    if n_dodge === automatic
        if dodge_gap == automatic
            n_dodge = 1
            if i_dodge > 1
                throw(ArgumentError("You must specify `n_dodge` or `dodge_gap` to "*
                                    "have a dodge index greater than 1"))
            end
        elseif dodge_gap isa Number
            n_dodge = maximum(i_dodge)
        else
            n_dodge = length(dodge_gap) + 1
        end
    end

    if !(dodge_gap isa Number) && length(dodge_gap) != (n_dodge - 1)
        throw(
            ArgumentError(
                "The keyword argument `dodge_gap` must have a length " *
                "of `n_dodge - 1` or it must be a number. There is one " *
                "less gap between elements as there are elements.",
            ),
        )
    end

    return n_dodge
end

function resolve_dodge_gap(width, dodge_gap)
    if dodge_gap === automatic
        return 0.03
    end

    if width === automatic
        return dodge_gap
    end

    if !(width isa Number) && !(dodge_gap isa Number)
        if length(width) - 1 != length(dodge_gap)
            throw(
                ArgumentError(
                    "When there are multiple values for `dodge_gap`, the `width` " *
                    "argument must be a single number or `length(width) == " *
                    "length(dodge_gap) + 1`. There is one less gap between elements as " *
                    "there are elements.",
                ),
            )
        end
        return dodge_gap
    end

    if !(width isa Number)
        return fill(dodge_gap, length(width) - 1)
    end

    return dodge_gap
end

function resolve_width(width, gap, dodge_gap)
    width = width .* (1 - gap)

    if dodge_gap isa Number
        return width
    elseif width isa Number
        return fill(width, length(dodge_gap) + 1)
    else
        return width
    end
end

# dodge_gap and width as scalars
function compute_x_and_width_helper(x, width::Number, i_dodge, n_dodge, dodge_gap::Number)
    dodge_width = scale_width(dodge_gap, n_dodge)
    shifts = shift_dodge.(i_dodge, dodge_width, dodge_gap)
    return x .+ width .* shifts, width * dodge_width
end

scale_width(dodge_gap, n_dodge) = (1 - (n_dodge - 1) * dodge_gap) / n_dodge

function shift_dodge(i, dodge_width, dodge_gap)
    return (dodge_width - 1) / 2 + (i - 1) * (dodge_width + dodge_gap)
end

# dodge_gap and width as vectors (1 element per dodge index)
function compute_x_and_width_helper(x, width, i_dodge, n_dodge, dodge_gap)
    # invariant enforced above: length(width) !== length(dodge_gap) - 1

    # `space_for_element` determines how much room there is for the plot element once after
    # accounting for gaps. It plays the same role that `(1 - (n_dodge - 1) * dodge_gap)`
    # plays in the scalar case.
    space_for_element = (1 - (sum(dodge_gap))) / n_dodge
    gap_scale = mean(width)
    # NOTE: to keep the meaning of `dodge_gap` values constant across a specified array, the
    # *effect* of each `dodge_gap` is not proportional to individual bar widths (since those
    # are also potentially variable) but rather to the total space allotted to gaps
    # (`sum(dodge_gap)`).

    # `width_shifts` determines how far we need to move on the x-axis to get to the nth
    # element's center. This plays the same role that `width * (i - 1) * (dodge_width +
    # dodge_gap)` plays for the scalar case. To find the nth bar's center we need the width
    # of the last bar (weight[i-1]), the gap between that bar and this bar (dodge_gap[i-1]),
    # and the width of the current bar (weight[i])
    width_shifts = cumsum(
        width[i - 1] * 0.5space_for_element +
            dodge_gap[i - 1] * gap_scale +
            width[i] * 0.5space_for_element
         for i in 2:n_dodge)

    # `half_width` plays the same role that `width * (dodge_width - 1) / 2` plays for the
    # the scalar case. It is used to center the dodged elements.
    half_width = width_shifts[end]/2

    el_width = getindex.(Ref(width), i_dodge) .* space_for_element
    el_width_shift = map(i_dodge) do i
        # compare to `shift_dodge` implementation above
        get(width_shifts, i - 1, 0.0) - half_width
    end

    x.+el_width_shift
    el_width
    return x .+ el_width_shift, el_width
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
