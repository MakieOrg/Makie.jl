############################################################################
const TOrSignal{T} = Union{Signal{T}, T}

const ArrayOrSignal{T, N} = TOrSignal{Array{T, N}}
const VecOrSignal{T} = ArrayOrSignal{T, 1}
const MatOrSignal{T} = ArrayOrSignal{T, 2}
const VolumeOrSignal{T} = ArrayOrSignal{T, 3}

const ArrayTypes{T, N} = Union{GPUArray{T, N}, ArrayOrSignal{T,N}}
const VectorTypes{T} = ArrayTypes{T, 1}
const MatTypes{T} = ArrayTypes{T, 2}
const VolumeTypes{T} = ArrayTypes{T, 3}

@enum Projection PERSPECTIVE ORTHOGRAPHIC
@enum MouseButton MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT

const GLContext = Any

"""
Returns the cardinality of a type. falls back to length
"""
cardinality(x) = length(x)
cardinality(x::Number) = 1
cardinality(x::Type{T}) where {T <: Number} = 1

#=
We need to track the current OpenGL context.
Since we can't do this via pointer identity  (OpenGL may reuse the same pointers)
We go for this slightly ugly version.
=#
const context = Base.RefValue{GLContext}(:none)

function current_context()
    context[] == :none && error("No active context")
    context[]
end

function is_current_context(x)
    x == context[]
end

function native_context_alive(x)
    error("Not implemented for $(typeof(x))")
end

"""
Is current context & is alive
"""
is_context_active(x) = is_current_context(x) && context_alive(x)

"""
Has context been destroyed or is it still living?
"""
context_alive(x) = native_context_alive(x)

function native_switch_context!(x)
    error("Not implemented for $(typeof(x))")
end

"""
Invalidates the current context
"""
function switch_context!()
    # for reverting to no context
    context[] = :none
end

"""
Switches to a new context `x`. Is a noop if `x` is already current
"""
function switch_context!(x)
    if !is_current_context(x)
        context[] = x
        native_switch_context!(x)
    end
end

struct Shader
    name::Symbol
    source::Vector{UInt8}
    typ::GLenum
    id::GLuint
    context::GLContext
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
    context     ::GLContext
    function GLProgram(id::GLuint, shader::Vector{Shader}, nametype::Dict{Symbol, GLenum}, uniformloc::Dict{Symbol, Tuple})
        obj = new(id, shader, nametype, uniformloc, current_context())
        finalizer(free, obj)
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


############################################
# Framebuffers and the like

struct RenderBuffer
    id      ::GLuint
    format  ::GLenum
    context ::GLContext
    function RenderBuffer(format, dimension)
        @assert length(dimensions) == 2
        id = GLuint[0]
        glGenRenderbuffers(1, id)
        glBindRenderbuffer(GL_RENDERBUFFER, id[1])
        glRenderbufferStorage(GL_RENDERBUFFER, format, dimension...)
        new(id, format, current_context())
    end
end
function resize!(rb::RenderBuffer, newsize::AbstractArray)
    if length(newsize) != 2
        error("RenderBuffer needs to be 2 dimensional. Dimension found: ", newsize)
    end
    glBindRenderbuffer(GL_RENDERBUFFER, rb.id)
    glRenderbufferStorage(GL_RENDERBUFFER, rb.format, newsize...)
end

struct FrameBuffer{T}
    id          ::GLuint
    attachments ::Vector{Any}
    context     ::GLContext
    function FrameBuffer{T}(dimensions::Signal) where T
        fb = glGenFramebuffers()
        glBindFramebuffer(GL_FRAMEBUFFER, fb)
        new(id, attachments, current_context())
    end
end
function resize!(fbo::FrameBuffer, newsize::AbstractArray)
    if length(newsize) != 2
        error("FrameBuffer needs to be 2 dimensional. Dimension found: ", newsize)
    end
    for elem in fbo.attachments
        resize!(elem)
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
    error("Type: $T not supported as opengl number datatype")
end

include("GLBuffer.jl")
include("GLTexture.jl")

########################################################################


"""
Represents an OpenGL vertex array type.
Can be created from a dict of buffers and an opengl Program.
Keys with the name `indices` will get special treatment and will be used as
the indexbuffer.
"""
mutable struct GLVertexArray{T}
    program      ::GLProgram
    id           ::GLuint
    bufferlength ::Int
    buffers      ::Dict{String, GLBuffer}
    indices      ::T
    context      ::GLContext

    function GLVertexArray{T}(program, id, bufferlength, buffers, indices) where T
        new(program, id, bufferlength, buffers, indices, current_context())
    end
end
"""
returns the length of the vertex array.
This is amount of primitives stored in the vertex array, needed for `glDrawArrays`
"""
function length(vao::GLVertexArray)
    length(first(vao.buffers)[2]) # all buffers have same length, so first should do!
end
function GLVertexArray(vao::GLVertexArray)
    GLVertexArray(vao.buffers, vao.program)
end
function GLVertexArray(bufferdict::Dict, program::GLProgram)
    #get the size of the first array, to assert later, that all have the same size
    indexes = -1
    len = -1
    id = glGenVertexArrays()
    glBindVertexArray(id)
    lenbuffer = 0
    buffers = Dict{String, GLBuffer}()
    for (name, buffer) in bufferdict
        if isa(buffer, GLBuffer) && buffer.buffertype == GL_ELEMENT_ARRAY_BUFFER
            bind(buffer)
            indexes = buffer
        elseif Symbol(name) == :indices
            indexes = buffer
        else
            attribute = string(name)
            len == -1 && (len = length(buffer))
            # TODO: use glVertexAttribDivisor to allow multiples of the longest buffer
            len != length(buffer) && error(
              "buffer $attribute has not the same length as the other buffers.
              Has: $(length(buffer)). Should have: $len"
            )
            bind(buffer)
            attribLocation = get_attribute_location(program.id, attribute)
            (attribLocation == -1) && continue
            glVertexAttribPointer(attribLocation, cardinality(buffer), julia2glenum(eltype(buffer)), GL_FALSE, 0, C_NULL)
            glEnableVertexAttribArray(attribLocation)
            buffers[attribute] = buffer
            lenbuffer = buffer
        end
    end
    glBindVertexArray(0)
    if indexes == -1
        indexes = len
    end
    obj = GLVertexArray{typeof(indexes)}(program, id, len, buffers, indexes)
    finalizer(free, obj)
    obj
end
function Base.show(io::IO, vao::GLVertexArray)
    show(io, vao.program)
    println(io, "GLVertexArray $(vao.id):")
    print(  io, "GLVertexArray $(vao.id) buffers: ")
    writemime(io, MIME("text/plain"), vao.buffers)
    println(io, "\nGLVertexArray $(vao.id) indices: ", vao.indices)
end


##################################################################################

const RENDER_OBJECT_ID_COUNTER = Ref(zero(GLushort))

mutable struct RenderObject{Pre} <: Composable{DeviceUnit}
    main                 # main object
    uniforms            ::Dict{Symbol, Any}
    vertexarray         ::GLVertexArray
    prerenderfunction   ::Pre
    postrenderfunction
    id                  ::GLushort
    boundingbox          # workaround for having lazy boundingbox queries, while not using multiple dispatch for boundingbox function (No type hierarchy for RenderObjects)
    function RenderObject{Pre}(
            main, uniforms::Dict{Symbol, Any}, vertexarray::GLVertexArray,
            prerenderfunctions, postrenderfunctions,
            boundingbox
        ) where Pre
        RENDER_OBJECT_ID_COUNTER[] += one(GLushort)
        new(
            main, uniforms, vertexarray,
            prerenderfunctions, postrenderfunctions,
            RENDER_OBJECT_ID_COUNTER[], boundingbox
        )
    end
end


function RenderObject(
        data::Dict{Symbol, Any}, program,
        pre::Pre, post,
        bbs=Signal(AABB{Float32}(Vec3f0(0),Vec3f0(1))),
        main=nothing
    ) where Pre
    targets = get(data, :gl_convert_targets, Dict())
    delete!(data, :gl_convert_targets)
    passthrough = Dict{Symbol, Any}() # we also save a few non opengl related values in data
    for (k,v) in data # convert everything to OpenGL compatible types
        if haskey(targets, k)
            # glconvert is designed to just convert everything to a fitting opengl datatype, but sometimes exceptions are needed
            # e.g. Texture{T,1} and GLBuffer{T} are both usable as an native conversion canditate for a Julia's Array{T, 1} type.
            # but in some cases we want a Texture, sometimes a GLBuffer or TextureBuffer
            data[k] = gl_convert(targets[k], v)
        else
            k in (:indices, :visible, :fxaa) && continue
            if isa_gl_struct(v) # structs are treated differently, since they have to be composed into their fields
                merge!(data, gl_convert_struct(v, k))
            elseif applicable(gl_convert, v) # if can't be converted to an OpenGL datatype,
                data[k] = gl_convert(v)
            else # put it in passthrough
                delete!(data, k)
                passthrough[k] = v
            end
        end
    end
    # handle meshes seperately, since they need expansion
    meshs = filter(((key, value),) -> isa(value, NativeMesh), data)
    if !isempty(meshs)
        merge!(data, [v.data for (k,v) in meshs]...)
    end
    buffers  = filter(((key, value),) -> isa(value, GLBuffer) || key == :indices, data)
    uniforms = filter(((key, value),) -> !isa(value, GLBuffer) && key != :indices, data)
    get!(data, :visible, true) # make sure, visibility is set
    merge!(data, passthrough) # in the end, we insert back the non opengl data, to keep things simple
    p = gl_convert(Reactive.value(program), data) # "compile" lazyshader
    vertexarray = GLVertexArray(Dict(buffers), p)
    robj = RenderObject{Pre}(
        main,
        data,
        vertexarray,
        pre,
        post,
        bbs
    )
    # automatically integrate object ID, will be discarded if shader doesn't use it
    robj[:objectid] = robj.id
    robj
end

include("GLRenderObject.jl")

####################################################################################
# freeing

function log_finalizer(x)
    open("finalizer_log.txt", "a") do io
        print(io, x)
        print(io, '\n')
    end
end

function free(x)
    try
        unsafe_free(x)
    catch e
        isa(e, ContextNotAvailable) && return # if context got destroyed no need to worry!
        if :msg in fieldnames(e)
            log_finalizer(e.msg)
        else
            log_finalizer(typeof(e))
        end
    end
end

# OpenGL has the annoying habit of reusing id's when creating a new context
# We need to make sure to only free the current one
function unsafe_free(x::GLProgram)
    is_context_active(x.context) || return
    glDeleteProgram(x.id)
    return
end
function unsafe_free(x::GLBuffer)
    # don't free from other context
    is_context_active(x.context) || return
    id = Ref(x.id)
    glDeleteBuffers(1, id)
    return
end
function unsafe_free(x::Texture)
    is_context_active(x.context) || return
    id = Ref(x.id)
    glDeleteTextures(x.id)
    return
end

function unsafe_free(x::GLVertexArray)
    is_context_active(x.context) || return
    id = Ref(x.id)
    glDeleteVertexArrays(1, id)
    return
end
