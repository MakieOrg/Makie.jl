module ReferenceTests

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 0
end

# Write your package code here.
using Test
using MeshIO
using FileIO
using MacroTools
using Makie
using Makie: Record, Stepper, Axis
using Makie.FFMPEG
using Printf
using Tar
using Downloads
using Pkg.TOML
using Statistics
using ImageShow
using Downloads: download

# Deps for tests
using CategoricalArrays
using LinearAlgebra
using Colors
using LaTeXStrings
using GeometryBasics
using DelimitedFiles
using DelaunayTriangulation

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))
loadasset(files...) = FileIO.load(assetpath(files...))

# The version in Images.jl throws an error... whyyyyy!?
# TODO look into error!
using Images, FixedPointNumbers, Colors, ColorTypes

include("database.jl")
include("stable_rng.jl")
include("runtests.jl")
include("image_download.jl")

export @include_reference_tests

end
