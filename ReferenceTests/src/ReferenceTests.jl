module ReferenceTests


using Test
using MeshIO
using FileIO
using MacroTools
using Makie
using Makie: Record, Stepper, Axis
using Makie.FFMPEG
using Printf
using ghr_jll
using Tar
using Downloads
using Pkg.TOML
using Statistics
using ImageShow
using Downloads: download
import HTTP
import JSON3
import ZipFile
import REPL
import REPL.TerminalMenus

# Deps for tests
using CategoricalArrays
using LinearAlgebra
using Colors
using LaTeXStrings
using GeometryBasics

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))
loadasset(files...) = FileIO.load(assetpath(files...))

# The version in Images.jl throws an error... whyyyyy!?
# TODO look into error!
using Images, FixedPointNumbers, Colors, ColorTypes

include("database.jl")
include("stable_rng.jl")
include("runtests.jl")
include("image_download.jl")
include("local_server.jl")

export @include_reference_tests

end
