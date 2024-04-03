"""
    annotations(strings::Vector{String}, positions::Vector{Point})

Plots an array of texts at each position in `positions`.
"""
@recipe Annotations (text, position) begin
    MakieCore.documented_attributes(Text)...
end

function convert_arguments(::Type{<: Annotations},
                           strings::AbstractVector{<: AbstractString},
                           text_positions::AbstractVector{<: Point{N, T}}) where {N, T}
    return (map(strings, text_positions) do str, pos
        (String(str), Point{N, float_type(T)}(pos))
    end,)
end

function plot!(plot::Annotations)
    # annotations are not necessary anymore with the different text behavior
    text!(plot, plot[1]; plot.attributes...)
    plot
end
