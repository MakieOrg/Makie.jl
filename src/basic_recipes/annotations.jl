"""
    annotations(strings::Vector{String}, positions::Vector{Point})

Plots an array of texts at each position in `positions`.

!!! warning

    `annotations` is deprecated and will be removed in a future Makie version. Use `text` instead.
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
    Base.depwarn("The `annotations` recipe is deprecated and will be removed in a future Makie version. Use `text` instead.", :annotations, force = true)
    # annotations are not necessary anymore with the different text behavior
    text!(plot, plot.attributes, plot[1])
    plot
end
