const SERIALIZATION_FORMAT_VERSION = "v7"

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
    glyph_indices::Dict{UInt64, Int}
end

Base.size(atlas::TextureAtlas) = size(atlas.data)
Base.size(atlas::TextureAtlas, dim) = size(atlas)[dim]


function TextureAtlas(; resolution = 2048, pix_per_glyph = 64, glyph_padding = 12, downsample = 5)
    return TextureAtlas(
        RectanglePacker(Rect2{Int32}(0, 0, resolution, resolution)),
        Dict{UInt32, Int}(),
        # We use the maximum distance of a glyph as a background to reduce texture bleed. See #2096
        fill(Float16(0.5pix_per_glyph + glyph_padding), resolution, resolution),
        Vec4f[],
        pix_per_glyph,
        glyph_padding,
        downsample,
        Function[],
        Dict{UInt64, Int}()
    )
end

function Base.show(io::IO, atlas::TextureAtlas)
    println(io, "TextureAtlas:")
    println(io, "  mappings: ", length(atlas.mapping))
    println(io, "  data: ", size(atlas))
    println(io, "  pix_per_glyph: ", atlas.pix_per_glyph)
    println(io, "  glyph_padding: ", atlas.glyph_padding)
    println(io, "  downsample: ", atlas.downsample)
    return println(io, "  font_render_callback: ", length(atlas.font_render_callback))
end

# basically a singleton for the textureatlas
function get_cache_path(resolution::Int, pix_per_glyph::Int)
    path = abspath(
        get_cache_path(),
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
    return if !isnothing(r)
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
    return write(io, array)
end

function read_array(io::IO, T)
    ndims = read(io, Int32)
    size = Vector{Int32}(undef, ndims)
    read!(io, size)
    array = Array{T}(undef, size...)
    read!(io, array)
    return array
end

function store_texture_atlas(path::AbstractString, atlas::TextureAtlas)
    return open(path, "w") do io
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
    return open(path) do io
        packer = read_node(io, Int32)
        mapping = read_array(io, Pair{UInt32, Int64})
        data = read_array(io, Float16)
        uv_rectangles = read_array(io, Vec4f)
        pix_per_glyph = read(io, Int32)
        glyph_padding = read(io, Int32)
        downsample = read(io, Int32)
        return TextureAtlas(packer, Dict(mapping), data, uv_rectangles, pix_per_glyph, glyph_padding, downsample, Function[], Dict{UInt64, Int}())
    end
end

const TEXTURE_ATLASES = Dict{Tuple{Int, Int}, TextureAtlas}()

function get_texture_atlas(resolution::Int = 2048, pix_per_glyph::Int = 64)
    return get!(TEXTURE_ATLASES, (resolution, pix_per_glyph)) do
        return cached_load(resolution, pix_per_glyph) # initialize only on demand
    end
end

const CACHE_DOWNLOAD_URL = "https://github.com/MakieOrg/Makie.jl/releases/download/v0.21.0/"

function cached_load(resolution::Int, pix_per_glyph::Int)
    path = get_cache_path(resolution, pix_per_glyph)
    if !isfile(path)
        try
            url = CACHE_DOWNLOAD_URL * basename(path)
            Downloads.download(url, path)
        catch e
            @warn "downloading texture atlas failed, need to re-create from scratch." exception = (e, Base.catch_backtrace())
        end
    end
    if isfile(path)
        try
            return load_texture_atlas(path)
        catch e
            @warn "reading texture atlas on disk failed, need to re-create from scratch." exception = (e, Base.catch_backtrace())
            rm(path; force = true)
        end
    end
    atlas = TextureAtlas(; resolution = resolution, pix_per_glyph = pix_per_glyph)
    @warn("Makie is caching fonts, this may take a while. This should usually not happen, unless you're getting your own texture atlas or are without internet!")
    render_default_glyphs!(atlas)
    store_texture_atlas(path, atlas) # cache it
    return atlas
end

const DEFAULT_FONT = NativeFont[]
const ALTERNATIVE_FONTS = NativeFont[]
const FONT_LOCK = Base.ReentrantLock()

function defaultfont()
    return lock(FONT_LOCK) do
        if isempty(DEFAULT_FONT)
            push!(DEFAULT_FONT, to_font("TeX Gyre Heros Makie"))
        end
        DEFAULT_FONT[]
    end
end

function alternativefonts()
    return lock(FONT_LOCK) do
        if isempty(ALTERNATIVE_FONTS)
            alternatives = [
                "TeXGyreHerosMakie-Regular.otf",
                "DejaVuSans.ttf",
                "NotoSansCuneiform-Regular.ttf",
                "NotoSansSymbols-Regular.ttf",
                "FiraMono-Medium.ttf",
            ]
            for font in alternatives
                push!(ALTERNATIVE_FONTS, NativeFont(assetpath("fonts", font)))
            end
        end
        return ALTERNATIVE_FONTS
    end
end

function render_default_glyphs!(atlas)
    chars = ['a':'z'..., 'A':'Z'..., '0':'9'..., '.', '-', MINUS_SIGN]
    fonts = map(x -> to_font(to_value(x)), values(MAKIE_DEFAULT_THEME.fonts))
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
    isfile(path) && rm(path; force = true)
    atlas = TextureAtlas(; resolution = resolution, pix_per_glyph = pix_per_glyph)
    render_default_glyphs!(atlas)
    store_texture_atlas(path, atlas) # cache it
    return atlas
end

function regenerate_texture_atlas()
    empty!(TEXTURE_ATLASES)
    TEXTURE_ATLASES[(1024, 32)] = regenerate_texture_atlas(1024, 32) # for WGLMakie
    return TEXTURE_ATLASES[(2048, 64)] = regenerate_texture_atlas(2048, 64) # for GLMakie
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
    glyph in ('\n', '\r', '\t', UInt32(0)) && return font
    for afont in alternativefonts()
        if FreeTypeAbstraction.glyph_index(afont, glyph) != 0
            return afont
        end
    end
    error("Can't represent character $(glyph) with any fallback font nor $(font.family_name)!")
end

function glyph_index!(atlas::TextureAtlas, glyph, font::NativeFont)
    h = hash((glyph, objectid(font)))
    return get!(atlas.glyph_indices, h) do
        # if the glyph is not in the atlas, insert it
        return insert_glyph!(atlas, glyph, find_font_for_char(glyph, font))
    end
end

function glyph_index!(atlas::TextureAtlas, b::BezierPath)
    h = fast_stable_hash(b)
    return get!(atlas.glyph_indices, h) do
        # if the glyph is not in the atlas, insert it
        return insert_glyph!(atlas, b)
    end
end

function glyph_uv_width!(atlas::TextureAtlas, glyph, font::NativeFont)
    idx = glyph_index!(atlas, glyph, font)
    return atlas.uv_rectangles[idx]
end

function glyph_uv_width!(atlas::TextureAtlas, b::BezierPath)
    return atlas.uv_rectangles[glyph_index!(atlas, b)]
end

function insert_glyph!(atlas::TextureAtlas, glyph, font::NativeFont)
    glyphindex = FreeTypeAbstraction.glyph_index(font, glyph)
    hash = fast_stable_hash((glyphindex, FreeTypeAbstraction.fontname(font)))
    return insert_glyph!(atlas, hash, (glyphindex, font))
end

function insert_glyph!(atlas::TextureAtlas, path::BezierPath)
    return insert_glyph!(atlas, fast_stable_hash(path), path)
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

function sdf_uv_to_pixel(atlas::TextureAtlas, uv_width::Vec4f)
    tex_size = Vec2f(size(atlas.data)) # (width, height)
    # uv: (left, bottom, right, top)
    uv_left_bottom = Vec2f(uv_width[1], uv_width[2])
    uv_right_top = Vec2f(uv_width[3], uv_width[4])

    # reverse the normalization to get pixel coordinates
    # Note: all uvs are pixel centered, so uv * size = integer + 0.5
    # taking the floor returns the left pixel border, equivalent to 0-based indices
    # taking the ceil return the right border, equivalent to 1-based indices
    px_left_bottom = ceil.(Int, uv_left_bottom .* tex_size)
    px_right_top = ceil.(Int, uv_right_top .* tex_size)

    # create pixel ranges
    x_range = px_left_bottom[1]:px_right_top[1]
    y_range = px_left_bottom[2]:px_right_top[2]
    return x_range, y_range
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
    # pad the image
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
    in_or_out[(pad + 1):wend, (pad + 1):hend] .= img .> (0.5 * 255)

    yres, xres = dividable_size .÷ downsample
    # divide by downsample to normalize distances!
    return Float32.(sdf(in_or_out, xres, yres) ./ downsample)
end

function font_render_callback!(f, atlas::TextureAtlas)
    return push!(atlas.font_render_callback, f)
end

function remove_font_render_callback!(atlas::TextureAtlas, f)
    return filter!(f2 -> f2 != f, atlas.font_render_callback)
end

const ATLAS_FONT_CACHE = Dict{NativeFont, NativeFont}()
const FTA = FreeTypeAbstraction
const FT = FTA.FreeType

function copy_font(font::NativeFont)
    mmapped = font.mmapped
    isnothing(mmapped) && error("Font $font is not mmapped, can't copy it")
    face = Ref{FT.FT_Face}()
    err = @lock FTA.LIBRARY_LOCK FT.FT_New_Memory_Face(FTA.FREE_FONT_LIBRARY[1], mmapped, length(mmapped), Int32(0), face)
    FTA.check_error(err, "Couldn't copy font \"$(font.fontname)\"")
    return NativeFont(face[], font.use_cache, mmapped)
end

function render(atlas::TextureAtlas, (glyph_index, _font)::Tuple{UInt64, NativeFont})
    # We copy fonts for rendering to avoid issues with Cairo mutating the font matrix
    font = get(() -> copy_font(_font), ATLAS_FONT_CACHE, _font)
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
    isnothing(uv) && error("texture atlas is too small. Resizing not implemented yet. Please file an issue at Makie if you encounter this") #TODO resize surface
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
marker_to_sdf_shape(::Union{BezierPath, Char, UInt32}) = DISTANCEFIELD
marker_to_sdf_shape(::Type{T}) where {T <: Circle} = CIRCLE
marker_to_sdf_shape(::Type{T}) where {T <: Rect} = RECTANGLE
marker_to_sdf_shape(x::Shape) = x

function marker_to_sdf_shape(arr::AbstractVector)
    isempty(arr) && error("Marker array can't be empty")
    shape1 = marker_to_sdf_shape(first(arr))
    for elem in arr
        shape2 = marker_to_sdf_shape(elem)
        shape2 isa Shape && shape1 isa Shape && continue
        shape1 !== shape2 && error("Can't use an array of markers that require different primitive_shapes $(typeof.(arr)).")
    end
    return shape1
end

function marker_to_sdf_shape(marker::Observable)
    return lift(marker; ignore_equal_values = true) do marker
        return Cint(marker_to_sdf_shape(to_spritemarker(marker)))
    end
end

"""
Extracts the offset from a primitive.
"""
primitive_offset(x, scale::Nothing) = Vec2f(0) # default offset
primitive_offset(x, scale) = scale ./ -2.0f0  # default offset

"""
Extracts the uv offset and width from a primitive.
"""
primitive_uv_offset_width(atlas::TextureAtlas, x, font) = Vec4f(0, 0, 1, 1)
primitive_uv_offset_width(atlas::TextureAtlas, b::BezierPath, font) = glyph_uv_width!(atlas, b)
primitive_uv_offset_width(atlas::TextureAtlas, b::Union{UInt64, Char}, font) = glyph_uv_width!(atlas, b, font)
primitive_uv_offset_width(atlas::TextureAtlas, hash::UInt32, font) = atlas.uv_rectangles[atlas.mapping[hash]]
function primitive_uv_offset_width(atlas::TextureAtlas, x::AbstractVector, font)
    dct = Dict{eltype(x), Vec4f}()
    return map(x) do b
        get!(dct, b) do
            primitive_uv_offset_width(atlas, b, font)
        end
    end
end
function primitive_uv_offset_width(atlas::TextureAtlas, marker::Observable, font::Observable)
    return lift((m, f) -> primitive_uv_offset_width(atlas, m, f), marker, font; ignore_equal_values = true)
end

function register_sdf_computations!(attr, atlas)
    haskey(attr, :sdf_uv) && haskey(attr, :sdf_marker_shape) && return
    return register_computation!(
        attr, [:uv_offset_width, :marker, :font],
        [:sdf_marker_shape, :sdf_uv]
    ) do (uv_off, m, f), changed, last
        new_mf = changed[2] || changed[3]
        uv = new_mf ? primitive_uv_offset_width(atlas, m[], f[]) : nothing
        marker = changed[1] ? marker_to_sdf_shape(m[]) : nothing
        return (marker, uv)
    end
end

function pack_images(images_marker)
    images = map(el32convert, images_marker)
    isempty(images) && error("Can not display empty vector of images as primitive")
    sizes = map(size, images)
    if !all(x -> x == sizes[1], sizes)
        # create texture atlas
        maxdims = sum(map(Vec{2, Int}, sizes))
        rectangles = map(x -> Rect2(0, 0, x...), sizes)
        rpack = RectanglePacker(Rect2(0, 0, maxdims...))
        uv_coordinates = [push!(rpack, rect).area for rect in rectangles]
        max_xy = mapreduce(maximum, (a, b) -> max.(a, b), uv_coordinates)
        texture_atlas = fill(eltype(images[1])(RGBAf(0, 0, 0, 0)), max_xy...)
        for (area, img) in zip(uv_coordinates, images)
            mini = minimum(area)
            maxi = maximum(area)
            texture_atlas[(mini[1] + 1):maxi[1], (mini[2] + 1):maxi[2]] = img # transfer to texture atlas
        end
        uvs = map(uv_coordinates) do uv
            m = max_xy .- 1
            mini = reverse((minimum(uv)) ./ m)
            maxi = reverse((maximum(uv) .- 1) ./ m)
            return Vec4f(mini..., maxi...)
        end
        images = texture_atlas
    else
        uvs = Vec4f(0, 0, 1, 1)
    end

    return (uvs, images)
end

# For switching between ellipse method and faster circle method in shader
is_all_equal_scale(o::Observable) = is_all_equal_scale(o[])
is_all_equal_scale(::Real) = true
is_all_equal_scale(::Vector{Real}) = true
is_all_equal_scale(v::Vec2f) = v[1] == v[2] # could use ≈ too
is_all_equal_scale(vs::Vector{Vec2f}) = all(is_all_equal_scale, vs)

function compute_marker_attributes((atlas, uv_off, m, f, scale), changed, last)
    # TODO, only calculate offset if needed
    # [atlas_sym, :uv_offset_width, :marker, :font, :markersize]
    # [:sdf_marker_shape, :sdf_uv, :image]
    if m isa Matrix{<:Colorant} # single image marker
        return (Cint(RECTANGLE), Vec4f(0, 0, 1, 1), m)
    elseif m isa Vector{<:Matrix{<:Colorant}} # multiple image markers
        # TODO: Should we cache the RectanglePacker so we don't need to redo everything?
        if changed[3]
            uvs, images = pack_images(m)
            return (Cint(RECTANGLE), uvs, images)
        else
            # if marker is up to date don't update
            return (nothing, nothing, nothing)
        end
    else # Char, BezierPath, Vectors thereof or Shapes (Rect, Circle)
        if changed[3] || changed.markersize
            shape = Cint(marker_to_sdf_shape(m)) # expensive for arrays with abstract eltype?
            if shape == 0 && !is_all_equal_scale(scale)
                shape = Cint(5)
            end
        else
            shape = last.sdf_marker_shape
        end

        if (shape == Cint(DISTANCEFIELD)) && (changed[3] || changed.font)
            uv = Makie.primitive_uv_offset_width(atlas, m, f)
        elseif isnothing(last)
            uv = Vec4f(0, 0, 1, 1)
        else
            uv = nothing # Is this even worth it?
        end
        return (shape, uv, nothing)
    end
end

function all_marker_computations!(attr, markername = :marker)
    add_constant!(attr, :atlas, get_texture_atlas())
    inputs = [:atlas, :uv_offset_width, markername, :font, :markersize]
    outputs = [:sdf_marker_shape, :sdf_uv, :image]
    return register_computation!(
        compute_marker_attributes, attr, inputs, outputs
    )
end

_bcast(x::Vec) = Ref(x)
_bcast(x) = x

# Calculates the scaling factor from unpadded size -> padded size
# Here we assume the glyph to be representative of pix_per_glyph
# regardless of its true size.
function marker_scale_factor(atlas::TextureAtlas, char::Char, font)::Vec2f
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
    full_pad = 2.0f0 * atlas.glyph_padding - 1
    # size without padding
    unpadded_pixel_size = full_pixel_size_in_atlas .- full_pad
    # See offset_bezierpath
    return full_pixel_size_in_atlas ./ maximum(unpadded_pixel_size)
end

function marker_scale_factor(atlas::TextureAtlas, path::BezierPath)::Vec2f
    # See offset_bezierpath
    return bezierpath_pad_scale_factor(atlas, path) * maximum(widths(bbox(path)))
end

function rescale_marker(atlas::TextureAtlas, pathmarker::BezierPath, font, markersize)
    return markersize .* marker_scale_factor(atlas, pathmarker)
end

function rescale_marker(atlas::TextureAtlas, pathmarker::AbstractVector{T}, font, markersize) where {T <: BezierPath}
    dct = Dict{eltype(pathmarker), Vec2f}()
    msf(pathmarker) =
        get!(dct, pathmarker) do
        marker_scale_factor(atlas, pathmarker)
    end
    return _bcast(markersize) .* msf.(pathmarker)
end

# Rect / Circle dont need no rescaling
rescale_marker(atlas, char, font, markersize) = markersize

function rescale_marker(atlas::TextureAtlas, char::AbstractVector{Char}, font, markersize)
    dct = Dict{Char, Vec2f}()
    msf(char) = get!(dct, char) do
        marker_scale_factor(atlas, char, font)
    end
    return _bcast(markersize) .* msf.(char)
end

function rescale_marker(atlas::TextureAtlas, char::Char, font, markersize)
    factor = marker_scale_factor.(Ref(atlas), char, font)
    return markersize .* factor
end

function offset_bezierpath(atlas::TextureAtlas, bp::BezierPath, markersize::Vec2)::Vec2f
    # - wh = widths(bbox(bp)) is the untouched size of the given bezierpath
    # - full_pixel_size_in_atlas is the size of the signed distance field in the
    #   texture atlas. This includes glyph padding
    # - px_size is the size of signed distance field without padding
    # To correct scaling on glow, stroke and AA widths in GLMakie we need to
    # keep the aspect ratio of the aspect ratio (somewhat) correct when
    # generating the sdf. This results in direct proportionality only for the
    # longer dimension of wh and px_size. The shorter side becomes inaccurate
    # due to integer rounding issues.
    # 1. To calculate the width we can use the ratio of the proportional sides
    #   scale = maximum(wh) / maximum(px_size)
    # to scale the padded_size we need to display
    #   scale * full_pixel_size_in_atlas
    # (Part of this is moved to bezierpath_pad_scale_factor)
    # 2. To calculate the offset we can simple move to the center of the bezier
    #    path and consider that the center of the final marker. (From the center
    #    scaling should be equal in ±x and ±y direction respectively.)

    bb = bbox(bp)
    scaled_size = bezierpath_pad_scale_factor(atlas, bp) * maximum(widths(bb))
    return markersize * (origin(bb) .+ 0.5f0 * widths(bb) .- 0.5f0 .* scaled_size)
end

function offset_bezierpath(atlas::TextureAtlas, bp, scale)
    return offset_bezierpath.(Ref(atlas), bp, Vec2d.(_bcast(scale)))
end

function offset_marker(atlas::TextureAtlas, marker::Union{T, AbstractVector{T}}, font, markersize) where {T <: BezierPath}
    return offset_bezierpath(atlas, marker, markersize)
end

function offset_marker(atlas::TextureAtlas, marker::Union{T, AbstractVector{T}}, font, markersize) where {T <: Char}
    return rescale_marker(atlas, marker, font, offset_marker(markersize))
end

offset_marker(atlas, marker, font, markersize) = offset_marker(markersize)
offset_marker(markersize) = Vec2f.(_bcast(-0.5 .* markersize))

function marker_attributes(atlas::TextureAtlas, marker, markersize, font, plot_object)
    atlas_obs = Observable(atlas) # for map to work
    scale = map(rescale_marker, plot_object, atlas_obs, marker, font, markersize; ignore_equal_values = true)
    quad_offset = map(
        offset_marker, plot_object, atlas_obs, marker, font, markersize;
        ignore_equal_values = true
    )

    return scale, quad_offset
end


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

function get_glyph_sdf(atlas::TextureAtlas, glyph::Char, font::NativeFont)
    gi = FreeTypeAbstraction.glyph_index(font, glyph)
    glyph_index!(atlas, gi, font)
    hash = fast_stable_hash((gi, FreeTypeAbstraction.fontname(font)))
    return get_glyph_sdf(atlas, hash)
end

function get_glyph_sdf(atlas::TextureAtlas, hash::UInt32)
    index = atlas.mapping[hash]
    uv = atlas.uv_rectangles[index]
    # create pixel ranges
    x_range, y_range = sdf_uv_to_pixel(atlas, uv)
    # slice the data
    return atlas.data[x_range, y_range]
end

function glyph_boundingbox(::BezierPath, ::Makie.NativeFont)
    # TODO:, implement this
    # Main blocker is the JS side since this is a bit more complicated.
    return (Vec2f(0), Vec2f(0))
end

function glyph_boundingbox(gi::UInt64, font::Makie.NativeFont)
    extent = FreeTypeAbstraction.get_extent(font, gi)
    glyph_bb = FreeTypeAbstraction.boundingbox(extent)
    w, mini = widths(glyph_bb), minimum(glyph_bb)
    return (w, mini)
end


function get_marker_hash(atlas::Makie.TextureAtlas, marker::BezierPath, f::Makie.NativeFont)
    hash = Makie.fast_stable_hash(marker)
    Makie.insert_glyph!(atlas, hash, marker)
    return hash, marker, f
end

function get_marker_hash(atlas::Makie.TextureAtlas, marker::Union{UInt64, Char}, font::Makie.NativeFont)
    ff = Makie.find_font_for_char(marker, font)
    gi = FreeTypeAbstraction.glyph_index(ff, marker)
    hash = Makie.fast_stable_hash((gi, FreeTypeAbstraction.fontname(ff)))
    Makie.insert_glyph!(atlas, hash, (gi, ff))
    return hash, gi, ff
end

get_marker_hash(::Makie.TextureAtlas, f::Makie.NativeFont, x::Any) = nothing, x, f


function inner_get_glyph_data(atlas::TextureAtlas, tracker, hash::UInt32, font::NativeFont)
    if !(hash in tracker)
        push!(tracker, hash)
        uv = atlas.uv_rectangles[atlas.mapping[hash]]
        sdf = get_glyph_sdf(atlas, hash)
        return (hash, [uv, sdf, Vec2f(0), Vec2f(0)])
    end
    return (hash, nothing)
end

function inner_get_glyph_data(atlas::TextureAtlas, tracker, marker::Union{BezierPath, UInt64, Char}, font::NativeFont)
    hash, tex_marker, ffont = get_marker_hash(atlas, marker, font)
    hash === nothing && return (hash, nothing)
    if !(hash in tracker)
        push!(tracker, hash)
        uv = primitive_uv_offset_width(atlas, marker, ffont)
        sdf = get_glyph_sdf(atlas, hash)
        w, mini = glyph_boundingbox(tex_marker, ffont)
        return (hash, [uv, sdf, w, mini])
    end
    return (hash, nothing)
end

function get_glyph_data(atlas::TextureAtlas, tracker, marker::Union{BezierPath, UInt64, Char}, font::NativeFont)
    hash, data = inner_get_glyph_data(atlas, tracker, marker, font)
    data === nothing && return [hash], Dict()
    return [hash], Dict(hash => data)
end

function get_glyph_data(atlas::TextureAtlas, tracker, markers::AbstractVector, fonts)
    new_glyphs = Dict{UInt32, Any}()
    glyph_hashes = UInt32[]
    for (i, marker) in enumerate(markers)
        font = Makie.sv_getindex(fonts, i)
        hash, data = inner_get_glyph_data(atlas, tracker, marker, font)
        push!(glyph_hashes, hash)
        isnothing(data) && continue
        push!(tracker, hash)
        new_glyphs[hash] = data
    end
    return glyph_hashes, new_glyphs
end
