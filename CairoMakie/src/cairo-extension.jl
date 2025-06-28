# TODO, move those to Cairo?

function set_font_matrix(ctx, matrix)
    return ccall((:cairo_set_font_matrix, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, Ref(matrix))
end

function get_font_matrix(ctx)
    matrix = Ref(Cairo.CairoMatrix())
    ccall((:cairo_get_font_matrix, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, matrix)
    return matrix[]
end

function pattern_set_matrix(ctx, matrix)
    return ccall((:cairo_pattern_set_matrix, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, Ref(matrix))
end

function pattern_get_matrix(ctx)
    matrix = Ref(Cairo.CairoMatrix())
    ccall((:cairo_pattern_get_matrix, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, matrix)
    return matrix[]
end

function cairo_font_face_destroy(font_face)
    return ccall(
        (:cairo_font_face_destroy, Cairo.libcairo),
        Cvoid, (Ptr{Cvoid},),
        font_face
    )
end

function cairo_transform(ctx, cairo_matrix)
    return ccall(
        (:cairo_transform, Cairo.libcairo),
        Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}),
        ctx.ptr, Ref(cairo_matrix)
    )
end

function set_ft_font(ctx, font)

    font_face = Base.@lock font.lock ccall(
        (:cairo_ft_font_face_create_for_ft_face, Cairo.libcairo),
        Ptr{Cvoid}, (Makie.FreeTypeAbstraction.FT_Face, Cint),
        font, 0
    )
    ccall((:cairo_set_font_face, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, font_face)

    return font_face
end

struct CairoGlyph
    index::Culong
    x::Cdouble
    y::Cdouble
end

function show_glyph(ctx, glyph, x, y)
    cg = Ref(CairoGlyph(glyph, x, y))
    return ccall(
        (:cairo_show_glyphs, Cairo.libcairo),
        Nothing, (Ptr{Nothing}, Ptr{CairoGlyph}, Cint),
        ctx.ptr, cg, 1
    )
end

function glyph_path(ctx, glyph, x, y)
    cg = Ref(CairoGlyph(glyph, x, y))
    return ccall(
        (:cairo_glyph_path, Cairo.libcairo),
        Nothing, (Ptr{Nothing}, Ptr{CairoGlyph}, Cint),
        ctx.ptr, cg, 1
    )
end

function surface_get_device_scale(surf)
    x = Ref(0.0)
    y = Ref(0.0)
    ccall(
        (:cairo_surface_get_device_scale, Cairo.libcairo),
        Cvoid, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}),
        surf.ptr, x, y
    )
    return x[], y[]
end

function surface_set_device_scale(surf, device_x_scale, device_y_scale = device_x_scale)
    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution

    # This call becomes increasingly expensive for some reason
    old_x_scale, old_y_scale = surface_get_device_scale(surf)
    if old_x_scale != device_x_scale || old_y_scale != device_y_scale
        ccall(
            (:cairo_surface_set_device_scale, Cairo.libcairo),
            Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
            surf.ptr, device_x_scale, device_y_scale
        )
    end
    return
end

function set_miter_limit(ctx, limit)
    return ccall((:cairo_set_miter_limit, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble), ctx.ptr, limit)
end

function get_render_type(surface::Cairo.CairoSurface)
    @assert surface.ptr != C_NULL
    typ = ccall((:cairo_surface_get_type, Cairo.libcairo), Cint, (Ptr{Nothing},), surface.ptr)
    typ == Cairo.CAIRO_SURFACE_TYPE_PDF && return PDF
    typ == Cairo.CAIRO_SURFACE_TYPE_PS && return EPS
    typ == Cairo.CAIRO_SURFACE_TYPE_SVG && return SVG
    typ == Cairo.CAIRO_SURFACE_TYPE_IMAGE && return IMAGE
    return IMAGE # By default assume that the render type is IMAGE
end

function restrict_pdf_version!(surface::Cairo.CairoSurface, v::Integer)
    @assert surface.ptr != C_NULL
    0 ≤ v ≤ 3 || throw(ArgumentError("version must be 0, 1, 2, or 3 (received $v)"))
    return ccall(
        (:cairo_pdf_surface_restrict_to_version, Cairo.libcairo), Nothing,
        (Ptr{UInt8}, Int32), surface.ptr, v
    )
end
