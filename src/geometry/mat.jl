
using LinearAlgebra

struct Mat{N,M,T}
    data::Matrix{T}
end

const Mat3{T} = Mat{3,3,T}
const Mat4{T} = Mat{4,4,T}
const Mat3f = Mat3{Float32}
const Mat4f = Mat4{Float32}

function Mat{N,M,T}(i::UniformScaling) where {N,M,T}
    return Mat{N,M,T}(Matrix{T}(i, M, N))
end

function Mat{N,M}(x::Matrix{T}) where {N,M,T}
    return Mat{N,M,T}(x)
end

function Base.:(*)(a::Mat4, b::Vec)
    return b
end

function Base.:(*)(a::Mat4, b::Mat4)
    return Mat4(a.data * b.data)
end
