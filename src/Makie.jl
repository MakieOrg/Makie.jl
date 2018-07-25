__precompile__(true)
module Makie



using AbstractPlotting
using Reactive, GeometryTypes, Colors, ColorVectorSpace, StaticArrays
import IntervalSets
using IntervalSets: ClosedInterval, (..)
using ImageCore
import Media, Juno
import FileIO

module ContoursHygiene
    import Contour
end
using .ContoursHygiene
const Contours = ContoursHygiene.Contour

using Primes
using Base.Iterators: repeated, drop
using FreeType, FreeTypeAbstraction, UnicodeFun
using PlotUtils, Showoff
using Base: RefValue
import Base: push!, isopen, show

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
    @eval export $(name)
end

# Unexported names
using AbstractPlotting: @info, @log_performance, @warn, jl_finalizer, NativeFont, Key, @key_str

export (..), GLNormalUVMesh
# conflicting identifiers
using AbstractPlotting: Text, volume, VecTypes
using GeometryTypes: widths
export widths, decompose

# NamedTuple shortcut for 0.6, for easy creation of nested attributes
const NT = Theme
export NT

const has_ffmpeg = Ref(false)

struct MakieDisplay <: Display
end

# Hacky workaround, for the difficulty of removing closed screens from the display stack
# So we just leave the makiedisplay on stack, and then just get the singleton gl display for now!
function Base.display(::MakieDisplay, scene::Scene)
    display(global_gl_screen(), scene)
end

function __init__()
    has_ffmpeg[] = try
        success(`ffmpeg -h`)
    catch
        false
    end
    pushdisplay(MakieDisplay())
end

function logo()
    FileIO.load(joinpath(@__DIR__, "..", "docs", "src", "assets", "logo.png"))
end

include("makie_recipes.jl")
include("utils.jl")
include("glbackend/glbackend.jl")
include("cairo/cairo.jl")
include("output.jl")
include("video_io.jl")


end
