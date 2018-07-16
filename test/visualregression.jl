
# The version in Images.jl throws an error... whyyyyy!?
# Also Images has so many dependencies, I try to get rid of it, especially on 0.7
using ImageFiltering, FixedPointNumbers, Colors, ColorTypes

"""
`m = maxfinite(A)` calculates the maximum value in `A`, ignoring any values that are not finite (Inf or NaN).
"""
function maxfinite(A::AbstractArray{T}) where T
    ret = sentinel_max(T)
    for a in A
        ret = maxfinite_scalar(a, ret)
    end
    ret
end
function maxfinite(f, A::AbstractArray)
    ret = sentinel_max(typeof(f(first(A))))
    for a in A
        ret = maxfinite_scalar(f(a), ret)
    end
    ret
end

"""
`m = maxabsfinite(A)` calculates the maximum absolute value in `A`, ignoring any values that are not finite (Inf or NaN).
"""
function maxabsfinite(A::AbstractArray{T}) where T
    ret = sentinel_min(typeof(abs(A[1])))
    for a in A
        ret = maxfinite_scalar(abs(a), ret)
    end
    ret
end

minfinite_scalar(a::T, b::T) where {T} = isfinite(a) ? (b < a ? b : a) : b
maxfinite_scalar(a::T, b::T) where {T} = isfinite(a) ? (b > a ? b : a) : b
minfinite_scalar(a::T, b::T) where {T<:Union{Integer,FixedPoint}} = b < a ? b : a
maxfinite_scalar(a::T, b::T) where {T<:Union{Integer,FixedPoint}} = b > a ? b : a
minfinite_scalar(a, b) = minfinite_scalar(promote(a, b)...)
maxfinite_scalar(a, b) = maxfinite_scalar(promote(a, b)...)

function minfinite_scalar(c1::C, c2::C) where C<:AbstractRGB
    C(minfinite_scalar(c1.r, c2.r),
      minfinite_scalar(c1.g, c2.g),
      minfinite_scalar(c1.b, c2.b))
end
function maxfinite_scalar(c1::C, c2::C) where C<:AbstractRGB
    C(maxfinite_scalar(c1.r, c2.r),
      maxfinite_scalar(c1.g, c2.g),
      maxfinite_scalar(c1.b, c2.b))
end

sentinel_min(::Type{T}) where {T<:Union{Integer,FixedPoint}} = typemax(T)
sentinel_max(::Type{T}) where {T<:Union{Integer,FixedPoint}} = typemin(T)
sentinel_min(::Type{T}) where {T<:AbstractFloat} = convert(T, NaN)
sentinel_max(::Type{T}) where {T<:AbstractFloat} = convert(T, NaN)
sentinel_min(::Type{C}) where {C<:AbstractRGB} = _sentinel_min(C, eltype(C))
_sentinel_min(::Type{C},::Type{T}) where {C<:AbstractRGB,T} = (s = sentinel_min(T); C(s,s,s))
sentinel_max(::Type{C}) where {C<:AbstractRGB} = _sentinel_max(C, eltype(C))
_sentinel_max(::Type{C},::Type{T}) where {C<:AbstractRGB,T} = (s = sentinel_max(T); C(s,s,s))



difftype(::Type{T}) where {T<:Integer} = Int
difftype(::Type{T}) where {T<:Real} = Float32
difftype(::Type{Float64}) = Float64
difftype(::Type{CV}) where {CV<:Colorant} = difftype(CV, eltype(CV))
difftype(::Type{CV}, ::Type{T}) where {CV<:RGBA,T<:Real} = RGBA{Float32}
difftype(::Type{CV}, ::Type{Float64}) where {CV<:RGBA} = RGBA{Float64}
difftype(::Type{CV}, ::Type{T}) where {CV<:BGRA,T<:Real} = BGRA{Float32}
difftype(::Type{CV}, ::Type{Float64}) where {CV<:BGRA} = BGRA{Float64}
difftype(::Type{CV}, ::Type{T}) where {CV<:AbstractRGB,T<:Real} = RGB{Float32}
difftype(::Type{CV}, ::Type{Float64}) where {CV<:AbstractRGB} = RGB{Float64}


function sumdiff(f, A::AbstractArray, B::AbstractArray)
    indices(A) == indices(B) || throw(DimensionMismatch("A and B must have the same indices"))
    T = promote_type(difftype(eltype(A)), difftype(eltype(B)))
    println(T)
    s = zero(accum(eltype(T)))
    for (a, b) in zip(A, B)
        x = convert(T, a) - convert(T, b)
        s += f(x)
    end
    s
end

"`s = ssd(A, B)` computes the sum-of-squared differences over arrays/images A and B"
ssd(A::AbstractArray, B::AbstractArray) = sumdiff(abs2, A, B)

"`s = sad(A, B)` computes the sum-of-absolute differences over arrays/images A and B"
sad(A::AbstractArray, B::AbstractArray) = sumdiff(abs, A, B)


function approx_difference(
        A::AbstractArray, B::AbstractArray,
        sigma::AbstractVector{T} = ones(ndims(A)),
        eps::AbstractFloat = 1e-2
    ) where T<:Real

    if length(sigma) != ndims(A)
        error("Invalid sigma in test_approx_eq_sigma_eps. Should be ndims(A)-length vector of the number of pixels to blur.  Got: $sigma")
    end
    kern = KernelFactors.IIRGaussian(sigma)
    Ai = RGB{Float64}.(A)
    Bi = RGB{Float64}.(B)
    Af = RGB{Float64}.(A)
    Bf = RGB{Float64}.(B)
    imfilter!(Af, Ai, kern, NA())
    imfilter!(Bf, Bi, kern, NA())
    diffscale = max(maxabsfinite(Ai), maxabsfinite(Bi))
    d = sad(Af, Bf)
    return d / (length(Af) * diffscale)
end
