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
        indices = range
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
        k in (:linestyle, :x, :y, :z) && continue
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
    result[:visible] = true
    result[:fxaa] = false
    result[:model] = eye(Mat4f0)
    result
end


function _lines(b, style, attributes)
    scene = get_global_scene()
    attributes = lines_defaults(b, scene, attributes)
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
        function lines(b::makie, $(arg...), attributes::Dict)
            $(insert_expr...)
            _lines(b, :lines, attributes)
        end
        function linesegment(b::makie, $(arg...), attributes::Dict)
            $(insert_expr...)
            _lines(b, :linesegment, attributes)
        end
    end
end

function linesegment(b::makie, pos::AbstractVector{<: Union{Tuple{P, P}, Pair{P, P}}}, attributes::Dict) where P <: Point
    positions = reinterpret(P, pos)
    linesegment(b, positions, attributes)
end
