using Reactive

import Base: IndexStyle, size, getindex, setindex!, _unsafe_getindex!, push!, similar

using Base.Broadcast: map_newindexer, _broadcast_eltype, broadcast_indices

struct ArrayNode{T, N, F, AT <: AbstractArray} <: AbstractArray{T, N}
    value::Signal{AT}
    convert::F
end


const AbstractNode = Union{ArrayNode, Node}
function lift_node(f, x::AbstractNode...)
    args = to_signal.(x)
    s = foreach(f, args...)
    to_node(s)
end

function push!(x::AbstractNode, value)
    val = x.convert(to_value(value))
    push!(x.value, val)
    val
end



IndexStyle(x::ArrayNode{T, N, F, AT}) where {T, N, F, AT} = IndexStyle(AT)
Array(x::ArrayNode) = value(x.value)
similar(A::ArrayNode) = to_node(similar(Array(A)))
similar(A::ArrayNode, ::Type{T}) where T = to_node(similar(Array(A), T))
similar(A::ArrayNode, dims::NTuple{N, Int}) where N = to_node(similar(Array(A), dims))
similar(A::ArrayNode, ::Type{T}, dims::NTuple{N, Int}) where {T, N} = to_node(similar(Array(A), T, dims))

size(x::ArrayNode) = size(value(x.value))

# Index Linear
function getindex(x::ArrayNode, i::Integer)
    Array(x)[i]
end
function setindex!(x::ArrayNode{T, N}, val, i::Integer) where {T, N}
    Array(x)[i] = val
    push!(x.value, Array(x)) # update array
    val
end
function getindex(x::ArrayNode, i::Vararg{Int, N}) where N
    Array(x)[i...]
end

function setindex!(x::ArrayNode{T, N}, val, i::Vararg{Int, N}) where {T, N}
    Array(x)[i...] = val
    push!(x.value, Array(x))
    val
end

function _unsafe_getindex!(dest::ArrayNode, src::AbstractArray, Is::Union{Real, AbstractArray}...)
    Array(dest)[Is...] = Array(src)
    push!(dest.value, Array(dest))
    return dest
end


to_node(obj::AbstractNode) = obj
to_node(obj::AbstractNode, f) = to_node(to_signal(obj), f)
to_node(obj, f = identity) = to_node(Signal(f(obj)), f)
to_node(obj::Signal, f = identity) = Node(map(f, obj), f)
to_node(obj::Scene, f = identity) = obj
function to_node(obj::Signal{AT}, f::F = identity) where {AT <: AbstractArray, F}
    A = value(obj)
    ArrayNode{eltype(A), ndims(A), F, AT}(obj, f)
end

to_value(obj::AbstractNode) = value(obj.value)
to_value(obj) = obj

to_signal(obj::AbstractNode) = obj.value
to_signal(obj) = obj

# Called by Base broadcasting mechanisms (in place and out of place)
Base.Broadcast._containertype(::Type{<:ArrayNode}) = ArrayNode
Base.Broadcast.promote_containertype(::Type{Any}, ::Type{ArrayNode}) = ArrayNode
Base.Broadcast.promote_containertype(::Type{ArrayNode}, ::Type{Any}) = ArrayNode

@inline function Base.Broadcast.broadcast_c!(f, ::Type{ArrayNode}, ::Type, C, A, Bs::Vararg{Any, N}) where N
    lift_node(to_node(C), to_node(A), to_node.(Bs)...) do c, a, bs...
        broadcast!(f, c, a, bs)
    end
    C
end

@inline function Base.Broadcast.broadcast_c(f, ::Type{ArrayNode}, A, Bs...)
    lift_node(to_node(A), to_node.(Bs)...) do a, bs...
        broadcast(f, a, bs...)
    end
end
