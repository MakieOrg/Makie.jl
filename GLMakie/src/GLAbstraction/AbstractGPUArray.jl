import Base: copy!
import Base: splice!
import Base: append!
import Base: push!
import Base: resize!
import Base: setindex!
import Base: getindex
import Base: map
import Base: size
import Base: iterate

abstract type GPUArray{T, NDim} <: AbstractArray{T, NDim} end

size(A::GPUArray) = A.size

function checkdimensions(value::Array, ranges::Union{Integer, UnitRange}...)
    array_size = size(value)
    indexes_size = map(length, ranges)
    (array_size != indexes_size) && throw(DimensionMismatch("Assigning a $array_size to a $(indexes_size) location"))
    return true
end
function to_range(index)
    return map(index) do val
        isa(val, Integer) && return val:val
        isa(val, AbstractRange) && return val
        error("Indexing only defined for integers or ranges. Found: $val")
    end
end

setindex!(A::GPUArray{T, N}, value::Union{T, Array{T, N}}) where {T, N} = (A[1] = value)

function setindex!(A::GPUArray{T, N}, value, indices::Vararg{Integer, N}) where {T, N}
    v = Array{T, N}(undef, ntuple(i -> 1, N))
    v[1] = convert(T, value)
    return setindex!(A, v, (:).(indices, indices)...)
end

function setindex!(A::GPUArray{T, N}, value, indexes...) where {T, N}
    ranges = to_range(Base.to_indices(A, indexes))
    v = isa(value, T) ? [value] : convert(Array{T, N}, value)
    return setindex!(A, v, ranges...)
end

setindex!(A::GPUArray{T, 2}, value::Vector{T}, i::Integer, range::UnitRange) where {T} =
    (A[i, range] = reshape(value, (length(value), 1)))

function setindex!(A::GPUArray{T, N}, value::Array{T, N}, ranges::UnitRange...) where {T, N}
    checkbounds(A, ranges...)
    checkdimensions(value, ranges...)
    gpu_setindex!(A, value, ranges...)
    return
end

gl_switch_context!(A::GPUArray) = gl_switch_context!(A.context)
function update!(A::GPUArray{T, N}, value::AbstractArray{T2, N}) where {T, N, T2}
    return update!(A, convert(Array{T, N}, value))
end
function update!(A::GPUArray{T, N}, value::AbstractArray{T, N}) where {T, N}
    gl_switch_context!(A)
    if size(A) != size(value)
        if isa(A, GLBuffer) && length(A) != length(value)
            resize!(A, length(value))
        elseif isa(A, Texture)
            resize_nocopy!(A, size(value))
        elseif isa(A, TextureBuffer)
            gpu_resize!(A, size(value))
        else
            error("Dynamic resizing not implemented for $(typeof(A))")
        end
    end
    dims = map(x -> 1:x, size(A))
    A[dims...] = value
    return
end
update!(A::GPUArray, value::ShaderAbstractions.Sampler) = update!(A, value.data)

function getindex(A::GPUArray{T, N}, i::Int) where {T, N}
    checkbounds(A, i)
    return gpu_getindex(A, i:i)[1] # not as bad as its looks, as so far gpu data must be loaded into an array anyways
end
function getindex(A::GPUArray{T, N}, ranges::UnitRange...) where {T, N}
    checkbounds(A, ranges...)
    return gpu_getindex(A, ranges...)
end

mutable struct GPUVector{T} <: GPUArray{T, 1}
    buffer
    size
    real_length
end

GPUVector(x::GPUArray) = GPUVector{eltype(x)}(x, size(x), length(x))

function update!(A::GPUVector{T}, value::AbstractVector{T}) where {T}
    if isa(A, GLBuffer) && (length(A) != length(value))
        resize!(A, length(value))
    end
    dims = map(x -> 1:x, size(A))
    A.buffer[dims...] = value
    return
end

size(v::GPUVector) = v.size
iterate(b::GPUVector, state = 1) = iterate(b.buffer, state)
gpu_data(A::GPUVector) = A.buffer[1:length(A)]
getindex(v::GPUVector, index::Int) = v.buffer[index]
getindex(v::GPUVector, index::UnitRange) = v.buffer[index]
setindex!(v::GPUVector{T}, value::T, index::Int) where {T} = v.buffer[index] = value
setindex!(v::GPUVector{T}, value::T, index::UnitRange) where {T} = v.buffer[index] = value


function grow_dimensions(real_length::Int, _size::Int, additonal_size::Int, growfactor::Real = 1.5)
    new_dim = round(Int, real_length * growfactor)
    return max(new_dim, additonal_size + _size)
end
function Base.push!(v::GPUVector{T}, x::AbstractVector{T}) where {T}
    lv, lx = length(v), length(x)
    if (v.real_length < lv + lx)
        resize!(v.buffer, grow_dimensions(v.real_length, lv, lx))
    end
    v.buffer[(lv + 1):(lv + lx)] = x
    v.real_length = length(v.buffer)
    v.size = (lv + lx,)
    return v
end
push!(v::GPUVector{T}, x::T) where {T} = push!(v, [x])
push!(v::GPUVector{T}, x::T...) where {T} = push!(v, [x...])
append!(v::GPUVector{T}, x::Vector{T}) where {T} = push!(v, x)

resize!(A::GPUArray{T, NDim}, dims::Int...) where {T, NDim} = resize!(A, dims)
function resize!(A::GPUArray{T, NDim}, newdims::NTuple{NDim, Int}) where {T, NDim}
    newdims == size(A) && return A
    gpu_resize!(A, newdims)
    return A
end

function resize!(v::GPUVector, newlength::Int)
    if v.real_length >= newlength # is still big enough
        v.size = (max(0, newlength),)
        return v
    end
    resize!(v.buffer, grow_dimensions(v.real_length, length(v), newlength - length(v)))
    v.size = (newlength,)
    return v.real_length = length(v.buffer)
end
function grow_at(v::GPUVector, index::Int, amount::Int)
    resize!(v, length(v) + amount)
    return copy!(v, index, v, index + amount, amount)
end

function splice!(v::GPUVector{T}, index::UnitRange, x::Vector = T[]) where {T}
    lenv = length(v)
    elements_to_grow = length(x) - length(index) # -1
    buffer = similar(v.buffer, length(v) + elements_to_grow)
    copy!(v.buffer, 1, buffer, 1, first(index) - 1) # copy first half
    copy!(v.buffer, last(index) + 1, buffer, first(index) + length(x), lenv - last(index)) # shift second half
    v.buffer = buffer
    v.real_length = length(buffer)
    v.size = (v.real_length,)
    copy!(x, 1, buffer, first(index), length(x)) # copy contents of insertion vector
    return
end

splice!(v::GPUVector{T}, index::Int, x::T) where {T} = v[index] = x
splice!(v::GPUVector{T}, index::Int, x::Vector = T[]) where {T} = splice!(v, index:index, map(T, x))


copy!(a::GPUVector, a_offset::Int, b::Vector, b_offset::Int, amount::Int) = copy!(a.buffer, a_offset, b, b_offset, amount)
copy!(a::GPUVector, a_offset::Int, b::GPUVector, b_offset::Int, amount::Int) = copy!(a.buffer, a_offset, b.buffer, b_offset, amount)


copy!(a::GPUArray, a_offset::Int, b::Vector, b_offset::Int, amount::Int) = _copy!(a, a_offset, b, b_offset, amount)
copy!(a::Vector, a_offset::Int, b::GPUArray, b_offset::Int, amount::Int) = _copy!(a, a_offset, b, b_offset, amount)
copy!(a::GPUArray, a_offset::Int, b::GPUArray, b_offset::Int, amount::Int) = _copy!(a, a_offset, b, b_offset, amount)

#don't overwrite Base.copy! with a::Vector, b::Vector
function _copy!(a::Union{Vector, GPUArray}, a_offset::Int, b::Union{Vector, GPUArray}, b_offset::Int, amount::Int)
    (amount <= 0) && return nothing
    @assert a_offset > 0 && (a_offset - 1) + amount <= length(a) "a_offset $a_offset, amount $amount, lengtha $(length(a))"
    @assert b_offset > 0 && (b_offset - 1) + amount <= length(b) "b_offset $b_offset, amount $amount, lengthb $(length(b))"
    unsafe_copy!(a, a_offset, b, b_offset, amount)
    return nothing
end

# Interface:
gpu_data(t) = error("gpu_data not implemented for: $(typeof(t)). This happens, when you call data on an array, without implementing the GPUArray interface")
gpu_resize!(t) = error("gpu_resize! not implemented for: $(typeof(t)). This happens, when you call resize! on an array, without implementing the GPUArray interface")
gpu_getindex(t) = error("gpu_getindex not implemented for: $(typeof(t)). This happens, when you call getindex on an array, without implementing the GPUArray interface")
gpu_setindex!(t) = error("gpu_setindex! not implemented for: $(typeof(t)). This happens, when you call setindex! on an array, without implementing the GPUArray interface")
max_dim(t) = error("max_dim not implemented for: $(typeof(t)). This happens, when you call setindex! on an array, without implementing the GPUArray interface")


function (::Type{GPUArrayType})(context, data::Observable; kw...) where {GPUArrayType <: GPUArray}
    gpu_mem = GPUArrayType(context, data[]; kw...)
    # TODO merge these and handle update tracking during construction
    obs2 = on(new_data -> update!(gpu_mem, new_data), data)
    if GPUArrayType <: TextureBuffer
        push!(gpu_mem.buffer.observers, obs2)
    else
        push!(gpu_mem.observers, obs2)
    end
    return gpu_mem
end

export data
export resize
export GPUArray
export GPUVector

export update!

export gpu_data
export gpu_resize!
export gpu_getindex
export gpu_setindex!
export max_dim
