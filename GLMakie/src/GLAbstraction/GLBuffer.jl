mutable struct GLBuffer{T} <: GPUArray{T, 1}
    id::GLuint
    size::NTuple{1, Int}
    buffertype::GLenum
    usage::GLenum
    context::GLContext
    # TODO maybe also delay upload to when render happens?
    observers::Vector{Observables.ObserverFunction}

    function GLBuffer{T}(context, ptr::Ptr{T}, buff_length::Int, buffertype::GLenum, usage::GLenum) where {T}
        gl_switch_context!(context)
        id = glGenBuffers()
        glBindBuffer(buffertype, id)
        # size of 0 can segfault it seems, but so can a draw call to an index buffer that has garbage data.
        # Therefore we let the buffer pull some garbage data in to have a GPU size > 0,
        # but keep the CPU size unchanged. Draw calls are then discarded if the CPU size is 0.
        glBufferData(buffertype, max(1, buff_length) * sizeof(T), ptr, usage)
        glBindBuffer(buffertype, 0)

        obj = new(
            id, (buff_length,), buffertype, usage, context,
            Observables.ObserverFunction[]
        )
        DEBUG[] && finalizer(verify_free, obj)
        return obj
    end
end

function bind(buffer::GLBuffer)
    if buffer.id == 0
        error("Binding freed GLBuffer{$(eltype(buffer))}")
    end
    return glBindBuffer(buffer.buffertype, buffer.id)
end

#used to reset buffer target
bind(buffer::GLBuffer, other_target) = glBindBuffer(buffer.buffertype, other_target)

function similar(x::GLBuffer{T}, buff_length::Int) where {T}
    return GLBuffer{T}(x.context, Ptr{T}(C_NULL), buff_length, x.buffertype, x.usage)
end

cardinality(::GLBuffer{T}) where {T} = cardinality(T)

#Function to deal with any Immutable type with Real as Subtype
function GLBuffer(
        context, buffer::Union{Base.ReinterpretArray{T, 1}, DenseVector{T}};
        buffertype::GLenum = GL_ARRAY_BUFFER, usage::GLenum = GL_STATIC_DRAW
    ) where {T <: GLArrayEltypes}
    GC.@preserve buffer begin
        return GLBuffer{T}(context, pointer(buffer), length(buffer), buffertype, usage)
    end
end

function GLBuffer(
        context, buffer::DenseVector{T};
        buffertype::GLenum = GL_ARRAY_BUFFER, usage::GLenum = GL_STATIC_DRAW
    ) where {T <: GLArrayEltypes}
    GC.@preserve buffer begin
        return GLBuffer{T}(context, pointer(buffer), length(buffer), buffertype, usage)
    end
end

function GLBuffer(
        context, buffer::ShaderAbstractions.Buffer{T};
        buffertype::GLenum = GL_ARRAY_BUFFER, usage::GLenum = GL_STATIC_DRAW
    ) where {T <: GLArrayEltypes}
    b = GLBuffer(context, ShaderAbstractions.data(buffer); buffertype = buffertype, usage = usage)
    au = ShaderAbstractions.updater(buffer)
    obsfunc = on(au.update) do (f, args)
        f(b, args...) # forward setindex! etc
        return
    end
    push!(b.observers, obsfunc)
    return b
end

# no-op conversions
GLBuffer(buffer::GLBuffer) = buffer
GLBuffer{T}(buffer::GLBuffer{T}) where {T} = buffer

function GLBuffer(context, buffer::AbstractVector{T}; kw_args...) where {T <: GLArrayEltypes}
    return GLBuffer(context, collect(buffer); kw_args...)
end

function GLBuffer{T}(context, buffer::AbstractVector; kw_args...) where {T <: GLArrayEltypes}
    return GLBuffer(context, convert(Vector{T}, buffer); kw_args...)
end

function GLBuffer(
        context, ::Type{T}, len::Int;
        buffertype::GLenum = GL_ARRAY_BUFFER, usage::GLenum = GL_STATIC_DRAW
    ) where {T <: GLArrayEltypes}
    return GLBuffer{T}(context, Ptr{T}(C_NULL), len, buffertype, usage)
end


function indexbuffer(
        context, buffer::VectorTypes{T}; usage::GLenum = GL_STATIC_DRAW
    ) where {T <: GLArrayEltypes}
    return GLBuffer(context, buffer, buffertype = GL_ELEMENT_ARRAY_BUFFER, usage = usage)
end
# GPUArray interface
function gpu_data(b::GLBuffer{T}) where {T}
    gl_switch_context!(b.context)
    data = Vector{T}(undef, length(b))
    bind(b)
    glGetBufferSubData(b.buffertype, 0, sizeof(data), data)
    bind(b, 0)
    return data
end

# for render() debug checks
function gpu_data_no_unbind(b::GLBuffer{T}) where {T}
    data = Vector{T}(undef, length(b))
    bind(b)
    glGetBufferSubData(b.buffertype, 0, sizeof(data), data)
    return data
end


# Resize buffer
function gpu_resize!(buffer::GLBuffer{T}, newdims::NTuple{1, Int}) where {T}
    gl_switch_context!(buffer.context)
    #TODO make this safe!
    newlength = newdims[1]
    oldlen = length(buffer)
    if oldlen > 0
        old_data = gpu_data(buffer)
    end
    bind(buffer)
    glBufferData(buffer.buffertype, newlength * sizeof(T), C_NULL, buffer.usage)
    bind(buffer, 0)
    buffer.size = newdims
    if oldlen > 0
        max_len = min(length(old_data), newlength) #might also shrink
        buffer[1:max_len] = old_data[1:max_len]
    end
    #probably faster, but changes the buffer ID
    # newbuff     = similar(buffer, newdims...)
    # unsafe_copy!(buffer, 1, newbuff, 1, length(buffer))
    # buffer.id   = newbuff.id
    # buffer.size = newbuff.size
    return nothing
end

function gpu_setindex!(b::GLBuffer{T}, value::Vector{T}, offset::Integer) where {T}
    gl_switch_context!(b.context)
    multiplicator = sizeof(T)
    bind(b)
    glBufferSubData(b.buffertype, multiplicator * (offset - 1), sizeof(value), value)
    return bind(b, 0)
end

function gpu_setindex!(b::GLBuffer{T}, value::Vector{T}, offset::UnitRange{Int}) where {T}
    gl_switch_context!(b.context)
    multiplicator = sizeof(T)
    bind(b)
    glBufferSubData(b.buffertype, multiplicator * (first(offset) - 1), sizeof(value), value)
    bind(b, 0)
    return nothing
end

# copy between two buffers
# could be a setindex! operation, with subarrays for buffers
function unsafe_copy!(a::GLBuffer{T}, readoffset::Int, b::GLBuffer{T}, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(a.context)
    @assert a.context == b.context
    multiplicator = sizeof(T)
    @assert a.id != 0 & b.id != 0
    glBindBuffer(GL_COPY_READ_BUFFER, a.id)
    glBindBuffer(GL_COPY_WRITE_BUFFER, b.id)
    glCopyBufferSubData(
        GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER,
        multiplicator * (readoffset - 1),
        multiplicator * (writeoffset - 1),
        multiplicator * len
    )
    glBindBuffer(GL_COPY_READ_BUFFER, 0)
    glBindBuffer(GL_COPY_WRITE_BUFFER, 0)
    return nothing
end

function Base.iterate(buffer::GLBuffer{T}, i = 1) where {T}
    i > length(buffer) && return nothing
    return gpu_getindex(buffer, i:i)[], i + 1
end

#copy inside one buffer
function unsafe_copy!(buffer::GLBuffer{T}, readoffset::Int, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(buffer.context)
    len <= 0 && return nothing
    bind(buffer)
    ptr = Ptr{T}(glMapBuffer(buffer.buffertype, GL_READ_WRITE))
    for i in 1:(len + 1)
        unsafe_store!(ptr, unsafe_load(ptr, i + readoffset - 1), i + writeoffset - 1)
    end
    glUnmapBuffer(buffer.buffertype)
    bind(buffer, 0)
    return nothing
end

function unsafe_copy!(a::Vector{T}, readoffset::Int, b::GLBuffer{T}, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(b.context)
    bind(b)
    ptr = Ptr{T}(glMapBuffer(b.buffertype, GL_WRITE_ONLY))
    for i in 1:len
        unsafe_store!(ptr, a[i + readoffset - 1], i + writeoffset - 1)
    end
    glUnmapBuffer(b.buffertype)
    return bind(b, 0)
end

function unsafe_copy!(a::GLBuffer{T}, readoffset::Int, b::Vector{T}, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(a.context)
    bind(a)
    ptr = Ptr{T}(glMapBuffer(a.buffertype, GL_READ_ONLY))
    for i in 1:len
        b[i + writeoffset - 1] = unsafe_load(ptr, i + readoffset - 2) #-2 => -1 to zero offset, -1 gl indexing starts at 0
    end
    glUnmapBuffer(a.buffertype)
    return bind(a, 0)
end

function gpu_getindex(b::GLBuffer{T}, range::UnitRange) where {T}
    gl_switch_context!(b.context)
    multiplicator = sizeof(T)
    offset = first(range) - 1
    value = Vector{T}(undef, length(range))
    bind(b)
    glGetBufferSubData(b.buffertype, multiplicator * offset, sizeof(value), value)
    bind(b, 0)
    return value
end
