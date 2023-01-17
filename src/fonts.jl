# first add some monkey patches to Fontconfig
# TODO: remove the following function definition after https://github.com/JuliaGraphics/Fontconfig.jl/pull/35
# is merged.
"""
    fclist(pat::Pattern, properties::Vector{String})::Vector{Pattern}

Selects fonts matching `pat` and creates patterns from those fonts. These patterns containing only those
properties listed in `properties`, and returns a vector of unique such patterns, as a `Vector{Pattern}`.
"""
function fclist(pat::Fontconfig.Pattern, properties::Vector{String})
    os = ccall((:FcObjectSetCreate, Fontconfig.libfontconfig), Ptr{Nothing}, ())
    for property in properties
        ccall((:FcObjectSetAdd, Fontconfig.libfontconfig), Cint, (Ptr{Nothing}, Ptr{UInt8}),
              os, property)
    end

    fs_ptr = ccall((:FcFontList, Fontconfig.libfontconfig), Ptr{Fontconfig.FcFontSet},
                   (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), C_NULL, pat.ptr, os)
    fs = unsafe_load(fs_ptr)
    patterns = Fontconfig.Pattern[]

    for i in 1:fs.nfont
        push!(patterns, Fontconfig.Pattern(unsafe_load(fs.fonts, i)))
    end

    ccall((:FcObjectSetDestroy, Fontconfig.libfontconfig), Nothing, (Ptr{Nothing},), os)
    return patterns
end

# Some basic helper functions

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

# Now for the real meat - interfacing FreeTypeAbstraction and Fontconfig

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

# This performs a search using Fontconfig and loads the result
# as a Makie-compatible NamedTuple.

"""
    populate_font_family(family::String; additional_params_for_fontconfig...)

Returns a NamedTuple of styles and loaded FreeType fonts available for family names.
This returns a NamedTuple with symbolic keys and `FreeTypeAbstraction.FTFont` values.

!!! danger
    The keys will be different for each font family!  This will require normalization
    of some kind.
"""
function populate_font_family(family::String; additional_params_for_fontconfig...)
    # Create a pattern to search for
    pattern = Fontconfig.Pattern(; family = family, additional_params_for_fontconfig...)
    # Use Fontconfig to generate a list of styles from that pattern.
    font_list = fclist(pattern, ["family", "style", "file", "index"])
    # Extract the style names (regular, light, bold, oblique, etc)
    styles = extract_fc_attr_string.(font_list, "style")
    # Return a NamedTuple
    return (; (Symbol.(lowercase.(styles)) .=> ftfont_from_fc_pattern.(font_list))...)
end


# Some convenient ways to get styles

function is_bold(font::FreeTypeAbstraction.FTFont)
    return font.style_flags & 1
end

function is_italic_or_oblique(font::FreeTypeAbstraction.FTFont)
    return font.style_flags & 2
end


function search_font(family::String, style::String = "regular"; exact = false)::NativeFont
    style = lowercase(style) # for better font matching
    exact || (style = replace(style, "_" => " "))

    list = populate_font_family(family; style = style)

    if length(list) == 0 || isnothing(list)
        if exact

            @error "No font in the family `$family` was found which matches `$style` exactly - please try something else.  Consider setting `exact=false` in your call to `search_font` as well."

        elseif contains(style, "italic")

            style_without_italic = string(chomp(replace(style, "italic" => "oblique")))
            new_list = populate_font_family(family; style = style_without_italic)
            # check that an actual match has been generated.  TODO: the second clause may be redundant.
            if length(new_list) != 0 && any(contains.(lowercase.(string.(collect(keys(new_list)))), "oblique"))
                style = style_without_italic
                list = new_list
            else
                @warn "The family presents neither italic nor oblique faces, but you have requested `italic`.  Consider modifying your fontconfig file to generate these, or loosen your search parameters."
            end

        elseif isequal(style, "regular")

            style_without_regular = "book"
            new_list = populate_font_family(family; style = style_without_regular)

            if length(new_list) == 0
                style_without_regular = "roman"
                new_list = populate_font_family(family; style = style_without_regular)
            end

            # check that an actual match has been generated.  TODO: the second clause may be redundant.
            if length(new_list) != 0 && any(contains.(lowercase.(string.(collect(keys(new_list)))), style_without_regular))
                style = style_without_regular
                list = new_list
            else
                @warn "The family presents neither regular nor $style_without_regular faces, but you have asked for a `regular` face.  Consider modifying your fontconfig file to generate these, or loosen your search parameters."
            end

        # The below fails safe; to fail secure, make the warning an error.
        else
            @error "No font in the family `$family` was found which matches `$style` - please try something else."
            # populate_font_family(family, "Regular")
        end

    end

    if length(list) == 1
        return list[1]
    end

    key_font_pairs = collect(pairs(list))

    key_s = string.(first.(key_font_pairs))

    if any(isequal(style), key_s)
        return list[findfirst(isequal(style), key_s)]
    else
        return list[1]
    end

end

"""
    FontFamily(family::String; search_kwargs)

Constructs a `FontFamily` object which caches all styles of a font family,
allowing the user to modify them at will by setindex!.
"""
struct FontFamily
    family::String
    attributes::Attributes
end

function FontFamily(family::String; search_kwargs...)
    # first, populate the font family attribute list using all known fonts
    attr_list = Attributes(populate_font_family(family; search_kwargs...))

    for style in (:regular, :italic, :bold, :bold_italic)
        haskey(attr_list, style) && continue
        try
            font = search_font(family, string(style))
            attr_list[style] = font
        catch e
            @warn "Could not find a `$style` style for the font family $family, continuing."
        end
    end

    return FontFamily(family, attr_list)
end

Base.propertynames(family::FontFamily) = (:family, propertynames(family.attributes)...)

function Base.getproperty(family::FontFamily, name::Symbol)
    if name in fieldnames(FontFamily)
        return getfield(family, name)
    else
        return Base.getproperty(Base.getfield(family, :attributes), name)
    end
end

function Base.setproperty!(family::FontFamily, name::Symbol, x)
    Base.setproperty!(family.attributes, name, x)
end

Base.getindex(family::FontFamily, args...) = Base.getindex(family.attributes, args...)

Base.setindex!(family::FontFamily, args...) = Base.setindex!(family.attributes, args...)
