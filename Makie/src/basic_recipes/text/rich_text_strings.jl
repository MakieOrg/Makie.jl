struct RichText
    type::Symbol
    children::Vector{Union{RichText, String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText, String}[children...]
        return new(type, cs, Dict(kwargs))
    end
end

is_layouter_compatible(::RichText, _) = false
is_layouter_compatible(::RichText, ::RichTextStringLayouter) = true

default_layouter(::RichText) = RichTextStringLayouter()





function draw_string_with_layouter!(plot, ::RichTextStringLayouter, id)
    @info "RichText drawing!"
end
