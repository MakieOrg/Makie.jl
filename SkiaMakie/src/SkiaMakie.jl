module SkiaMakie

using Makie.ComputePipeline
using Makie, LinearAlgebra
using Colors, GeometryBasics, FileIO
using Colors: N0f8
using Skia
using Skia: SK_COLOR_TYPE_RGBA_8888, SK_ALPHA_TYPE_PREMUL,
    SK_PAINT_STYLE_FILL, SK_PAINT_STYLE_STROKE, SK_PAINT_STYLE_STROKE_AND_FILL,
    SK_STROKE_CAP_BUTT, SK_STROKE_CAP_ROUND, SK_STROKE_CAP_SQUARE,
    SK_STROKE_JOIN_MITER, SK_STROKE_JOIN_ROUND, SK_STROKE_JOIN_BEVEL,
    SK_CLIP_OP_INTERSECT, SK_CLIP_OP_DIFFERENCE,
    SK_PATH_DIRECTION_CW, SK_PATH_DIRECTION_CCW,
    SK_PATH_FILLTYPE_WINDING, SK_PATH_FILLTYPE_EVENODD,
    SK_FILTER_MODE_NEAREST, SK_FILTER_MODE_LINEAR,
    SK_MIPMAP_MODE_NONE, SK_MIPMAP_MODE_NEAREST, SK_MIPMAP_MODE_LINEAR,
    SRC_RECT_CONSTRAINT_STRICT, SRC_RECT_CONSTRAINT_FAST,
    sk_image_info_t, sk_rect_t, sk_matrix_t, sk_point_t,
    sk_sampling_options_t, sk_image_caching_hint_t, sk_text_encoding_t,
    sk_surface_t, sk_canvas_t, sk_paint_t, sk_path_t, sk_image_t,
    sk_data_t, sk_shader_t, sk_path_effect_t, sk_color_space_t,
    sk_font_t, sk_typeface_t, sk_font_mgr_t, sk_text_blob_t,
    sk_text_blob_builder_t, sk_text_blob_builder_run_buffer_t,
    SK_TEXT_ENCODING_UTF8, SK_TEXT_ENCODING_GLYPH_ID,
    sk_document_t, sk_wstream_t, sk_file_wstream_t,
    SK_FONT_HINTING_NONE, SK_FONT_EDGING_ANTIALIAS

using Makie: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using Makie: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using Makie: @info, @get_attribute, Plot, MakieScreen
using Makie: to_value, to_colormap, extrema_nan
using Makie.Observables
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
using Makie: numbers_to_colors
using Makie: Mat3f, Mat4f, Mat3d, Mat4d
using Makie: sv_getindex
using Makie: compute_colors

# re-export Makie, including deprecated names
for name in names(Makie, all = true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

include("skia-helpers.jl")
include("screen.jl")
include("display.jl")
include("plot-primitives.jl")
include("utils.jl")
include("lines.jl")
include("scatter.jl")
include("image-hmap.jl")
include("mesh.jl")
include("overrides.jl")

function __init__()
    # Register default screen config with Makie's theme system
    if !haskey(Makie.CURRENT_DEFAULT_THEME, :SkiaMakie)
        Makie.CURRENT_DEFAULT_THEME[:SkiaMakie] = Makie.Attributes(
            px_per_unit = 2.0,
            pt_per_unit = 0.75,
            antialias = :best,
            visible = true,
            start_renderloop = false,
        )
    end
    return activate!()
end

end
