# basic helper functions for Fontconfig

############################################################
#            Fontconfig <-> FreeTypeAbstraction            #
############################################################

"""
    ftfont_from_fc_pattern(pattern::Fontconfig.Pattern)::FreeTypeAbstraction.FTFont

Construct an FTFont from the provided `pattern`, assuming the `file` and `index`
properties are present in `pattern`.
"""
function ftfont_from_fc_pattern(pattern::Fontconfig.Pattern)::FreeTypeAbstraction.FTFont
    # Extract the file path and the index of the font within that file
    # from the Pattern.
    # WARNING: This assumes that they are both present!
    # Then, use them to load the freetype face.
    # Note: I hesitate to use the `extract_fc_attr` function for this,
    # because I'm not sure how it interacts with garbage collection,
    # and we don't want the pointer to randomly become invalid
    file = Fontconfig.extract_fc_attr(pattern, "file")
    index = Fontconfig.extract_fc_attr(pattern, "index")
    # Construct a FTFont, given the above information.
    return FreeTypeAbstraction.FTFont(FreeTypeAbstraction.newface(file, index))
end

############################################################
#                  Font family populator                   #
############################################################
# Be fruitful, and multiply...

"""
    font_family(family::String; additional_params_for_fontconfig...)

Returns `Attributes` which comprise all styles found for the given font family.
This uses Fontconfig to search your computer for the relevant file!

It also tries to find fonts which represent regular, bold, italic and bold_italic,
which are the default fonts which Makie tries to recognize.  If there is no font
which exactly matches one of the styles, it will try to search for a similar one,
from a heuristic; for example, alternatives to `regular` are `book`, `roman`, `sans`, etc.
"""
function font_family(family::String; additional_params_for_fontconfig...)
    # create `Attributes` which work with this
    attrs = Attributes(; populate_font_family(family; additional_params_for_fontconfig...)...)

    # make sure that regular, bold, italic, bold_italic exist!
    for key in (:regular, :bold, :italic, :bold_italic)
        if !haskey(attrs, key)
            _, found_font = Fontconfig.search_with_fallbacks(family, to_string_style(key), to_string_style(key), _known_style_fallbacks(to_string_style(key))...; additional_params_for_fontconfig...)
            !isnothing(found_font) && (attrs[key] = ftfont_from_fc_pattern(found_font))
        end
    end
    
    if isempty(attrs)
        @warn """
        Could not find family $family, using TeX Gyre Heros Makie.
        Additional parameters provided to Fontconfig were:
        $additional_params_for_fontconfig
        """
        return font_family("TeX Gyre Heros Makie")
    end

    return attrs
end


# Some convenient ways to get styles

"""
    is_bold(font::FreeTypeAbstraction.FTFont)

Checks whether the font is bold, by checking FreeType's style flags.
Returns a Boolean value.
"""
function is_bold(font::FreeTypeAbstraction.FTFont)
    return font.style_flags & 1
end

is_italic(x) = is_italic(to_font(x))

"""
    is_italic(font::FreeTypeAbstraction.FTFont)

Checks whether the font is italic (or oblique), by checking FreeType's style flags.
Returns a Boolean value.
"""
function is_italic(font::FreeTypeAbstraction.FTFont)
    return font.style_flags & 2
end

is_bold(x) = is_bold(to_font(x))
