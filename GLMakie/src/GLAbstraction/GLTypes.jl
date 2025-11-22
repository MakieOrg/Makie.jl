############################################################################
const TOrSignal{T} = Union{Observable{T}, T}

const ArrayOrSignal{T, N} = TOrSignal{X} where {X <: AbstractArray{T, N}}
const VecOrSignal{T} = ArrayOrSignal{T, 1}
const MatOrSignal{T} = ArrayOrSignal{T, 2}
const VolumeOrSignal{T} = ArrayOrSignal{T, 3}

const ArrayTypes{T, N} = Union{GPUArray{T, N}, ArrayOrSignal{T, N}}
const VectorTypes{T} = ArrayTypes{T, 1}
const MatTypes{T} = ArrayTypes{T, 2}
const VolumeTypes{T} = ArrayTypes{T, 3}

@enum Projection PERSPECTIVE ORTHOGRAPHIC
@enum MouseButton MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT

"""
Returns the cardinality of a type. falls back to length
"""
cardinality(x) = length(x)
cardinality(x::Number) = 1
cardinality(x::Type{T}) where {T <: Number} = 1

mutable struct Shader
    name::Symbol
    source::Vector{UInt8}
    typ::GLenum
    id::GLuint
    context::GLContext

    function Shader(context, name, source, typ, id)
        obj = new(Symbol(name), source, typ, id, context)
        DEBUG[] && finalizer(verify_free, obj)
        return obj
    end
end

function Shader(context, name, source::Vector{UInt8}, typ)
    return compile_shader(context, source, typ, name)
end

name(s::Shader) = s.name

import Base: ==

function (==)(a::Shader, b::Shader)
    return a.source == b.source && a.typ == b.typ && a.id == b.id && a.context == b.context
end

function Base.hash(s::Shader, h::UInt64)
    return hash((s.source, s.typ, s.id, s.context), h)
end


function Base.show(io::IO, shader::Shader)
    println(io, GLENUM(shader.typ).name, " shader: $(shader.name))")
    println(io, "source:")
    return print_with_lines(io, String(shader.source))
end

mutable struct GLProgram
    id::GLuint
    shader::Vector{Shader}
    nametype::Dict{Symbol, GLenum}
    uniformloc::Dict{Symbol, Tuple}
    context::GLContext
    function GLProgram(id::GLuint, shader::Vector{Shader}, nametype::Dict{Symbol, GLenum}, uniformloc::Dict{Symbol, Tuple}, context = first(shader).context)
        obj = new(id, shader, nametype, uniformloc, context)
        DEBUG[] && finalizer(verify_free, obj)
        return obj
    end
end

function Base.show(io::IO, p::GLProgram)
    println(io, "GLProgram: $(p.id)")
    println(io, "Shaders:")
    for shader in p.shader
        println(io, shader)
    end
    println(io, "uniforms:")
    for (name, typ) in p.nametype
        println(io, "   ", name, "::", GLENUM(typ).name)
    end
    return
end

############################################
# Framebuffers and the like

struct RenderBuffer
    id::GLuint
    format::GLenum
    context::GLContext
    function RenderBuffer(format, dimension)
        @assert length(dimensions) == 2
        id = GLuint[0]
        glGenRenderbuffers(1, id)
        glBindRenderbuffer(GL_RENDERBUFFER, id[1])
        glRenderbufferStorage(GL_RENDERBUFFER, format, dimension...)
        return new(id, format, current_context())
    end
end

function resize!(rb::RenderBuffer, newsize::AbstractArray)
    if length(newsize) != 2
        error("RenderBuffer needs to be 2 dimensional. Dimension found: ", newsize)
    end
    glBindRenderbuffer(GL_RENDERBUFFER, rb.id)
    return glRenderbufferStorage(GL_RENDERBUFFER, rb.format, newsize...)
end

########################################################################################
# OpenGL Arrays

const GLArrayEltypes = Union{StaticVector, Quaternion, Real, Colorant}
"""
Transform julia datatypes to opengl enum type
"""
julia2glenum(x::Type{T}) where {T <: FixedPoint} = julia2glenum(FixedPointNumbers.rawtype(x))
julia2glenum(x::Union{Type{T}, T}) where {T <: Union{StaticVector, Quaternion, Colorant}} = julia2glenum(eltype(x))
julia2glenum(::Type{OffsetInteger{O, T}}) where {O, T} = julia2glenum(T)
julia2glenum(::Type{GLubyte}) = GL_UNSIGNED_BYTE
julia2glenum(::Type{GLbyte}) = GL_BYTE
julia2glenum(::Type{GLuint}) = GL_UNSIGNED_INT
julia2glenum(::Type{GLushort}) = GL_UNSIGNED_SHORT
julia2glenum(::Type{GLshort}) = GL_SHORT
julia2glenum(::Type{GLint}) = GL_INT
julia2glenum(::Type{GLfloat}) = GL_FLOAT
julia2glenum(::Type{GLdouble}) = GL_DOUBLE
julia2glenum(::Type{Float16}) = GL_HALF_FLOAT

struct DepthStencil_24_8 <: Real
    data::NTuple{4, UInt8}
end

Base.eltype(::Type{<:DepthStencil_24_8}) = DepthStencil_24_8
julia2glenum(x::Type{DepthStencil_24_8}) = GL_UNSIGNED_INT_24_8

function julia2glenum(::Type{T}) where {T}
    error("Type: $T not supported as opengl number datatype")
end

include("GLBuffer.jl")
include("GLTexture.jl")

########################################################################

include("GLVertexArray.jl")

##################################################################################

include("GLRenderObject.jl")

####################################################################################
# freeing

# Note: can be called from scene finalizer, must not error or print unless to Core.stdout
function free(x::T) where {T}
    # don't free if already freed (this should only be set by unsafe_free)
    clean_up_observables(x)
    x.id == 0 && return

    # OpenGL has the annoying habit of reusing id's when creating a new context
    # We need to make sure to only free the current one
    if context_alive(x.context) && is_context_active(x.context)
        unsafe_free(x)
    end
    x.id = 0
    return
end

# robj indices could be a Julia type
free(::Union{Nothing, Number}) = nothing

function clean_up_observables(x::T) where {T}
    return if hasfield(T, :observers)
        foreach(off, x.observers)
        empty!(x.observers)
    end
end

unsafe_free(x::GLProgram) = glDeleteProgram(x.id)
unsafe_free(x::Shader) = glDeleteShader(x.id)
unsafe_free(x::GLBuffer) = glDeleteBuffers(x.id)
unsafe_free(x::Texture) = glDeleteTextures(x.id)
unsafe_free(x::GLVertexArray) = glDeleteVertexArrays(x.id)
