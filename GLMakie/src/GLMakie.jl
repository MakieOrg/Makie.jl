module GLMakie

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    # GLMakie doesn't do much work, besides assembling shaders.
    # If it does, code should be 100% inferable, so hopefully shouldn't be influenced by this
    @eval Base.Experimental.@max_methods 1
end

const DEBUG = Ref(false)

using ModernGL, FixedPointNumbers, Colors, GeometryBasics
using Makie, FileIO

using Makie: @key_str, Key, broadcast_foreach, to_ndim, NativeFont
using Makie: Scene, Lines, Text, Image, Heatmap, Scatter
using Makie: convert_attribute, @extractvalue, LineSegments
using Makie: @get_attribute, to_value, to_colormap, extrema_nan
using Makie: ClosedInterval, (..)
using Makie: to_native
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
using Makie: BudgetedTimer, reset!
import Makie: to_font, el32convert, Shape, CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, DISTANCEFIELD, TRIANGLE
import Makie: RelocatableFolders

using ShaderAbstractions
using FreeTypeAbstraction
using GeometryBasics: StaticVector
using Observables

using Base: RefValue
import Base: push!, isopen, show
using Base.Iterators: repeated, drop

using LinearAlgebra

# re-export Makie, including deprecated names
for name in names(Makie, all = true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

import ShaderAbstractions: Sampler, Buffer
export Sampler, Buffer

struct ShaderSource
    typ::GLenum
    source::String
    name::String
end

function ShaderSource(path)
    typ = GLAbstraction.shadertype(splitext(path)[2])
    source = read(path, String)
    name = String(path)
    return ShaderSource(typ, source, name)
end

const SHADER_DIR = normpath(joinpath(@__DIR__, "..", "assets", "shader"))
const LOADED_SHADERS = Dict{String, ShaderSource}()
const WARN_ON_LOAD = Ref(false)

function loadshader(name)
    return get!(LOADED_SHADERS, name) do
        if WARN_ON_LOAD[]
            @warn("Reloading shader")
        end
        return ShaderSource(joinpath(SHADER_DIR, name))
    end
end

function load_all_shaders(folder)
    for name in readdir(folder)
        path = joinpath(folder, name)
        if isdir(path)
            load_all_shaders(path)
        elseif any(x -> endswith(name, x), [".frag", ".vert", ".geom"])
            path = relpath(path, SHADER_DIR)
            loadshader(replace(path, "\\" => "/"))
        end
    end
    return
end


gl_texture_atlas() = Makie.get_texture_atlas(2048, 64)

# don't put this into try catch, to not mess with normal errors
include("gl_backend.jl")

# We load all shaders to compile them into the package Image
# Making them relocatable
load_all_shaders(SHADER_DIR)
WARN_ON_LOAD[] = true

function __init__()
    activate!()
    # trigger OpenGL cleanup to avoid errors in debug mode
    return atexit(GLMakie.closeall)
end

include("precompiles.jl")

end
