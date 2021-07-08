module Makie

module ContoursHygiene
    import Contour
end

using .ContoursHygiene
const Contours = ContoursHygiene.Contour
using Base64

using LaTeXStrings
export @L_str
using MathTeXEngine
using Artifacts
using Random
using FFMPEG # get FFMPEG on any system!
using Observables, GeometryBasics, IntervalSets, PlotUtils
using ColorBrewer, ColorTypes, Colors, ColorSchemes
using FixedPointNumbers, Packing, SignedDistanceFields
using Markdown, DocStringExtensions # documentation
using Serialization # serialize events
using StructArrays
using GeometryBasics: widths, positive_widths, VecTypes, AbstractPolygon, value
using StaticArrays
import StatsBase, Distributions, KernelDensity
using Distributions: Distribution, VariateForm, Discrete, QQPair, pdf, quantile, qqbuild
# Text related packages
using FreeType, FreeTypeAbstraction, UnicodeFun
using LinearAlgebra, Statistics
import ImageIO, FileIO, SparseArrays
import FileIO: save
using Printf: @sprintf
import Isoband
import PolygonOps
import GridLayoutBase
using MakieCore

import MakieCore: plot, plot!, theme, plotfunc, plottype, merge_attributes!, calculated_attributes!, get_attribute, plotsym, plotkey, attributes, used_attributes

using MakieCore: SceneLike, AbstractScreen, ScenePlot, AbstractScene, AbstractPlot, Transformable, Attributes, Combined, Theme, Plot

using MakieCore: Heatmap, Image, Lines, LineSegments, Mesh, MeshScatter, Scatter, Surface, Text, Volume
import MakieCore: heatmap, image, lines, linesegments, mesh, meshscatter, scatter, surface, text, volume
import MakieCore: heatmap!, image!, lines!, linesegments!, mesh!, meshscatter!, scatter!, surface!, text!, volume!

import MakieCore: convert_arguments, convert_attribute, default_theme, conversion_trait
using MakieCore: ConversionTrait, NoConversion, PointBased, SurfaceLike, ContinuousSurface, DiscreteSurface, VolumeLike
export ConversionTrait, NoConversion, PointBased, SurfaceLike, ContinuousSurface, DiscreteSurface, VolumeLike
using MakieCore: Key, @key_str, Automatic, automatic, @recipe
using MakieCore: Pixel, px, Unit, Billboard
export Pixel, px, Unit, plotkey, attributes, used_attributes

using StatsFuns: logit, logistic

# Imports from Base which we don't want to have to qualify
using Base: RefValue
using Base.Iterators: repeated, drop
import Base: getindex, setindex!, push!, append!, parent, get, get!, delete!, haskey
using Observables: listeners, to_value, notify

const RealVector{T} = AbstractVector{T} where T <: Number
const Node = Observable # shorthand
const RGBAf0 = RGBA{Float32}
const RGBf0 = RGB{Float32}
const NativeFont = FreeTypeAbstraction.FTFont







include("documentation/docstringextension.jl")

include("utilities/quaternions.jl")
include("interaction/PriorityObservable.jl")

struct ScalarOrVector{T}
    sv::Union{T, Vector{T}}
end

Base.convert(::Type{<:ScalarOrVector}, v::AbstractVector{T}) where T = ScalarOrVector{T}(collect(v))
Base.convert(::Type{<:ScalarOrVector}, x::T) where T = ScalarOrVector{T}(x)
Base.convert(::Type{<:ScalarOrVector{T}}, x::ScalarOrVector{T}) where T = x

function collect_vector(sv::ScalarOrVector, n::Int)
    if sv.sv isa Vector
        if length(sv.sv) != n
            error("Requested collected vector with $n elements, contained vector had $(length(sv.sv)) elements.")
        end
        sv.sv
    else
        [sv.sv for i in 1:n]
    end
end

"""
    GlyphCollection

Stores information about the glyphs in a string that had a layout calculated for them.
"""
struct GlyphCollection
    glyphs::Vector{Char}
    fonts::Vector{FTFont}
    origins::Vector{Point3f0}
    extents::Vector{FreeTypeAbstraction.FontExtent{Float32}}
    scales::ScalarOrVector{Vec2f0}
    rotations::ScalarOrVector{Quaternionf0}
    colors::ScalarOrVector{RGBAf0}
    strokecolors::ScalarOrVector{RGBAf0}
    strokewidths::ScalarOrVector{Float32}

    function GlyphCollection(glyphs, fonts, origins, extents, scales, rotations,
            colors, strokecolors, strokewidths)

        n = length(glyphs)
        @assert length(fonts)  == n
        @assert length(origins)  == n
        @assert length(extents)  == n
        @assert attr_broadcast_length(scales) in (n, 1)
        @assert attr_broadcast_length(rotations)  in (n, 1)
        @assert attr_broadcast_length(colors) in (n, 1)

        rotations = convert_attribute(rotations, key"rotation"())
        fonts = [convert_attribute(f, key"font"()) for f in fonts]
        colors = convert_attribute(colors, key"color"())
        strokecolors = convert_attribute(strokecolors, key"color"())
        strokewidths = Float32.(strokewidths)
        new(glyphs, fonts, origins, extents, scales, rotations, colors, strokecolors, strokewidths)
    end
end


include("types.jl")
include("utilities/utilities.jl")
include("utilities/texture_atlas.jl")
include("interaction/nodes.jl")
include("interaction/liftmacro.jl")

include("colorsampler.jl")
include("patterns.jl")

# Basic scene/plot/recipe interfaces + types
include("scenes.jl")



struct Figure
    scene::Scene
    layout::GridLayoutBase.GridLayout
    content::Vector
    attributes::Attributes
    current_axis::Ref{Any}

    function Figure(args...)
        f = new(args...)
        current_figure!(f)
        f
    end
end

struct FigureAxisPlot
    figure::Figure
    axis
    plot::AbstractPlot
end

const FigureLike = Union{Scene, Figure, FigureAxisPlot}

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

# Node/Signal related
export Node, Observable, lift, map_once, to_value, on, onany, @lift, off, connect!

# utilities and macros
export @recipe, @extract, @extractvalue, @key_str, @get_attribute
export broadcast_foreach, to_vector, replace_automatic!

# conversion infrastructure
export @key_str, convert_attribute, convert_arguments
export to_color, to_colormap, to_rotation, to_font, to_align, to_textsize
export to_ndim, Reverse

# Transformations
export translated, translate!, scale!, rotate!, Accum, Absolute
export boundingbox, insertplots!, center!, translation, scene_limits

# Spaces for widths and markers
const PixelSpace = Pixel
export SceneSpace, PixelSpace, Pixel

# camera related
export AbstractCamera, EmptyCamera, Camera, Camera2D, Camera3D, cam2d!, cam2d
export campixel!, campixel, cam3d!, cam3d_cad!, old_cam3d!, old_cam3d_cad!
export update_cam!, rotate_cam!, translate_cam!, zoom!
export pixelarea, plots, cameracontrols, cameracontrols!, camera, events
export to_world

# picking + interactive use cases + events
export mouseover, ispressed, onpick, pick, Events, Keyboard, Mouse, mouse_selection
export register_callbacks
export window_area
export window_open
export mouse_buttons
export mouse_position
export scroll
export keyboard_buttons
export unicode_input
export dropped_files
export hasfocus
export entered_window
export disconnect!, must_update, force_update!, update!, update_limits!
export DataInspector
export Consume

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


export Stepper, replay_events, record_events, RecordEvents, record, VideoStream
export VideoStream, recordframe!, record
export save

# colormap stuff from PlotUtils, and showgradients
export cgrad, available_gradients, showgradients

export Pattern

assetpath(files...) = normpath(joinpath(artifact"assets", files...))

export assetpath
# default icon for Makie
function icon()
    path = assetpath("icons")
    icons = FileIO.load.(joinpath.(path, readdir(path)))
    return reinterpret.(NTuple{4,UInt8}, icons)
end

function logo()
    FileIO.load(assetpath("misc", "makie_logo.png"))
end

function __init__()
    cfg_path = joinpath(homedir(), ".config", "makie", "theme.jl")
    if isfile(cfg_path)
        @warn "The global configuration file is no longer supported." *
        "Please include the file manually with `include(\"$cfg_path\")` before plotting."
    end
end


include("figures.jl")
export content

include("makielayout/MakieLayout.jl")
# re-export MakieLayout
for name in names(MakieLayout)
    @eval import .MakieLayout: $(name)
    @eval export $(name)
end

include("figureplotting.jl")
include("basic_recipes/series.jl")

export Heatmap, Image, Lines, LineSegments, Mesh, MeshScatter, Scatter, Surface, Text, Volume
export heatmap, image, lines, linesegments, mesh, meshscatter, scatter, surface, text, volume
export heatmap!, image!, lines!, linesegments!, mesh!, meshscatter!, scatter!, surface!, text!, volume!



function project_point2(mat4, point2)
    Point2f0(mat4 * to_ndim(Point4f0, to_ndim(Point3f0, point2, 0), 1))
end


function plot!(plot::Text{<:Tuple{<:Union{LaTeXString, AbstractVector{<:LaTeXString}}}})

    # attach a function to any text that calculates the glyph layout and stores it
    lineels_glyphcollection_offset = lift(plot[1], plot.textsize, plot.align, plot.rotation,
            plot.model, plot.color, plot.strokecolor, plot.strokewidth, plot.position) do latexstring,
                ts, al, rot, mo, color, scolor, swidth, _


        ts = to_textsize(ts)
        rot = to_rotation(rot)
        col = to_color(color)

        if latexstring isa AbstractVector
            tex_elements = []
            glyphcollections = GlyphCollection[]
            offsets = Point2f0[]
            broadcast_foreach(latexstring, ts, al, rot, color, scolor, swidth) do latexstring,
                ts, al, rot, color, scolor, swidth

                te, gc, offs = texelems_and_glyph_collection(latexstring, ts,
                    al[1], al[2], rot, color, scolor, swidth)
                push!(tex_elements, te)
                push!(glyphcollections, gc)
                push!(offsets, offs)
            end
            tex_elements, glyphcollections, offsets
        else
            tex_elements, glyphcollection, offset = texelems_and_glyph_collection(latexstring, ts,
                al[1], al[2], rot, color, scolor, swidth)
        end
    end

    glyphcollection = @lift($lineels_glyphcollection_offset[2])


    linepairs = Node(Tuple{Point2f0, Point2f0}[])
    linewidths = Node(Float32[])

    scene = Makie.parent_scene(plot)

    onany(lineels_glyphcollection_offset, scene.camera.projectionview) do (allels, gcs, offs), projview

        inv_projview = inv(projview)
        pos = plot.position[]
        ts = plot.textsize[]
        rot = plot.rotation[]

        ts = to_textsize(ts)
        rot = convert_attribute(rot, key"rotation"())

        empty!(linepairs.val)
        empty!(linewidths.val)

        # for the vector case, allels is a vector of vectors
        # so for broadcasting the single vector needs to be wrapped in Ref
        if gcs isa GlyphCollection
            allels = [allels]
        end
        broadcast_foreach(allels, offs, pos, ts, rot) do allels, offs, pos, ts, rot
            offset = Point2f0(pos)

            els = map(allels) do el
                el[1] isa VLine || el[1] isa HLine || return nothing

                t = el[1].thickness * ts
                p = el[2]

                ps = if el[1] isa VLine
                    h = el[1].height
                    (Point2f0(p[1], p[2]) .* ts, Point2f0(p[1], p[2] + h) .* ts) .- Ref(offs)
                else
                    w = el[1].width
                    (Point2f0(p[1], p[2]) .* ts, Point2f0(p[1] + w, p[2]) .* ts) .- Ref(offs)
                end
                ps = Ref(rot) .* to_ndim.(Point3f0, ps, 0)
                # TODO the points need to be projected to work inside Axis
                # ps = project ps with projview somehow

                ps = Point2f0.(ps) .+ Ref(offset)
                ps, t
            end
            pairs = filter(!isnothing, els)
            append!(linewidths.val, repeat(last.(pairs), inner = 2))
            append!(linepairs.val, first.(pairs))
        end
        notify(linepairs)
    end

    notify(plot.position)

    text!(plot, glyphcollection; plot.attributes...)
    linesegments!(plot, linepairs, linewidth = linewidths, color = plot.color)

    plot
end

function texelems_and_glyph_collection(str::LaTeXString, fontscale_px, halign, valign,
        rotation, color, strokecolor, strokewidth)

    rot = convert_attribute(rotation, key"rotation"())

    all_els = generate_tex_elements(str.s[2:end-1])
    els = filter(x -> x[1] isa TeXChar, all_els)

    # hacky, but attr per char needs to be fixed
    fs = Vec2f0(first(fontscale_px))

    scales_2d = [Vec2f0(x[3] * Vec2f0(fs)) for x in els]

    chars = [x[1].char for x in els]
    fonts = [x[1].font for x in els]

    extents = [FreeTypeAbstraction.get_extent(f, c) for (f, c) in zip(fonts, chars)]

    bboxes = map(extents, fonts, scales_2d) do ext, font, scale
        unscaled_hi_bb = FreeTypeAbstraction.height_insensitive_boundingbox(ext, font)
        hi_bb = FRect2D(
            origin(unscaled_hi_bb) * scale,
            widths(unscaled_hi_bb) * scale
        )
    end

    basepositions = [to_ndim(Vec3f0, fs, 0) .* to_ndim(Point3f0, x[2], 0)
        for x in els]

    bb = isempty(bboxes) ? BBox(0, 0, 0, 0) : begin
        mapreduce(union, zip(bboxes, basepositions)) do (b, pos)
            FRect2D(FRect3D(b) + pos)
        end
    end


    xshift = if halign == :center
        width(bb) / 2
    elseif halign == :left
        minimum(bb)[1]
    elseif halign == :right
        maximum(bb)[1]
    end

    yshift = if valign == :center
        maximum(bb)[2] - (height(bb) / 2)
    elseif valign == :top
        maximum(bb)[2]
    else
        minimum(bb)[2]
    end

    positions = basepositions .- Ref(Point3f0(xshift, yshift, 0))
    positions .= Ref(rot) .* positions

    pre_align_gl = GlyphCollection(
        chars,
        fonts,
        Point3f0.(positions),
        extents,
        scales_2d,
        rot,
        color,
        strokecolor,
        strokewidth,
    )

    all_els, pre_align_gl, Point2f0(xshift, yshift)
end

MakieLayout.iswhitespace(l::LaTeXString) = MakieLayout.iswhitespace(l.s[2:end-1])


end # module
