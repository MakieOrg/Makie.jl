# loses dispatch to type calls, e.g.
# argument_dims(::Type{<:Scatter}, args...; kwargs...)
function argument_dims(PT, args...; kwargs...)
    CT = conversion_trait(PT, args...)
    return argument_dims(CT, args...; kwargs...)
end

# Loses dispatch to specific traits, e.g.
# argument_dims(trait::PointBased, args...; kwargs...)
function argument_dims(trait::ConversionTrait, args...; kwargs...)
    return _argument_dims(args...; kwargs...)
end

# Default handling
function _argument_dims(arg1, args...; direction::Symbol = :y, orientation::Symbol = :vertrical)
    dims = ntuple(identity, 1 + length(args))
    dims = ifelse(direction === :y, dims, (dims[2], dims[1]))
    dims = ifelse(orientation === :vertical, dims, (dims[2], dims[1]))
    return dims
end

# Block any one argument case by default, e.g. VecTypes, GeometryPrimitive
_argument_dims(::Any; kwargs...) = nothing

# attributes that are needed to map args to dims, e.g. direction/orientation
# TODO: This is completely unrelated to args, right?
argument_dim_kwargs(::Type{<:Plot}) = tuple()
