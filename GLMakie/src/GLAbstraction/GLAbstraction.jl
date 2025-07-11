module GLAbstraction

using GeometryBasics
using ModernGL
using Makie
using FixedPointNumbers
using ColorTypes
using ..GLMakie.GLFW
using ..GLMakie: ShaderSource
import ..GLMakie.Makie.ComputePipeline: update!
import ..GLMakie: DEBUG
using Printf
using LinearAlgebra
using Observables
using ShaderAbstractions
using ShaderAbstractions: current_context, is_context_active, context_alive, switch_context!
using GeometryBasics: StaticVector

import FixedPointNumbers: N0f8, N0f16, N0f8, Normed

import Base: merge, resize!, similar, length, getindex, setindex!

# Debug tools
const CONTEXT_LOCK1 = ReentrantLock()
const CONTEXT_LOCK2 = ReentrantLock()

# implemented in GLMakie/glwindow.jl
function require_context_no_error(args...) end

function require_context(ctx, current = ShaderAbstractions.current_context())
    msg = require_context_no_error(ctx, current)
    isnothing(msg) && return nothing
    error(msg)
end

function gl_switch_context!(context = nothing)
    return lock(CONTEXT_LOCK1) do
        if isnothing(context)
            ShaderAbstractions.switch_context!()
        elseif ShaderAbstractions.context_alive(context)
            ShaderAbstractions.switch_context!(context)
        else
            error("Switching to unalived context!")
        end
    end
end

function with_context(f, context)
    if !ShaderAbstractions.context_alive(context)
        error("Context is not alive anymore!")
    end
    old_ctx = nothing
    lock(CONTEXT_LOCK1) do
        CTX = ShaderAbstractions.ACTIVE_OPENGL_CONTEXT
        old_ctx = isassigned(CTX) ? CTX[] : nothing
        ShaderAbstractions.switch_context!(context)
    end
    return try
        f()
    finally
        if isnothing(old_ctx) || !ShaderAbstractions.context_alive(old_ctx)
            gl_switch_context!()
        else
            gl_switch_context!(old_ctx)
        end
    end
end

export require_context, with_context, gl_switch_context!

include("AbstractGPUArray.jl")

#Methods which get overloaded by GLExtendedFunctions.jl:
import ModernGL.glShaderSource
import ModernGL.glGetAttachedShaders
import ModernGL.glGetActiveUniform
import ModernGL.glGetActiveAttrib
import ModernGL.glGetProgramiv
import ModernGL.glGetIntegerv
import ModernGL.glGenBuffers
import ModernGL.glGetProgramiv
import ModernGL.glGenVertexArrays
import ModernGL.glGenTextures
import ModernGL.glGenFramebuffers
import ModernGL.glGetTexLevelParameteriv
import ModernGL.glGenRenderbuffers
import ModernGL.glDeleteTextures
import ModernGL.glDeleteVertexArrays
import ModernGL.glDeleteBuffers
import ModernGL.glGetShaderiv
import ModernGL.glViewport
import ModernGL.glScissor

include("shaderabstraction.jl")
include("GLUtils.jl")

include("GLTypes.jl")
export GLProgram                # Shader/program object
export Texture                  # Texture object, basically a 1/2/3D OpenGL data array
export TextureParameters
export TextureBuffer            # OpenGL texture buffer
export update!                  # updates a gpu array with a Julia array
export gpu_data                 # gets the data of a gpu array as a Julia Array

export RenderObject             # An object which holds all GPU handles and datastructes to ready for rendering by calling render(obj)
export prerender!               # adds a function to a RenderObject, which gets executed before setting the OpenGL render state
export postrender!              # adds a function to a RenderObject, which gets executed after setting the OpenGL render states
export extract_renderable
export set_arg!
export GLVertexArray            # VertexArray wrapper object
export GLBuffer                 # OpenGL Buffer object wrapper
export indexbuffer              # Shortcut to create an OpenGL Buffer object for indexes (1D, cardinality of one and GL_ELEMENT_ARRAY_BUFFER set)
export opengl_compatible        # infers if a type is opengl compatible and returns stats like cardinality and eltype (will be deprecated)
export cardinality              # returns the cardinality of the elements of a buffer

export mergedefault!            # merges a style dict via a given style
export TOrSignal, VecOrSignal, ArrayOrSignal, MatOrSignal, VolumeOrSignal, ArrayTypes, VectorTypes, MatTypes, VolumeTypes
export MouseButton, MOUSE_LEFT, MOUSE_MIDDLE, MOUSE_RIGHT

include("GLExtendedFunctions.jl")
export glTexImage # Julian wrapper for glTexImage1D, glTexImage2D, glTexImage3D
include("GLShader.jl")
export Shader                 #Shader Type
export readshader             #reads a shader
export glsl_variable_access # creates access string from julia variable for the use in glsl shaders
export createview #creates a view from a templated shader
export TemplateProgram # Creates a shader from a Mustache view and and a shader file, which uses mustache syntax to replace values.
export @comp_str #string macro for the different shader types.
export @frag_str # with them you can write frag""" ..... """, returning shader object
export @vert_str
export @geom_str
export AbstractLazyShader, LazyShader

include("GLUniforms.jl")
export gluniform                # wrapper of all the OpenGL gluniform functions, which call the correct gluniform function via multiple dispatch. Example: gluniform(location, x::Matrix4x4) = gluniformMatrix4fv(location, x)
export toglsltype_string        # infers a glsl type string from a julia type. Example: Matrix4x4 -> uniform mat4
# Also exports Macro generated GLSL alike aliases for Float32 Matrices and Vectors
# only difference to GLSL: first character is uppercase uppercase
export gl_convert


include("GLRender.jl")
export render  #renders arbitrary objects
export enabletransparency # can be pushed to an renderobject, enables transparency
export renderinstanced # renders objects instanced

include("GLInfo.jl")
export getUniformsInfo
export getProgramInfo
export getAttributesInfo

end # module
