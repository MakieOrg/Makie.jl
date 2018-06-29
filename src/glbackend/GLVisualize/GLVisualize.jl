module GLVisualize

using ..GLAbstraction
using ..Makie: RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA

using GLFW
using ModernGL
using StaticArrays
using GeometryTypes
using Colors
using Reactive
using FixedPointNumbers
using FileIO
using FreeType
import IterTools
using Base.Markdown
using FreeTypeAbstraction
using ImageCore
import ColorVectorSpace

import ImageCore
import AxisArrays, ImageAxes

import Base: merge, convert, show
using Base.Iterators: Repeated, repeated


using IndirectArrays
const HasAxesArray{T, N} = AxisArrays.AxisArray{T, N}
const AxisMatrix{T} = HasAxesArray{T, 2}


const GLBoundingBox = AABB{Float32}

"""
Replacement of Pkg.dir("GLVisualize") --> GLVisualize.dir,
returning the correct path
"""
dir(dirs...) = joinpath(@__DIR__, dirs...)

"""
returns path relative to the assets folder
"""
assetpath(folders...) = dir("assets", folders...)

"""
Loads a file from the asset folder
"""
function loadasset(folders...; kw_args...)
    path = assetpath(folders...)
    isfile(path) || isdir(path) || error("Could not locate file at $path")
    load(path; kw_args...)
end

export assetpath, loadasset


include("StructsOfArrays.jl")
using .StructsOfArrays

include("types.jl")
export CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, DISTANCEFIELD, TRIANGLE

include("config.jl")
include("boundingbox.jl")

include("visualize_interface.jl")
export visualize # Visualize an object
export visualize_default # get the default parameter for a visualization

include("utils.jl")
export y_partition, y_partition_abs
export x_partition, x_partition_abs
export loop, bounce

include(joinpath("visualize", "lines.jl"))
include(joinpath("visualize", "containers.jl"))
include(joinpath("visualize", "image_like.jl"))
include(joinpath("visualize", "mesh.jl"))
include(joinpath("visualize", "particles.jl"))
include(joinpath("visualize", "surface.jl"))
include(joinpath("visualize", "text.jl"))

end # module
