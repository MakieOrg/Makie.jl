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

    name2idx::Dict{Symbol, Int}
    attachments::Vector{GLenum}
    buffers::Vector{Texture}
    counter::UInt32 # for color attachments

    function GLFramebuffer(size::NTuple{2, Int})
        # Create framebuffer
        id = glGenFramebuffers()
        glBindFramebuffer(GL_FRAMEBUFFER, id)

        obj = new(
            id, size, current_context(),
            Dict{Symbol, Int}(), GLenum[], Texture[], UInt32(0)
        )
        finalizer(free, obj)

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

"""
    draw_buffers(fb::GLFrameBuffer[, N::Int])

Activates the first N color buffers attached to the given GLFramebuffer. If N
is not given all color attachments are activated.
"""
function set_draw_buffers(fb::GLFramebuffer, N::Integer = fb.counter)
    bind(fb)
    glDrawBuffers(N, fb.attachments)
end
function set_draw_buffers(fb::GLFramebuffer, key::Symbol)
    bind(fb)
    glDrawBuffer(get_attachment(fb, key))
end
function set_draw_buffers(fb::GLFramebuffer, keys::Symbol...)
    bind(fb)
    glDrawBuffer(get_attachment.(Ref(fb), keys))
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

const ATTACHMENT_LOOKUP = Dict{Int, Symbol}(
    GL_DEPTH_ATTACHMENT => :GL_DEPTH_ATTACHMENT,
    GL_STENCIL_ATTACHMENT => :GL_STENCIL_ATTACHMENT,
    GL_DEPTH_STENCIL_ATTACHMENT => :GL_DEPTH_STENCIL_ATTACHMENT,
    GL_COLOR_ATTACHMENT0 => :GL_COLOR_ATTACHMENT0,
    GL_COLOR_ATTACHMENT1 => :GL_COLOR_ATTACHMENT1,
    GL_COLOR_ATTACHMENT2 => :GL_COLOR_ATTACHMENT2,
    GL_COLOR_ATTACHMENT3 => :GL_COLOR_ATTACHMENT3,
    GL_COLOR_ATTACHMENT4 => :GL_COLOR_ATTACHMENT4,
    GL_COLOR_ATTACHMENT5 => :GL_COLOR_ATTACHMENT5,
    GL_COLOR_ATTACHMENT6 => :GL_COLOR_ATTACHMENT6,
    GL_COLOR_ATTACHMENT7 => :GL_COLOR_ATTACHMENT7,
    GL_COLOR_ATTACHMENT8 => :GL_COLOR_ATTACHMENT8,
    GL_COLOR_ATTACHMENT9 => :GL_COLOR_ATTACHMENT9,
    GL_COLOR_ATTACHMENT10 => :GL_COLOR_ATTACHMENT10,
    GL_COLOR_ATTACHMENT11 => :GL_COLOR_ATTACHMENT11,
    GL_COLOR_ATTACHMENT12 => :GL_COLOR_ATTACHMENT12,
    GL_COLOR_ATTACHMENT13 => :GL_COLOR_ATTACHMENT13,
    GL_COLOR_ATTACHMENT14 => :GL_COLOR_ATTACHMENT14,
    GL_COLOR_ATTACHMENT15 => :GL_COLOR_ATTACHMENT15
)

function attach(fb::GLFramebuffer, key::Symbol, buffer, idx::Integer, attachment::GLenum)
    haskey(fb, key) && error("Cannot attach $key to Framebuffer because it is already set.")
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
        error("Cannot attach $key as a $type attachment as it is already attached.")
    end

    try
        bind(fb)
        gl_attach(buffer, attachment)
        check_framebuffer()
    catch e
        @info "$key -> $attachment = $(get(ATTACHMENT_LOOKUP, attachment, :UNKNOWN)) failed, with framebuffer id = $(fb.id)"
        rethrow(e)
    end
    # keep depth/stenctil/depth_stencil at end so that we can directly use
    # fb.attachments when setting drawbuffers
    for (k, v) in fb.name2idx
        fb.name2idx[k] = ifelse(v < idx, v, v+1)
    end
    fb.name2idx[key] = idx
    insert!(fb.attachments, idx, attachment)
    insert!(fb.buffers, idx, buffer)
    return attachment
end

function gl_attach(t::Texture{T, 2}, attachment::GLenum) where {T}
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end
function gl_attach(buffer::RenderBuffer, attachment::GLenum)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, buffer)
end

# Need to be careful with counter here
# We have [colorbuffers..., depth/stencil]
#                       ^- counter = last before depth/stencil
# And also with the GLFramebuffer being ordered
# So we only allow pop! for colorbuffers, no delete!()
function pop_colorbuffer!(fb::GLFramebuffer)
    attachment = fb.attachments[fb.counter]
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, 0, 0)
    deleteat!(fb.attachments, fb.counter)
    deleteat!(fb.buffers, fb.counter)
    key = :unknown
    for (k, v) in fb.name2idx
        (v == fb.counter) && (key = k)
        (v > fb.counter) && (fb.name2idx[k] = v-1)
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
    print(io, ") with id ", fb.id)
end

function attachment_enum_to_string(x::GLenum)
    x == GL_DEPTH_ATTACHMENT && return "GL_DEPTH_ATTACHMENT"
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

    attachments = attachment_enum_to_string(fb.attachments)
    attachment_pad = mapreduce(length, max, attachments)
    attachments = rpad.(attachments, attachment_pad)

    for (key, attachment, buffer) in zip(key_strings, attachments, fb.buffers)
        print(io, "\n  ", key, " => ", attachment, " ::", typeof(buffer))
    end
end