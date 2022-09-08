mutable struct TextureAtlas
    rectangle_packer::RectanglePacker
    mapping::Dict{Union{BezierPath, Tuple{UInt64, String}}, Int} # styled glyph to index in sprite_attributes
    index::Int
    data::Matrix{Float16}
    # rectangles we rendered our glyphs into in normalized uv coordinates
    uv_rectangles::Vector{Vec4f}
end

Base.size(atlas::TextureAtlas) = size(atlas.data)

@enum GlyphResolution High Low

const HIGH_PIXELSIZE = 64
const LOW_PIXELSIZE = 32

const CACHE_RESOLUTION_PREFIX = Ref("high")
const TEXTURE_RESOLUTION = Ref((2048, 2048))
const PIXELSIZE_IN_ATLAS = Ref(HIGH_PIXELSIZE)
# Small padding results in artifacts during downsampling. It seems like roughly
# 1.5px padding is required for a scaled glyph to be displayed without artifacts.
# E.g. for textsize = 8px we need 1.5/8 * 64 = 12px+ padding (in each direction)
# for things to look clear with a 64px glyph size.
const GLYPH_PADDING = Ref(12)

function set_glyph_resolution!(res::GlyphResolution)
    if res == High
        TEXTURE_RESOLUTION[] = (2048, 2048)
        CACHE_RESOLUTION_PREFIX[] = "high"
        PIXELSIZE_IN_ATLAS[] = HIGH_PIXELSIZE
        GLYPH_PADDING[] = 12
    else
        TEXTURE_RESOLUTION[] = (1024, 1024)
        CACHE_RESOLUTION_PREFIX[] = "low"
        PIXELSIZE_IN_ATLAS[] = LOW_PIXELSIZE
        GLYPH_PADDING[] = 6
    end
end

function TextureAtlas(initial_size = TEXTURE_RESOLUTION[])
    return TextureAtlas(
        RectanglePacker(Rect2(0, 0, initial_size...)),
        Dict{Tuple{UInt64, String}, Int}(),
        1,
        # We use float max here to avoid texture bleed. See #2096
        fill(Float16(0.5PIXELSIZE_IN_ATLAS[] + GLYPH_PADDING[]), initial_size...),
        Vec4f[],
    )
end

begin
    # basically a singleton for the textureatlas

    function get_cache_path()
        return abspath(
            first(Base.DEPOT_PATH), "makie",
            "texture_atlas_$(CACHE_RESOLUTION_PREFIX[])_$(VERSION).jls"
        )
    end

    const _default_font = NativeFont[]
    const _alternative_fonts = NativeFont[]

    function defaultfont()
        if isempty(_default_font)
            push!(_default_font, to_font("TeX Gyre Heros Makie"))
        end
        _default_font[]
    end

    function alternativefonts()
        if isempty(_alternative_fonts)
            alternatives = [
                "TeXGyreHerosMakie-Regular.otf",
                "DejaVuSans.ttf",
                "NotoSansCJKkr-Regular.otf",
                "NotoSansCuneiform-Regular.ttf",
                "NotoSansSymbols-Regular.ttf",
                "FiraMono-Medium.ttf"
            ]
            for font in alternatives
                push!(_alternative_fonts, NativeFont(assetpath("fonts", font)))
            end
        end
        return _alternative_fonts
    end

    function load_ascii_chars!(atlas)
        # for c in '\u0000':'\u00ff' #make sure all ascii is mapped linearly
        #     insert_glyph!(atlas, c, defaultfont())
        # end
        for c in '0':'9' #make sure all ascii is mapped linearly
            insert_glyph!(atlas, c, defaultfont())
        end
        for c in 'A':'Z' #make sure all ascii is mapped linearly
            insert_glyph!(atlas, c, defaultfont())
        end
    end

    function cached_load()
        if isfile(get_cache_path())
            try
                return open(get_cache_path()) do io
                    dict = Serialization.deserialize(io)
                    fields = map(fieldnames(TextureAtlas)) do n
                        v = dict[n]
                        isa(v, Vector) ? copy(v) : v # otherwise there seems to be a problem with resizing
                    end
                    TextureAtlas(fields...)
                end
            catch e
                @info("You can likely ignore the following warning, if you just switched Julia versions for Makie")
                @warn(e)
                rm(get_cache_path())
            end
        end
        atlas = TextureAtlas()
        @info("Makie is caching fonts, this may take a while. Needed only on first run!")
        load_ascii_chars!(atlas)
        to_cache(atlas) # cache it
        return atlas
    end

    function to_cache(atlas)
        if !ispath(dirname(get_cache_path()))
            mkpath(dirname(get_cache_path()))
        end
        open(get_cache_path(), "w") do io
            dict = Dict(map(fieldnames(typeof(atlas))) do name
                name => getfield(atlas, name)
            end)
            Serialization.serialize(io, dict)
        end
    end

    const global_texture_atlas = Dict{Int, TextureAtlas}()

    function get_texture_atlas()
        return get!(global_texture_atlas, PIXELSIZE_IN_ATLAS[]) do
            return cached_load() # initialize only on demand
        end
    end
end


"""
    find_font_for_char(c::Char, font::NativeFont)
Finds the best font for a character from a list of fallback fonts, that get chosen
if `font` can't represent char `c`
"""
function find_font_for_char(glyph, font::NativeFont)
    FreeTypeAbstraction.glyph_index(font, glyph) != 0 && return font
    # it seems that linebreaks are not found which messes up font metrics
    # if another font is selected just for those chars
    glyph in ('\n', '\r', '\t') && return font
    for afont in alternativefonts()
        if FreeTypeAbstraction.glyph_index(afont, glyph) != 0
            return afont
        end
    end
    error("Can't represent character $(glyph) with any fallback font nor $(font.family_name)!")
end

function glyph_index!(atlas::TextureAtlas, glyph, font::NativeFont)
    if FreeTypeAbstraction.glyph_index(font, glyph) == 0
        for afont in alternativefonts()
            if FreeTypeAbstraction.glyph_index(afont, glyph) != 0
                font = afont
            end
        end
    end
    return insert_glyph!(atlas, glyph, font)
end

function glyph_index!(atlas::TextureAtlas, b::BezierPath)
    return insert_glyph!(atlas, b)
end

function glyph_uv_width!(atlas::TextureAtlas, glyph, font::NativeFont)
    return atlas.uv_rectangles[glyph_index!(atlas, glyph, font)]
end

function glyph_uv_width!(glyph)
    return glyph_uv_width!(get_texture_atlas(), glyph, defaultfont())
end

function glyph_uv_width!(b::BezierPath)
    atlas = get_texture_atlas()
    return atlas.uv_rectangles[glyph_index!(atlas, b)]
end

function insert_glyph!(atlas::TextureAtlas, glyph, font::NativeFont)
    glyphindex = FreeTypeAbstraction.glyph_index(font, glyph)
    return get!(atlas.mapping, (glyphindex, FreeTypeAbstraction.fontname(font))) do
        # We save glyphs as signed distance fields, i.e. we save the distance
        # a pixel is away from the edge of a symbol (continuous at the edge).
        # To get accurate distances we want to draw the symbol at high
        # resolution and then downsample to the PIXELSIZE_IN_ATLAS.
        downsample = 5
        # To draw a symbol from a sdf we essentially do `color * (sdf > 0)`. For
        # antialiasing we smooth out the step function `sdf > 0`. That means we
        # need a few values outside the symbol. To guarantee that we have those
        # at all relevant scales we add padding to the rendered bitmap and the
        # resulting sdf.
        pad = GLYPH_PADDING[]

        uv_pixel = render(atlas, glyphindex, font, downsample, pad)
        tex_size = Vec2f(size(atlas.data) .- 1) # starts at 1

        # 0 based
        idx_left_bottom = minimum(uv_pixel)
        idx_right_top = maximum(uv_pixel)

        # transform to normalized texture coordinates
        # -1 for indexing offset
        uv_left_bottom_pad = (idx_left_bottom) ./ tex_size
        uv_right_top_pad = (idx_right_top .- 1) ./ tex_size

        uv_offset_rect = Vec4f(uv_left_bottom_pad..., uv_right_top_pad...)
        i = atlas.index
        push!(atlas.uv_rectangles, uv_offset_rect)
        atlas.index = i + 1
        return i
    end
end

function insert_glyph!(atlas::TextureAtlas, path::BezierPath)
    return get!(atlas.mapping, path) do
        # We save glyphs as signed distance fields, i.e. we save the distance
        # a pixel is away from the edge of a symbol (continuous at the edge).
        # To get accurate distances we want to draw the symbol at high
        # resolution and then downsample to the PIXELSIZE_IN_ATLAS.
        downsample = 5
        # To draw a symbol from a sdf we essentially do `color * (sdf > 0)`. For
        # antialiasing we smooth out the step function `sdf > 0`. That means we
        # need a few values outside the symbol. To guarantee that we have those
        # at all relevant scales we add padding to the rendered bitmap and the
        # resulting sdf.
        pad = GLYPH_PADDING[]

        uv_pixel = render(atlas, path, downsample, pad)
        tex_size = Vec2f(size(atlas.data) .- 1) # starts at 1

        # 0 based
        idx_left_bottom = minimum(uv_pixel)
        idx_right_top = maximum(uv_pixel)

        # transform to normalized texture coordinates
        # -1 for indexing offset
        uv_left_bottom_pad = (idx_left_bottom) ./ tex_size
        uv_right_top_pad = (idx_right_top .- 1) ./ tex_size

        uv_offset_rect = Vec4f(uv_left_bottom_pad..., uv_right_top_pad...)
        i = atlas.index
        push!(atlas.uv_rectangles, uv_offset_rect)
        atlas.index = i + 1
        return i
    end
end

"""
    sdistancefield(img, downsample, pad)
Calculates a distance fields, that is downsampled `downsample` time,
with a padding applied of `pad`.
The padding is in units after downscaling!
"""
function sdistancefield(img, downsample, pad)
    # we pad before downsampling, so we need to have `downsample` as much padding
    pad = downsample * pad
    # padd the image
    padded_size = size(img) .+ 2pad

    # for the downsampling, we need to make sure that
    # we can divide the image size by `downsample` without reminder
    dividable_size = ceil.(Int, padded_size ./ downsample) .* downsample

    in_or_out = fill(false, dividable_size)
    # the size we fill the image up to
    wend, hend = size(img) .+ pad
    in_or_out[pad+1:wend, pad+1:hend] .= img .> (0.5 * 255)

    yres, xres = dividable_size .÷ downsample
    # divide by downsample to normalize distances!
    return Float16.(sdf(in_or_out, xres, yres) ./ downsample)
end

const font_render_callbacks = Dict{Int, Vector{Function}}()

function font_render_callback!(f)
    funcs = get!(font_render_callbacks, PIXELSIZE_IN_ATLAS[], Function[])
    push!(funcs, f)
end

function remove_font_render_callback!(f)
    for (s, callbacks) in font_render_callbacks
        filter!(f2-> f2 != f, callbacks)
    end
end

function render(atlas::TextureAtlas, glyph, font, downsample=5, pad=6)
    # TODO: Is this needed or should newline be filtered before this?
    if FreeTypeAbstraction.glyph_index(font, glyph) == FreeTypeAbstraction.glyph_index(font, '\n') # don't render  newline
        glyph = ' '
    end

    # the target pixel size of our distance field
    pixelsize = PIXELSIZE_IN_ATLAS[]
    # we render the font `downsample` sizes times bigger
    # Make sure the font doesn't have a mutated font matrix from e.g. Cairo
    FreeTypeAbstraction.FreeType.FT_Set_Transform(font, C_NULL, C_NULL)
    bitmap, extent = renderface(font, glyph, pixelsize * downsample)
    # Our downsampeld & padded distancefield
    sd = sdistancefield(bitmap, downsample, pad)
    rect = Rect2(0, 0, size(sd)...)
    uv = push!(atlas.rectangle_packer, rect) # find out where to place the rectangle
    uv == nothing && error("texture atlas is too small. Resizing not implemented yet. Please file an issue at Makie if you encounter this") #TODO resize surface
    # write distancefield into texture
    atlas.data[uv.area] = sd
    for f in get(font_render_callbacks, pixelsize, ())
        # update everyone who uses the atlas image directly (e.g. in GLMakie)
        f(sd, uv.area)
    end
    # return the area we rendered into!
    return uv.area
end

function render(atlas::TextureAtlas, b::BezierPath, downsample=5, pad=6)
    # the target pixel size of our distance field
    pixelsize = PIXELSIZE_IN_ATLAS[]
    bitmap = render_path(b)
    # Our downsampeld & padded distancefield
    sd = sdistancefield(bitmap, downsample, pad)
    rect = Rect2(0, 0, size(sd)...)
    uv = push!(atlas.rectangle_packer, rect) # find out where to place the rectangle
    uv == nothing && error("texture atlas is too small. Resizing not implemented yet. Please file an issue at Makie if you encounter this") #TODO resize surface
    # write distancefield into texture
    atlas.data[uv.area] = sd
    for f in get(font_render_callbacks, pixelsize, ())
        # update everyone who uses the atlas image directly (e.g. in GLMakie)
        f(sd, uv.area)
    end
    # return the area we rendered into!
    return uv.area
end




# The marker types whos signed distancefield get looked up in the texture atlas
const TextureAtlasShape = Union{Char, BezierPath, AbstractVector{Char}, AbstractVector{BezierPath}}
# The marker types, which have a distancefield defined in the shader via a geometric function
const GeometryShape = Union{Circle, Rect2, AbstractVector{Char}, AbstractVector{BezierPath}}

@enum Shape CIRCLE RECTANGLE ROUNDED_RECTANGLE DISTANCEFIELD TRIANGLE

"""
returns the Shape type for the distancefield shader
"""
marker_to_sdf_shape(x) = error("$(x) is not a valid scatter marker shape.")

marker_to_sdf_shape(::AbstractMatrix) = RECTANGLE # Image marker
marker_to_sdf_shape(::Union{BezierPath, Char}) = DISTANCEFIELD
marker_to_sdf_shape(::Type{T}) where {T <: Circle} = CIRCLE
marker_to_sdf_shape(::Type{T}) where {T <: Rect} = RECTANGLE
marker_to_sdf_shape(x::Shape) = x

function marker_to_sdf_shape(arr::AbstractVector)
    isempty(arr) && error("Marker array can't be empty")
    shape1 = marker_to_sdf_shape(first(arr))
    for elem in arr
        shape2 = marker_to_sdf_shape(elem)
        shape1 !== shape2 && error("Can't use an array of markers that require different primitive_shapes $(typeof.(arr)).")
    end
    return shape1
end

function marker_to_sdf_shape(marker::Observable)
    return lift(marker; ignore_equal_values=true) do marker
        return Cint(marker_to_sdf_shape(to_spritemarker(marker)))
    end
end

"""
Gets the texture atlas if primitive shape needs it.
"""
function primitive_distancefield(shape)
    if Cint(shape) === Cint(DISTANCEFIELD)
        return get_texture_atlas()
    else
        return nothing
    end
end

function primitive_distancefield(marker::Observable)
    return lift(primitive_distancefield, marker; ignore_equal_values=true)
end
"""
Extracts the offset from a primitive.
"""
primitive_offset(x, scale::Nothing) = Vec2f(0) # default offset
primitive_offset(x, scale) = scale ./ -2f0  # default offset

"""
Extracts the uv offset and width from a primitive.
"""
primitive_uv_offset_width(x) = Vec4f(0,0,1,1)
primitive_uv_offset_width(b::Union{Char, BezierPath}) = glyph_uv_width!(b)
primitive_uv_offset_width(x::AbstractVector) = map(primitive_uv_offset_width, x)
function primitive_uv_offset_width(marker::Observable)
    return lift(primitive_uv_offset_width, marker; ignore_equal_values=true)
end

_bcast(x::Vec) = (x,)
_bcast(x) = x

# Calculates the scaling factor from unpadded size -> padded size
# Here we assume the glyph to be representative of Makie.PIXELSIZE_IN_ATLAS[]
# regardless of its true size.
function marker_scale_factor(char::Char, font)
    ta = Makie.get_texture_atlas()
    lbrt = glyph_uv_width!(ta, char, font)
    uv_width = Vec(lbrt[3] - lbrt[1], lbrt[4] - lbrt[2])
    full_pixel_size_in_atlas = uv_width .* Vec2f(size(ta.data) .- 1)
    return full_pixel_size_in_atlas ./ Makie.PIXELSIZE_IN_ATLAS[]
end

# full_pad / unpadded_atlas_width
function bezierpath_pad_scale_factor(bp)
    ta = Makie.get_texture_atlas()
    lbrt = glyph_uv_width!(bp)
    uv_width = Vec(lbrt[3] - lbrt[1], lbrt[4] - lbrt[2])
    full_pixel_size_in_atlas = uv_width * Vec2f(size(ta.data) .- 1)
    full_pad = 2f0 * Makie.GLYPH_PADDING[] # left + right pad
    return full_pad ./ (full_pixel_size_in_atlas .- full_pad)
end

function marker_scale_factor(path::BezierPath)
    # padded_width = (unpadded_target_width + unpadded_target_width * pad_per_unit)
    path_width = widths(Makie.bbox(path))
    return (1f0 .+ bezierpath_pad_scale_factor(path)) .* path_width
end

function rescale_marker(pathmarker::BezierPath, font, markersize)
    return markersize .* marker_scale_factor(pathmarker)
end

function rescale_marker(pathmarker::AbstractVector{T}, font, markersize) where T <: BezierPath
    return _bcast(markersize) .* marker_scale_factor.(pathmarker)
end

# Rect / Circle dont need no rescaling
rescale_marker(char, font, markersize) = markersize

function rescale_marker(char::AbstractVector{Char}, font, markersize)
    return _bcast(markersize) .* marker_scale_factor.(char, font)
end

function rescale_marker(char::Char, font, markersize)
    factor = marker_scale_factor.(char, font)
    return markersize .* factor
end

function offset_bezierpath(bp::BezierPath, markersize::Vec2, markeroffset::Vec2)
    bb = Makie.bbox(bp)
    pad_offset = (origin(bb) .- 0.5f0 .* bezierpath_pad_scale_factor(bp) .* widths(bb))
    return markersize .* pad_offset
end

function offset_bezierpath(bp, scale, offset)
    return offset_bezierpath.(bp, _bcast(scale), _bcast(offset))
end

function offset_marker(marker::Union{T, AbstractVector{T}}, font, markersize, markeroffset) where T <: BezierPath
    return offset_bezierpath(marker, markersize, markeroffset)
end

function offset_marker(marker::Union{T, AbstractVector{T}}, font, markersize, markeroffset) where T <: Char
    return rescale_marker(marker, font, markeroffset)
end

offset_marker(marker, font, markersize, markeroffset) = markeroffset

function marker_attributes(marker, markersize, font, marker_offset)
    scale = map(rescale_marker, marker, font, markersize; ignore_equal_values=true)
    quad_offset = map(offset_marker, marker, font, markersize, marker_offset; ignore_equal_values=true)

    return scale, quad_offset
end
