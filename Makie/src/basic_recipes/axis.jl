module Formatters
    using Showoff

    function scientific(ticks::AbstractVector)
        return Showoff.showoff(ticks, :scientific)
    end

    function plain(ticks::AbstractVector)
        return try
            Showoff.showoff(ticks, :plain)
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
    $(SIGNATURES)

Plots a 3-dimensional OldAxis.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Axis3D) do scene

    q1 = qrotation(Vec3f(1, 0, 0), -0.5f0 * pi)
    q2 = qrotation(Vec3f(0, 0, 1), 1.0f0 * pi)
    tickrotations3d = (
        qrotation(Vec3f(0, 0, 1), -1.5pi),
        q2,
        qrotation(Vec3f(1, 0, 0), -0.5pi) * q2,
    )
    axisnames_rotation3d = tickrotations3d
    tickalign3d = (
        (:left, :center), # x axis
        (:right, :center), # y axis
        (:right, :center), # z axis
    )
    axisnames_align3d = tickalign3d
    tick_color = RGBAf(0.5, 0.5, 0.5, 0.6)
    grid_color = RGBAf(0.5, 0.5, 0.5, 0.4)
    grid_thickness = 1
    axis_linewidth = 1.5
    gridthickness = ntuple(x -> 1.0f0, Val(3))
    axislinewidth = ntuple(x -> 1.5f0, Val(3))
    tsize = 5 # in percent
    return Attributes(
        visible = true,
        showticks = (true, true, true),
        showaxis = (true, true, true),
        showgrid = (true, true, true),
        scale = Vec3f(1),
        padding = 0.1,
        inspectable = false,
        clip_planes = Plane3f[],
        fonts = theme(scene, :fonts),
        names = Attributes(
            axisnames = ("x", "y", "z"),
            textcolor = (:black, :black, :black),
            rotation = axisnames_rotation3d,
            fontsize = (6.0, 6.0, 6.0),
            align = axisnames_align3d,
            font = lift(to_3tuple, theme(scene, :font)),
            gap = 3
        ),

        ticks = Attributes(
            ranges_labels = (automatic, automatic),
            formatter = Formatters.plain,

            textcolor = (tick_color, tick_color, tick_color),

            rotation = tickrotations3d,
            fontsize = (tsize, tsize, tsize),
            align = tickalign3d,
            gap = 3,
            font = lift(to_3tuple, theme(scene, :font)),
        ),

        frame = Attributes(
            linecolor = (grid_color, grid_color, grid_color),
            linewidth = (grid_thickness, grid_thickness, grid_thickness),
            axislinewidth = (axis_linewidth, axis_linewidth, axis_linewidth),
            axiscolor = (:black, :black, :black),
        )
    )
end

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
        return 0.01 * widths(lims) .* fontsize
    end
    map!(attr, [:padded_limits, attr.names.fontsize], :axisnames_fontsize) do lims, fontsize
        return 0.01 * widths(lims) .* fontsize
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
            attr.names.align, attr.names.font, :scene_scale
        ],
        [:text_positions, :text_strings, :text_color, :text_rotation, :text_fontsize, :text_align, :text_font]
    ) do lims, showticks, ranges, tgap, ticklabels, axisnames, fonts, tfont,
        tfontsize, titlegap, ttextcolor, trotation, talign,
        axisnames_size, axisnames_color, axisrotation, axisalign, axisnames_font, scale

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
            if showticks[i]
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
                            push!(color, to_color(ttextcolor[i]))
                            push!(rotation, trotation[i])
                            push!(fontsize, tfontsize[i])
                            push!(align, talign[i])
                            push!(font_buffer, to_font(fonts, tfont[i]))
                        end
                    end
                end

                if !isempty(axisnames[i])
                    font = to_font(fonts, tfont[i])
                    tick_widths = maximum(ticklabels[i]) do label
                        widths(text_bb(label, font, tfontsize[i]))[1]
                    end / scale[j]
                    pos = labelposition(ranges, i, tickdir, titlegap[i] + tick_widths, origin) .+ offset2
                    push!(textbuffer, UnicodeFun.to_latex(axisnames[i]))
                    push!(positionbuffer, pos)
                    push!(fontsize, axisnames_size[i])
                    push!(color, to_color(axisnames_color[i]))
                    push!(rotation, axisrotation[i])
                    push!(align, axisalign[i])
                    push!(font_buffer, to_font(fonts, axisnames_font[i]))
                end
            end
        end

        return positionbuffer, textbuffer, color, rotation, fontsize, align, font_buffer
    end

    text!(
        plot, plot.text_positions, text = plot.text_strings, color = plot.text_color,
        rotation = plot.text_rotation, fontsize = plot.text_fontsize,
        align = plot.text_align, font = plot.text_font,
        transparency = true, markerspace = :data, inspectable = plot.inspectable,
        visible = plot.visible
    )

    # TODO: linesegments
    map!(
        attr,
        [
            :padded_limits, :showaxis, :showgrid, :ranges,
            attr.frame.axiscolor, attr.frame.axislinewidth,
            attr.frame.linecolor, attr.frame.linewidth
        ],
        [:line_positions, :line_colors, :line_widths]
    ) do lims, showaxis, showgrid, ranges, axiscolors, axislinewidth, gridcolors, gridthickness

        limit_widths = widths(lims)
        origin = minimum(lims)

        position_buffer = Point3f[]
        color = RGBAf[]
        linewidth = Float32[]

        for i in 1:N
            axis_vec = GeometryBasics.unit(Point{N, Float32}, i)
            width = Float32(limit_widths[i])
            stop = origin .+ (width .* axis_vec)

            if showaxis[i]
                push!(position_buffer, origin, stop)
                push!(color, to_color(axiscolors[i]))
                push!(linewidth, axislinewidth[i])
            end

            if showgrid[i]
                c = gridcolors[i]
                thickness = gridthickness[i]
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
    return axis3d!(scene, Attributes(), lims; ticks = (ranges = automatic, labels = automatic), kw...)
end
