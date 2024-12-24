# For completion sake

# Doesn't implement getindex, setindex etc I think?
mutable struct GLRenderbuffer
    id::GLuint
    size::NTuple{2, Int}
    format::GLenum
    context::GLContext

    function GLRenderbuffer(size, format::GLenum)
        renderbuffer = GLuint[0]
        glGenRenderbuffers(1, renderbuffer)
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer[1])
        glRenderbufferStorage(GL_RENDERBUFFER, format, size...)

        obj = new(renderbuffer[1], size, format, current_context())
        finalizer(free, obj)

        return obj
    end
end

function bind(buffer::GLRenderbuffer)
    if buffer.id == 0
        error("Binding freed GLRenderbuffer")
    end
    glBindRenderbuffer(GL_RENDERBUFFER, buffer.id)
    return
end

function unsafe_free(x::GLRenderbuffer)
    # don't free if already freed
    x.id == 0 && return
    # don't free from other context
    GLAbstraction.context_alive(x.context) || return
    GLAbstraction.switch_context!(x.context)
    id = Ref(x.id)
    glDeleteRenderbuffers(1, id)
    x.id = 0
    return
end


# TODO: Add RenderBuffer, resize!() with renderbuffer (recreate?)
mutable struct GLFramebuffer
    id::GLuint
    size::NTuple{2, Int}

    context::GLContext

    attachments::Dict{Symbol, GLenum}
    buffers::Dict{Symbol, Texture}
    counter::UInt32 # for color attachments

    function GLFramebuffer(size::NTuple{2, Int})
        # Create framebuffer
        id = glGenFramebuffers()
        glBindFramebuffer(GL_FRAMEBUFFER, id)

        obj = new(
            id, size, current_context(),
            Dict{Symbol, GLuint}(),
            Dict{Symbol, Texture}(),
            UInt32(0)
        )
        finalizer(free, obj)

        return obj
    end
end

function bind(fb::GLFramebuffer)
    if fb.id == 0
        error("Binding freed GLFramebuffer")
    end
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    return
end

function unsafe_free(x::GLFramebuffer)
    # don't free if already freed
    x.id == 0 && return
    # don't free from other context
    GLAbstraction.context_alive(x.context) || return
    GLAbstraction.switch_context!(x.context)
    id = Ref(x.id)
    glDeleteFramebuffers(1, id)
    x.id = 0
    return
end

Base.size(fb::GLFramebuffer) = fb.size
Base.haskey(fb::GLFramebuffer, key::Symbol) = haskey(fb.buffers, key)

function Base.resize!(fb::GLFramebuffer, w::Int, h::Int)
    (w > 0 && h > 0 && (w, h) != size(fb)) || return
    for (key, buffer) in fb.buffers
        resize_nocopy!(buffer, (w, h))
    end
    fb.size = (w, h)
    return
end

function get_next_colorbuffer_attachment(fb::GLFramebuffer)
    if fb.counter >= 15
        error("The framebuffer has exhausted its maximum number of color attachments.")
    end
    attachment = GL_COLOR_ATTACHMENT0 + fb.counter
    fb.counter += 1
    return attachment
end

attach_colorbuffer(fb::GLFramebuffer, key::Symbol, buffer) = attach(fb, key, buffer, get_next_colorbuffer_attachment(fb))
attach_depthbuffer(fb::GLFramebuffer, key::Symbol, buffer) = attach(fb, key, buffer, GL_DEPTH_ATTACHMENT)
attach_stencilbuffer(fb::GLFramebuffer, key::Symbol, buffer) = attach(fb, key, buffer, GL_STENCIL_ATTACHMENT)

function attach(fb::GLFramebuffer, key::Symbol, buffer, attachment::GLenum)
    haskey(fb, key) && error("Cannot attach $key to Framebuffer because it is already set.")
    if in(attachment, keys(fb.buffers))
        if attachment == GL_DEPTH_ATTACHMENT
            type = "depth"
        elseif attachment == GL_STENCIL_ATTACHMENT
            type = "stencil"
        else
            type = "color"
        end
        error("Cannot attach $key as a $type attachment as it is already attached.")
    end

    bind(fb)
    _attach(buffer, attachment)
    fb.attachments[key] = attachment
    fb.buffers[key] = buffer
    return attachment
end

function _attach(t::Texture{T, 2}, attachment::GLenum) where {T}
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end
function _attach(buffer::RenderBuffer, attachment::GLenum)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, buffer)
end

get_attachment(fb::GLFramebuffer, key::Symbol) = fb.attachments[key]
get_buffer(fb::GLFramebuffer, key::Symbol) = fb.buffers[key]

function enum_to_error(s)
    s == GL_FRAMEBUFFER_COMPLETE && return
    s == GL_FRAMEBUFFER_UNDEFINED &&
        error("GL_FRAMEBUFFER_UNDEFINED: The specified framebuffer is the default read or draw framebuffer, but the default framebuffer does not exist.")
    s == GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT &&
        error("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: At least one of the framebuffer attachment points is incomplete.")
    s == GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT &&
        error("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: The framebuffer does not have at least one image attached to it.")
    s == GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER &&
        error("GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER: The value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for any color attachment point(s) specified by GL_DRAW_BUFFERi.")
    s == GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER &&
        error("GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER: GL_READ_BUFFER is not GL_NONE and the value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for the color attachment point specified by GL_READ_BUFFER.")
    s == GL_FRAMEBUFFER_UNSUPPORTED &&
        error("GL_FRAMEBUFFER_UNSUPPORTED: The combination of internal formats of the attached images violates a driver implementation-dependent set of restrictions. Check your OpenGL driver!")
    s == GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE &&
        error("GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE: The value of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers;
if the value of GL_TEXTURE_SAMPLES is not the same for all attached textures; or, if the attached images consist of a mix of renderbuffers and textures,
    the value of GL_RENDERBUFFER_SAMPLES does not match the value of GL_TEXTURE_SAMPLES.
    GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE is also returned if the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not consistent across all attached textures;
        or, if the attached images include a mix of renderbuffers and textures, the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not set to GL_TRUE for all attached textures.")
    s == GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS &&
        error("GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS: Any framebuffer attachment is layered, and any populated attachment is not layered, or if all populated color attachments are not from textures of the same target.")
    return error("Unknown framebuffer completion error code: $s")
end

function check_framebuffer()
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
    return enum_to_error(status)
end

function Base.show(io::IO, fb::GLFramebuffer)
    X, Y = fb.size
    print(io, "$X×$Y GLFrameBuffer(:")
    join(io, string.(keys(fb.buffers)), ", :")
    print(io, ")")
end

function attachment_enum_to_string(x::GLenum)
    x == GL_DEPTH_ATTACHMENT && return "GL_DEPTH_ATTACHMENT"
    x == GL_STENCIL_ATTACHMENT && return "GL_STENCIL_ATTACHMENT"
    i = Int(x - GL_COLOR_ATTACHMENT0)
    return "GL_COLOR_ATTACHMENT$i"
end

function Base.show(io::IO, ::MIME"text/plain", fb::GLFramebuffer)
    X, Y = fb.size
    print(io, "$X×$Y GLFrameBuffer()")

    ks = collect(keys(fb.buffers))
    key_strings = [":$k" for k in ks]
    key_pad = mapreduce(length, max, key_strings)
    key_strings = rpad.(key_strings, key_pad)

    attachments = map(key -> attachment_enum_to_string(get_attachment(fb, key)), ks)
    idxs = sortperm(attachments)
    attachment_pad = mapreduce(length, max, attachments)
    attachments = rpad.(attachments, attachment_pad)

    for i in idxs
        T = typeof(get_buffer(fb, ks[i]))
        print(io, "\n  ", key_strings[i], " => ", attachments[i], " ::", T)
    end
end