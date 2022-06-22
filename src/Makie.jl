module Makie

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    @eval Base.Experimental.@max_methods 1
end

module ContoursHygiene
    import Contour
end

using .ContoursHygiene
const Contours = ContoursHygiene.Contour
using Base64

using LaTeXStrings
using MathTeXEngine
using Random
using FFMPEG # get FFMPEG on any system!
using Observables
using GeometryBasics
using PlotUtils
using ColorBrewer
using ColorTypes
using Colors
using ColorSchemes
using Packing
using SignedDistanceFields
using Markdown
using DocStringExtensions # documentation
using Serialization # serialize events
using StructArrays
# Text related packages
using FreeType
using FreeTypeAbstraction
using UnicodeFun
using LinearAlgebra
using Statistics
using MakieCore
using OffsetArrays

import RelocatableFolders
import StatsBase
import Distributions
import KernelDensity
import Isoband
import PolygonOps
import GridLayoutBase
import ImageIO
import FileIO
import SparseArrays

using IntervalSets: IntervalSets, (..), OpenInterval, ClosedInterval, AbstractInterval, Interval, endpoints
using FixedPointNumbers: N0f8

using GeometryBasics: width, widths, height, positive_widths, VecTypes, AbstractPolygon, value, StaticVector
using Distributions: Distribution, VariateForm, Discrete, QQPair, pdf, quantile, qqbuild

import FileIO: save
import FreeTypeAbstraction: height_insensitive_boundingbox
using Printf: @sprintf
using StatsFuns: logit, logistic
# Imports from Base which we don't want to have to qualify
using Base: RefValue
using Base.Iterators: repeated, drop
import Base: getindex, setindex!, push!, append!, parent, get, get!, delete!, haskey
using Observables: listeners, to_value, notify

using MakieCore: SceneLike, AbstractScreen, ScenePlot, AbstractScene, AbstractPlot, Transformable, Attributes, Combined, Theme, Plot
using MakieCore: Heatmap, Image, Lines, LineSegments, Mesh, MeshScatter, Scatter, Surface, Text, Volume
using MakieCore: ConversionTrait, NoConversion, PointBased, SurfaceLike, ContinuousSurface, DiscreteSurface, VolumeLike
using MakieCore: Key, @key_str, Automatic, automatic, @recipe
using MakieCore: Pixel, px, Unit, Billboard
using MakieCore: not_implemented_for
import MakieCore: plot, plot!, theme, plotfunc, plottype, merge_attributes!, calculated_attributes!,
get_attribute, plotsym, plotkey, attributes, used_attributes
import MakieCore: heatmap, image, lines, linesegments, mesh, meshscatter, scatter, surface, text, volume
import MakieCore: heatmap!, image!, lines!, linesegments!, mesh!, meshscatter!, scatter!, surface!, text!, volume!
import MakieCore: convert_arguments, convert_attribute, default_theme, conversion_trait
import MakieCore: @convert_target, convert_arguments_typed

export @L_str
export ConversionTrait, NoConversion, PointBased, SurfaceLike, ContinuousSurface, DiscreteSurface, VolumeLike
export Pixel, px, Unit, plotkey, attributes, used_attributes

const RealVector{T} = AbstractVector{T} where T <: Number
const RGBAf = RGBA{Float32}
const RGBf = RGB{Float32}
const NativeFont = FreeTypeAbstraction.FTFont

include("documentation/docstringextension.jl")
include("utilities/quaternions.jl")
include("types.jl")
include("utilities/texture_atlas.jl")
include("interaction/observables.jl")
include("interaction/liftmacro.jl")
include("colorsampler.jl")
include("patterns.jl")
include("utilities/utilities.jl") # need Makie.AbstractPattern
# Basic scene/plot/recipe interfaces + types
include("scenes.jl")

include("theming.jl")
include("themes/theme_ggplot2.jl")
include("themes/theme_black.jl")
include("themes/theme_minimal.jl")
include("themes/theme_light.jl")
include("themes/theme_dark.jl")
include("interfaces.jl")
include("units.jl")
include("conversions.jl")
include("shorthands.jl")

# camera types + functions
include("camera/projection_math.jl")
include("camera/camera.jl")
include("camera/camera2d.jl")
include("camera/camera3d.jl")
include("camera/old_camera3d.jl")

# basic recipes
include("basic_recipes/convenience_functions.jl")
include("basic_recipes/ablines.jl")
include("basic_recipes/annotations.jl")
include("basic_recipes/arc.jl")
include("basic_recipes/arrows.jl")
include("basic_recipes/axis.jl")
include("basic_recipes/band.jl")
include("basic_recipes/barplot.jl")
include("basic_recipes/buffers.jl")
include("basic_recipes/contours.jl")
include("basic_recipes/contourf.jl")
include("basic_recipes/error_and_rangebars.jl")
include("basic_recipes/hvlines.jl")
include("basic_recipes/hvspan.jl")
include("basic_recipes/pie.jl")
include("basic_recipes/poly.jl")
include("basic_recipes/scatterlines.jl")
include("basic_recipes/spy.jl")
include("basic_recipes/stairs.jl")
include("basic_recipes/stem.jl")
include("basic_recipes/streamplot.jl")
include("basic_recipes/timeseries.jl")
include("basic_recipes/volumeslices.jl")
include("basic_recipes/wireframe.jl")

# layouting of plots
include("layouting/transformation.jl")
include("layouting/data_limits.jl")
include("layouting/layouting.jl")
include("layouting/boundingbox.jl")
# more default recipes
# statistical recipes
include("stats/conversions.jl")
include("stats/hist.jl")
include("stats/density.jl")
include("stats/ecdf.jl")
include("stats/distributions.jl")
include("stats/crossbar.jl")
include("stats/boxplot.jl")
include("stats/violin.jl")

# Interactiveness
include("interaction/events.jl")
include("interaction/interactive_api.jl")
include("interaction/inspector.jl")

# documentation and help functions
include("documentation/documentation.jl")
include("display.jl")

# help functions and supporting functions
export help, help_attributes, help_arguments

# Abstract/Concrete scene + plot types
export AbstractScene, SceneLike, Scene, AbstractScreen
export AbstractPlot, Combined, Atomic, OldAxis

# Theming, working with Plots
export Attributes, Theme, attributes, default_theme, theme, set_theme!, with_theme, update_theme!
export xlims!, ylims!, zlims!
export xlabel!, ylabel!, zlabel!

export theme_ggplot2
export theme_black
export theme_minimal
export theme_light
export theme_dark

export xticklabels, yticklabels, zticklabels
export xtickrange, ytickrange, ztickrange
export xticks!, yticks!, zticks!
export xtickrotation, ytickrotation, ztickrotation
export xtickrotation!, ytickrotation!, ztickrotation!

# Observable/Signal related
export Observable, Observable, lift, map_once, to_value, on, onany, @lift, off, connect!

# utilities and macros
export @recipe, @extract, @extractvalue, @key_str, @get_attribute
export broadcast_foreach, to_vector, replace_automatic!

# conversion infrastructure
export @key_str, convert_attribute, convert_arguments
export to_color, to_colormap, to_rotation, to_font, to_align, to_textsize, categorical_colors, resample_cmap
export to_ndim, Reverse

# Transformations
export translated, translate!, scale!, rotate!, Accum, Absolute
export boundingbox, insertplots!, center!, translation, data_limits

# Spaces for widths and markers
const PixelSpace = Pixel
export SceneSpace, PixelSpace, Pixel

# camera related
export AbstractCamera, EmptyCamera, Camera, Camera2D, Camera3D, cam2d!, cam2d
export campixel!, campixel, cam3d!, cam3d_cad!, old_cam3d!, old_cam3d_cad!, cam_relative!
export update_cam!, rotate_cam!, translate_cam!, zoom!
export pixelarea, plots, cameracontrols, cameracontrols!, camera, events
export to_world

# picking + interactive use cases + events
export mouseover, onpick, pick, Events, Keyboard, Mouse, mouse_selection, is_mouseinside
export ispressed, Exclusively
export connect_screen
export window_area, window_open, mouse_buttons, mouse_position, mouseposition_px,
       scroll, keyboard_buttons, unicode_input, dropped_files, hasfocus, entered_window
export disconnect!
export DataInspector
export Consume

# Raymarching algorithms
export RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA
export Billboard

# Reexports of
# Color/Vector types convenient for 3d/2d graphics
export Quaternion, Quaternionf, qrotation
export RGBAf, RGBf, VecTypes, RealVector
export Transformation
export Sphere, Circle
export Vec4f, Vec3f, Vec2f, Point4f, Point3f, Point2f
export Vec, Vec2, Vec3, Vec4, Point, Point2, Point3, Point4
export (..)
export Rect, Rectf, Rect2f, Rect2i, Rect3f, Rect3i, Rect3, Recti, Rect2
export widths, decompose

# building blocks for series recipes
export PlotSpec

export plot!, plot
export abline! # until deprecation removal


export Stepper, replay_events, record_events, RecordEvents, record, VideoStream
export VideoStream, recordframe!, record
export save

# colormap stuff from PlotUtils, and showgradients
export cgrad, available_gradients, showgradients

export Pattern

const ASSETS_DIR = RelocatableFolders.@path joinpath(@__DIR__, "..", "assets")
assetpath(files...) = normpath(joinpath(ASSETS_DIR, files...))

export assetpath
# default icon for Makie
function icon()
    path = assetpath("icons")
    imgs = FileIO.load.(joinpath.(path, readdir(path)))
    icons = map(img-> RGBA{Colors.N0f8}.(img), imgs)
    return reinterpret.(NTuple{4,UInt8}, icons)
end

function logo()
    FileIO.load(assetpath("logo.png"))
end

function __init__()
    # Make GridLayoutBase default row and colgaps themeable when using Makie
    # This mutates module-level state so it could mess up other libraries using
    # GridLayoutBase at the same time as Makie, which is unlikely, though
    GridLayoutBase.DEFAULT_COLGAP_GETTER[] = function()
        ct = Makie.current_default_theme()
        if haskey(ct, :colgap)
            ct[:colgap][]
        else
            GridLayoutBase.DEFAULT_COLGAP[]
        end
    end
    GridLayoutBase.DEFAULT_ROWGAP_GETTER[] = function()
        ct = Makie.current_default_theme()
        if haskey(ct, :rowgap)
            ct[:rowgap][]
        else
            GridLayoutBase.DEFAULT_ROWGAP[]
        end
    end

    cfg_path = joinpath(homedir(), ".config", "makie", "theme.jl")
    if isfile(cfg_path)
        @warn "The global configuration file is no longer supported." *
        "Please include the file manually with `include(\"$cfg_path\")` before plotting."
    end
end

include("figures.jl")
export content
export resize_to_layout!

include("makielayout/MakieLayout.jl")
include("figureplotting.jl")
include("basic_recipes/series.jl")
include("basic_recipes/text.jl")
include("basic_recipes/raincloud.jl")

export Heatmap, Image, Lines, LineSegments, Mesh, MeshScatter, Scatter, Surface, Text, Volume
export heatmap, image, lines, linesegments, mesh, meshscatter, scatter, surface, text, volume
export heatmap!, image!, lines!, linesegments!, mesh!, meshscatter!, scatter!, surface!, text!, volume!

export PointLight, EnvironmentLight, AmbientLight, SSAO

include("precompiles.jl")

end # module
