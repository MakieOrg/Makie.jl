############################################################################
const TOrSignal{T} = Union{Signal{T}, T}

const ArrayOrSignal{T, N} = TOrSignal{Array{T, N}}
const VecOrSignal{T} = ArrayOrSignal{T, 1}
const MatOrSignal{T} = ArrayOrSignal{T, 2}
const VolumeOrSignal{T} = ArrayOrSignal{T, 3}

const ArrayTypes{T, N} = Union{GPUArray{T, N}, ArrayOrSignal{T,N}}
const VecTypes{T} = ArrayTypes{T, 1}
const MatTypes{T} = ArrayTypes{T, 2}
const VolumeTypes{T} = ArrayTypes{T, 3}

@enum Projection PERSPECTIVE ORTHOGRAPHIC
@enum MouseButton MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT

# const GLContext = Symbol

"""
Returns the cardinality of a type. falls back to length
"""
cardinality(x) = length(x)
cardinality(x::Number) = 1
cardinality(x::Type{T}) where {T <: Number} = 1


#Context and current_context should be overloaded by users of the library! They are standard Symbols
abstract type AbstractContext end

struct DummyContext <: AbstractContext
    id::Symbol
end
#=
We need to track the current OpenGL context.
Since we can't do this via pointer identity  (OpenGL may reuse the same pointers)
We go for this slightly ugly version.
In the future, this should probably be part of GLWindow.
=#
const context = Base.RefValue{AbstractContext}(DummyContext(:none))
new_context() = (context[] = DummyContext(gensym()))
current_context() = context[]
is_current_context(x) = x == context[]
clear_context!() = (context[] = DummyContext(:none))
set_context!(x) = (context[] = x)

Base.Symbol(c::DummyContext) = c.id
Base.convert(::Type{Symbol}, c::DummyContext) = c.id

function exists_context()
    if current_context().id == :none
        error("Couldn't find valid OpenGL Context. OpenGL Context active?")
    end
end

#These have to get overloaded for the pipeline to work!
swapbuffers(c::AbstractContext) = return
Base.clear!(c::AbstractContext) = return

struct Shader
    name::Symbol
    source::Vector{UInt8}
    typ::GLenum
    id::GLuint
    context::AbstractContext
    function Shader(name, source, typ, id)
        new(name, source, typ, id, current_context())
    end
end
function Shader(name, source::Vector{UInt8}, typ)
    compile_shader(source, typ, name)
end
name(s::Shader) = s.name

import Base: ==

function (==)(a::Shader, b::Shader)
    a.source == b.source && a.typ == b.typ && a.id == b.id && a.context == b.context
end

function Base.hash(s::Shader, h::UInt64)
    hash((s.source, s.typ, s.id, s.context), h)
end


function Base.show(io::IO, shader::Shader)
    println(io, GLENUM(shader.typ).name, " shader: $(shader.name))")
    println(io, "source:")
    print_with_lines(io, String(shader.source))
end

mutable struct GLProgram
    id          ::GLuint
    shader      ::Vector{Shader}
    nametype    ::Dict{Symbol, GLenum}
    uniformloc  ::Dict{Symbol, Tuple}
    context     ::AbstractContext
    function GLProgram(id::GLuint, shader::Vector{Shader}, nametype::Dict{Symbol, GLenum}, uniformloc::Dict{Symbol, Tuple})
        obj = new(id, shader, nametype, uniformloc, current_context())
        finalizer(obj, free)
        obj
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
end


########################################################################################
# OpenGL Arrays


const GLArrayEltypes = Union{StaticVector, Real, Colorant}
"""
Transform julia datatypes to opengl enum type
"""
julia2glenum(x::Type{T}) where {T <: FixedPoint} = julia2glenum(FixedPointNumbers.rawtype(x))
julia2glenum(x::Type{OffsetInteger{O, T}}) where {O, T} = julia2glenum(T)
julia2glenum(x::Union{Type{T}, T}) where {T <: Union{StaticVector, Colorant}} = julia2glenum(eltype(x))
julia2glenum(x::Type{GLubyte})  = GL_UNSIGNED_BYTE
julia2glenum(x::Type{GLbyte})   = GL_BYTE
julia2glenum(x::Type{GLuint})   = GL_UNSIGNED_INT
julia2glenum(x::Type{GLushort}) = GL_UNSIGNED_SHORT
julia2glenum(x::Type{GLshort})  = GL_SHORT
julia2glenum(x::Type{GLint})    = GL_INT
julia2glenum(x::Type{GLfloat})  = GL_FLOAT
julia2glenum(x::Type{GLdouble}) = GL_DOUBLE
julia2glenum(x::Type{Float16})  = GL_HALF_FLOAT
function julia2glenum(::Type{T}) where T
    glasserteltype(T)
    julia2glenum(eltype(T))
end

include("buffer.jl")
include("texture.jl")

########################################################################

include("vertexarray.jl")
# """
# Represents an OpenGL vertex array type.
# Can be created from a dict of buffers and an opengl Program.
# Keys with the name `indices` will get special treatment and will be used as
# the indexbuffer.
# """
# mutable struct VertexArray{T}
#     program      ::GLProgram
#     id           ::GLuint
#     bufferlength ::Int
#     buffers      ::Dict{String, Buffer}
#     indices      ::T
#     context      ::AbstractContext
#
#     function VertexArray{T}(program, id, bufferlength, buffers, indices) where T
#         new(program, id, bufferlength, buffers, indices, current_context())
#     end
# end
# """
# returns the length of the vertex array.
# This is amount of primitives stored in the vertex array, needed for `glDrawArrays`
# """
# function length(vao::VertexArray)
#     length(first(vao.buffers)[2]) # all buffers have same length, so first should do!
# end
# function VertexArray(vao::VertexArray)
#     VertexArray(vao.buffers, vao.program)
# end
# function VertexArray(bufferdict::Dict, program::GLProgram)
#     #get the size of the first array, to assert later, that all have the same size
#     indexes = -1
#     len = -1
#     id = glGenVertexArrays()
#     glBindVertexArray(id)
#     lenbuffer = 0
#     buffers = Dict{String, Buffer}()
#     for (name, buffer) in bufferdict
#         if isa(buffer, Buffer) && buffer.buffertype == GL_ELEMENT_ARRAY_BUFFER
#             bind(buffer)
#             indexes = buffer
#         elseif Symbol(name) == :indices
#             indexes = buffer
#         else
#             attribute = string(name)
#             len == -1 && (len = length(buffer))
#             # TODO: use glVertexAttribDivisor to allow multiples of the longest buffer
#             len != length(buffer) && error(
#               "buffer $attribute has not the same length as the other buffers.
#               Has: $(length(buffer)). Should have: $len"
#             )
#             bind(buffer)
#             attribLocation = get_attribute_location(program.id, attribute)
#             (attribLocation == -1) && continue
#             glVertexAttribPointer(attribLocation, cardinality(buffer), julia2glenum(eltype(buffer)), GL_FALSE, 0, C_NULL)
#             glEnableVertexAttribArray(attribLocation)
#             buffers[attribute] = buffer
#             lenbuffer = buffer
#         end
#     end
#     glBindVertexArray(0)
#     if indexes == -1
#         indexes = len
#     end
#     obj = VertexArray{typeof(indexes)}(program, id, len, buffers, indexes)
#     finalizer(obj, free)
#     obj
# end
# function Base.show(io::IO, vao::VertexArray)
#     show(io, vao.program)
#     println(io, "VertexArray $(vao.id):")
#     print(  io, "VertexArray $(vao.id) buffers: ")
#     writemime(io, MIME("text/plain"), vao.buffers)
#     println(io, "\nVertexArray $(vao.id) indices: ", vao.indices)
# end


##################################################################################


include("GLRenderObject.jl")




####################################################################################
# freeing

# OpenGL has the annoying habit of reusing id's when creating a new context
# We need to make sure to only free the current one
function free(x::GLProgram)
    is_context_active(x.context) || return
    try
        glDeleteProgram(x.id)
    catch e
        free_handle_error(e)
    end
    return
end

function free_handle_error(e)
    #ignore, since freeing is not needed if context is not available
    isa(e, ContextNotAvailable) && return
    rethrow(e)
end
