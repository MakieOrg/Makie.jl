__precompile__(true)
module Makie

using Reactive, GeometryTypes, Colors, StaticArrays

using Colors, GeometryTypes, GLVisualize, GLAbstraction, ColorVectorSpace
using StaticArrays, GLWindow, ModernGL, Contour
import Quaternions

using Base.Iterators: repeated, drop
using Base: RefValue
using Fontconfig, FreeType, FreeTypeAbstraction, UnicodeFun
using IntervalSets

include("types.jl")
include("utils.jl")
include("signals.jl")

GLAbstraction.gl_convert(x::Vector{Vec3f0}) = x

include("scene.jl")

include("basic_drawing.jl")
include("layouting.jl")

include("attribute_conversion.jl")


include("events.jl")
include("glbackend/glbackend.jl")

include("plot.jl")
include("camera2d.jl")
include("camera3d.jl")

export cam2d!, Scene, update_cam!, Screen, scatter

end
