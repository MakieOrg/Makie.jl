module GLVisualize

using ..GLAbstraction
using AbstractPlotting: RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA

using ..GLMakie.GLFW
using ModernGL
using StaticArrays
using GeometryBasics
using Colors
using AbstractPlotting
using FixedPointNumbers
using FileIO
using Markdown
using Observables

import Base: merge, convert, show
using Base.Iterators: Repeated, repeated
using LinearAlgebra

import AbstractPlotting: to_font, glyph_uv_width!, glyph_scale!
import ..GLMakie: get_texture!

const GLBoundingBox = FRect3D

"""
Replacement of Pkg.dir("GLVisualize") --> GLVisualize.dir,
returning the correct path
"""
dir(dirs...) = joinpath(@__DIR__, dirs...)
using ..GLMakie: assetpath, loadasset

include("types.jl")
export CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, DISTANCEFIELD, TRIANGLE

include("visualize_interface.jl")
export visualize # Visualize an object
export visualize_default # get the default parameter for a visualization

include("utils.jl")


include(joinpath("visualize", "lines.jl"))
include(joinpath("visualize", "image_like.jl"))
include(joinpath("visualize", "mesh.jl"))
include(joinpath("visualize", "particles.jl"))
include(joinpath("visualize", "surface.jl"))

end # module
