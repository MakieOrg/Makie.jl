struct SampleBased <: ConversionTrait end

function Makie.argument_docs(::SampleBased)
    return [
        "`ys`: An `AbstractVector{<:Real}` defining samples.",
        "`xs`: An `AbstractVector{<:Real}` defining the x positions and grouping of `ys`. This can typically be reinterpreted as y positions by adjusting the `orientation` or `direction` attribute. (x, y) pairs with the same x value are considered part of the same group, category or sample.",
    ]
end

function convert_arguments(::SampleBased, args::NTuple{N, AbstractVector{<:Number}}) where {N}
    return args
end

function convert_arguments(P::SampleBased, positions::Vararg{AbstractVector})
    return convert_arguments(P, positions)
end
