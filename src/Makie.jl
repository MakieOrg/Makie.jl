__precompile__(true)
module Makie

using Reactive, GeometryTypes, Colors, StaticArrays

using Colors, GeometryTypes, ColorVectorSpace
using Contour
import Quaternions
using Primes

using Base.Iterators: repeated, drop
using Fontconfig, FreeType, FreeTypeAbstraction, UnicodeFun
using IntervalSets
using PlotUtils, Showoff

using Base: RefValue
import Base: push!, isopen

include("logging.jl")
include("types.jl")
include("utils.jl")
include("signals.jl")
include("camera_math.jl")

include("scene.jl")

include("basic_drawing.jl")
include("basic_recipes.jl")
include("layouting.jl")

include("attribute_conversion.jl")

include("events.jl")
include("glbackend/glbackend.jl")
include("cairo/cairo.jl")

include("argument_conversion.jl")
include("plot.jl")
include("camera2d.jl")
include("camera3d.jl")
include("axis2d.jl")
include("axis3d.jl")
include("buffers.jl")
include("legend.jl")
include("output.jl")
include("gui.jl")

export Scene, Screen, plot!, CairoScreen, axis2d, RGBAf0
export Combined, Theme, node, @extract
export translated, translate!, transform!, scale!, rotate!, grid, Accum, Absolute
export @key_str, convert_attribute, Attributes, colorlegend, Node

# camera related
export cam2d!, campixel!, cam3d!, update_cam!

# picking
export mouseover, onpick, pick

# gui
export slider, button, playbutton

export (..) # reexport interval

# attribute_conversion shortcuts
export to_color, to_colormap, to_rotation, to_font, to_align, to_textsize

# Raymarching algorithms
export IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA


end
