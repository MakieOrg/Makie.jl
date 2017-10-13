"""
Converts index arrays to the OpenGL equivalent.
"""
to_index_buffer(b, x::GLBuffer) = x
to_index_buffer(b, x::TOrSignal{Int}) = x
to_index_buffer(b, x::VecOrSignal{UnitRange{Int}}) = x

"""
For integers, we transform it to 0 based indices
"""
to_index_buffer(b, x::Vector{I}) where {I <: Integer} = indexbuffer(map(i-> Cuint(i-1), x))
function to_index_buffer(b, x::AbstractVector{I}) where I<:Integer
    gpu_mem = GLBuffer(value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    x = lift_node(to_node(x)) do x
        val = Cuint[i-1 for i = x]
        update!(gpu_mem, val)
     end
    gpu_mem
end

"""
If already GLuint, we assume its 0 based (bad heuristic, should better be solved with some Index type)
"""
to_index_buffer(b, x::Vector{I}) where {I<:GLuint} = indexbuffer(x)
function to_index_buffer(b, x::Signal{Vector{I}}) where I <: GLuint
    gpu_mem = GLBuffer(value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    preserve(const_lift(update!, gpu_mem, x))
    gpu_mem
end

to_index_buffer(b, x) = error(
    "Not a valid index type: $(typeof(x)).
    Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them"
)

const position_types = """
    1) X, Y, [Z] Vector or Matrix
    2) AbstractArray{T} where T is convertible to a point (E.g. Tuple, AbstractVector)

"""

"""
Position convert. Supports currently:
$position_types
"""
function to_positions(b, x::Tuple{<: AbstractArray, <: AbstractArray})
    Point{2, Float32}.(x...)
end
function to_positions(b, x::Tuple{<: AbstractArray, <: AbstractArray, <: AbstractArray})
    Point{3, Float32}.(x...)
end
function to_positions(b, x::AbstractArray{T, ND}) where {T, ND}
    N = if applicable(length, T)
        length(T)
    else
        error("Point type needs to have length defined and needs to be convertible to GeometryTypes point (e.g. tuples, abstract arrays etc.)")
    end
    Point{N, Float32}.(x)
end
function to_positions(b, x)
    error("Not a valid position type: $(typeof(x)). Try one of: $position_types")
end


to_array(b, x) = x


to_scalefunc(b, x) = x
to_text(b, x) = x
to_font(b, x) = x
