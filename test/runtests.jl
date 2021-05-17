using Pkg
using Test
using MeshIO
using StaticArrays
using AbstractPlotting
using ImageMagick

using AbstractPlotting.Observables
using AbstractPlotting.GeometryBasics
using AbstractPlotting.PlotUtils
using AbstractPlotting.FileIO
using AbstractPlotting.IntervalSets
using GeometryBasics: Pyramid

# ImageIO seems broken on 1.6 ... and there doesn't
# seem to be a clean way anymore to force not to use a loader library?
filter!(x-> x !== :ImageIO, FileIO.sym2saver[:PNG])
filter!(x-> x !== :ImageIO, FileIO.sym2loader[:PNG])

include("reference_tests.jl")
include("unit_tests/runtests.jl")
