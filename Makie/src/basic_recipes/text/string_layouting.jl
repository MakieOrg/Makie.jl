struct DefaultStringLayouter end
struct RichTextStringLayouter end
struct LaTeXStringLayouter end

struct LayoutedString
    string
    layouter
end

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
    draw_string_with_layouter!(plot, layouter, string, position, id)

draws the string into the plot using the layouting algorithm specified by layouter.
Receives the `id`, which is the index into the positions/text array of the current iteration.
"""
function draw_string_with_layouter! end

# draw_string_with_layouter!(plot, layouter, string::LayoutedString, position, id) =
#     draw_string_with_layouter!(plot, layouter, string.string, position, id)