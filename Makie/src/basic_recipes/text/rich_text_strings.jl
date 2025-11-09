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





function layouted_string_plotspecs(inputs, ::RichTextStringLayouter, id)
    # to make precompilation pass for now.
    [PlotSpec(:Scatter, rand(100), rand(100))]
end
