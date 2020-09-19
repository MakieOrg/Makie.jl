using AbstractPlotting: @cell
module RNG

using StableRNGs
using Colors
using Random

const STABLE_RNG = StableRNG(123)

rand(args...) = Base.rand(STABLE_RNG, args...)
randn(args...) = Base.randn(STABLE_RNG, args...)

seed_rng!() = Random.seed!(STABLE_RNG, 123)

function Base.rand(r::StableRNGs.LehmerRNG, ::Random.SamplerType{T}) where T<:ColorAlpha
    return T(Base.rand(r), Base.rand(r), Base.rand(r), Base.rand(r))
end

function Base.rand(r::StableRNGs.LehmerRNG, ::Random.SamplerType{T}) where T<:AbstractRGB
    return T(Base.rand(r), Base.rand(r), Base.rand(r))
end

end

using .RNG
empty!(AbstractPlotting.DATABASE)
using AbstractPlotting: Record, Stepper

module MakieGallery
    using FileIO
    assetpath(files...) = normpath(joinpath(@__DIR__, "..", "..", "..", "MakieGallery", "assets", files...))
    loadasset(files...) = FileIO.load(assetpath(files...))
end
using .MakieGallery

function load_database()
    empty!(AbstractPlotting.DATABASE)
    include("examples2d.jl")
    include("attributes.jl")
    include("documentation.jl")
    include("examples2d.jl")
    include("examples3d.jl")
    include("layouting.jl")
    include("short_tests.jl")
    return AbstractPlotting.DATABASE

db = AbstractPlotting.DATABASE

function run_tests()
    evaled = 0
    for (n, func) in db
        try
            func() |> display
            evaled += 1
        catch e
            @show "Error" exception=e
        end
    end
    return evaled
end