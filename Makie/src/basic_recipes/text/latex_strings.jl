is_layouter_compatible(::LaTeXString, _) = false
is_layouter_compatible(::LaTeXString, ::DefaultStringLayouter) = false
is_layouter_compatible(::LaTeXString, ::LaTeXStringLayouter) = true

default_layouter(string::LaTeXString) = LaTeXStringLayouter()

function layouted_string_plotspecs(inputs, ::LaTeXStringLayouter, id)
    @info "LaTeX drawing!"
    []
end