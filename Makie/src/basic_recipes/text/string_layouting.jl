struct DefaultStringLayouter end
struct RichTextStringLayouter end
struct LaTeXStringLayouter end

struct LayoutedString
    string
    layouter
end

unwrap_string(s::LayoutedString) = s.string
unwrap_string(s) = s

"""
    default_layouter(string)

returns the default layouter for the given string type.
"""
function default_layouter end
default_layouter(string::LayoutedString) = string.layouter

"""
    is_layouter_compatible(string, layouter)

checks if a layouter is compatible with a given string type.
(To be extended.)
"""
function is_layouter_compatible end
is_layouter_compatible(string::LayoutedString, _) = false

"""
    resolve_string_layouter(string, given_layouter)

takes an input string and the layouter given by the theme and inputs,
and returns a layouter that is appropriate for the given string.
(Should the given layouter not be compatible with the string type, 
return the default layouter for that type.)
"""
function resolve_string_layouter(string, given_layouter)
    if is_layouter_compatible(string, given_layouter)
        given_layouter
    else
        default_layouter(string)
    end
end

"""
    draw_string_with_layouter!(plot, layouter, id)

draws the string at index `id` into the plot using the layouting algorithm specified by layouter.
"""
function draw_string_with_layouter! end