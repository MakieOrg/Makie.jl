"""
Buffer one can easily insert/remove line segments from.
This is great for working with line data that is changing a lot with minimal
performanc impact. It's also great for batching draw calls, since you can
insert lines in different points of the program, and then draw it with a single
opengl draw call.
"""
struct LinesegmentBuffer{N}
    positions::GPUVector{Point{N, Float32}}
    colors::GPUVector{RGBAf0}
    thickness::GPUVector{Float32}
    robj::RenderObject
    range::Signal{Int}
end

function LinesegmentBuffer(pos::Point{N, <: AbstractFloat} = Point3f0(0)) where N
    positions = gpuvec(Point{N, Float32}[])
    colors = gpuvec(RGBAf0[])
    thickness = gpuvec(Float32[])
    range = Signal(0)
    robj = visualize(
        positions.buffer, :linesegment,
        color = colors.buffer,
        thickness = thickness.buffer,
        indices = range,
        boundingbox = Signal(AABB{Float32}())
    ).children[]
    robj.boundingbox = Signal(AABB{Float32}())
    LinesegmentBuffer{N}(
        positions,
        colors,
        thickness,
        robj,
        range
    )
end

same_length_array(array, value) = fill(value, length(array))
same_length_array(arr, value::Vector) = value

function Base.append!(lsb::LinesegmentBuffer{N}, pos::Vector{Point{N, Float32}}, color, thickness) where N
    thickv = Float32.(same_length_array(pos, thickness))
    append!(lsb.positions, pos)
    append!(lsb.colors, same_length_array(pos, to_color(color)))
    append!(lsb.thickness, thickv)
    bb = value(lsb.robj.boundingbox)
    for (s, pos) in zip(thickv, pos)
        pos3d = Vec{3, Float32}(to_nd(pos, Val{3}, 0))
        bb = update(bb, pos3d)
        bb = update(bb, pos3d .+ s)
    end
    push!(lsb.robj.boundingbox, bb)
    push!(lsb.range, length(lsb.positions))
    return
end

function Base.empty!(lsb::LinesegmentBuffer)
    resize!(lsb.positions, 0)
    resize!(lsb.colors, 0)
    resize!(lsb.thickness, 0)
    push!(lsb.range, 0)
    push!(lsb.robj.boundingbox, AABB{Float32}())
    return
end


function extract_view(x::SubArray)
    x.parent, x.indexes[1]
end
function extract_view(x::ArrayNode)
    p = if isa(to_value(x).parent, ArrayNode)
        to_value(x).parent
    else
        lift_node(x-> x.parent, x)
    end
    idx = if isa(to_value(x).parent, ArrayNode)
        to_value(x).indexes[1]
    else
        lift_node(x-> x.indexes[1], x)
    end
    p, idx
end

function lines_2glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:x, :y, :z, :scale, :rotation, :offset, :camera) && continue
        if k == :linestyle
            # TODO implement pattern as signal
            result[:pattern] = to_value(v)
            continue
        end
        if k == :drawover
            if v == true
                result[:prerender] = ()-> glDisable(GL_DEPTH_TEST)
            end
            continue
        end
        if k == :colornorm
            k = :color_norm
        end
        if k == :colormap
            k = :color_map
        end
        if k == :linewidth
            k = :thickness
        end
        if k == :positions
            k = :vertex
            if isa(to_value(v), SubArray)
                v, idx = extract_view(v)
                result[:indices] = to_signal(to_index_buffer((), idx))
            end
        end
        result[k] = to_signal(v)
    end
    result[:fxaa] = false
    result
end


function _lines(scene, style, attributes)
    attributes = lines_defaults(scene, attributes)
    data = lines_2glvisualize(attributes)
    pos = data[:vertex]
    delete!(data, :vertex)
    viz = GLVisualize._default(pos, Style(style), data)
    viz = GLVisualize.assemble_shader(viz).children[]
    insert_scene!(scene, style, viz, attributes)
end


for arg in ((:x, :y), (:x, :y, :z), (:positions,))
    insert_expr = map(arg) do elem
        :(attributes[$(QuoteNode(elem))] = $elem)
    end
    @eval begin
        function lines(scene::makie, $(arg...), attributes::Dict)
            $(insert_expr...)
            _lines(scene, :lines, attributes)
        end
        function linesegment(scene::makie, $(arg...), attributes::Dict)
            $(insert_expr...)
            _lines(scene, :linesegment, attributes)
        end
    end
end

function linesegment(scene::makie, pos::AbstractVector{<: Union{Tuple{P, P}, Pair{P, P}}}, attributes::Dict) where P <: Point
    positions = lift_node(x->reinterpret(P, x), to_node(pos))
    linesegment(scene, positions, attributes)
end



function arc(pmin, pmax, a1, a2)

    xy = Vector{Point2f0}(361)

    xcenter = (x_lin(xmin) + x_lin(xmax)) / 2.0;
    ycenter = (y_lin(ymin) + y_lin(ymax)) / 2.0;
    width = abs(x_lin(xmax) - x_lin(xmin)) / 2.0;
    height = abs(y_lin(ymax) - y_lin(ymin)) / 2.0;

    start = min(a1, a2);
    stop = max(a1, a2);
    start += (stop - start) / 360 * 360;

    n = 0;
    for a in start:stop
        x[n] = x_log(xcenter + width  * cos(a * M_PI / 180));
        y[n] = y_log(ycenter + height * sin(a * M_PI / 180));
        n += 1
    end
    if (n > 1)
        lines(x, y)
    end

end
