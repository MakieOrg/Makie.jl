
function labelposition(ranges, dim)
    a, b = extrema(ranges[dim])
    pos = Float32(((b - a) / 2) + a)
    axis_vec = unit(Point{N, Float32}, dim)
    normal = unit(Point{N, Float32}, mod1(dim + 1, 3))
    pos .* axis_vec .- (normal * 0.2f0)
end


function GeometryTypes.widths(x::Range)
    mini, maxi = Float32.(extrema(x))
    maxi - mini
end



function draw_axis(
        textbuffer::TextBuffer{N}, linebuffer, ranges,
        axisnames, visible, showaxis, showticks, showgrid,
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
        nametext = axisnames[i]
        # if !isempty(first(nametext))
        #     pos = labelposition(ranges, i)
        #     printat(textio, startpos, nametext...)
        # end
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
        :axisnames, :visible, :showaxis, :showticks,
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
