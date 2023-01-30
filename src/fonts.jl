# basic helper functions for Fontconfig

############################################################
#                  Fontconfig extractors                   #
############################################################

"""
extract_fc_attr_string(pat::Fontconfig.Pattern, attr::String)::String

Extracts the FontConfig attribute, whose name is given by `attr`, from a `Fontconfig.Pattern`.
Returns a String.
"""
function extract_fc_attr_string(pat::Fontconfig.Pattern, attr::String; num::Int = 0)
      local output_str = Ref(Ptr{Cchar}())
      success = @ccall Fontconfig.Fontconfig_jll.libfontconfig.FcPatternGetString(pat.ptr::Ptr{Cvoid}, attr::Cstring, num::Cint, output_str::Ptr{Ptr{Cchar}})::Cint
      if success != 0
          error("The operation did not succeed!  Fontconfig returned the error code $success when extracting the $(num)th entry of attribute $attr from pattern $pat.")
      end
      return unsafe_string(output_str[])
end

"""
extract_fc_attr_int(pat::Fontconfig.Pattern, attr::String)::Int

Extracts the FontConfig attribute, whose name is given by `attr`, from a `Fontconfig.Pattern`.
Returns a String.
"""
function extract_fc_attr_int(pat::Fontconfig.Pattern, attr::String; num::Int = 0)
  local output_int = Ref{Cint}()
  success = @ccall Fontconfig.Fontconfig_jll.libfontconfig.FcPatternGetInteger(pat.ptr::Ptr{Cvoid}, attr::Cstring, num::Cint, output_int::Ptr{Cint})::Cint
  if success != 0
      error("The operation did not succeed!  Fontconfig returned the error code $success when extracting the $(num)th entry of attribute $attr from pattern $pat.")
  end
  return output_int[]
end

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
    file = extract_fc_attr_string(pattern, "file")
    index = extract_fc_attr_int(pattern, "index")
    # Construct a FTFont, given the above information.
    return FreeTypeAbstraction.FTFont(FreeTypeAbstraction.newface(file, index))
end


############################################################
#                Fontconfig-powered search                 #
############################################################

# This performs a search using Fontconfig and loads the result
# as a Makie-compatible NamedTuple.

function _font_list_and_styles_from_fontconfig(family; additional_params_for_fontconfig...)
    pattern = Fontconfig.Pattern(; family = family, additional_params_for_fontconfig...)
    # Use Fontconfig to generate a list of styles from that pattern.
    font_list = Fontconfig.list(pattern, ["family", "style", "file", "index"])
    # Extract the style names (regular, light, bold, oblique, etc)
    styles = extract_fc_attr_string.(font_list, "style")
    return (font_list, styles)
end

"""
    populate_font_family(family::String; additional_params_for_fontconfig...)

Returns a NamedTuple of styles and loaded FreeType fonts available for family names.
This returns a NamedTuple with symbolic keys and `FreeTypeAbstraction.FTFont` values.
!!! danger
    Style keys can and do vary across font families; make sure that you normalize them!
"""
function populate_font_family(family::String; additional_params_for_fontconfig...)
    font_list, styles = _font_list_and_styles_from_fontconfig(family; additional_params_for_fontconfig...)
    # Return a NamedTuple
    return (; (Symbol.(lowercase.(styles)) .=> ftfont_from_fc_pattern.(font_list))...)
end

"""
    search_with_fallbacks(family::String, style::String, key::String, fallbacks::String...; params_for_fontconfig...)
"""
function search_with_fallbacks(family::String, style::String, key::String, fallbacks::String...; params_for_fontconfig...)
    # try the original search first
    font_list, styles = _font_list_and_styles_from_fontconfig(family; style = lowercase(style), params_for_fontconfig...)

    # return the corresponding style if found
    if length(styles) != 0
        return Symbol(styles[1]) => ftfont_from_fc_pattern(font_list[1])
    # if not, go to fallbacks
    else
        # loop through fallbacks and keep trying
        for fallback in fallbacks
            new_style = string(chomp(replace(style, key => fallback)))
            font_list, styles = _font_list_and_styles_from_fontconfig(family; style = lowercase(new_style), params_for_fontconfig...)
            if length(styles) != 0
                return Symbol(styles[1]) => ftfont_from_fc_pattern(font_list[1])
            end
        end
    end
    # we didn't find anything, so return nothing
    return (nothing, nothing)
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
            _, found_font = search_with_fallbacks(family, to_string_style(key), to_string_style(key), _known_style_fallbacks(to_string_style(key))...; additional_params_for_fontconfig...)
            !isnothing(found_font) && (attrs[key] = found_font)
        end
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

to_string_style(sym::Symbol) = replace(string(sym), "_" => " ")

# basically a lookup table for known fallbacks
function _known_style_fallbacks(s::String)
    if s == "regular"
        return ("roman", "book", "sans", "serif")
    elseif s == "italic"
        return ("oblique", "slanted")
    elseif s == "bold"
        return ("demibold", "semibold", "heavy")
    elseif s == "bold italic" || s == "bold_italic"
        return ("bold oblique", "demibold italic", "demibold oblique", "semibold italic", "semibold oblique")
    end
    return ()
end

_known_style_fallbacks(s::Symbol) = _known_style_fallbacks(string(s))