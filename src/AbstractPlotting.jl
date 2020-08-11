module AbstractPlotting

using Random
using FFMPEG # get FFMPEG on any system!
using Observables, GeometryBasics, IntervalSets, PlotUtils
using ColorBrewer, ColorTypes, Colors, ColorSchemes
using FixedPointNumbers, Packing, SignedDistanceFields
using Markdown, DocStringExtensions # documentation
using Serialization # serialize events
using StructArrays
using GeometryBasics: widths, positive_widths, VecTypes
using StaticArrays
import StatsBase, Distributions, KernelDensity
using Distributions: Distribution, VariateForm, Discrete, QQPair, pdf, quantile, qqbuild
# Text related packages
using FreeType, FreeTypeAbstraction, UnicodeFun
using LinearAlgebra, Statistics
import ImageIO, FileIO, SparseArrays
import FileIO: save
using Printf: @sprintf

# Imports from Base which we don't want to have to qualify
using Base: RefValue
using Base.Iterators: repeated, drop
import Base: getindex, setindex!, push!, append!, parent, get, get!, delete!, haskey
using Observables: listeners, notify!, to_value
# Imports from Observables which we use a lot
using Observables: notify!, listeners

module ContoursHygiene
    import Contour
end

using .ContoursHygiene
const Contours = ContoursHygiene.Contour

const RealVector{T} = AbstractVector{T} where T <: Number
const Node = Observable # shorthand
const RGBAf0 = RGBA{Float32}
const RGBf0 = RGB{Float32}
const NativeFont = FreeTypeAbstraction.FTFont

include("documentation/docstringextension.jl")

include("utilities/quaternions.jl")
include("attributes.jl")
include("dictlike.jl")
include("types.jl")
include("utilities/utilities.jl")
include("utilities/texture_atlas.jl")
include("interaction/nodes.jl")
include("interaction/liftmacro.jl")

include("colorsampler.jl")
include("patterns.jl")

# Basic scene/plot/recipe interfaces + types
include("scenes.jl")
include("theming.jl")
include("recipes.jl")
include("interfaces.jl")
include("units.jl")
include("conversions.jl")
include("shorthands.jl")

# camera types + functions
include("camera/projection_math.jl")
include("camera/camera.jl")
include("camera/camera2d.jl")
include("camera/camera3d.jl")

# some default recipes
include("basic_recipes/basic_recipes.jl")
include("basic_recipes/errorbars.jl")
include("basic_recipes/pie.jl")
# layouting of plots
include("layouting/transformation.jl")
include("layouting/data_limits.jl")
include("layouting/layouting.jl")
include("layouting/boundingbox.jl")
# more default recipes
include("basic_recipes/buffers.jl")
include("basic_recipes/axis.jl")
include("basic_recipes/legend.jl")
include("basic_recipes/title.jl")
# statistical recipes
include("stats/conversions.jl")
include("stats/histogram.jl")
include("stats/density.jl")
include("stats/distributions.jl")
include("stats/crossbar.jl")
include("stats/boxplot.jl")
include("stats/violin.jl")

# Interactiveness
include("interaction/events.jl")
include("interaction/gui.jl")
include("interaction/interactive_api.jl")

# documentation and help functions
include("documentation/documentation.jl")
include("display.jl")


# help functions and supporting functions
export help, help_attributes, help_arguments

# Abstract/Concrete scene + plot types
export AbstractScene, SceneLike, Scene, AbstractScreen
export AbstractPlot, Combined, Atomic, Axis

# Theming, working with Plots
export Attributes, Theme, attributes, default_theme, theme, set_theme!
export title
export xlims!, ylims!, zlims!
export xlabel!, ylabel!, zlabel!

export xticklabels, yticklabels, zticklabels
export xtickrange, ytickrange, ztickrange
export xticks!, yticks!, zticks!
export xtickrotation, ytickrotation, ztickrotation
export xtickrotation!, ytickrotation!, ztickrotation!

# Node/Signal related
export Node, Observable, lift, map_once, to_value, on, @lift

# utilities and macros
export @recipe, @extract, @extractvalue, @key_str, @get_attribute
export broadcast_foreach, to_vector, replace_automatic!

# conversion infrastructure
export @key_str, convert_attribute, convert_arguments
export to_color, to_colormap, to_rotation, to_font, to_align, to_textsize
export to_ndim, Reverse

# Transformations
export translated, translate!, transform!, scale!, rotate!, grid, Accum, Absolute
export boundingbox, insertplots!, center!, translation, scene_limits
export hbox, vbox

# Spaces for widths and markers
const PixelSpace = Pixel
export SceneSpace, PixelSpace, Pixel

# camera related
export AbstractCamera, EmptyCamera, Camera, Camera2D, Camera3D, cam2d!, cam2d
export campixel!, campixel, cam3d!, cam3d_cad!, update_cam!, rotate_cam!, translate_cam!, zoom!
export pixelarea, plots, cameracontrols, cameracontrols!, camera, events
export to_world

# picking + interactive use cases + events
export mouseover, ispressed, onpick, pick, Events, Keyboard, Mouse, mouse_selection
export register_callbacks
export window_area
export window_open
export mouse_buttons
export mouse_position
export mousedrag
export scroll
export keyboard_buttons
export unicode_input
export dropped_files
export hasfocus
export entered_window
export disconnect!, must_update, force_update!, update!, update_limits!

# currently special-cased functions (`textslider`) for example
export textslider

# gui
export slider, button, playbutton
export move!

# Raymarching algorithms
export RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA
export Billboard

# Reexports of
# Color/Vector types convenient for 3d/2d graphics
export Quaternion, Quaternionf0, qrotation
export RGBAf0, RGBf0, VecTypes, RealVector, FRect, FRect2D, IRect2D
export FRect3D, IRect3D, Rect3D, Transformation
export IRect, FRect, Rect, Rect2D, Sphere, Circle
export Vec4f0, Vec3f0, Vec2f0, Point4f0, Point3f0, Point2f0
export Vec, Vec2, Vec3, Vec4, Point, Point2, Point3, Point4
export (..), GLNormalUVMesh



export widths, decompose

# building blocks for series recipes
export PlotSpec

export plot!, plot


export Stepper, step!, replay_events, record_events, RecordEvents, record, VideoStream
export VideoStream, recordframe!, record
export save

# colormap stuff from PlotUtils, and showgradients
export cgrad, available_gradients, showgradients

export Pattern


# default icon for Makie
function icon()
    path = joinpath(dirname(pathof(AbstractPlotting)), "..", "assets", "icons")
    icons = FileIO.load.(joinpath.(path, readdir(path)))
    icons = reinterpret.(NTuple{4,UInt8}, icons)
end

function logo()
    FileIO.load(joinpath(dirname(@__DIR__), "assets", "misc", "makie_logo.png"))
end

function __init__()
    pushdisplay(PlotDisplay())
    cfg_path = joinpath(homedir(), ".config", "makie", "theme.jl")
    if isfile(cfg_path)
        @warn "The global configuration file is no longer supported."*
        "Please include the file manually with `include(\"$cfg_path\")` before plotting."
    end
end

include("makielayout/MakieLayout.jl")

end # module
