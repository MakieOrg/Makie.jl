module ReferenceTests


# Write your package code here.
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

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))
loadasset(files...) = FileIO.load(assetpath(files...))

# The version in Images.jl throws an error... whyyyyy!?
# TODO look into error!
using Images, FixedPointNumbers, Colors, ColorTypes

include("database.jl")
include("stable_rng.jl")
include("runtests.jl")
include("image_download.jl")
include("html_rendering.jl")
include("local_server.jl")

end
