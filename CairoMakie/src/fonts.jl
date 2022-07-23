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

"""
Finds a font that can represent the unicode character!
Returns Makie.defaultfont() if not representable!
"""
function best_font(c::Char, font = Makie.defaultfont())
    if Makie.FreeType.FT_Get_Char_Index(font, c) == 0
        for afont in Makie.alternativefonts()
            if Makie.FreeType.FT_Get_Char_Index(afont, c) != 0
                return afont
            end
        end
        return Makie.defaultfont()
    end
    return font
end
