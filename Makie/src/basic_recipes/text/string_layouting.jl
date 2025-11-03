
struct DefaultStringLayouter end

struct RichTextStringLayouter end

struct LaTeXStringLayouter end


# function plot!(t::Text)
#     # for every string in t.attributes.input_texts
#     # resolve the layouter from
#     # - default theme
#     # - default for string type
#     # - explicitly set as an attribute
#     # use the layouter to dispatch the string and attribute graph
#     # to something like register_string_layout!(attr, layouter, string)
#     # in which we then are able to plot everything that we like,
#     # usually something that includes a new atomic glyph_collection
# end