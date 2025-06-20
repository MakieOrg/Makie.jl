struct TextureParameters{NDim}
    minfilter::Symbol
    magfilter::Symbol # magnification
    repeat::NTuple{NDim, Symbol}
    anisotropic::Float32
    swizzle_mask::Vector{GLenum}
end

abstract type OpenglTexture{T, NDIM} <: GPUArray{T, NDIM} end

mutable struct Texture{T <: GLArrayEltypes, NDIM} <: OpenglTexture{T, NDIM}
    id::GLuint
    texturetype::GLenum
    pixeltype::GLenum
    internalformat::GLenum
    format::GLenum
    parameters::TextureParameters{NDIM}
    size::NTuple{NDIM, Int}
    context::GLContext
    observers::Vector{Observables.ObserverFunction}
    function Texture{T, NDIM}(
            context::GLContext,
            id::GLuint,
            texturetype::GLenum,
            pixeltype::GLenum,
            internalformat::GLenum,
            format::GLenum,
            parameters::TextureParameters{NDIM},
            size::NTuple{NDIM, Int},
        ) where {T, NDIM}
        tex = new(
            id,
            texturetype,
            pixeltype,
            internalformat,
            format,
            parameters,
            size,
            context,
            Observables.ObserverFunction[]
        )
        DEBUG[] && finalizer(verify_free, tex)
        return tex
    end
end

# for bufferSampler, aka Texture Buffer
mutable struct TextureBuffer{T <: GLArrayEltypes} <: OpenglTexture{T, 1}
    texture::Texture{T, 1}
    buffer::GLBuffer{T}
    function TextureBuffer(texture::Texture{T, 1}, buffer::GLBuffer{T}) where {T}
        return new{T}(texture, buffer)
    end
end
Base.size(t::TextureBuffer) = size(t.buffer)
Base.size(t::TextureBuffer, i::Integer) = size(t.buffer, i)
Base.length(t::TextureBuffer) = length(t.buffer)
function bind(t::Texture)
    gl_switch_context!(t.context)
    if t.id == 0
        error("Binding freed Texture{$(eltype(t))}")
    end
    return glBindTexture(t.texturetype, t.id)
end

bind(t::Texture, id) = glBindTexture(t.texturetype, id)
gl_switch_context!(t::TextureBuffer) = gl_switch_context!(t.texture.context)

function free(tb::TextureBuffer)
    free(tb.texture)
    return free(tb.buffer)
end

is_texturearray(t::Texture) = t.texturetype == GL_TEXTURE_2D_ARRAY
is_texturebuffer(t::Texture) = t.texturetype == GL_TEXTURE_BUFFER

colordim(::Type{T}) where {T} = cardinality(T)
colordim(::Type{T}) where {T <: Real} = 1

function set_packing_alignment(a) # at some point we should specialize to array/ptr a
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0)
    return glPixelStorei(GL_UNPACK_SKIP_ROWS, 0)
end

Makie.@noconstprop function Texture(
        context, data::Ptr{T}, dims::NTuple{NDim, Int};
        internalformat::GLenum = default_internalcolorformat(T),
        texturetype::GLenum = default_texturetype(NDim),
        format::GLenum = default_colorformat(T),
        mipmap = false,
        parameters... # rest should be texture parameters
    ) where {T, NDim}
    texparams = TextureParameters(T, NDim; parameters...)
    id = glGenTextures()
    glBindTexture(texturetype, id)
    set_packing_alignment(data)
    numbertype = julia2glenum(eltype(T))
    glTexImage(texturetype, 0, internalformat, dims..., 0, format, numbertype, data)
    mipmap && glGenerateMipmap(texturetype)
    texture = Texture{T, NDim}(
        context, id, texturetype, numbertype, internalformat, format,
        texparams,
        dims
    )
    set_parameters(texture)
    texture::Texture{T, NDim}
end
export resize_nocopy!
function resize_nocopy!(t::Texture{T, NDim}, newdims::NTuple{NDim, Int}) where {T, NDim}
    gl_switch_context!(t.context)
    bind(t)
    glTexImage(t.texturetype, 0, t.internalformat, newdims..., 0, t.format, t.pixeltype, C_NULL)
    t.size = newdims
    bind(t, 0)
    return t
end

"""
Constructor for empty initialization with NULL pointer instead of an array with data.
You just need to pass the wanted color/vector type and the dimensions.
To which values the texture gets initialized is driver dependent
"""
Texture(context, ::Type{T}, dims::NTuple{N, Int}; kw_args...) where {T <: GLArrayEltypes, N} =
    Texture(context, convert(Ptr{T}, C_NULL), dims; kw_args...)::Texture{T, N}

"""
Constructor for a normal array, with color or Abstract Arrays as elements.
So Array{Real, 2} == Texture2D with 1D Colorant dimension
Array{Vec1/2/3/4, 2} == Texture2D with 1/2/3/4D Colorant dimension
Colors from Colors.jl should mostly work as well
"""
Texture(context, image::Array{T, NDim}; kw_args...) where {T <: GLArrayEltypes, NDim} =
    Texture(context, pointer(image), size(image); kw_args...)::Texture{T, NDim}

Texture(context, image::AbstractArray{T, NDim}; kw_args...) where {T <: GLArrayEltypes, NDim} =
    Texture(context, collect(image); kw_args...)

function Texture(context, s::ShaderAbstractions.Sampler{T, N}; kwargs...) where {T, N}
    tex = Texture(
        context, pointer(s.data), size(s.data),
        minfilter = s.minfilter, magfilter = s.magfilter,
        x_repeat = s.repeat[1], y_repeat = s.repeat[min(2, N)], z_repeat = s.repeat[min(3, N)],
        mipmap = s.mipmap, anisotropic = s.anisotropic; kwargs...
    )
    obsfunc = ShaderAbstractions.connect!(s, tex)
    push!(tex.observers, obsfunc)
    return tex
end

"""
Constructor for Array Texture
"""
function Texture(
        context, data::Vector{Array{T, 2}};
        internalformat::GLenum = default_internalcolorformat(T),
        texturetype::GLenum = GL_TEXTURE_2D_ARRAY,
        format::GLenum = default_colorformat(T),
        parameters...
    ) where {T <: GLArrayEltypes}
    texparams = TextureParameters(T, 2; parameters...)
    id = glGenTextures()

    glBindTexture(texturetype, id)

    numbertype = julia2glenum(eltype(T))

    layers = length(data)
    dims = map(size, data)
    maxdims = foldl(dims, init = (0, 0)) do v0, x
        a = max(v0[1], x[1])
        b = max(v0[2], x[2])
        (a, b)
    end
    set_packing_alignment(data)
    glTexStorage3D(GL_TEXTURE_2D_ARRAY, 1, internalformat, maxdims..., layers)
    for (layer, texel) in enumerate(data)
        width, height = size(texel)
        glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, layer - 1, width, height, 1, format, numbertype, texel)
    end

    texture = Texture{T, 2}(
        context, id, texturetype, numbertype,
        internalformat, format, texparams,
        tuple(maxdims...)
    )
    set_parameters(texture)
    return texture
end


function TextureBuffer(buffer::GLBuffer{T}) where {T <: GLArrayEltypes}
    texture_type = GL_TEXTURE_BUFFER
    id = glGenTextures()
    glBindTexture(texture_type, id)
    internalformat = default_internalcolorformat(T)
    glTexBuffer(texture_type, internalformat, buffer.id)
    tex = Texture{T, 1}(
        buffer.context, id, texture_type, julia2glenum(T), internalformat,
        default_colorformat(T), TextureParameters(T, 1),
        size(buffer)
    )
    return TextureBuffer(tex, buffer)
end
function TextureBuffer(context, buffer::Vector{T}) where {T <: GLArrayEltypes}
    buff = GLBuffer(context, buffer, buffertype = GL_TEXTURE_BUFFER, usage = GL_DYNAMIC_DRAW)
    return TextureBuffer(buff)
end

#=
Some special treatmend for types, with alpha in the First place

function Texture{T <: Real, NDim}(image::Array{ARGB{T}, NDim}, texture_properties::Vector{(Symbol, Any)})
    data = map(image) do colorvalue
        AlphaColorValue(colorvalue.c, colorvalue.alpha)
    end
    Texture(pointer(data), [size(data)...], texture_properties)
end
=#

#=
Creates a texture from an Image
=#
##function Texture(image::Image, texture_properties::Vector{(Symbol, Any)})
#    data = image.data
#    Texture(mapslices(reverse, data, ndims(data)), texture_properties)
#end

# AbstractArrays default show assumes `getindex`. Try to catch all calls
# https://discourse.julialang.org/t/overload-show-for-array-of-custom-types/9589

Base.show(io::IO, t::Texture) = show(IOContext(io), MIME"text/plain"(), t)

function Base.show(io::IOContext, mime::MIME"text/plain", t::Texture{T, D}) where {T, D}
    return if get(io, :compact, false)
        println(io, "Texture$(D)D, ID: $(t.id), Size: $(size(t))")
    else
        show(io.io, mime, t)
    end
end

function Base.show(io::IO, ::MIME"text/plain", t::Texture{T, D}) where {T, D}
    println(io, "Texture$(D)D: ")
    println(io, "                  ID: ", t.id)
    println(
        io, "                Size: ", reduce(size(t), init = "Dimensions: ") do v0, v1
            v0 * "x" * string(v1)
        end
    )
    println(io, "    Julia pixel type: ", T)
    println(io, "   OpenGL pixel type: ", GLENUM(t.pixeltype).name)
    println(io, "              Format: ", GLENUM(t.format).name)
    println(io, "     Internal format: ", GLENUM(t.internalformat).name)
    return println(io, "          Parameters: ", t.parameters)
end

# GPUArray interface:
function unsafe_copy!(a::Vector{T}, readoffset::Int, b::TextureBuffer{T}, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(b.texture.context)
    copy!(a, readoffset, b.buffer, writeoffset, len)
    bind(b.texture)
    return glTexBuffer(b.texture.texturetype, b.texture.internalformat, b.buffer.id) # update texture
end

function unsafe_copy!(a::TextureBuffer{T}, readoffset::Int, b::Vector{T}, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(a.texture.context)
    copy!(a.buffer, readoffset, b, writeoffset, len)
    bind(a.texture)
    return glTexBuffer(a.texture.texturetype, a.texture.internalformat, a.buffer.id) # update texture
end

function unsafe_copy!(a::TextureBuffer{T}, readoffset::Int, b::TextureBuffer{T}, writeoffset::Int, len::Int) where {T}
    gl_switch_context!(a.texture.context)
    @assert a.texture.context == b.texture.context
    unsafe_copy!(a.buffer, readoffset, b.buffer, writeoffset, len)

    bind(a.texture)
    glTexBuffer(a.texture.texturetype, a.texture.internalformat, a.buffer.id) # update texture

    bind(b.texture)
    glTexBuffer(b.texture.texturetype, b.texture.internalformat, b.buffer.id) # update texture
    return bind(t.texture, 0)
end

function gpu_setindex!(t::TextureBuffer{T}, newvalue::Vector{T}, indexes::UnitRange{I}) where {T, I <: Integer}
    gl_switch_context!(t.texture.context)
    bind(t.texture)
    t.buffer[indexes] = newvalue # set buffer indexes
    glTexBuffer(t.texture.texturetype, t.texture.internalformat, t.buffer.id) # update texture
    return bind(t.texture, 0)
end

function gpu_setindex!(t::Texture{T, 1}, newvalue::Array{T, 1}, indexes::UnitRange{I}) where {T, I <: Integer}
    gl_switch_context!(t.context)
    bind(t)
    texsubimage(t, newvalue, indexes)
    return bind(t, 0)
end
function gpu_setindex!(t::Texture{T, N}, newvalue::Array{T, N}, indexes::Union{UnitRange, Integer}...) where {T, N}
    gl_switch_context!(t.context)
    bind(t)
    texsubimage(t, newvalue, indexes...)
    return bind(t, 0)
end


function gpu_setindex!(target::Texture{T, 2}, source::Texture{T, 2}, fbo = glGenFramebuffers()) where {T}
    gl_switch_context!(target.context)
    @assert target.context == source.context
    glBindFramebuffer(GL_FRAMEBUFFER, fbo)
    glFramebufferTexture2D(
        GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
        GL_TEXTURE_2D, source.id, 0
    )
    glFramebufferTexture2D(
        GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT1,
        GL_TEXTURE_2D, target.id, 0
    )
    glDrawBuffer(GL_COLOR_ATTACHMENT1)
    w, h = map(minimum, zip(size(target), size(source)))
    return glBlitFramebuffer(
        0, 0, w, h, 0, 0, w, h,
        GL_COLOR_BUFFER_BIT, GL_NEAREST
    )
end


#=
function gpu_setindex!{T}(target::Texture{T, 2}, source::Texture{T, 2}, fbo=glGenFramebuffers())
    w, h = map(minimum, zip(size(target), size(source)))
    glCopyImageSubData( source.id, source.texturetype,
    0,0,0,0,
    target.id, target.texturetype,
    0,0,0,0, w,h,0);
end
=#
# Implementing the GPUArray interface
function gpu_data(t::Texture{T, NDim}) where {T, NDim}
    gl_switch_context!(t.context)
    result = Array{T, NDim}(undef, size(t))
    unsafe_copy!(result, t)
    return result
end

function unsafe_copy!(dest::Array{T, N}, source::Texture{T, N}) where {T, N}
    gl_switch_context!(source.context)
    bind(source)
    glGetTexImage(source.texturetype, 0, source.format, source.pixeltype, dest)
    bind(source, 0)
    return nothing
end

gpu_data(t::TextureBuffer{T}) where {T} = gpu_data(t.buffer)
gpu_getindex(t::TextureBuffer{T}, i::UnitRange{Int64}) where {T} = t.buffer[i]

similar(t::Texture{T, NDim}, newdims::Int...) where {T, NDim} = similar(t, newdims)
function similar(t::TextureBuffer{T}, newdims::NTuple{1, Int}) where {T}
    buff = similar(t.buffer, newdims...)
    return TextureBuffer(buff)
end

function similar(t::Texture{T, NDim}, newdims::NTuple{NDim, Int}) where {T, NDim}
    id = glGenTextures()
    glBindTexture(t.texturetype, id)
    glTexImage(t.texturetype, 0, t.internalformat, newdims..., 0, t.format, t.pixeltype, C_NULL)
    return Texture{T, NDim}(
        t.context, id,
        t.texturetype,
        t.pixeltype,
        t.internalformat,
        t.format,
        t.parameters,
        newdims
    )
end
# Resize Texture
function gpu_resize!(t::TextureBuffer{T}, newdims::NTuple{1, Int}) where {T}
    gl_switch_context!(t.texture.context)
    resize!(t.buffer, newdims)
    bind(t.texture)
    glTexBuffer(t.texture.texturetype, t.texture.internalformat, t.buffer.id) #update data in texture
    t.texture.size = newdims
    bind(t.texture, 0)
    return t
end
# Resize Texture
function gpu_resize!(t::Texture{T, NDim}, newdims::NTuple{NDim, Int}) where {T, NDim}
    gl_switch_context!(t.context)
    # dangerous code right here...Better write a few tests for this
    newtex = similar(t, newdims)
    old_size = size(t)
    gpu_setindex!(newtex, t)
    t.size = newdims
    free(t)
    t.id = newtex.id
    return t
end

function texsubimage(t::Texture{T, 1}, newvalue::Array{T}, xrange::UnitRange, level = 0) where {T}
    gl_switch_context!(t.context)
    return glTexSubImage1D(
        t.texturetype, level, first(xrange) - 1, length(xrange), t.format, t.pixeltype, newvalue
    )
end
function texsubimage(t::Texture{T, 2}, newvalue::Array{T}, xrange::UnitRange, yrange::UnitRange, level = 0) where {T}
    gl_switch_context!(t.context)
    return glTexSubImage2D(
        t.texturetype, level,
        first(xrange) - 1, first(yrange) - 1, length(xrange), length(yrange),
        t.format, t.pixeltype, newvalue
    )
end
function texsubimage(t::Texture{T, 3}, newvalue::Array{T}, xrange::UnitRange, yrange::UnitRange, zrange::UnitRange, level = 0) where {T}
    gl_switch_context!(t.context)
    return glTexSubImage3D(
        t.texturetype, level,
        first(xrange) - 1, first(yrange) - 1, first(zrange) - 1, length(xrange), length(yrange), length(zrange),
        t.format, t.pixeltype, newvalue
    )
end

function Base.iterate(t::TextureBuffer{T}) where {T}
    gl_switch_context!(t.context)
    return iterate(t.buffer)
end
function Base.iterate(t::TextureBuffer{T}, state::Tuple{Ptr{T}, Int}) where {T}
    v_idx = iterate(t.buffer, state)
    if v_idx === nothing
        bind(t)
        glTexBuffer(t.texturetype, t.internalformat, t.buffer.id)
        bind(t, 0)
    end
    return v_idx
end
function default_colorformat_sym(colordim::Integer, isinteger::Bool, colororder::AbstractString)
    colordim > 4 && error("no colors with dimension > 4 allowed. Dimension given: ", colordim)
    sym = "GL_"
    # Handle that colordim == 1 => RED instead of R
    color = colordim == 1 ? "RED" : colororder[1:colordim]
    # Handle gray value
    integer = isinteger ? "_INTEGER" : ""
    sym *= color * integer
    return Symbol(sym)
end

default_colorformat_sym(::Type{T}) where {T <: Real} = default_colorformat_sym(1, T <: Integer, "RED")
default_colorformat_sym(::Type{T}) where {T <: AbstractArray} = default_colorformat_sym(cardinality(T), eltype(T) <: Integer, "RGBA")
default_colorformat_sym(::Type{T}) where {T <: StaticVector} = default_colorformat_sym(cardinality(T), eltype(T) <: Integer, "RGBA")
default_colorformat_sym(::Type{T}) where {T <: Quaternion} = default_colorformat_sym(cardinality(T), eltype(T) <: Integer, "RGBA")
default_colorformat_sym(::Type{T}) where {T <: Colorant} = default_colorformat_sym(cardinality(T), eltype(T) <: Integer, string(Base.typename(T).name))

@generated function default_colorformat(::Type{T}) where {T}
    sym = default_colorformat_sym(T)
    if !isdefined(ModernGL, sym)
        error("$T doesn't have a proper mapping to an OpenGL format")
    end
    return :($sym)
end

function default_internalcolorformat_sym(::Type{T}) where {T}
    cdim = colordim(T)
    if cdim > 4 || cdim < 1
        error("$(cdim)-dimensional colors not supported")
    end
    eltyp = eltype(T)
    sym = "GL_"
    sym *= "RGBA"[1:cdim]
    bits = sizeof(eltyp) * 8
    sym *= bits <= 32 ? string(bits) : error("$(T) has too many bits")
    if eltyp <: AbstractFloat
        sym *= "F"
    elseif eltyp <: FixedPoint
        sym *= eltyp <: Normed ? "" : "_SNORM"
    elseif eltyp <: Signed
        sym *= "I"
    elseif eltyp <: Unsigned
        sym *= "UI"
    end
    return Symbol(sym)
end

# for I = 1:4
#     for
@generated function default_internalcolorformat(::Type{T}) where {T}
    sym = default_internalcolorformat_sym(T)
    if !isdefined(ModernGL, sym)
        error("$T doesn't have a proper mapping to an OpenGL format")
    end
    return :($sym)
end


#Supported texture modes/dimensions
function default_texturetype(ndim::Integer)
    ndim == 1 && return GL_TEXTURE_1D
    ndim == 2 && return GL_TEXTURE_2D
    ndim == 3 && return GL_TEXTURE_3D
    error("Dimensionality: $(ndim), not supported for OpenGL texture")
end


map_texture_paramers(s::NTuple{N, Symbol}) where {N} = map(map_texture_paramers, s)

function map_texture_paramers(s::Symbol)

    s === :clamp_to_edge && return GL_CLAMP_TO_EDGE
    s === :mirrored_repeat && return GL_MIRRORED_REPEAT
    s === :repeat && return GL_REPEAT

    s === :linear && return GL_LINEAR
    s === :nearest && return GL_NEAREST
    s === :nearest_mipmap_nearest && return GL_NEAREST_MIPMAP_NEAREST
    s === :linear_mipmap_nearest && return GL_LINEAR_MIPMAP_NEAREST
    s === :nearest_mipmap_linear && return GL_NEAREST_MIPMAP_LINEAR
    s === :linear_mipmap_linear && return GL_LINEAR_MIPMAP_LINEAR

    error("$s is not a valid texture parameter")
end

function TextureParameters(
        T, NDim;
        minfilter = T <: Integer ? :nearest : :linear,
        magfilter = minfilter, # magnification
        x_repeat = :clamp_to_edge, #wrap_s
        y_repeat = x_repeat, #wrap_t
        z_repeat = x_repeat, #wrap_r
        anisotropic = 1.0f0
    )
    T <: Integer && (minfilter === :linear || magfilter === :linear) && error("Wrong Texture Parameter: Integer texture can't interpolate. Try :nearest")
    repeat = (x_repeat, y_repeat, z_repeat)
    swizzle_mask = if T <: Gray
        GLenum[GL_RED, GL_RED, GL_RED, GL_ONE]
    elseif T <: GrayA
        GLenum[GL_RED, GL_RED, GL_RED, GL_ALPHA]
    else
        GLenum[]
    end
    return TextureParameters(
        minfilter, magfilter, ntuple(i -> repeat[i], NDim),
        anisotropic, swizzle_mask
    )
end
function TextureParameters(t::Texture{T, NDim}; kw_args...) where {T, NDim}
    return TextureParameters(T, NDim; kw_args...)
end

const GL_TEXTURE_MAX_ANISOTROPY_EXT = GLenum(0x84FE)

function set_parameters(t::Texture{T, N}, params::TextureParameters = t.parameters) where {T, N}
    fnames = (:minfilter, :magfilter, :repeat)
    data = Dict([(name, map_texture_paramers(getfield(params, name))) for name in fnames])
    result = Tuple{GLenum, Any}[]
    push!(result, (GL_TEXTURE_MIN_FILTER, data[:minfilter]))
    push!(result, (GL_TEXTURE_MAG_FILTER, data[:magfilter]))
    push!(result, (GL_TEXTURE_WRAP_S, data[:repeat][1]))
    if !isempty(params.swizzle_mask)
        push!(result, (GL_TEXTURE_SWIZZLE_RGBA, params.swizzle_mask))
    end
    N >= 2 && push!(result, (GL_TEXTURE_WRAP_T, data[:repeat][2]))
    if N >= 3 && !is_texturearray(t) # for texture arrays, third dimension can not be set
        push!(result, (GL_TEXTURE_WRAP_R, data[:repeat][3]))
    end
    try
        if GLFW.ExtensionSupported("GL_ARB_texture_filter_anisotropic")
            push!(result, (GL_TEXTURE_MAX_ANISOTROPY_EXT, params.anisotropic))
        end
    catch e
        e.code == GLFW.NO_CURRENT_CONTEXT || rethrow(e)
    end
    t.parameters = params
    return set_parameters(t, result)
end
function texparameter(t::Texture, key::GLenum, val::GLenum)
    return glTexParameteri(t.texturetype, key, val)
end
function texparameter(t::Texture, key::GLenum, val::Vector)
    return glTexParameteriv(t.texturetype, key, val)
end
function texparameter(t::Texture, key::GLenum, val::Float32)
    return glTexParameterf(t.texturetype, key, val)
end
function set_parameters(t::Texture, parameters::Vector{Tuple{GLenum, Any}})
    gl_switch_context!(t.context)
    bind(t)
    for elem in parameters
        texparameter(t, elem...)
    end
    return bind(t, 0)
end
