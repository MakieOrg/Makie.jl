
struct TextureAtlas
    rectangle_packer::RectanglePacker{Int32}
    # hash of what we're rendering to index in `uv_rectangles`
    mapping::Dict{UInt32, Int64}
    data::Matrix{Float16}
    # rectangles we rendered our glyphs into in normalized uv coordinates
    uv_rectangles::Vector{Vec4f}
    pix_per_glyph::Int32
    # To draw a symbol from a sdf we essentially do `color * (sdf > 0)`. For
    # antialiasing we smooth out the step function `sdf > 0`. That means we
    # need a few values outside the symbol. To guarantee that we have those
    # at all relevant scales we add padding to the rendered bitmap and the
    # resulting sdf.
    # Small padding results in artifacts during downsampling. It seems like roughly
    # 1.5px padding is required for a scaled glyph to be displayed without artifacts.
    # E.g. for fontsize = 8px we need 1.5/8 * 64 = 12px+ padding (in each direction)
    # for things to look clear with a 64px glyph size.
    glyph_padding::Int32
    # We save glyphs as signed distance fields, i.e. we save the distance
    # a pixel is away from the edge of a symbol (continuous at the edge).
    # To get accurate distances we want to draw the symbol at high
    # resolution and then downsample to the pix_per_glyph.
    downsample::Int32
    font_render_callback::Vector{Function}
end

Base.size(atlas::TextureAtlas) = size(atlas.data)
Base.size(atlas::TextureAtlas, dim) = size(atlas)[dim]

"""
    get_uv_img(atlas::TextureAtlas, glyph_bezierpath, [font])

Helper to debug texture atlas (this usually happens on the GPU)!

can be used like this:
```julia
matr = Makie.get_uv_img(atlas, glyph_index, font)
scatter(Point2f(0), distancefield=matr, uv_offset_width=Vec4f(0, 0, 1, 1), markersize=100)
```
"""
get_uv_img(atlas::TextureAtlas, glyph, font) = get_uv_img(atlas, primitive_uv_offset_width(atlas, glyph, font))
get_uv_img(atlas::TextureAtlas, path) = get_uv_img(atlas, primitive_uv_offset_width(atlas, path, nothing))
function get_uv_img(atlas::TextureAtlas, uv_rect::Vec4f)
    xmin, ymin, xmax, ymax = round.(Int, uv_rect .* Vec4f(size(atlas)..., size(atlas)...))
    return atlas.data[Rect(xmin, ymin, xmax - xmin, ymax - ymin)]
end

function TextureAtlas(; resolution=2048, pix_per_glyph=64, glyph_padding=12, downsample=5)
    return TextureAtlas(
        RectanglePacker(Rect2{Int32}(0, 0, resolution, resolution)),
        Dict{UInt32, Int}(),
        # We use the maximum distance of a glyph as a background to reduce texture bleed. See #2096
        fill(Float16(0.5pix_per_glyph + glyph_padding), resolution, resolution),
        Vec4f[],
        pix_per_glyph,
        glyph_padding,
        downsample,
        Function[]
    )
end

function Base.show(io::IO, atlas::TextureAtlas)
    println(io, "TextureAtlas:")
    println(io, "  mappings: ", length(atlas.mapping))
    println(io, "  data: ", size(atlas))
    println(io, "  pix_per_glyph: ", atlas.pix_per_glyph)
    println(io, "  glyph_padding: ", atlas.glyph_padding)
    println(io, "  downsample: ", atlas.downsample)
    println(io, "  font_render_callback: ", length(atlas.font_render_callback))
end

const SERIALIZATION_FORMAT_VERSION = "v2"

# basically a singleton for the textureatlas
function get_cache_path(resolution::Int, pix_per_glyph::Int)
    path = abspath(
        first(Base.DEPOT_PATH), "makie",
        "$(SERIALIZATION_FORMAT_VERSION)_texture_atlas_$(resolution)_$(pix_per_glyph).bin"
    )
    if !ispath(dirname(path))
        mkpath(dirname(path))
    end
    return path
end

function write_node(io::IO, packer::RectanglePacker)
    write(io, Ref(packer.area))
    write(io, UInt8(packer.filled))
    l = packer.left
    write(io, isnothing(l) ? UInt8(0) : UInt8(1))
    if !isnothing(l)
        write_node(io, l)
    end
    r = packer.right
    write(io, isnothing(r) ? UInt8(0) : UInt8(1))
    if !isnothing(r)
        write_node(io, r)
    end
end

function read_node(io, T)
    area = Ref{Rect2{T}}()
    read!(io, area)
    filled = read(io, UInt8)
    hasleft = read(io, UInt8)
    left = hasleft == 1 ? read_node(io, T) : nothing
    hasright = read(io, UInt8)
    right = hasright == 1 ? read_node(io, T) : nothing
    return RectanglePacker{T}(area[], filled, left, right)
end

function write_array(io::IO, array::AbstractArray)
    write(io, Int32(ndims(array)))
    write(io, Int32.(size(array))...)
    write(io, array)
end

function read_array(io::IO, T)
    nd = read(io, Int32)
    size = Vector{Int32}(undef, nd)
    read!(io, size)
    array = Array{T}(undef, size...)
    read!(io, array)
    return array
end

function store_texture_atlas(path::AbstractString, atlas::TextureAtlas)
    open(path, "w") do io
        write_node(io, atlas.rectangle_packer)
        write_array(io, collect(atlas.mapping))
        write_array(io, atlas.data)
        write_array(io, atlas.uv_rectangles)
        write(io, atlas.pix_per_glyph)
        write(io, atlas.glyph_padding)
        write(io, atlas.downsample)
    end
end

function load_texture_atlas(path::AbstractString)
    open(path) do io
        packer = read_node(io, Int32)
        mapping = read_array(io, Pair{UInt32, Int64})
        data = read_array(io, Float16)
        uv_rectangles = read_array(io, Vec4f)
        pix_per_glyph = read(io, Int32)
        glyph_padding = read(io, Int32)
        downsample = read(io, Int32)
        return TextureAtlas(packer, Dict(mapping), data, uv_rectangles, pix_per_glyph, glyph_padding, downsample, Function[])
    end
end

const TEXTURE_ATLASES = Dict{Tuple{Int, Int}, TextureAtlas}()

function get_texture_atlas(resolution::Int = 2048, pix_per_glyph::Int = 64)
    return get!(TEXTURE_ATLASES, (resolution, pix_per_glyph)) do
        return cached_load(resolution, pix_per_glyph) # initialize only on demand
    end
end

const CACHE_DOWNLOAD_URL = "https://github.com/MakieOrg/Makie.jl/releases/download/v0.19.0/"

function cached_load(resolution::Int, pix_per_glyph::Int)
    path = get_cache_path(resolution, pix_per_glyph)
    if !isfile(path)
        try
            url = CACHE_DOWNLOAD_URL * basename(path)
            Downloads.download(url, path)
        catch e
            @warn "downloading texture atlas failed, need to re-create from scratch." exception=(e, Base.catch_backtrace())
        end
    end
    if isfile(path)
        try
            return load_texture_atlas(path)
        catch e
            @warn "reading texture atlas on disk failed, need to re-create from scratch." exception=(e, Base.catch_backtrace())
            rm(path; force=true)
        end
    end
    atlas = TextureAtlas(; resolution=resolution, pix_per_glyph=pix_per_glyph)
    @warn("Makie is caching fonts, this may take a while. This should usually not happen, unless you're getting your own texture atlas or are without internet!")
    render_default_glyphs!(atlas)
    store_texture_atlas(path, atlas) # cache it
    return atlas
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

function render_default_glyphs!(atlas)
    font = defaultfont()
    chars = ['a':'z'..., 'A':'Z'..., '0':'9'..., '.', '-']
    fonts = to_font.(to_value.(values(Makie.minimal_default.fonts)))
    for font in fonts
        for c in chars
            insert_glyph!(atlas, c, font)
        end
    end
    for (_, path) in default_marker_map()
        insert_glyph!(atlas, path)
    end
    return atlas
end

function regenerate_texture_atlas(resolution, pix_per_glyph)
    path = get_cache_path(resolution, pix_per_glyph)
    isfile(path) && rm(path; force=true)
    atlas = TextureAtlas(; resolution=resolution, pix_per_glyph=pix_per_glyph)
    render_default_glyphs!(atlas)
    store_texture_atlas(path, atlas) # cache it
    atlas
end

function regenerate_texture_atlas()
    empty!(TEXTURE_ATLASES)
    TEXTURE_ATLASES[(1024, 32)] = regenerate_texture_atlas(1024, 32) # for WGLMakie
    TEXTURE_ATLASES[(2048, 64)] = regenerate_texture_atlas(2048, 64) # for GLMakie
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

function glyph_uv_width!(atlas::TextureAtlas, b::BezierPath)
    return atlas.uv_rectangles[glyph_index!(atlas, b)]
end

function insert_glyph!(atlas::TextureAtlas, glyph, font::NativeFont)
    glyphindex = FreeTypeAbstraction.glyph_index(font, glyph)
    hash = StableHashTraits.stable_hash((glyphindex, FreeTypeAbstraction.fontname(font)))
    return insert_glyph!(atlas, hash, (glyphindex, font))
end

function insert_glyph!(atlas::TextureAtlas, path::BezierPath)
    return insert_glyph!(atlas, StableHashTraits.stable_hash(path), path)
end


function insert_glyph!(atlas::TextureAtlas, hash::UInt32, path_or_glyp::Union{BezierPath, Tuple{UInt64, NativeFont}})
    return get!(atlas.mapping, hash) do
        uv_pixel = render(atlas, path_or_glyp)
        tex_size = Vec2f(size(atlas))
        # 0 based
        idx_left_bottom = minimum(uv_pixel)
        idx_right_top = maximum(uv_pixel)
        # transform to normalized texture coordinates
        # these should be flush with outer borders of pixels
        uv_left_bottom_pad = (idx_left_bottom .+ 0.5) ./ tex_size
        uv_right_top_pad = (idx_right_top .- 0.5) ./ tex_size
        uv_offset_rect = Vec4f(uv_left_bottom_pad..., uv_right_top_pad...)
        push!(atlas.uv_rectangles, uv_offset_rect)
        return length(atlas.uv_rectangles)
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

    # Note: This adds extra space with `ceil` and removes space with `floor`.
    # This effectively shrinks or enlarges the glyph, doing the opposite to the
    # rendered marker (as it is scaled up to the same size either way)
    dividable_size = ceil.(Int, padded_size ./ downsample) .* downsample

    in_or_out = fill(false, dividable_size)
    # the size we fill the image up to
    wend, hend = size(img) .+ pad
    in_or_out[pad+1:wend, pad+1:hend] .= img .> (0.5 * 255)

    yres, xres = dividable_size .÷ downsample
    # divide by downsample to normalize distances!
    return Float32.(sdf(in_or_out, xres, yres) ./ downsample)
end

function font_render_callback!(f, atlas::TextureAtlas)
    push!(atlas.font_render_callback, f)
end

function remove_font_render_callback!(atlas::TextureAtlas, f)
    filter!(f2-> f2 != f, atlas.font_render_callback)
end

function render(atlas::TextureAtlas, (glyph_index, font)::Tuple{UInt64, NativeFont})
    downsample = atlas.downsample
    pad = atlas.glyph_padding
    # the target pixel size of our distance field
    pixelsize = atlas.pix_per_glyph

    # TODO: Is this needed or should newline be filtered before this?
    if glyph_index == 0 # don't render  newline and others
        # TODO, render them as box and filter out newlines in GlyphCollection
        glyph_index = FreeTypeAbstraction.glyph_index(font, ' ')
    end

    # we render the font `downsample` sizes times bigger
    # Make sure the font doesn't have a mutated font matrix from e.g. Cairo
    FreeTypeAbstraction.FreeType.FT_Set_Transform(font, C_NULL, C_NULL)
    bitmap, extent = renderface(font, glyph_index, pixelsize * downsample)
    # Our downsampeld & padded distancefield
    sd = sdistancefield(bitmap, downsample, pad)
    rect = Rect2{Int32}(0, 0, size(sd)...)
    uv = push!(atlas.rectangle_packer, rect) # find out where to place the rectangle
    uv == nothing && error("texture atlas is too small. Resizing not implemented yet. Please file an issue at Makie if you encounter this") #TODO resize surface
    # write distancefield into texture
    atlas.data[uv.area] = sd
    for f in atlas.font_render_callback
        # update everyone who uses the atlas image directly (e.g. in GLMakie)
        f(sd, uv.area)
    end
    # return the area we rendered into!
    return uv.area
end

function render(atlas::TextureAtlas, b::BezierPath)
    downsample = atlas.downsample
    pad = atlas.glyph_padding
    pixelsize = atlas.pix_per_glyph

    # `sdf` may adjust the size of the source image to make it dividable by
    # downsample. To avoid this, we use a fitting size here.
    source_size = floor(Int, 256 / downsample) * downsample
    bitmap = render_path(b, source_size)

    # Our downsampeld & padded distancefield
    sd = sdistancefield(bitmap, downsample, pad)
    rect = Rect2{Int32}(0, 0, size(sd)...)
    uv = push!(atlas.rectangle_packer, rect) # find out where to place the rectangle

    uv == nothing && error("texture atlas is too small. Resizing not implemented yet. Please file an issue at Makie if you encounter this") #TODO resize surface
    # write distancefield into texture
    atlas.data[uv.area] = sd
    for f in atlas.font_render_callback
        # update everyone who uses the atlas image directly (e.g. in GLMakie)
        f(sd, uv.area)
    end
    # return the area we rendered into!
    return uv.area
end

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
Extracts the offset from a primitive.
"""
primitive_offset(x, scale::Nothing) = Vec2f(0) # default offset
primitive_offset(x, scale) = scale ./ -2f0  # default offset

"""
Extracts the uv offset and width from a primitive.
"""
primitive_uv_offset_width(atlas::TextureAtlas, x, font) = Vec4f(0,0,1,1)
primitive_uv_offset_width(atlas::TextureAtlas, b::BezierPath, font) = glyph_uv_width!(atlas, b)
primitive_uv_offset_width(atlas::TextureAtlas, b::Union{UInt64, Char}, font) = glyph_uv_width!(atlas, b, font)
primitive_uv_offset_width(atlas::TextureAtlas, x::AbstractVector, font) = map(m-> primitive_uv_offset_width(atlas, m, font), x)
function primitive_uv_offset_width(atlas::TextureAtlas, marker::Observable, font::Observable)
    return lift((m, f)-> primitive_uv_offset_width(atlas, m, f), marker, font; ignore_equal_values=true)
end

_bcast(x::Vec) = (x,)
_bcast(x) = x

# Calculates the scaling factor from unpadded size -> padded size
# Here we assume the glyph to be representative of pix_per_glyph
# regardless of its true size.
function marker_scale_factor(atlas::TextureAtlas, char::Char, font)
    lbrt = glyph_uv_width!(atlas, char, font)
    uv_width = Vec(lbrt[3] - lbrt[1], lbrt[4] - lbrt[2])
    full_pixel_size_in_atlas = uv_width .* Vec2f(size(atlas))
    return full_pixel_size_in_atlas ./ atlas.pix_per_glyph
end

# full_pad / unpadded_atlas_width
function bezierpath_pad_scale_factor(atlas::TextureAtlas, bp)
    lbrt = glyph_uv_width!(atlas, bp)
    uv_width = Vec(lbrt[3] - lbrt[1], lbrt[4] - lbrt[2])
    full_pixel_size_in_atlas = uv_width * Vec2f(size(atlas))
    # left + right pad - cutoff from pixel centering
    full_pad = 2f0 * atlas.glyph_padding - 1 
    return full_pad ./ (full_pixel_size_in_atlas .- full_pad)
end

function marker_scale_factor(atlas::TextureAtlas, path::BezierPath)
    # padded_width = (unpadded_target_width + unpadded_target_width * pad_per_unit)
    return (1f0 .+ bezierpath_pad_scale_factor(atlas, path)) .* widths(Makie.bbox(path))
end

function rescale_marker(atlas::TextureAtlas, pathmarker::BezierPath, font, markersize)
    return markersize .* marker_scale_factor(atlas, pathmarker)
end

function rescale_marker(atlas::TextureAtlas, pathmarker::AbstractVector{T}, font, markersize) where T <: BezierPath
    return _bcast(markersize) .* marker_scale_factor.(Ref(atlas), pathmarker)
end

# Rect / Circle dont need no rescaling
rescale_marker(atlas, char, font, markersize) = markersize

function rescale_marker(atlas::TextureAtlas, char::AbstractVector{Char}, font, markersize)
    return _bcast(markersize) .* marker_scale_factor.(Ref(atlas), char, font)
end

function rescale_marker(atlas::TextureAtlas, char::Char, font, markersize)
    factor = marker_scale_factor.(Ref(atlas), char, font)
    return markersize .* factor
end

function offset_bezierpath(atlas::TextureAtlas, bp::BezierPath, markersize::Vec2, markeroffset::Vec2)
    bb = bbox(bp)
    pad_offset = origin(bb) .- 0.5f0 .* bezierpath_pad_scale_factor(atlas, bp) * widths(bb)
    return markersize .* pad_offset
end

function offset_bezierpath(atlas::TextureAtlas, bp, scale, offset)
    return offset_bezierpath.(Ref(atlas), bp, _bcast(scale), _bcast(offset))
end

function offset_marker(atlas::TextureAtlas, marker::Union{T, AbstractVector{T}}, font, markersize, markeroffset) where T <: BezierPath
    return offset_bezierpath(atlas, marker, markersize, markeroffset)
end

function offset_marker(atlas::TextureAtlas, marker::Union{T, AbstractVector{T}}, font, markersize, markeroffset) where T <: Char
    return rescale_marker(atlas, marker, font, markeroffset)
end

offset_marker(atlas, marker, font, markersize, markeroffset) = markeroffset

function marker_attributes(atlas::TextureAtlas, marker, markersize, font, marker_offset)
    atlas_obs = Observable(atlas) # for map to work
    scale = map(rescale_marker, atlas_obs, marker, font, markersize; ignore_equal_values=true)
    quad_offset = map(offset_marker, atlas_obs, marker, font, markersize, marker_offset; ignore_equal_values=true)

    return scale, quad_offset
end
