# loses dispatch to type calls, e.g.
# argument_dims(::Type{<:Scatter}, args...; kwargs...)
"""
    argument_dims(P::Type{<:Plot}, args...; attributes...)
    argument_dims(trait::ConversionTrait, args...; attributes...)

Maps arguments to spatial dimensions for dim converts. This optionally includes
the attributes defined via `argument_dim_kwargs(P)`.

The return type of this function can be `nothing` to indicate that the plot/trait
arguments are not compatible with dim converts or a `tuple` otherwise. The
elements can be `1, 2, 3` to connect the argument to the respective dim convert,
or `0` to mark it as non-dimensonal. Trailing `0`s can be omitted. Point-like
arguments can be represented by an inner tuple, range or array of integers.

For example:

```
Makie.argument_dims(::Type{<:MyPlot}, xs, ys) = (1, 2) # default
Makie.argument_dims(::Type{<:MyPlot}, f::Function, xs) = (0, 1)
Makie.argument_dims(::Type{<:MyPlot}, xs, f::Function) = (1,)

# default
function Makie.argument_dims(::Type{<:MyPlot}, ps::AbstractVector{<:Point{N}}) where {N}
    return (1:N,)
end

# default
Makie.argument_dim_kwargs(::Type{<:MyPlot2}) = (:direction,)
function Makie.argument_dims(::Type{<:MyPlot2}, xs, ys; direction)
    return direction == :y ? (1, 2) : (2, 1)
end
```

The default implementation treats the common cases of `PointBased` data, i.e.
`xs, ys` and `xs, ys, zs` vectors (or values) as well as vectors of `VecTypes`.
The latter also allows multiple vectors with matching inner dimension `VecTypes{N}`.
If included via `argument_dim_kwargs()`, `:direction` and `:orientation` are also
handled by the default path in the 2D case. For this `direction == :y` and
`orientation == :vertical` are considered neutral, not swapping dimensions.
Examples marked `# default` above mirror the default path.

Note that the `::Type{<:Plot}` methods take precedence over `::ConversionTrait`.
"""
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
        t::Tuple{Vararg{Union{VecTypes{N}, VecTypesVector{N}}}};
        direction::Symbol = :y, orientation::Symbol = :vertical
    ) where {N}

    dims = ntuple(identity, N)
    if N == 2
        dims = ifelse(direction === :y, dims, (dims[2], dims[1]))
        dims = ifelse(orientation === :vertical, dims, (dims[2], dims[1]))
    end
    return ntuple(i -> dims, length(t))
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
"""
    argument_dim_kwargs(P::Type{<:Plot})

Returns a tuple of symbols marking attributes that need to be passed to
`argument_dims(P, args; attributes...)`.

This is meant to be extended for recipes. For example:

    Makie.argument_dim_kwargs(::Type{<:MyPlot}) = (:direction,)
"""
argument_dim_kwargs(::Type{<:Plot}) = tuple()
