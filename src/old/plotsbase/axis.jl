
function labelposition(ranges, dim, dir, origin::StaticVector{3})
    a, b = extrema(ranges[dim])
    whalf = Float32(((b - a) / 2))
    halfaxis = unit(Point{3, Float32}, dim) .* whalf

    origin .+ (halfaxis .+ (dir * (whalf / 3f0)))
end

function labelposition(ranges, dim, dir, origin::StaticVector{2})
    a, b = extrema(ranges[dim])
    whalf = Float32(((b - a) / 2))
    halfaxis = unit(Point{2, Float32}, dim) .* whalf
    origin .+ (halfaxis .- (dir * (whalf / 2f0)))
end

function GeometryTypes.widths(x::Range)
    mini, maxi = Float32.(extrema(x))
    maxi - mini
end

function standard_ticks(range)
    str = sprint(io-> print(io, round(tick, 2)))
end
#

#
# # return (continuous_values, discrete_values) for the ticks on this axis
# function get_ticks(axis::Axis)
#     ticks = _transform_ticks(axis[:ticks])
#     ticks in (nothing, false) && return nothing
#
#     dvals = axis[:discrete_values]
#     cv, dv = if !isempty(dvals) && ticks == :auto
#         # discrete ticks...
#         axis[:continuous_values], dvals
#     elseif ticks == :auto
#         # compute optimal ticks and labels
#         optimal_ticks_and_labels(axis)
#     elseif typeof(ticks) <: Union{AVec, Int}
#         # override ticks, but get the labels
#         optimal_ticks_and_labels(axis, ticks)
#     elseif typeof(ticks) <: NTuple{2, Any}
#         # assuming we're passed (ticks, labels)
#         ticks
#     else
#         error("Unknown ticks type in get_ticks: $(typeof(ticks))")
#     end
#     # @show ticks dvals cv dv
#
#     # TODO: better/smarter cutoff values for sampling ticks
#     if length(cv) > 30 && ticks == :auto
#         rng = Int[round(Int,i) for i in linspace(1, length(cv), 15)]
#         cv[rng], dv[rng]
#     else
#         cv, dv
#     end
# end



function draw_axis(show, textbuffer::TextBuffer{N}, linebuffer, framestyle) where N


end

function draw_grid(show, textbuffer::TextBuffer{N}, linebuffer, gridstyle) where N


end


function draw_titles(show, textbuffer::TextBuffer{N}, linebuffer, title_style) where N


end







function draw_axis(
        textbuffer::TextBuffer{N}, linebuffer, ranges,
        axisnames, axisnames_color, axisnames_size, axisnames_rotation_align, axisnames_font,
        visible, showaxis, showticks, showgrid,
        axiscolors, gridcolors, gridthickness, tickfont
    ) where N

    empty!(textbuffer); empty!(linebuffer)
    origin = Point{N, Float32}(map(minimum, ranges))
    is2d = N == 2 # sadly we need to special case on 2D case
    for i = 1:N
        axis_vec = unit(Point{N, Float32}, i)
        width = widths(ranges[i])
        stop = origin .+ (width .* axis_vec)
        if showaxis[i]
            append!(linebuffer, [origin, stop], axiscolors[i], 1.5f0)
        end
        if showticks[i]
            range = ranges[i]
            j = mod1(i + 1, N)
            tickdir = unit(Point{N, Float32}, j)
            tickdir, offset2 = if i != 2
                tickdir = unit(Vec{N, Float32}, j)
                tickdir, Float32(widths(ranges[j]) + 0.3f0) * tickdir
            else
                tickdir = unit(Vec{N, Float32}, 1)
                tickdir, Float32(widths(ranges[1]) + 0.3f0) * tickdir
            end
            if is2d
                offset2 = Vec2f0(0)
            end
            offset = -tickdir .* 0.1f0
            for tick in drop(range, 1)
                startpos = origin .+ ((Float32(tick - range[1]) * axis_vec) .+ offset) .+ offset2
                str = sprint(io-> print(io, round(tick, 2)))
                append!(textbuffer, startpos, str, tickfont[i]...)
            end
            if !isempty(axisnames[i])
                rot, align = axisnames_rotation_align[i]
                if N == 2
                    rot = (Vec4f0(0,0,0,1), qrotation(Vec3f0(0,0,1), -1.5pi))[i]
                    align = ((:center, :top), (:bottom, :center))[i]
                end
                pos = labelposition(ranges, i, tickdir, origin)# .+ offset2
                append!(
                    textbuffer, pos, to_latex(axisnames[i]),
                    axisnames_size[i], axisnames_color[i],
                    rot, align, axisnames_font
                )
            end
        end
        if showgrid[i]
            c = gridcolors[i]
            thickness = gridthickness[i]
            for _j = (i + 1):(i + N - 1)
                j = mod1(_j, N)
                dir = unit(Point{N, Float32}, j)
                range = ranges[j]
                for tick in drop(range, 1)
                    offset = Float32(tick - range[1]) * dir
                    append!(linebuffer, [origin .+ offset, stop .+ offset], c, thickness)
                end
            end
        end
    end
    return
end

function axis(scene::Scene, x, y, attributes::Dict)
    axis(scene, to_node((x, y)), attributes)
end

function axis(scene::Scene, x, y, z, attributes::Dict)
    axis(scene, to_node((x, y, z)), attributes)
end


function axis(scene::Scene, ranges::Node{<: NTuple{N}}, attributes::Dict) where N
    textbuffer = TextBuffer(Point{N, Float32}(0))
    linebuffer = LinesegmentBuffer(Point{N, Float32}(0))
    scene = get_global_scene()
    attributes = axis_defaults(scene, attributes)
    tickfont = N == 2 ? :tickfont2d : :tickfont3d
    names = (
        :axisnames, :axisnames_color, :axisnames_size, :axisnames_rotation_align, :axisnames_font, :visible, :showaxis, :showticks,
        :showgrid, :axiscolors, :gridcolors, :gridthickness, tickfont
    )
    args = getindex.(attributes, names)
    lift_node(
        draw_axis,
        to_node(textbuffer), to_node(linebuffer), ranges, args...
    )
    bb = to_signal(lift_node(ranges) do ranges
        mini, maxi = Vec{N, Float32}(map(minimum, ranges)), Vec{N, Float32}(map(maximum, ranges))
        mini3d, w = Vec3f0(to_nd(mini, Val{3}, 0f0)), Vec3f0(to_nd(maxi .- mini, Val{3}, 0f0))
        HyperRectangle(mini3d, w)
    end)
    linebuffer.robj.boundingbox = bb
    viz = Context(linebuffer.robj, textbuffer.robj)
    insert_scene!(scene, :axis, viz, attributes)
end
