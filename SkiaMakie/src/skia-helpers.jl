################################################################################
#                    Julia-friendly wrappers around Skia.jl                   #
################################################################################

# We wrap the low-level Skia C API in slightly more ergonomic Julia functions.
# All Skia objects are opaque Ptr types — we manage their lifetime manually.

"""
Convert an RGBA colorant to Skia's packed UInt32 ARGB format (0xAARRGGBB).
"""
function to_skia_color(c::Colorant)
    rgba = RGBA(c)
    a = round(UInt32, clamp(alpha(rgba), 0, 1) * 255)
    r = round(UInt32, clamp(red(rgba), 0, 1) * 255)
    g = round(UInt32, clamp(green(rgba), 0, 1) * 255)
    b = round(UInt32, clamp(blue(rgba), 0, 1) * 255)
    return (a << 24) | (r << 16) | (g << 8) | b
end

to_skia_color(r, g, b, a) = to_skia_color(RGBAf(r, g, b, a))

################################################################################
#                         Font / typeface cache                                #
################################################################################

# Cache: FreeType FTFont → (Skia typeface ptr, font manager ptr)
const _TYPEFACE_CACHE = Dict{UInt, Ptr{Skia.sk_typeface_t}}()
const _FONTMGR = Ref{Ptr{Skia.sk_font_mgr_t}}(Ptr{Skia.sk_font_mgr_t}(C_NULL))

function _get_fontmgr()
    if _FONTMGR[] == C_NULL
        _FONTMGR[] = sk_fontmgr_ref_default()
    end
    return _FONTMGR[]
end

"""
Get or create a Skia typeface from a FreeType font.
Caches by the objectid of the FTFont to avoid re-creating typefaces.
"""
function get_skia_typeface(ft_font::Makie.FreeTypeAbstraction.FTFont)
    key = objectid(ft_font)
    return get!(_TYPEFACE_CACHE, key) do
        font_data = ft_font.mmapped
        sk_data = sk_data_new_with_copy(pointer(font_data), Csize_t(length(font_data)))
        typeface = sk_fontmgr_create_from_data(_get_fontmgr(), sk_data, Int32(0))
        typeface == C_NULL && error("Failed to create Skia typeface from font data")
        return typeface
    end
end

"""
Create a Skia font object at the given size from a FreeType font.
The caller is responsible for the lifetime (no auto-cleanup).
"""
function make_skia_font(ft_font::Makie.FreeTypeAbstraction.FTFont, size::Real)
    typeface = get_skia_typeface(ft_font)
    font = sk_font_new_with_values(typeface, Float32(size), 1.0f0, 0.0f0)
    # Disable hinting — we render at size=1 and scale via canvas transform,
    # so hinting at the nominal size would distort glyph outlines.
    sk_font_set_hinting(font, SK_FONT_HINTING_NONE)
    sk_font_set_subpixel(font, true)
    return font
end

"""
Build a text blob from glyph IDs and per-glyph positions using Skia's text blob builder.
`glyph_ids` is a Vector{UInt16}, `positions` is a Vector of (x::Float32, y::Float32) tuples
packed as a flat Float32 vector [x1,y1, x2,y2, ...].
"""
function make_positioned_glyph_blob(sk_font, glyph_ids::Vector{UInt16}, pos_flat::Vector{Float32})
    n = length(glyph_ids)
    n == 0 && return Ptr{Skia.sk_text_blob_t}(C_NULL)
    builder = sk_textblob_builder_new()
    run_buf_ptr = sk_textblob_builder_alloc_run_pos(builder, sk_font, Int32(n), C_NULL)
    run_buf = unsafe_load(run_buf_ptr)
    unsafe_copyto!(run_buf.glyphs, pointer(glyph_ids), n)
    unsafe_copyto!(run_buf.pos, pointer(pos_flat), 2 * n)
    blob = sk_textblob_builder_make(builder)
    sk_textblob_builder_delete(builder)
    return blob
end

################################################################################
#                         PDF document helpers                                 #
################################################################################

"""
Create a PDF document writing to `path`, returning (document_ptr, canvas_ptr, file_wstream_ptr).
The canvas is valid until `finish_pdf_document` is called.
`w` and `h` are in points (1/72 inch).
"""
function make_pdf_document(path::String, w::Real, h::Real)
    fileWstream = sk_file_wstream_new(path)
    stream = sk_file_wstream_as_wstream(fileWstream)
    dt = Skia.sk_date_time_t(Int16(0), UInt16(2026), UInt8(1), UInt8(0), UInt8(1), UInt8(0), UInt8(0), UInt8(0))
    metadata = Ref(Skia.sk_metadata_t(
        pointer(""), pointer(""), pointer(""),
        pointer(""), pointer("SkiaMakie"), pointer("Skia.jl"),
        dt, dt, 72.0f0, 0.0f0, Int32(1)
    ))
    document = sk_document_make_pdf(stream, metadata)
    document == C_NULL && error("Failed to create Skia PDF document")
    canvas = sk_document_begin_page(document, Float32(w), Float32(h))
    return document, canvas, fileWstream
end

"""
Finish and close a PDF document created with `make_pdf_document`.
"""
function finish_pdf_document(document, fileWstream)
    sk_document_end_page(document)
    sk_document_close(document)
    sk_file_wstream_flush(fileWstream)
    sk_file_wstream_delete(fileWstream)
    return
end

"""
Render a Makie scene to a PDF file using SkiaMakie.
This is a convenience function that creates a temporary Screen{PDF}.
"""
function save_scene_to_pdf(scene::Scene, path::String; pt_per_unit=0.75)
    w, h = Makie.size(scene)
    pw, ph = w * pt_per_unit, h * pt_per_unit
    document, canvas, fileWstream = make_pdf_document(path, pw, ph)

    # Build a Screen with the PDF canvas
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}())
    dsf = pt_per_unit
    screen = Screen{PDF}(scene, Ptr{Skia.sk_surface_t}(C_NULL), canvas, round(Int, pw), round(Int, ph), dsf, false, config)

    # Apply device scaling so Makie scene coords map to PDF points
    sk_canvas_scale(canvas, Float32(dsf), Float32(dsf))

    skia_draw(screen, scene)

    finish_pdf_document(document, fileWstream)
    return path
end

"""
Create a raster (CPU) surface of given dimensions, returning (surface_ptr, canvas_ptr, pixel_buffer).
The pixel buffer is a Julia-owned Matrix{UInt32} in premultiplied ARGB format.
"""
function make_raster_surface(w::Integer, h::Integer)
    colorspace = sk_colorspace_new_srgb()
    info = Ref(sk_image_info_t(
        colorspace,
        SK_COLOR_TYPE_RGBA_8888,
        SK_ALPHA_TYPE_PREMUL,
        Int32(w),
        Int32(h),
    ))
    surface = sk_surface_make_raster_n32_premul(info, C_NULL)
    if surface == C_NULL
        error("Failed to create Skia raster surface of size $w × $h")
    end
    canvas = sk_surface_get_canvas(surface)
    return surface, canvas
end

"""
Save a Skia surface snapshot to a PNG file. Returns nothing.
Since there is no GPU context for raster surfaces, we read pixels and encode directly.
"""
function save_surface_to_png(surface, path::String)
    snapshot = sk_surface_make_image_snapshot(surface)
    # For raster surfaces, pass C_NULL as the graphics context
    pngdata = sk_encode_png(C_NULL, snapshot, Int32(0))
    sk_write_data_to_file(path, pngdata)
    return
end

"""
Read pixels from a Skia surface into a Julia Matrix{UInt32} (RGBA8888, premultiplied).
Returns a (w, h) matrix where each element is a packed ARGB pixel.
"""
function read_surface_pixels(surface, w::Integer, h::Integer)
    snapshot = sk_surface_make_image_snapshot(surface)
    colorspace = sk_colorspace_new_srgb()
    info = Ref(sk_image_info_t(
        colorspace,
        SK_COLOR_TYPE_RGBA_8888,
        SK_ALPHA_TYPE_PREMUL,
        Int32(w),
        Int32(h),
    ))
    pixels = Matrix{UInt32}(undef, w, h)
    rowBytes = Csize_t(w * 4)
    sk_image_read_pixels(snapshot, info, pixels, rowBytes, Cint(0), Cint(0),
        sk_image_caching_hint_t(0))
    return pixels
end

"""
Create a new Skia paint object with common defaults.
"""
function new_paint(; antialias=true, style=SK_PAINT_STYLE_FILL, color::UInt32=0xFF000000)
    paint = sk_paint_new()
    sk_paint_set_antialias(paint, antialias)
    sk_paint_set_style(paint, style)
    sk_paint_set_color(paint, color)
    return paint
end

"""
Set paint color from a Julia Colorant.
"""
function set_paint_color!(paint, c::Colorant)
    sk_paint_set_color(paint, to_skia_color(c))
    return paint
end

"""
Create a Skia path from a series of Point2 vertices (closed polygon).
"""
function points_to_path(points::AbstractVector{<:VecTypes{2}})
    path = sk_path_new()
    isempty(points) && return path
    sk_path_move_to(path, Float32(points[1][1]), Float32(points[1][2]))
    for i in 2:length(points)
        sk_path_line_to(path, Float32(points[i][1]), Float32(points[i][2]))
    end
    sk_path_close(path)
    return path
end

"""
Create an open Skia path from a series of Point2 vertices (not closed).
"""
function points_to_open_path(points::AbstractVector{<:VecTypes{2}})
    path = sk_path_new()
    isempty(points) && return path
    sk_path_move_to(path, Float32(points[1][1]), Float32(points[1][2]))
    for i in 2:length(points)
        sk_path_line_to(path, Float32(points[i][1]), Float32(points[i][2]))
    end
    return path
end

# Skia linecap mapping
function to_skia_linecap(linecap_symb::Symbol)
    linecap = Makie.convert_attribute(linecap_symb, key"linecap"())
    return to_skia_linecap(linecap)
end
function to_skia_linecap(linecap::Integer)
    linecap == 0 && return SK_STROKE_CAP_BUTT
    linecap == 1 && return SK_STROKE_CAP_SQUARE
    linecap == 2 && return SK_STROKE_CAP_ROUND
    error("Invalid linecap value: $linecap")
end

# Skia joinstyle mapping
function to_skia_joinstyle(joinstyle_symb::Symbol)
    joinstyle = Makie.convert_attribute(joinstyle_symb, key"joinstyle"())
    return to_skia_joinstyle(joinstyle)
end
function to_skia_joinstyle(joinstyle::Integer)
    joinstyle == 0 && return SK_STROKE_JOIN_MITER
    joinstyle == 2 && return SK_STROKE_JOIN_ROUND
    joinstyle == 3 && return SK_STROKE_JOIN_BEVEL
    error("Invalid joinstyle value: $joinstyle")
end

"""
Convert Makie's cumulative linestyle array to Skia's dash intervals.
Returns a `sk_path_effect_t` pointer, or C_NULL if no dash.
"""
function to_skia_dash_effect(linestyle, linewidth)
    isnothing(linestyle) && return C_NULL
    linestyle isa AbstractVector || return C_NULL
    linewidth isa AbstractArray && return C_NULL  # per-point linewidth: no global dash
    pattern = diff(Float64.(linestyle)) .* linewidth
    isodd(length(pattern)) && push!(pattern, 0.0)
    intervals = Float32.(pattern)
    return sk_path_effect_create_dash(intervals, Int32(length(intervals)), 0.0f0)
end

"""
Apply a 2D affine transform to the Skia canvas via sk_matrix_t.
The matrix is column-major:
    | scaleX  skewX  transX |
    | skewY   scaleY transY |
    | persp0  persp1 persp2 |
"""
function set_canvas_matrix!(canvas, m::sk_matrix_t)
    sk_canvas_set_matrix(canvas, Ref(m))
    return
end

function concat_canvas_matrix!(canvas, m::sk_matrix_t)
    sk_canvas_concat(canvas, Ref(m))
    return
end

function sk_matrix_identity()
    return sk_matrix_t(
        1.0f0, 0.0f0, 0.0f0,
        0.0f0, 1.0f0, 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    )
end

function sk_matrix_translate(tx, ty)
    return sk_matrix_t(
        1.0f0, 0.0f0, Float32(tx),
        0.0f0, 1.0f0, Float32(ty),
        0.0f0, 0.0f0, 1.0f0,
    )
end

function sk_matrix_scale(sx, sy)
    return sk_matrix_t(
        Float32(sx), 0.0f0, 0.0f0,
        0.0f0, Float32(sy), 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    )
end

function sk_matrix_from_2x3(m::Mat{2, 3, Float32})
    # m is stored column-major as [m11 m21 m12 m22 m13 m23]
    # Map to Skia's row-major:
    # | m[1,1]  m[1,2]  m[1,3] |
    # | m[2,1]  m[2,2]  m[2,3] |
    # |   0       0       1    |
    return sk_matrix_t(
        m[1,1], m[1,2], m[1,3],
        m[2,1], m[2,2], m[2,3],
        0.0f0, 0.0f0, 1.0f0,
    )
end

"""
Create a Skia image from a Julia color matrix (for heatmaps/images).
Returns a (sk_image_t pointer, pixel data reference to prevent GC).
"""
function colormatrix_to_skia_image(img::AbstractMatrix{<:Colorant})
    # img has size (nx, ny) where nx = x-cells, ny = y-cells (Makie convention)
    nx, ny = size(img)
    # Skia image: width=nx pixels per row, height=ny rows
    # Pixel data must be row-major (row 0 first, then row 1, etc.)
    # Julia is column-major, so we store as (nx, ny) and pass row-by-row
    # since Julia's memory layout for Matrix{UInt32}(undef, nx, ny) is
    # column-major: pixels[1,1], pixels[2,1], ..., pixels[nx,1], pixels[1,2], ...
    # That IS row-major when width=nx: row 0 = pixels[:,1], row 1 = pixels[:,2], etc.
    pixels = Matrix{UInt32}(undef, nx, ny)
    for j in 1:ny, i in 1:nx
        c = img[i, j]
        rgba = RGBA(c)
        a = clamp(alpha(rgba), 0, 1)
        r = clamp(red(rgba), 0, 1) * a  # premultiply
        g = clamp(green(rgba), 0, 1) * a
        b = clamp(blue(rgba), 0, 1) * a
        # SK_COLOR_TYPE_RGBA_8888: bytes R,G,B,A in memory order
        # On little-endian as UInt32: 0xAABBGGRR
        pixels[i, j] = (round(UInt32, a * 255) << 24) |
                        (round(UInt32, b * 255) << 16) |
                        (round(UInt32, g * 255) << 8) |
                        round(UInt32, r * 255)
    end
    colorspace = sk_colorspace_new_srgb()
    info = Ref(sk_image_info_t(
        colorspace,
        SK_COLOR_TYPE_RGBA_8888,
        SK_ALPHA_TYPE_PREMUL,
        Int32(nx),
        Int32(ny),
    ))
    rowbytes = Csize_t(nx * 4)
    data = sk_data_new_with_copy(pointer(pixels), Csize_t(nx * ny * 4))
    image = sk_image_new_raster_data(info, data, rowbytes)
    return image, pixels  # return pixels to prevent GC
end
