bar_label_formatter(value::Number) = string(round(value; digits = 3))
bar_label_formatter(label::String) = label
bar_label_formatter(label::LaTeXString) = label

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
    "Sets the gap between dodged bars relative to the size of the dodged bars."
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
    The gapless width of the bars. If `automatic`, the width `w` is calculated as `minimum(diff(sort(unique(positions)))`.
    The actual width of the bars is calculated as `w * (1 - gap)`.
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

"""
    add_slow_limits!(plot)

Adds `slow_limits_transformed` to the plot.

These limits update when the real axis limits are no longer inside the slow
limits, or if the slow limits become more than 20000 times larger.
"""
function add_slow_limits!(plot::Plot)
    scene = parent_scene(plot)
    add_axis_limits!(plot)
    register_computation!(
        scene.compute, [:axis_limits_transformed], [:slow_limits_transformed]
    ) do (lims,), changed, cached
        ws = widths(lims)
        if isnothing(cached) || !(lims in cached[1]) || any(widths(cached[1]) .> 20000 .* ws)
            mini = minimum(lims)
            return (Rect2d(mini - 100ws, 201ws),)
        else
            return nothing
        end
    end
    add_input!(plot.attributes, :slow_limits_transformed, scene.compute.slow_limits_transformed)
end

function bar_rectangle(tf, x, y, offset, width, fillto, in_y_direction, lims)
    # y could be smaller than fillto...
    y += offset
    ymin = min(fillto, y)
    ymax = max(fillto, y)
    w = 0.5 * abs(width)

    # To deal with log transforms we apply the transform_func here and clamp
    # the result to a renderable range of values. Edge case problems:
    # - clamping to e.g. -floatmax(Float32) .. floatmax(Float32) breaks down
    #   when the visible area <<< than that range (maybe float issues in
    #   projectionview * position?)
    # - `Rect` can't deal with transformations that curve space (e.g. Polar)
    #    because it only stores the origin and widths
    # - `Rect` also has float precision issues due to calculating origin + widths
    # - to avoid running this excessively `lims` should update slowly (but always
    #   be larger than the real axis limits)
    minlim = minimum(lims)
    maxlim = maximum(lims)
    points = Point2d[(x - w, ymin), (x - w, ymax), (x + w, ymax), (x + w, ymin)]
    points = map(points) do point
        point = ifelse(in_y_direction, point, reverse(point))
        return clamp.(apply_transform(tf, point), minlim, maxlim)
    end

    return Polygon(points)
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
    map!(p, :direction, :in_y_direction) do dir
        return get((y = true, x = false), dir) do
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    map!(p, :positions, [:raw_x, :raw_y]) do xy
        return first.(xy), last.(xy)
    end

    # Bar width + dodge
    map!(
        p, [:raw_x, :width, :gap, :dodge, :n_dodge, :dodge_gap], [:x, :barwidth]
    ) do x, userwidth, gap, dodge, n_dodge, dodge_gap
        # by default, `width` is `minimum(diff(sort(unique(x)))`
        if userwidth === automatic
            x_unique = unique(filter(isfinite, x))
            x_diffs = diff(sort(x_unique))
            width = isempty(x_diffs) ? 1.0 : minimum(x_diffs)
        else
            width = userwidth
        end

        # compute width of bars and x̂ (horizontal position after dodging)
        return compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)
    end

    # stack
    map!(
        p, [:stack, :fillto, :x, :raw_y, :offset], [:y, :computed_fillto]
    ) do stack, fillto, x, y, offset
        if stack === automatic
            return y, ifelse(fillto === automatic, offset, fillto)
        elseif eltype(stack) <: Integer
            fillto === automatic || @warn "Ignore keyword fillto when keyword stack is provided"
            if !iszero(offset)
                @warn "Ignore keyword offset when keyword stack is provided"
                offset = 0.0
            end
            i_stack = stack

            from, to = stack_grouped_from_to(i_stack, y, (x = x,))
            return to, from
        else
            throw(ArgumentError("The keyword argument `stack` currently supports only `AbstractVector{<: Integer}`"))
        end
    end

    try
        add_slow_limits!(p)
    catch e
        # allow PolarAxis to not error
        add_input!(p.attributes, :slow_limits_transformed, Rect2d(-Inf, -Inf, Inf, Inf))
    end

    map!(
        p,
        [:x, :y, :offset, :barwidth, :computed_fillto, :in_y_direction, :transform_func, :slow_limits_transformed],
        :bar_rectangles
    ) do x, y, offset, barwidth, fillto, in_y_direction, transform_func, lims
        return bar_rectangle.(
            Ref(transform_func), x, y, offset, barwidth, fillto, in_y_direction, Ref(lims)
        )
    end

    # bar Labels
    map!(
        p,
        [
            :label_color, :color_over_background, :color_over_bar,
            :x, :y, :offset, :bar_labels, :in_y_direction, :flip_labels_at,
            :label_formatter, :label_offset, :label_rotation, :label_align,
            :label_position, :computed_fillto
        ],
        [:labels, :label_aligns, :label_offsets, :label_colors]
    ) do label_color, color_over_background, color_over_bar,
            x, y, offset, bar_labels, in_y_direction, flip_labels_at,
            label_formatter, label_offset, label_rotation, label_align,
            label_position, fillto

        if !isnothing(bar_labels)
            oback = default_automatic(color_over_background, label_color)
            obar = default_automatic(color_over_bar, label_color)
            return barplot_labels(
                x, y, offset, bar_labels, in_y_direction,
                flip_labels_at, to_color(oback), to_color(obar),
                label_formatter, label_offset, label_rotation, label_align, label_position, fillto
            )
        end
    end


    poly!(p, p.attributes, p.bar_rectangles, transformation = :inherit_model)

    if !isnothing(p.bar_labels[])
        text!(
            p, p.attributes, p.labels;
            align = p.label_aligns, offset = p.label_offsets, color = p.label_colors,
            font = p.label_font, fontsize = p.label_size, rotation = p.label_rotation,
            fxaa = false
        )
    end

    return p
end

function boundingbox(p::BarPlot, space::Symbol = :data)
    if is_identity_transform(p.transform_func[])
        x0 = minimum(p.x[] .- 0.5 .* p.barwidth[])
        x1 = maximum(p.x[] .+ 0.5 .* p.barwidth[])
        y0 = minimum(min.(p.y[] .+ p.offset[], p.computed_fillto[]))
        y1 = maximum(max.(p.y[] .+ p.offset[], p.computed_fillto[]))
        bb = Rect2d(x0, y0, x1 - x0, y1 - y0)
        bb = ifelse(p.in_y_direction[], bb, flip(bb))
    else
        # track the minimum and maximum of all bar vertices after tranform_func
        # For log axis we may get log(0) = -Inf from the default `fillto = 0`.
        # If we do, we use
        #   apply_transform(tf, 0.5 * minimum(ys + offset))
        # as the lower limit instead. (E.g. log(0.5 * min_bar_height))
        alt_ref = Point2d(Inf)
        maxi = Point2d(-Inf)
        mini = Point2d(Inf)
        tf = p.transform_func[]
        maybe_flip = p.in_y_direction[] ? identity : reverse
        broadcast_foreach(p.x[], p.barwidth[], p.y[], p.offset[], p.computed_fillto[]) do x, width, y, offset, fillto
            w = 0.5width
            ymin = min(y + offset, fillto)
            ymax = max(y + offset, fillto)
            p00 = apply_transform(tf, maybe_flip(Point2d(x - w, ymin)))
            p01 = apply_transform(tf, maybe_flip(Point2d(x - w, ymax)))
            p11 = apply_transform(tf, maybe_flip(Point2d(x + w, ymax)))
            p10 = apply_transform(tf, maybe_flip(Point2d(x + w, ymin)))
            mini = min.(mini, p00, p01, p11, p10)
            maxi = max.(maxi, p00, p01, p11, p10)
            alt_ref = min.(alt_ref, maybe_flip(Point2d(x - w, ymax)))
        end
        alt_mini = apply_transform(tf, 0.5 * alt_ref)
        mini = ifelse.(isfinite.(mini), mini, alt_mini)
        bb = Rect2d(mini, maxi .- mini)
    end
    return apply_model(transformationmatrix(p)[], Rect3d(bb))
end