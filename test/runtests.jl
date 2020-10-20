using Pkg
using Test
using StaticArrays
using AbstractPlotting
using AbstractPlotting.Observables
using AbstractPlotting.GeometryBasics
using AbstractPlotting.GeometryBasics: Pyramid
using AbstractPlotting.PlotUtils
using AbstractPlotting.FileIO
using AbstractPlotting.MakieLayout
using AbstractPlotting.IntervalSets

include("reference_tests.jl")
include("unit_tests/runtests.jl")
