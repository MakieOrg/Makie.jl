############################################################################
const TOrSignal{T} = Union{Observable{T},T}

const ArrayOrSignal{T,N} = TOrSignal{X} where X <: AbstractArray{T,N}
const VecOrSignal{T} = ArrayOrSignal{T,1}
const MatOrSignal{T} = ArrayOrSignal{T,2}
const VolumeOrSignal{T} = ArrayOrSignal{T,3}

const ArrayTypes{T,N} = Union{GPUArray{T,N},ArrayOrSignal{T,N}}
const VectorTypes{T} = ArrayTypes{T,1}
const MatTypes{T} = ArrayTypes{T,2}
const VolumeTypes{T} = ArrayTypes{T,3}

@enum Projection PERSPECTIVE ORTHOGRAPHIC
@enum MouseButton MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT

"""
Returns the cardinality of a type. falls back to length
"""
cardinality(x) = length(x)
cardinality(x::Number) = 1
cardinality(x::Type{T}) where {T <: Number} = 1

struct Shader
    name::Symbol
    source::Vector{UInt8}
    typ::GLenum
    id::GLuint
    context::GLContext
    function Shader(name, source, typ, id)
        new(Symbol(name), source, typ, id, current_context())
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
    id::GLuint
    shader::Vector{Shader}
    nametype::Dict{Symbol,GLenum}
    uniformloc::Dict{Symbol,Tuple}
    context::GLContext
    function GLProgram(id::GLuint, shader::Vector{Shader}, nametype::Dict{Symbol,GLenum}, uniformloc::Dict{Symbol,Tuple})
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
    id::GLuint
    format::GLenum
    context::GLContext
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
    id::GLuint
    attachments::Vector{Any}
    context::GLContext
    function FrameBuffer{T}(dimensions::Observable) where T
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

const GLArrayEltypes = Union{StaticVector,Real,Colorant}
"""
Transform julia datatypes to opengl enum type
"""
julia2glenum(x::Type{T}) where {T <: FixedPoint} = julia2glenum(FixedPointNumbers.rawtype(x))
julia2glenum(x::Union{Type{T},T}) where {T <: Union{StaticVector,Colorant}} = julia2glenum(eltype(x))
julia2glenum(::Type{OffsetInteger{O,T}}) where {O,T} = julia2glenum(T)
julia2glenum(::Type{GLubyte})  = GL_UNSIGNED_BYTE
julia2glenum(::Type{GLbyte})   = GL_BYTE
julia2glenum(::Type{GLuint})   = GL_UNSIGNED_INT
julia2glenum(::Type{GLushort}) = GL_UNSIGNED_SHORT
julia2glenum(::Type{GLshort})  = GL_SHORT
julia2glenum(::Type{GLint})    = GL_INT
julia2glenum(::Type{GLfloat})  = GL_FLOAT
julia2glenum(::Type{GLdouble}) = GL_DOUBLE
julia2glenum(::Type{Float16})  = GL_HALF_FLOAT

struct DepthStencil_24_8 <: Real
    data::NTuple{4,UInt8}
end

Base.eltype(::Type{<: DepthStencil_24_8}) = DepthStencil_24_8
julia2glenum(x::Type{DepthStencil_24_8}) = GL_UNSIGNED_INT_24_8

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
    program::GLProgram
    id::GLuint
    bufferlength::Int
    buffers::Dict{String,GLBuffer}
    indices::T
    context::GLContext
    function GLVertexArray{T}(program, id, bufferlength, buffers, indices) where T
        va = new(program, id, bufferlength, buffers, indices, current_context())
        return va
    end
end

"""
returns the length of the vertex array.
This is amount of primitives stored in the vertex array, needed for `glDrawArrays`
"""
length(vao::GLVertexArray) = length(first(vao.buffers)[2]) # all buffers have same length, so first should do!

GLVertexArray(vao::GLVertexArray) = GLVertexArray(vao.buffers, vao.program)

function GLVertexArray(bufferdict::Dict, program::GLProgram)
    # get the size of the first array, to assert later, that all have the same size
    indexes = -1
    len = -1
    ShaderAbstractions.switch_context!(program.context)
    id = glGenVertexArrays()
    glBindVertexArray(id)
    lenbuffer = 0
    buffers = Dict{String,GLBuffer}()
    for (name, buffer) in bufferdict
        if isa(buffer, GLBuffer) && buffer.buffertype == GL_ELEMENT_ARRAY_BUFFER
            bind(buffer)
            indexes = buffer
        elseif Symbol(name) === :indices
            indexes = buffer
        else
            attribute = string(name)
            len == -1 && (len = length(buffer))
            # TODO: use glVertexAttribDivisor to allow multiples of the longest buffer
            if len != length(buffer)
                # We don't know which buffer has the wrong size, so list all of them
                bufferlengths = ""
                for (name, buffer) in bufferdict
                    if isa(buffer, GLBuffer) && buffer.buffertype == GL_ELEMENT_ARRAY_BUFFER
                    elseif Symbol(name) === :indices
                    else
                        bufferlengths *= "\n\t$name has length $(length(buffer))"
                    end
                end
                error(
                    "Buffer $attribute does not have the same length as the other buffers." *
                    bufferlengths
                )
            end
            bind(buffer)
            attribLocation = get_attribute_location(program.id, attribute)
            if attribLocation == -1
                # Right now we may create a buffer e.g. in mesh.jl,
                # but we don't use it so it gets optimized away in the shader (e.g. normals with shading=false)
                # We still need to clean up that buffer in free(vertexarray), so we put it in the buffer list without binding it.
                # TODO, don't even create the buffer if it isn't needed. Right now we don't have this info in meshes.jl, so it's a todo for now
                buffers[attribute] = buffer
                continue
            end
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
    return obj
end
using ShaderAbstractions: Buffer
function GLVertexArray(program::GLProgram, buffers::Buffer, triangles::AbstractVector{<: GLTriangleFace})
    # get the size of the first array, to assert later, that all have the same size
    id = glGenVertexArrays()
    glBindVertexArray(id)
    for property_name in propertynames(buffers)
        array = getproperty(buffers, property_name)
        attribute = string(property_name)
        # TODO: use glVertexAttribDivisor to allow multiples of the longest buffer
        buffer = GLBuffer(array)
        bind(buffer)
        attribLocation = get_attribute_location(program.id, attribute)
        if attribLocation == -1
            error("could not bind attribute $(attribute)")
        end
        glVertexAttribPointer(attribLocation, cardinality(buffer), julia2glenum(eltype(buffer)), GL_FALSE, 0, C_NULL)
        glEnableVertexAttribArray(attribLocation)
        buffers[attribute] = buffer
    end
    glBindVertexArray(0)
    indices = indexbuffer(triangles)
    obj = GLVertexArray{typeof(indexes)}(program, id, len, buffers, indices)
    finalizer(free, obj)
    return obj
end

function bind(va::GLVertexArray)
    if va.id == 0
        error("Binding freed VertexArray")
    end
    glBindVertexArray(va.id)
end


function Base.show(io::IO, vao::GLVertexArray)
    show(io, vao.program)
    println(io, "GLVertexArray $(vao.id):")
    print(io, "GLVertexArray $(vao.id) buffers: ")
    writemime(io, MIME("text/plain"), vao.buffers)
    println(io, "\nGLVertexArray $(vao.id) indices: ", vao.indices)
end

##################################################################################

const RENDER_OBJECT_ID_COUNTER = Ref(zero(UInt32))

function pack_bool(id, bool)
    highbit_mask = UInt32(1) << UInt32(31)
    return id + (bool ? highbit_mask : UInt32(0))
end

mutable struct RenderObject{Pre}
    context # OpenGL context
    uniforms::Dict{Symbol,Any}
    observables::Vector{Observable} # for clean up
    vertexarray::GLVertexArray
    prerenderfunction::Pre
    postrenderfunction
    id::UInt32
    visible::Bool

    function RenderObject{Pre}(
            context,
            uniforms::Dict{Symbol,Any}, observables::Vector{Observable},
            vertexarray::GLVertexArray,
            prerenderfunctions, postrenderfunctions,
            visible
        ) where Pre
        fxaa = Bool(to_value(get!(uniforms, :fxaa, true)))
        RENDER_OBJECT_ID_COUNTER[] += one(UInt32)
        # Store fxaa in ID, so we can access it in the shader to create a mask
        # for the fxaa render pass
        # In theory, we need to unpack the id again as well,
        # But with this implementation, the fxaa flag can't be changed,
        # and since this is a UUID, it shouldn't matter
        id = pack_bool(RENDER_OBJECT_ID_COUNTER[], fxaa)
        robj = new(
            context,
            uniforms, observables, vertexarray,
            prerenderfunctions, postrenderfunctions,
            id, visible[]
        )
        push!(observables, visible)
        on(visible) do visible
            robj.visible = visible
            return
        end
        return robj
    end
end

function RenderObject(
        data::Dict{Symbol,Any}, program,
        pre::Pre, post,
        context=current_context()
    ) where Pre

    switch_context!(context)

    # This is a lazy workaround for disabling updates of `requires_update` when
    # not rendering on demand. A cleaner implementation should probably go
    # through @gen_defaults! and adjust constructors instead.
    track_updates = to_value(pop!(data, :track_updates, true))

    # Explicit conversion targets for gl_convert
    targets = get(data, :gl_convert_targets, Dict())
    delete!(data, :gl_convert_targets)

    # Not handled as uniform
    visible = pop!(data, :visible, Observable(true))

    # for clean up on deletion
    observables = Observable[]

    # Overwriting data with break direct iteration over it
    _keys = collect(keys(data))
    for k in _keys
        v = data[k]
        v isa Observable && push!(observables, v)

        if haskey(targets, k)
            # glconvert is designed to convert everything to a fitting opengl datatype, but sometimes
            # the conversion is not unique. (E.g. Array -> Texture, TextureBuffer, GLBuffer, ...)
            # In these cases an explicit conversion target is required
            data[k] = gl_convert(targets[k], v)
        else
            k in (:indices, :visible, :ssao, :label, :cycle) && continue

            # structs are decomposed into fields
            #     $k.$fieldname -> v.$fieldname
            if isa_gl_struct(v)
                merge!(data, gl_convert_struct(v, k))
                delete!(data, k)

            # try direct conversion
            elseif applicable(gl_convert, v)
                try
                    data[k] = gl_convert(v)
                catch e
                    @error "gl_convert for key `$k` failed"
                    rethrow(e)
                end

            # Otherwise just let the value pass through
            # TODO: Is this ok/ever not filtered?
            else
                # @debug "Passed on $k -> $(typeof(v)) without conversion."
            end
        end
    end

    buffers = filter(((key, value),) -> isa(value, GLBuffer) || key === :indices, data)
    program = gl_convert(to_value(program), data) # "compile" lazyshader
    vertexarray = GLVertexArray(Dict(buffers), program)

    # remove all uniforms not occuring in shader
    # ssao, instances transparency are special for rendering passes. TODO do this more cleanly
    special = Set([:ssao, :transparency, :instances, :fxaa])
    for k in setdiff(keys(data), keys(program.nametype))
        if !(k in special)
            delete!(data, k)
        end
    end

    robj = RenderObject{Pre}(
        context,
        data,
        observables,
        vertexarray,
        pre,
        post,
        visible
    )

    # automatically integrate object ID, will be discarded if shader doesn't use it
    robj[:objectid] = robj.id

    return robj
end

include("GLRenderObject.jl")

####################################################################################
# freeing
function free(x)
    try
        unsafe_free(x)
    catch e
        isa(e, ContextNotAvailable) && return # if context got destroyed no need to worry!
        rethrow(e)
    end
end

function clean_up_observables(x::T) where T
    if hasfield(T, :observers)
        foreach(off, x.observers)
        empty!(x.observers)
    end
end

# OpenGL has the annoying habit of reusing id's when creating a new context
# We need to make sure to only free the current one
function unsafe_free(x::GLProgram)
    x.id == 0 && return
    GLAbstraction.context_alive(x.context) || return
    GLAbstraction.switch_context!(x.context)
    glDeleteProgram(x.id)
    return
end

function unsafe_free(x::GLBuffer)
    # don't free if already freed
    x.id == 0 && return
    clean_up_observables(x)
    # don't free from other context
    GLAbstraction.context_alive(x.context) || return
    GLAbstraction.switch_context!(x.context)
    id = Ref(x.id)
    glDeleteBuffers(1, id)
    x.id = 0
    return
end

function unsafe_free(x::Texture)
    x.id == 0 && return
    clean_up_observables(x)
    GLAbstraction.context_alive(x.context) || return
    GLAbstraction.switch_context!(x.context)
    id = Ref(x.id)
    glDeleteTextures(x.id)
    x.id = 0
    return
end

function unsafe_free(x::GLVertexArray)
    x.id == 0 && return
    GLAbstraction.context_alive(x.context) || return
    GLAbstraction.switch_context!(x.context)
    for (key, buffer) in x.buffers
        free(buffer)
    end
    if x.indices isa GPUArray
        free(x.indices)
    end
    id = Ref(x.id)
    glDeleteVertexArrays(1, id)
    x.id = 0
    return
end
