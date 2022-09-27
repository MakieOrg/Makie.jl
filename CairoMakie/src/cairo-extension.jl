# TODO, move those to Cairo?

function set_font_matrix(ctx, matrix)
    ccall((:cairo_set_font_matrix, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, Ref(matrix))
end

function get_font_matrix(ctx)
    matrix = Cairo.CairoMatrix()
    ccall((:cairo_get_font_matrix, Cairo.libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), ctx.ptr, Ref(matrix))
    return matrix
end

function cairo_font_face_destroy(font_face)
    ccall(
        (:cairo_font_face_destroy, Cairo.libcairo),
        Cvoid, (Ptr{Cvoid},),
        font_face
    )
end

function set_ft_font(ctx, font)

    font_face = ccall(
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
    ccall((:cairo_show_glyphs, Cairo.libcairo),
            Nothing, (Ptr{Nothing}, Ptr{CairoGlyph}, Cint),
            ctx.ptr, cg, 1)
end

function glyph_path(ctx, glyph::Culong, x, y)
    cg = Ref(CairoGlyph(glyph, x, y))
    ccall((:cairo_glyph_path, Cairo.libcairo),
            Nothing, (Ptr{Nothing}, Ptr{CairoGlyph}, Cint),
            ctx.ptr, cg, 1)
end

function surface_set_device_scale(surf, device_x_scale, device_y_scale=device_x_scale)
    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution
    ccall(
        (:cairo_surface_set_device_scale, Cairo.libcairo),
        Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, device_x_scale, device_y_scale)
end

function set_miter_limit(ctx, limit)
    ccall((:cairo_set_miter_limit, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble), ctx.ptr, limit)
end

function get_render_type(surface::Cairo.CairoSurface)
    typ = ccall((:cairo_surface_get_type, Cairo.libcairo), Cint, (Ptr{Nothing},), surface.ptr)
    typ == Cairo.CAIRO_SURFACE_TYPE_PDF && return PDF
    typ == Cairo.CAIRO_SURFACE_TYPE_PS && return EPS
    typ == Cairo.CAIRO_SURFACE_TYPE_SVG && return SVG
    typ == Cairo.CAIRO_SURFACE_TYPE_IMAGE && return IMAGE
    error("Unsupported surface type: $(typ)")
end
