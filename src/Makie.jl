__precompile__(true)
module Makie

using AbstractPlotting
importall AbstractPlotting
using AbstractPlotting: @info, @log_performance, @warn, jl_finalizer, NativeFont, Key, @key_str

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

# functions we overload

include("scene.jl")
include("makie_recipes.jl")
include("argument_conversion.jl")
include("tickranges.jl")
include("utils.jl")
include("glbackend/glbackend.jl")
include("cairo/cairo.jl")
include("output.jl")

export Scene
# Abstract/Concrete scene + plot types
export AbstractScene, SceneLike, Scene, AbstractScreen
export AbstractPlot, Combined, Atomic

# Theming, working with Plots
export Attributes, Theme, attributes, arguments, default_theme

# Node/Signal related
export Node, node, lift, map_once

# utilities and macros
export @recipe, @extract, @extractvalue, @key_str, @get_attribute

# conversion infrastructure
export @key_str, convert_attribute, convert_arguments
export to_color, to_colormap, to_rotation, to_font, to_align, to_textsize
export to_ndim

# Transformations
export translated, translate!, transform!, scale!, rotate!, grid, Accum, Absolute

# camera related
export AbstractCamera, EmptyCamera, Camera, Camera2D, Camera3D, cam2d!, campixel!, cam3d!, update_cam!
export pixelarea, plots, cameracontrols, cameracontrols!, camera, events

# picking + interactive use cases + events
export mouseover, onpick, pick, Events
export register_callbacks, window_area, window_open, mouse_buttons
export mouse_position, mousedrag, scroll, keyboard_buttons, unicode_input
export dropped_files, hasfocus, entered_window, disconnect!, must_update, force_update!

# gui
export slider, button, playbutton

# Raymarching algorithms
export RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection
export AbsorptionRGBA, IndexedAbsorptionRGBA
export Billboard

# Reexports of
# Color/Vector types convenient for 3d/2d graphics
export RGBAf0, VecTypes, RealVector, IRect, FRect, FRect2D, IRect, IRect2D
export FRect3D, IRect3D, Rect3D, Transformation, RGBAf0, Quaternionf0
export Point2f0, Vec2f0, Vec3f0, Point3f0
export GLNormalMesh, GLUVmesh, GLNormalUVMesh, Sphere

for func in AbstractPlotting.atomic_function_symbols
    @eval export $(func)
    @eval export $(Symbol("$(func)!"))
end
export wireframe
export (..)

end
