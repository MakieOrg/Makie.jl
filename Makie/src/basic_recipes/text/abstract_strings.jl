is_layouter_compatible(::AbstractString, _) = false 
is_layouter_compatible(string::AbstractString, ::DefaultStringLayouter) = true

default_layouter(::AbstractString) = DefaultStringLayouter()

function draw_string_with_layouter!(plot, ::DefaultStringLayouter, string, point, id)
    @info "Default drawing!"
end