is_layouter_compatible(::RichText, _) = false
is_layouter_compatible(::RichText, ::RichTextStringLayouter) = true

default_layouter(::RichText) = RichTextStringLayouter()

function draw_string_with_layouter!(plot, ::RichTextStringLayouter, string, point, id)
    @info "RichText drawing!"
end