module Formatters
    import ..Makie: format_ticks_plain, format_ticks_scientific_string

    scientific(ticks::AbstractVector) = format_ticks_scientific_string(ticks)

    function plain(ticks::AbstractVector)
        return try
            format_ticks_plain(ticks; minus_sign = false)
        catch e
            bt = Base.catch_backtrace()
            Base.showerror(stderr, e)
            Base.show_backtrace(stdout, bt)
            println("with ticks: ", ticks)
            String["-Inf", "Inf"]
        end
    end

end
using .Formatters


to_3tuple(x) = ntuple(i -> x, Val(3))
to_3tuple(x::NTuple{3, Any}) = x

to_2tuple(x) = ntuple(i -> x, Val(2))
to_2tuple(x::NTuple{2, Any}) = x

"""
Plots a 3-dimensional OldAxis.
"""
@recipe Axis3D begin
    "Controls the visibility of the axis as whole."
    visible = true
    "Controls the visibility of (x, y, z) ticks."
    showticks = (true, true, true)
    "Controls the visibility of axis (x, y, z) axis lines."
    showaxis = (true, true, true)
    "Controls the visibility of axis (x, y, z) axis grids."
    showgrid = (true, true, true)
    # scale = Vec3f(1) unused?
    "Sets the fractional padding for the axis relative to the current limits."
    padding = 0.1
    "Sets whether the axis can be picked by DataInspector"
    inspectable = false
    clip_planes = Plane3f[]
    "Sets the font name lookup for the axis. This sets what :regular, :bold, etc. lowers to."
    fonts = @inherit :fonts
    "The text handler used to lay out the axis labels, see `text`."
    text_handler = @inherit text_handler

    "Controls the displayed axis labels."
    names = @attributes begin
        "Sets the displayed strings for (x, y, z) axis labels."
        axisnames = ("x", "y", "z")
        "Sets the color for the (x, y, z) axis labels"
        textcolor = (:black, :black, :black)
        "Sets the rotation of the (x, y, z) axis label. The starting orientation uses +y as up and +x as right."
        rotation = (
            qrotation(Vec3f(0, 0, 1), -1.5pi),
            qrotation(Vec3f(0, 0, 1), 1.0f0 * pi),
            qrotation(Vec3f(1, 0, 0), -0.5pi) * qrotation(Vec3f(0, 0, 1), 1.0f0 * pi),
        )
        "Sets the fontsize of (x, y, z) axis labels as a percentage of (padded) limits"
        fontsize = (6.0, 6.0, 6.0)
        "Sets the alignment of (x, y, z) axis labels"
        align = (
            (:left, :center), # x axis
            (:right, :center), # y axis
            (:right, :center), # z axis
        )
        "Sets the font used for all axis labels"
        font = @inherit :font
        "Sets the gap between ticks and axis labels as a percentage of (padded) axis limits."
        gap = 3
    end

    "Controls the displayed tick labels"
    ticks = @attributes begin
        """
        Sets the positions of (x, y, z) ticks as an iterable of absolute values. E.g.
        ((0, 5, 10), 0:10:30, [1,2,3]). This also sets the grid positions.
        """
        ranges = automatic
        "Sets the labels of (x, y, z) ticks as an iterable corresponding to `ranges`. E.g. ((\"0\", \"5\", \"10\"), string.(0:10:30), [\"1\", \"2\", \"3\"])."
        labels = automatic
        """
        Sets the string formatter for ticks. This is used for formatting default tick labels.
        Can be `Makie.Formatters.plain`, `Makie.Formatters.scientific` or a callback `format(::Vector{<:Real})` producing strings.
        """
        formatter = Formatters.plain
        "Sets the color of (x, y, z) tick labels"
        textcolor = (RGBAf(0.5, 0.5, 0.5, 0.6), RGBAf(0.5, 0.5, 0.5, 0.6), RGBAf(0.5, 0.5, 0.5, 0.6))
        "Sets the rotation fo (x, y, z) tick labels. The starting orientation uses +y as up and +x as right."
        rotation = (
            qrotation(Vec3f(0, 0, 1), -1.5pi),
            qrotation(Vec3f(0, 0, 1), 1.0f0 * pi),
            qrotation(Vec3f(1, 0, 0), -0.5pi) * qrotation(Vec3f(0, 0, 1), 1.0f0 * pi),
        )
        "Sets the fontsize of (x, y, z) tick labels as a percentage of (padded) tick labels"
        fontsize = (5, 5, 5)
        "Sets the align of tick labels"
        align = (
            (:left, :center), # x axis
            (:right, :center), # y axis
            (:right, :center), # z axis
        )
        "Sets the gap between the axis frame and ticks as a percentage of the (padded) limits"
        gap = 3
        "Sets the font of axis ticks."
        font = @inherit :font
    end

    "Controls the displayed axis frame and grid"
    frame = @attributes begin
        "Sets the color of the (x, y, z) grid lines"
        linecolor = (RGBAf(0.5, 0.5, 0.5, 0.4), RGBAf(0.5, 0.5, 0.5, 0.4), RGBAf(0.5, 0.5, 0.5, 0.4))
        "Sets the linewidth of the (x, y, z) grid lines"
        linewidth = (1.0f0, 1.0f0, 1.0f0)
        "Sets the linewidth of the (x, y, z) frame line"
        axislinewidth = (1.5f0, 1.5f0, 1.5f0)
        "Sets the color of the (x, y, z) frame line"
        axiscolor = (:black, :black, :black)
    end
end

argument_dim_kwargs(::Type{<:Axis3D}) = tuple()
argument_dims(::Type{<:Axis3D}, args...) = nothing

isaxis(x) = false
isaxis(x::Axis3D) = true

const Limits{N} = NTuple{N, <:Tuple{<:Number, <:Number}}

function default_ticks(limits::Limits, ticks, scale_func::Function)
    return default_ticks.(limits, (ticks,), scale_func)
end

default_ticks(limits::Tuple{Number, Number}, ticks, scale_func::Function) = default_ticks(limits..., ticks, scale_func)

function default_ticks(
        lmin::Number, lmax::Number,
        ticks::AbstractVector{<:Number}, scale_func::Function
    )
    return scale_func.((filter(t -> lmin <= t <= lmax, ticks)))
end

function default_ticks(
        lmin::Number, lmax::Number, ::Automatic, scale_func::Function
    )
    # scale the limits
    scaled_ticks, mini, maxi = optimize_ticks(
        Float64(scale_func(lmin)),
        Float64(scale_func(lmax));
        k_min = 4, # minimum number of ticks
        k_max = 8, # maximum number of ticks
    )
    length(scaled_ticks) == 1 && isnan(scaled_ticks[1]) && return [-Inf, Inf]
    return scaled_ticks
end

function default_ticks(
        lmin::Number, lmax::Number, ticks::Integer, scale_func = identity
    )
    scaled_ticks, mini, maxi = optimize_ticks(
        Float64(scale_func(lmin)),
        Float64(scale_func(lmax));
        k_min = ticks, # minimum number of ticks
        k_max = ticks, # maximum number of ticks
        k_ideal = ticks,
        # `strict_span = false` rewards cases where the span of the
        # chosen  ticks is not too much bigger than amin - amax:
        strict_span = false,
    )
    return scaled_ticks
end

function default_ticks(x::Automatic, limits::Tuple, n)
    return default_ticks(limits, n, identity)
end

function default_ticks(ticks::Tuple, limits::Tuple, n::Tuple)
    return default_ticks.(ticks, (limits,), n)
end

default_ticks(ticks::Tuple, limits::Limits, n) = default_ticks.(ticks, limits, (n,))

default_ticks(ticks::Tuple, limits::Limits, n::Tuple) = default_ticks.(ticks, limits, n)

default_ticks(ticks::AbstractVector{<:Number}, limits, n) = ticks


function default_labels(x::NTuple{N, Any}, formatter::Function) where {N}
    return default_labels.(x, formatter)
end

function default_labels(x::AbstractVector, y::AbstractVector, formatter::Function = Formatters.plain)
    return default_labels.((x, y), formatter)
end

function default_labels(ticks::AbstractVector, formatter::Function = Formatters.plain)
    if applicable(formatter, ticks)
        return formatter(ticks) # takes the whole array
    elseif applicable(formatter, first(ticks))
        return formatter.(ticks)
    else
        error("Formatting function $(formatter) is neither applicable to $(typeof(ticks)) nor $(eltype(ticks)).")
    end
end

default_labels(x::Automatic, ranges, formatter) = default_labels(ranges, formatter)
default_labels(x::Tuple, ranges::Tuple, formatter) = default_labels.(x, ranges, (formatter,))
default_labels(x::Tuple, ranges, formatter) = default_labels.(x, (ranges,), (formatter,))
default_labels(x::AbstractVector{<:AbstractString}, ranges, formatter::Function) = x
default_labels(x::AbstractVector{<:AbstractString}, ranges::AbstractVector, formatter::Function) = x

function convert_arguments(::Type{<:Axis3D}, limits::Rect)
    e = (minimum(limits), maximum(limits))
    return (((e[1][1], e[2][1]), (e[1][2], e[2][2]), (e[1][3], e[2][3])),)
end

a_length(x::AbstractVector) = length(x)
a_length(x::Automatic) = x

function calculated_attributes!(::Type{<:Axis3D}, plot)
    ticks = plot.ticks
    # TODO: Should this look at ranges_labels? Or should those be removed?
    args = [plot[1], ticks.ranges, ticks.labels, ticks.formatter]
    map!(plot.attributes, args, [:ranges, :labels]) do lims, ranges, labels, formatter
        num_ticks = labels === automatic ? automatic : a_length.(labels)
        ranges = default_ticks(ranges, lims, num_ticks)
        labels = default_labels(labels, ranges, formatter)
        return ranges, labels
    end
    return
end

function labelposition(ranges, dim, dir, tgap, origin::StaticVector{N}) where {N}
    a, b = extrema(ranges[dim])
    whalf = Float32(((b - a) / 2))
    halfaxis = GeometryBasics.unit(Point{N, Float32}, dim) .* whalf

    return origin .+ (halfaxis .+ (normalize(dir) * tgap))
end

_widths(x::Tuple{<:Number, <:Number}) = x[2] - x[1]
_widths(x) = Float32(maximum(x) - minimum(x))

to3tuple(x::Tuple{Any}) = (x[1], x[1], x[1])
to3tuple(x::Tuple{Any, Any}) = (x[1], x[2], x[2])
to3tuple(x::Tuple{Any, Any, Any}) = x
to3tuple(x) = ntuple(i -> x, Val(3))

"""
    svtuple_getindex(x, idx)

Like `sv_getindex(x, idx)` but treats VecTypes as an indexable collection.
"""
svtuple_getindex(x::VecTypes, idx) = x[idx]
svtuple_getindex(x, idx) = sv_getindex(x, idx)

function draw_axis3d(plot)
    attr = plot.attributes::ComputeGraph
    ComputePipeline.alias!(attr, :converted_1, :limits)

    map!(attr, [:limits, :padding], :padded_widths) do lim, padding
        return padding .* (last.(lim) .- first.(lim))
    end
    map!(attr, [:limits, :ranges, :padding], :padded_limits) do lim, ranges, padding
        mini = first.(lim)
        maxi = last.(lim)
        pad = padding .* (maxi .- mini)
        mini = min.(mini .- pad, first.(ranges))
        maxi = max.(maxi .+ pad, last.(ranges))
        return Rect3f(mini, maxi .- mini)
    end

    map!(attr, [:padded_limits, attr.ticks.fontsize], :tickfontsize) do lims, fontsize
        return to3tuple(0.01 * minimum(widths(lims)) .* fontsize)
    end
    map!(attr, [:padded_limits, attr.names.fontsize], :axisnames_fontsize) do lims, fontsize
        return to3tuple(0.01 * minimum(widths(lims)) .* fontsize)
    end

    N = 3
    offset_indices = Vec(ntuple(i -> ifelse(i != 2, mod1(i + 1, N), 1), N))

    # index of the direction in which ticks and labels are drawn
    # These need the real limits, not (%), to be scale-aware
    map!(attr, [:padded_limits, attr.names.gap], :titlegap) do lims, gap
        return 0.01 * widths(lims)[offset_indices] .* gap
    end
    map!(attr, [:padded_limits, attr.ticks.gap], :tickgap) do lims, gap
        return 0.01 * widths(lims)[offset_indices] .* gap
    end

    add_input!(attr, :scene_scale, scale(parent_scene(plot)))

    map!(
        attr,
        [
            :padded_limits, :showticks, :ranges, :tickgap, :labels, attr.names.axisnames,
            :fonts, attr.ticks.font, :tickfontsize, :titlegap, attr.ticks.textcolor,
            attr.ticks.rotation, attr.ticks.align,
            :axisnames_fontsize, attr.names.textcolor, attr.names.rotation,
            attr.names.align, attr.names.font, :scene_scale, :text_handler,
        ],
        [:text_positions, :text_strings, :text_color, :text_rotation, :text_fontsize, :text_align, :text_font]
    ) do lims, showticks, ranges, tgap, ticklabels, axisnames,
            fonts, tfont, tfontsize, titlegap, ttextcolor,
            trotation, talign,
            axisnames_size, axisnames_color, axisrotation,
            axisalign, axisnames_font, scale, text_handler

        positionbuffer = Point3f[]
        textbuffer = String[]
        color = RGBAf[]
        rotation = Quaternionf[]
        fontsize = Float32[]
        align = Tuple{Symbol, Symbol}[]
        font_buffer = FTFont[]

        origin = minimum(lims)
        limit_widths = widths(lims)

        for i in 1:N
            axis_vec = GeometryBasics.unit(Point{N, Float32}, i)
            width = Float32(limit_widths[i])
            if svtuple_getindex(showticks, i)
                range = ranges[i]
                j = offset_indices[i]
                tickdir = GeometryBasics.unit(Vec{N, Float32}, j)
                offset2 = Float32(limit_widths[j] + tgap[i]) * tickdir
                for (j, tick) in enumerate(range)
                    labels = ticklabels[i]
                    if length(labels) >= j
                        str = labels[j]
                        if !isempty(str)
                            startpos = (origin .+ ((Float32(tick - origin[i]) * axis_vec)) .+ offset2)
                            push!(textbuffer, str)
                            push!(positionbuffer, startpos)
                            push!(color, to_color(svtuple_getindex(ttextcolor, i)))
                            push!(rotation, svtuple_getindex(trotation, i))
                            push!(fontsize, svtuple_getindex(tfontsize, i))
                            push!(align, svtuple_getindex(talign, i))
                            push!(font_buffer, to_font(fonts, svtuple_getindex(tfont, i)))
                        end
                    end
                end

                if !isempty(svtuple_getindex(axisnames, i))
                    font = to_font(fonts, svtuple_getindex(tfont, i))
                    attrs = TextAttributes(; font, fonts, fontsize = tfontsize[i])
                    tick_widths = maximum(ticklabels[i]) do label
                        widths(layout_text(text_handler, label, attrs).bbox)[1]
                    end / scale[j]
                    pos = labelposition(ranges, i, tickdir, titlegap[i] + tick_widths, origin) .+ offset2
                    push!(textbuffer, UnicodeFun.to_latex(svtuple_getindex(axisnames, i)))
                    push!(positionbuffer, pos)
                    push!(fontsize, svtuple_getindex(axisnames_size, i))
                    push!(color, to_color(svtuple_getindex(axisnames_color, i)))
                    push!(rotation, svtuple_getindex(axisrotation, i))
                    push!(align, svtuple_getindex(axisalign, i))
                    push!(font_buffer, to_font(fonts, svtuple_getindex(axisnames_font, i)))
                end
            end
        end

        return positionbuffer, textbuffer, color, rotation, fontsize, align, font_buffer
    end

    text!(
        plot, plot.text_positions, text = plot.text_strings, color = plot.text_color,
        rotation = plot.text_rotation, fontsize = plot.text_fontsize,
        align = plot.text_align, font = plot.text_font, text_handler = plot.text_handler,
        transparency = true, markerspace = :data, inspectable = plot.inspectable,
        visible = plot.visible
    )

    map!(
        attr,
        [
            :padded_limits, :showaxis, :showgrid, :ranges,
            attr.frame.axiscolor, attr.frame.axislinewidth,
            attr.frame.linecolor, attr.frame.linewidth,
        ],
        [:line_positions, :line_colors, :line_widths]
    ) do lims, showaxis, showgrid, ranges,
            axiscolors, axislinewidth,
            gridcolors, gridthickness

        limit_widths = widths(lims)
        origin = minimum(lims)

        position_buffer = Point3f[]
        color = RGBAf[]
        linewidth = Float32[]

        for i in 1:N
            axis_vec = GeometryBasics.unit(Point{N, Float32}, i)
            width = Float32(limit_widths[i])
            stop = origin .+ (width .* axis_vec)

            if svtuple_getindex(showaxis, i)
                push!(position_buffer, origin, stop)
                push!(color, to_color(svtuple_getindex(axiscolors, i)))
                push!(linewidth, svtuple_getindex(axislinewidth, i))
            end

            if svtuple_getindex(showgrid, i)
                c = svtuple_getindex(gridcolors, i)
                thickness = svtuple_getindex(gridthickness, i)
                for _j in (i + 1):(i + N - 1)
                    j = mod1(_j, N)
                    dir = GeometryBasics.unit(Point{N, Float32}, j)
                    range = ranges[j]
                    for tick in range
                        offset = Float32(tick - origin[j]) * dir
                        push!(position_buffer, origin .+ offset, stop .+ offset)
                        push!(color, to_color(c))
                        push!(linewidth, thickness)
                    end
                end
            end
        end

        return position_buffer, color, linewidth
    end

    linesegments!(
        plot, plot.line_positions, color = plot.line_colors, linewidth = plot.line_widths,
        transparency = true, inspectable = plot.inspectable, visible = plot.visible
    )
    return
end

function plot!(axis::Axis3D)
    # Disable any non linear transform for the axis plot!
    axis.transformation.transform_func[] = identity
    draw_axis3d(axis)
    return axis
end


function axis3d!(scene::Scene, lims = boundingbox(scene, p -> isaxis(p) || not_in_data_space(p)); kw...)
    return axis3d!(scene, Attributes(), lims; kw...)
end
