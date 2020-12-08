using Pkg
using Test
using MeshIO
using StaticArrays
using AbstractPlotting

using AbstractPlotting.Observables
using AbstractPlotting.GeometryBasics
using AbstractPlotting.PlotUtils
using AbstractPlotting.FileIO
using AbstractPlotting.IntervalSets
using GeometryBasics: Pyramid

include("reference_tests.jl")
include("unit_tests/runtests.jl")
