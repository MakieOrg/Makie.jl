module AbstractPlotting

using Observables, GeometryTypes, StaticArrays, ColorTypes, Colors, IntervalSets
using ColorBrewer, FixedPointNumbers, Packing, SignedDistanceFields
using Markdown # documentation
using Serialization # serialize events

# Text related packages
using FreeType, FreeTypeAbstraction, UnicodeFun
using LinearAlgebra, Statistics
import ImageMagick, FileIO

using Base: RefValue
using Base.Iterators: repeated, drop
import Base: getindex, setindex!, push!, append!, parent, get, get!, delete!, haskey

module ContoursHygiene
    import Contour
end
using .ContoursHygiene
const Contours = ContoursHygiene.Contour

include("utilities/quaternions.jl")
include("types.jl")
include("utilities/utilities.jl")
include("utilities/logging.jl")
include("utilities/texture_atlas.jl")
include("interaction/nodes.jl")

# Basic scene/plot/recipe interfaces + types
include("scenes.jl")
include("theming.jl")
include("recipes.jl")
include("interfaces.jl")
include("conversions.jl")

# camera types + functions
include("camera/projection_math.jl")
include("camera/camera.jl")
include("camera/camera2d.jl")
include("camera/camera3d.jl")



# some default recipes
include("basic_recipes/basic_recipes.jl")
include("basic_recipes/multiple.jl")
# layouting of plots
include("layouting/transformation.jl")
include("layouting/data_limits.jl")
include("layouting/layouting.jl")
include("layouting/boundingbox.jl")
# more default recipes
include("basic_recipes/buffers.jl")
include("basic_recipes/axis.jl")
include("basic_recipes/legend.jl")

#
include("interaction/events.jl")
include("interaction/gui.jl")

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

# Node/Signal related
export Node, node, lift, map_once, to_value, on

# utilities and macros
export @recipe, @extract, @extractvalue, @key_str, @get_attribute
export broadcast_foreach, to_vector, replace_automatic!

# conversion infrastructure
export @key_str, convert_attribute, convert_arguments
export to_color, to_colormap, to_rotation, to_font, to_align, to_textsize
export to_ndim, Reverse

# Transformations
export translated, translate!, transform!, scale!, rotate!, grid, Accum, Absolute
export boundingbox, insertplots!, center!, translation
export hbox, vbox

# camera related
export AbstractCamera, EmptyCamera, Camera, Camera2D, Camera3D, cam2d!, cam2d
export campixel!, campixel, cam3d!, update_cam!, rotate_cam!, translate_cam!
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
export disconnect!, must_update, force_update!


# gui
export slider, button, playbutton

# Raymarching algorithms
export RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA
export Billboard

# Reexports of
# Color/Vector types convenient for 3d/2d graphics
export Quaternion, Quaternionf0, qrotation
export RGBAf0, RGBf0, VecTypes, RealVector, FRect, FRect2D, IRect2D
export FRect3D, IRect3D, Rect3D, Transformation
export IRect, FRect, Rect, Sphere, Circle
export Vec4f0, Vec3f0, Vec2f0, Point4f0, Point3f0, Point2f0
export Vec, Vec2, Vec3, Vec4, Point, Point2, Point3, Point4
export (..), GLNormalUVMesh
# conflicting identifiers
using GeometryTypes: widths
export widths, decompose

# building blocks for series recipes
export PlotList, PlotSpec

export plot!, plot


export Stepper, step!, replay_events, record_events, RecordEvents, record, VideoStream
export VideoStream, recordframe!, record

# default icon for Makie
function icon()
    path = joinpath(dirname(pathof(AbstractPlotting)), "..", "assets", "icons")
    icons = FileIO.load.(joinpath.(path, readdir(path)))
    icons = reinterpret.(NTuple{4,UInt8}, icons)
end

const cached_logo = Ref{String}()

function logo()
    if !isassigned(cached_logo)
        cached_logo[] = download(
            "https://raw.githubusercontent.com/JuliaPlots/Makie.jl/sd/abstract/docs/src/assets/logo.png",
            joinpath(@__DIR__, "logo.png")
        )
    end
    FileIO.load(cached_logo[])
end

end # module
