using Reactive

import Base: IndexStyle, size, getindex, setindex!, _unsafe_getindex!, push!, similar

using Base.Broadcast: map_newindexer, _broadcast_eltype, broadcast_indices

struct ArrayNode{T, N, F, AT <: AbstractArray} <: AbstractArray{T, N}
    signal::Signal{AT}
    convert::F
end
const AbstractNode{T} = Union{ArrayNode{T}, Node{T}}


function children(x::Signal)
    filter(x-> x != nothing, (x-> x.value).(Reactive.nodes[Reactive.edges[x.id]]))
end
children(x::AbstractNode) = children(to_signal(x))
    

function disconnect!(x::Signal, toremove::Signal)
    x.parents = (Iterators.filter(x-> x != toremove, x.parents)...,)
end

disconnect_all_children!(x::AbstractNode) = disconnect_all_children!(to_signal(x))

function disconnect_all_children!(x::Signal)
    for child in children(x)
        disconnect!(child, x)
    end
end

function closenode!(x::AbstractNode)
    s = to_signal(x)
    disconnect_all_children!(s)
    close(s, false)
end

"""
Lift nodes of a scene by supplying fetching nodes via keys into the scene.
A tuple of symboles will be interpreted as `scene[:tupl_elem_1, :tupl_elem_2, ...]`
"""
function lift_node(f, scene::Scene, keys::Union{Symbol, Tuple}...)
    args = map(x-> getindex(scene, x), keys)
    lift_node(f, args...)
end

"""
Registers a callback to `nodes`, which calls function `f` whenever any node in `nodes` updates.
`f` will get the values of each `node` as an argument, so basically `f(to_value.(nodes))`.
Returns a new node which is the result of `f` applied to the updated `nodes`. 
"""
function lift_node(f, nodes::AbstractNode...)
    args = to_signal.(nodes)
    s = foreach(f, args...)
    to_node(s)
end

function push!(x::AbstractNode, value)
    val = x.convert(to_value(value))
    s = to_signal(x)
    Reactive.set_value!(s, val) # make the value available already!
    push!(s, val)
    val
end



IndexStyle(x::ArrayNode{T, N, F, AT}) where {T, N, F, AT} = IndexStyle(AT)
Array(x::ArrayNode) = value(to_signal(x))
similar(A::ArrayNode) = to_node(similar(Array(A)))
similar(A::ArrayNode, ::Type{T}) where T = to_node(similar(Array(A), T))
similar(A::ArrayNode, dims::NTuple{N, Int}) where N = to_node(similar(Array(A), dims))
similar(A::ArrayNode, ::Type{T}, dims::NTuple{N, Int}) where {T, N} = to_node(similar(Array(A), T, dims))

size(x::ArrayNode) = size(value(to_signal(x)))

# Index Linear
function getindex(x::ArrayNode, i::Integer)
    Array(x)[i]
end
function setindex!(x::ArrayNode{T, N}, val, i::Integer) where {T, N}
    Array(x)[i] = val
    push!(to_signal(x), Array(x)) # update array
    val
end
function getindex(x::ArrayNode, i::Vararg{Int, N}) where N
    Array(x)[i...]
end

function setindex!(x::ArrayNode{T, N}, val, i::Vararg{Int, N}) where {T, N}
    Array(x)[i...] = val
    push!(to_signal(x), Array(x))
    val
end

function _unsafe_getindex!(dest::ArrayNode, src::AbstractArray, Is::Union{Real, AbstractArray}...)
    Array(dest)[Is...] = Array(src)
    push!(to_signal(dest), Array(dest))
    return dest
end


to_node(obj::AbstractNode) = obj
function to_node(obj::AbstractNode, f)
    to_node(map(f, to_signal(obj)))
end
to_node(obj, f = identity) = to_node(Signal(f(obj)), f)
to_node(obj::Signal, f = identity) = Node(map(f, obj), f)
to_node(obj::Scene, f = identity) = obj
function to_node(obj::Signal{AT}, f::F = identity) where {AT <: AbstractArray, F}
    A = value(obj)
    ArrayNode{eltype(A), ndims(A), F, AT}(obj, f)
end

to_value(obj::AbstractNode) = value(to_signal(obj))
to_value(obj) = obj

to_signal(obj::AbstractNode) = obj.signal
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
