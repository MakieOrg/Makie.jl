struct SampleBased <: ConversionTrait end

function convert_arguments(::SampleBased, args::NTuple{N, AbstractVector{<:Number}}) where {N}
    return args
end

function convert_arguments(P::SampleBased, positions::Vararg{AbstractVector})
    return convert_arguments(P, positions)
end
