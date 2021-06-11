using Test
using MeshIO
using StaticArrays
using Makie
using ImageMagick

using Makie.Observables
using Makie.GeometryBasics
using Makie.PlotUtils
using Makie.FileIO
using Makie.IntervalSets
using GeometryBasics: Pyramid

include("reference_tests.jl")
include("unit_tests/runtests.jl")
