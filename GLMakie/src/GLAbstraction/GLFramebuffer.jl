# TODO: Add RenderBuffer, resize!() with renderbuffer (recreate?)
mutable struct GLFramebuffer
    id::GLuint
    size::NTuple{2, Int}

    context::GLContext

    name2idx::Dict{Symbol, Int}
    attachments::Vector{GLenum}
    buffers::Vector{Texture}
    counter::UInt32 # for color attachments

    function GLFramebuffer(context, size::NTuple{2, Int})
        gl_switch_context!(context)

        # Create framebuffer
        id = glGenFramebuffers()
        glBindFramebuffer(GL_FRAMEBUFFER, id)

        obj = new(
            id, size, context,
            Dict{Symbol, Int}(), GLenum[], Texture[], UInt32(0)
        )
        finalizer(verify_free, obj)

        return obj
    end
end

function bind(fb::GLFramebuffer, target = fb.id)
    if fb.id == 0
        error("Binding freed GLFramebuffer")
    end
    glBindFramebuffer(GL_FRAMEBUFFER, target)
    return
end

# This allows you to just call `set_draw_buffers(framebuffer)` with a framebuffer
# dedicated to a specific (type of) draw call, i.e. one that only contains
# attachments matching the outputs of the draw call. But it restricts how you
# can modify the framebuffer a bit (1)
"""
    draw_buffers(fb::GLFrameBuffer[, N::Int])

Activates the first N color buffers attached to the given GLFramebuffer. If N
is not given all color attachments are activated.
"""
function set_draw_buffers(fb::GLFramebuffer, N::Integer = fb.counter)
    gl_switch_context!(fb.context)
    bind(fb)
    glDrawBuffers(N, fb.attachments)
    return
end
function set_draw_buffers(fb::GLFramebuffer, key::Symbol)
    gl_switch_context!(fb.context)
    bind(fb)
    glDrawBuffer(get_attachment(fb, key))
    return
end
function set_draw_buffers(fb::GLFramebuffer, keys::Symbol...)
    gl_switch_context!(fb.context)
    bind(fb)
    glDrawBuffer(get_attachment.(Ref(fb), keys))
    return
end

function unsafe_free(x::GLFramebuffer)
    id = Ref(x.id)
    glDeleteFramebuffers(1, id)
    x.id = 0
    return
end

Base.size(fb::GLFramebuffer) = fb.size
Base.haskey(fb::GLFramebuffer, key::Symbol) = haskey(fb.name2idx, key)

function Base.resize!(fb::GLFramebuffer, w::Int, h::Int)
    (w > 0 && h > 0 && (w, h) != size(fb)) || return
    for buffer in fb.buffers
        resize_nocopy!(buffer, (w, h))
    end
    fb.size = (w, h)
    return
end

function get_next_colorbuffer_attachment(fb::GLFramebuffer)
    if fb.counter >= 15
        error("The framebuffer has exhausted its maximum number of color attachments.")
    end
    # (1) Disallows random deletion as that can change the order of buffers. As
    # a result we don't have to worry about counter pointing to an existing item here.
    attachment = GL_COLOR_ATTACHMENT0 + fb.counter
    fb.counter += 1
    return (fb.counter, attachment)
end

function attach_colorbuffer(fb::GLFramebuffer, key::Symbol, buffer)
    return attach(fb, key, buffer, get_next_colorbuffer_attachment(fb)...)
end
function attach_depthbuffer(fb::GLFramebuffer, key::Symbol, buffer)
    return attach(fb, key, buffer, length(fb.attachments) + 1, GL_DEPTH_ATTACHMENT)
end
function attach_stencilbuffer(fb::GLFramebuffer, key::Symbol, buffer)
    return attach(fb, key, buffer, length(fb.attachments) + 1, GL_STENCIL_ATTACHMENT)
end
function attach_depthstencilbuffer(fb::GLFramebuffer, key::Symbol, buffer)
    return attach(fb, key, buffer, length(fb.attachments) + 1, GL_DEPTH_STENCIL_ATTACHMENT)
end

function attach(fb::GLFramebuffer, key::Symbol, buffer, idx::Integer, attachment::GLenum)
    gl_switch_context!(fb.context)
    haskey(fb, key) && error("Cannot attach " * string(key) * " to Framebuffer because it is already set.")
    if attachment in fb.attachments
        if attachment == GL_DEPTH_ATTACHMENT
            type = "depth"
        elseif attachment == GL_STENCIL_ATTACHMENT
            type = "stencil"
        elseif attachment == GL_DEPTH_STENCIL_ATTACHMENT
            type = "depth-stencil"
        else
            type = "color"
        end
        error("Cannot attach " * string(key) * " as a " * type * " attachment as it is already attached.")
    end

    try
        bind(fb)
        gl_attach(buffer, attachment)
        check_framebuffer()
    catch e
        if GL_COLOR_ATTACHMENT0 <= attachment <= GL_COLOR_ATTACHMENT15
            # If we failed to attach correctly we should probably overwrite
            # the attachment next time we try?
            fb.counter -= 1
        end
        @info "$key -> $(GLENUM(attachment).name) failed with framebuffer id = $(fb.id)"
        rethrow(e)
    end
    # (1) requires us to keep depth/stenctil/depth_stencil at end so that the first
    # fb.counter buffers are usable draw buffers.
    for (k, v) in fb.name2idx
        fb.name2idx[k] = ifelse(v < idx, v, v + 1)
    end
    fb.name2idx[key] = idx
    insert!(fb.attachments, idx, attachment)
    insert!(fb.buffers, idx, buffer)
    return attachment
end

function gl_attach(t::Texture{T, 2}, attachment::GLenum) where {T}
    return glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end
function gl_attach(buffer::RenderBuffer, attachment::GLenum)
    return glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, buffer)
end

# (1) disallows random deletion because that could disrupt the order of draw buffers -> no delete!()
function pop_colorbuffer!(fb::GLFramebuffer)
    gl_switch_context!(fb.context)
    # (1) depth, stencil are attached after the last colorbuffer, after fb.counter.
    # Need to fix their indices after deletion
    attachment = fb.attachments[fb.counter]
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, 0, 0)
    deleteat!(fb.attachments, fb.counter)
    deleteat!(fb.buffers, fb.counter)
    key = :unknown
    for (k, v) in fb.name2idx
        (v == fb.counter) && (key = k)
        (v > fb.counter) && (fb.name2idx[k] = v - 1)
    end
    delete!(fb.name2idx, key)
    fb.counter -= 1
    return fb
end

get_attachment(fb::GLFramebuffer, key::Symbol) = fb.attachments[fb.name2idx[key]]
get_buffer(fb::GLFramebuffer, key::Symbol) = fb.buffers[fb.name2idx[key]]

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
    join(io, string.(keys(fb.name2idx)), ", :")
    return print(io, ") with id ", fb.id)
end

function attachment_enum_to_string(x::GLenum)
    x == GL_DEPTH_ATTACHMENT && return "GL_DEPTH_ATTACHMENT"
    x == GL_STENCIL_ATTACHMENT && return "GL_STENCIL_ATTACHMENT"
    x == GL_DEPTH_STENCIL_ATTACHMENT && return "GL_DEPTH_STENCIL_ATTACHMENT"
    x == GL_STENCIL_ATTACHMENT && return "GL_STENCIL_ATTACHMENT"
    i = Int(x - GL_COLOR_ATTACHMENT0)
    return "GL_COLOR_ATTACHMENT$i"
end

function Base.show(io::IO, ::MIME"text/plain", fb::GLFramebuffer)
    X, Y = fb.size
    print(io, "$X×$Y GLFrameBuffer() with id ", fb.id)

    ks = collect(keys(fb.name2idx))
    sort!(ks, by = k -> fb.name2idx[k])
    key_strings = [":$k" for k in ks]
    key_pad = mapreduce(length, max, key_strings)
    key_strings = rpad.(key_strings, key_pad)

    attachments = attachment_enum_to_string.(fb.attachments)
    attachment_pad = mapreduce(length, max, attachments)
    attachments = rpad.(attachments, attachment_pad)

    for (key, attachment, buffer) in zip(key_strings, attachments, fb.buffers)
        print(io, "\n  ", key, " => ", attachment, " ::", typeof(buffer))
    end
    return
end
