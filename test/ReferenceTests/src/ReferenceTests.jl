module ReferenceTests


# Write your package code here.
using Test
using MeshIO
using FileIO
using MacroTools
using AbstractPlotting
using AbstractPlotting: Record, Stepper
using AbstractPlotting.MakieLayout

assetpath(files...) = normpath(joinpath(@__DIR__, "..", "assets", files...))
loadasset(files...) = FileIO.load(assetpath(files...))

# The version in Images.jl throws an error... whyyyyy!?
# TODO look into error!
using Images, FixedPointNumbers, Colors, ColorTypes

include("database.jl")
include("stable_rng.jl")
include("runtests.jl")

end
