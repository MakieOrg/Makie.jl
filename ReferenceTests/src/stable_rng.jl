module RNG

    using StableRNGs
    using Colors
    using Random

    const STABLE_RNG = StableRNG(123)

    rand(args...) = Base.rand(STABLE_RNG, args...)
    randn(args...) = Base.randn(STABLE_RNG, args...)

    seed_rng!() = Random.seed!(STABLE_RNG, 123)

    function Base.rand(r::StableRNGs.LehmerRNG, ::Random.SamplerType{T}) where {T <: ColorAlpha}
        return T(Base.rand(r), Base.rand(r), Base.rand(r), Base.rand(r))
    end

    function Base.rand(r::StableRNGs.LehmerRNG, ::Random.SamplerType{T}) where {T <: AbstractRGB}
        return T(Base.rand(r), Base.rand(r), Base.rand(r))
    end

end

using .RNG
