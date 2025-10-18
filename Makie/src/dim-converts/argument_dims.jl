# loses dispatch to type calls, e.g.
# argument_dims(::Type{<:Scatter}, args...; kwargs...)
function argument_dims(PT, args...; kwargs...)
    CT = conversion_trait(PT, args...)
    return argument_dims(CT, args...; kwargs...)
end

# Loses dispatch to specific traits, e.g.
# argument_dims(trait::PointBased, args...; kwargs...)
function argument_dims(trait::ConversionTrait, args...; kwargs...)
    return _argument_dims(args; kwargs...)
end

# Default handling

# point like data
function _argument_dims(
        ::Tuple{<:Union{VecTypes{N}, AbstractVector{<:VecTypes{N}}}};
        direction::Symbol = :y, orientation::Symbol = :vertical
    ) where {N}

    dims = ntuple(identity, N)
    if N == 2
        dims = ifelse(direction === :y, dims, (dims[2], dims[1]))
        dims = ifelse(orientation === :vertical, dims, (dims[2], dims[1]))
    end
    return (dims,)
end

# 2 or 3 values/arrays of values
function _argument_dims(args; direction::Symbol = :y, orientation::Symbol = :vertical)
    # Block any one argument case by default, e.g. VecTypes, GeometryPrimitive
    length(args) in (2, 3) || return nothing

    # disallow VecTypes
    if any(arg -> arg isa Union{VecTypes, AbstractArray{<:VecTypes}}, args)
        return nothing
    end

    dims = ntuple(identity, length(args))
    if length(args) == 2
        dims = ifelse(direction === :y, dims, (dims[2], dims[1]))
        dims = ifelse(orientation === :vertical, dims, (dims[2], dims[1]))
    end
    return dims
end


argument_dims(::ImageLike, x, y, z) = (1, 2)
argument_dims(::VertexGrid, x, y, z) = (1, 2) # contour, contourf
argument_dims(::CellGrid, x, y, z) = (1, 2)
argument_dims(::VolumeLike, x, y, z, volume) = (1, 2, 3)

argument_dims(::Type{<:Mesh}, ps::VecTypesVector{N}, faces) where {N} = (1:N,)
argument_dims(::Type{<:Mesh}, x, y, z, faces) = (1, 2, 3)
argument_dims(::Type{<:Surface}, x, y, z) = (1, 2, 3) # not like contour

# attributes that are needed to map args to dims, e.g. direction/orientation
# TODO: This is completely unrelated to args, right?
argument_dim_kwargs(::Type{<:Plot}) = tuple()
