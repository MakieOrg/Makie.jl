module ReferenceTests

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 0
end

using Test
using MeshIO
using FileIO
using MacroTools
using Makie
using Makie: Record, Stepper, Axis
using Printf
using Tar
using Downloads
using Pkg.TOML
using Statistics
using ImageShow
using Downloads: download

# Deps for tests
using Makie.ComputePipeline: ResolveException
using CategoricalArrays
using LinearAlgebra
using Colors
using LaTeXStrings
using GeometryBasics
using DelimitedFiles
using DelaunayTriangulation
using SparseArrays
using DynamicQuantities

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))
using Makie: loadasset

# The version in Images.jl throws an error... whyyyyy!?
# TODO look into error!
using Images, FixedPointNumbers, Colors, ColorTypes

include("database.jl")
include("stable_rng.jl")
include("compare_media.jl")
include("runtests.jl")
include("image_download.jl")
include("cross_backend_scores.jl")

export @include_reference_tests

end
