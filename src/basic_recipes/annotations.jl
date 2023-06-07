"""
    annotations(strings::Vector{String}, positions::Vector{Point})

Plots an array of texts at each position in `positions`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Annotations, text, position) do scene
    default_theme(scene, Text)
end

function Makie.convert_arguments(::Type{<: Annotations},
                           strings::AbstractVector{<: AbstractString},
                           text_positions::AbstractVector{<: Point})
    return (map(strings, text_positions) do str, pos
        (String(str), pos)
    end,)
end

function Makie.plot!(plot::Annotations)
    # annotations are not necessary anymore with the different text behavior
    text!(plot, plot[1]; plot.attributes...)
    plot
end
