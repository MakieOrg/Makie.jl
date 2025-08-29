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

# Import FilePaths for invalidations
# When loading Electron for WGLMakie, which depends on FilePaths
# It invalidates half of Makie. Simplest fix is to load it early on in Makie
# So that the bulk of Makie gets compiled after FilePaths invalidadet Base code
import FilePaths
using LaTeXStrings
using MathTeXEngine
using Random
using FFMPEG_jll # get FFMPEG on any system!
using Observables
using GeometryBasics
using PlotUtils
using ColorBrewer
using ColorTypes
using Colors
using ColorSchemes
using CRC32c
using Packing
using SignedDistanceFields
using Markdown
using DocStringExtensions # documentation
using Scratch
using StructArrays
# Text related packages
using FreeType
using FreeTypeAbstraction
using LinearAlgebra
using Statistics
using OffsetArrays
using Downloads
using ShaderAbstractions
using Dates
using ComputePipeline

import Unitful
import UnicodeFun
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
import TriplotBase
import DelaunayTriangulation as DelTri
import REPL
import MacroTools

using IntervalSets: IntervalSets, (..), OpenInterval, ClosedInterval, AbstractInterval, Interval, endpoints, leftendpoint, rightendpoint
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

import InverseFunctions

export @L_str, @colorant_str
export ConversionTrait, NoConversion, PointBased, GridBased, VertexGrid, CellGrid, ImageLike, VolumeLike
export Pixel, px, Unit, plotkey, attributes, used_attributes
export Linestyle
using Pkg.Artifacts
assetpath(files...) = normpath(joinpath(artifact"MakieAssets", files...))
loadasset(files...) = FileIO.load(assetpath(files...))

const RGBAf = RGBA{Float32}
const RGBf = RGB{Float32}
const NativeFont = FreeTypeAbstraction.FTFont


# 1.6 compatible way to disable constprop for compile time improvements (and also disable inlining)
# We use this mainly in GLMakie to avoid a few bigger OpenGL based functions to get constant propagation
# (e.g. GLFrameBuffer((width, height)), which should not profit from any constant propagation)
macro noconstprop(expr)
    if isdefined(Base, Symbol("@constprop"))
        return esc(:(Base.@constprop :none @noinline $(expr)))
    else
        return esc(:(@noinline $(expr)))
    end
end

include("documentation/docstringextension.jl")
include("utilities/quaternions.jl")
include("utilities/stable-hashing.jl")
include("coretypes.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")
include("conversion.jl")
include("bezier.jl")
include("types.jl")
include("utilities/Plane.jl")
include("utilities/timing.jl")
include("utilities/texture_atlas.jl")
include("interaction/observables.jl")
include("interaction/liftmacro.jl")
include("colorsampler.jl")
include("patterns.jl")
include("utilities/utilities.jl") # need Makie.AbstractPattern
include("lighting.jl")
# Basic scene/plot/recipe interfaces + types

include("dim-converts/dim-converts.jl")
include("dim-converts/unitful-integration.jl")
include("dim-converts/dynamic-quantities-integration.jl")
include("dim-converts/categorical-integration.jl")
include("dim-converts/dates-integration.jl")

include("scenes.jl")
include("float32-scaling.jl")

include("interfaces.jl")
include("compute-plots.jl")
include("units.jl")
include("shorthands.jl")

# camera types + functions
include("camera/projection_math.jl")
include("camera/camera.jl")
include("camera/camera2d.jl")
include("camera/camera3d.jl")
include("camera/old_camera3d.jl")

include("utilities/projection_utils.jl")

# basic recipes
include("basic_recipes/convenience_functions.jl")
include("basic_recipes/ablines.jl")
include("basic_recipes/annotation.jl")
include("basic_recipes/arc.jl")
include("basic_recipes/arrows.jl")
include("basic_recipes/axis.jl")
include("basic_recipes/band.jl")
include("basic_recipes/barplot.jl")
include("basic_recipes/buffers.jl")
include("basic_recipes/bracket.jl")
include("basic_recipes/contours.jl")
include("basic_recipes/contourf.jl")
include("basic_recipes/datashader.jl")
include("basic_recipes/error_and_rangebars.jl")
include("basic_recipes/hvlines.jl")
include("basic_recipes/hvspan.jl")
include("basic_recipes/mesh.jl")
include("basic_recipes/pie.jl")
include("basic_recipes/poly.jl")
include("basic_recipes/scatterlines.jl")
include("basic_recipes/spy.jl")
include("basic_recipes/stairs.jl")
include("basic_recipes/stem.jl")
include("basic_recipes/streamplot.jl")
include("basic_recipes/timeseries.jl")
include("basic_recipes/tricontourf.jl")
include("basic_recipes/triplot.jl")
include("basic_recipes/volumeslices.jl")
include("basic_recipes/voronoiplot.jl")
include("basic_recipes/voxels.jl")
include("basic_recipes/waterfall.jl")
include("basic_recipes/wireframe.jl")
include("basic_recipes/textlabel.jl")
include("basic_recipes/tooltip.jl")

include("basic_recipes/makiecore_examples/scatter.jl")
include("basic_recipes/makiecore_examples/lines.jl")

# conversions: need to be after plot recipes
include("conversions.jl")

# uses to_color() from conversions.jl
include("theming.jl")
include("themes/theme_ggplot2.jl")
include("themes/theme_black.jl")
include("themes/theme_minimal.jl")
include("themes/theme_light.jl")
include("themes/theme_dark.jl")
include("themes/theme_latexfonts.jl")


# layouting of plots
include("layouting/transformation.jl")
include("layouting/data_limits.jl")
include("layouting/text_layouting.jl")
include("layouting/boundingbox.jl")
include("layouting/text_boundingbox.jl")

# Declarative SpecApi
include("specapi.jl")

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
include("stats/hexbin.jl")
include("stats/dendrogram.jl")


# Interactiveness
include("interaction/events.jl")
include("interaction/interactive_api.jl")
include("interaction/ray_casting.jl")
include("interaction/inspector.jl")

# documentation and help functions
include("documentation/documentation.jl")
include("display.jl")
include("ffmpeg-util.jl")
include("recording.jl")
include("event-recorder.jl")
include("backend-functionality.jl")

# bezier paths
export BezierPath, MoveTo, LineTo, CurveTo, EllipticalArc, ClosePath

# help functions and supporting functions
export help, help_attributes, help_arguments

# Abstract/Concrete scene + plot types
export AbstractScene, SceneLike, Scene, MakieScreen
export AbstractPlot, Plot, Atomic, OldAxis

# Theming, working with Plots
export Attributes, Theme, attributes, default_theme, theme, set_theme!, with_theme, update_theme!
export xlims!, ylims!, zlims!
export xlabel!, ylabel!, zlabel!

export theme_ggplot2
export theme_black
export theme_minimal
export theme_light
export theme_dark
export theme_latexfonts

export xticklabels, yticklabels, zticklabels
export xtickrange, ytickrange, ztickrange
export xticks!, yticks!, zticks!
export xtickrotation, ytickrotation, ztickrotation
export xtickrotation!, ytickrotation!, ztickrotation!
export Categorical

# Observable/Signal related
export Observable, Observable, lift, to_value, on, onany, @lift, off, connect!

# utilities and macros
export @recipe, @extract, @extractvalue, @key_str, @get_attribute
export broadcast_foreach, to_vector, replace_automatic!
export register_projected_positions!, register_projected_rotations_2d!
export register_position_transforms!, register_positions_transformed!, register_positions_transformed_f32c!

# conversion infrastructure
export @key_str, convert_attribute, convert_arguments
export to_color, to_colormap, to_rotation, to_font, to_align, to_fontsize, categorical_colors, resample_cmap
export to_ndim, Reverse

# Ticks
export DateTimeTicks

# Transformations
export translated, translate!, scale!, rotate!, origin!, Accum, Absolute
export boundingbox, insertplots!, center!, translation, data_limits

# Spaces for widths and markers
const PixelSpace = Pixel
export SceneSpace, PixelSpace, Pixel

# camera related
export AbstractCamera, EmptyCamera, Camera, Camera2D, Camera3D, cam2d!, cam2d
export campixel!, campixel, cam3d!, cam3d_cad!, old_cam3d!, old_cam3d_cad!, cam_relative!
export update_cam!, rotate_cam!, translate_cam!, zoom!
export viewport, plots, cameracontrols, cameracontrols!, camera, events
export to_world

# picking + interactive use cases + events
export mouseover, onpick, pick, Events, Keyboard, Mouse, is_mouseinside
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
export NoShading, FastShading, MultiLightShading

# Reexports of
# Color/Vector types convenient for 3d/2d graphics
export Quaternion, Quaternionf, qrotation
export RGBAf, RGBf, VecTypes, RealVector
export Transformation
export Sphere, Circle
for kind in (:Vec, :Point, :Rect)
    @eval export $kind
    for n in (2, 3, 4), typesuffix in ("f", "d", "i", "")
        kind === :Rect && n == 4 && continue
        @eval export $(Symbol(kind, n, typesuffix))
    end
end
export (..)
export Rectf, Recti, Rectd
export Plane3f, Plane3d # other planes aren't used much for Makie
export widths, decompose

# building blocks for series recipes
export PlotSpec

export plot!, plot
export abline! # until deprecation removal

export Stepper, replay_events, record_events, RecordEvents, record, VideoStream
export VideoStream, recordframe!, record, Record
export save, colorbuffer

# colormap stuff from PlotUtils, and showgradients
export cgrad, available_gradients, showgradients

# other "available" functions
export available_plotting_methods, available_marker_symbols


export Pattern
export ReversibleScale

export assetpath

using PNGFiles

# default icon for Makie
function load_icon(name::String)::Matrix{NTuple{4, UInt8}}
    img = PNGFiles.load(name)::Matrix{RGBA{Colors.N0f8}}
    return reinterpret(NTuple{4, UInt8}, img)
end

function icon()
    path = assetpath("icons")
    icons = readdir(path; join = true)
    return map(load_icon, icons)
end

function logo()
    return PNGFiles.load(assetpath("logo.png"))
end

# populated by __init__()
const makie_cache_dir = Ref{String}("")

function get_cache_path()
    if isempty(makie_cache_dir[])
        # If the cache dir is not set, we use a default location
        # This is used by the precompilation cache and other things
        makie_cache_dir[] = @get_scratch!("makie")
    end
    return makie_cache_dir[]
end

function __init__()
    # Make GridLayoutBase default row and colgaps themeable when using Makie
    # This mutates module-level state so it could mess up other libraries using
    # GridLayoutBase at the same time as Makie, which is unlikely, though
    GridLayoutBase.DEFAULT_COLGAP_GETTER[] = function ()
        return convert(Float64, to_value(Makie.theme(:colgap; default = GridLayoutBase.DEFAULT_COLGAP[])))
    end
    GridLayoutBase.DEFAULT_ROWGAP_GETTER[] = function ()
        return convert(Float64, to_value(Makie.theme(:rowgap; default = GridLayoutBase.DEFAULT_ROWGAP[])))
    end
    # fonts aren't cacheable by precompilation, so we need to empty it on load!
    empty!(FONT_CACHE)
    cfg_path = joinpath(homedir(), ".config", "makie", "theme.jl")
    if isfile(cfg_path)
        @warn "The global configuration file is no longer supported." *
            "Please include the file manually with `include(\"$cfg_path\")` before plotting."
    end
    return
end

include("figures.jl")
export content
export resize_to_layout!

include("makielayout/MakieLayout.jl")
include("figureplotting.jl")
include("basic_recipes/series.jl")
include("basic_recipes/text.jl")
include("basic_recipes/raincloud.jl")
include("deprecated.jl")

export Heatmap, Image, Lines, LineSegments, Mesh, MeshScatter, Poly, Scatter, Surface, Text, Volume, Wireframe, Voxels
export heatmap, image, lines, linesegments, mesh, meshscatter, poly, scatter, surface, text, volume, wireframe, voxels
export heatmap!, image!, lines!, linesegments!, mesh!, meshscatter!, poly!, scatter!, surface!, text!, volume!, wireframe!, voxels!

export arrows, arrows!

export AbstractLight, get_lights, set_lights!, set_light!, set_ambient_light!, push_light!
export set_shading_algorithm!, set_directional_light!
export AmbientLight, PointLight, DirectionalLight, SpotLight, EnvironmentLight, RectLight, SSAO
export FastPixel
export update!
export Ann

include("precompiles.jl")

end # module
