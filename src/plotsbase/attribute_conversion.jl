convert_attribute(x::AbstractArray{<: AbstractFloat}, ::Val{:image}) = Gray.(x)
convert_attribute(x::AbstractArray{<: Colorant}, ::Val{:image}) = x



"""
    to_positions(b, positionlike)
`NTuple{2, AbstractArray{Float}}` for 2D points
"""
function to_positions(b, x::Tuple{<: AbstractArray, <: AbstractArray})
    to_position.(b, x...)
end

"""
`NTuple{3, AbstractArray{Float}}` for 3D points
"""
function to_positions(b, x::Tuple{<: AbstractArray, <: AbstractArray, <: AbstractArray})
    Point{3, Float32}.(x...)
end

"""
`view(AbstractArray{Point}, idx)` for a subset of points. Can be shared (so you can plot subsets of the same data)!
"""
function to_positions(b, x::SubArray)
    view(to_positions(b, x.parent), x.indexes...)
end

"""
`AbstractArray{T}` where T needs to have `length` defined and must be convertible to a Point
"""
function to_positions(b, x::AbstractArray{NTuple{N, T}}) where {N, T}
    Point{N, Float32}.(x)
end
function attribute_convert(x::AbstractArray{T}, ::Val{:positions}) where T
    N = if applicable(length, T)
        length(T)
    else
        error("Point type needs to have length defined and needs to be convertible to GeometryTypes point (e.g. tuples, abstract arrays etc.)")
    end
    Point{N, Float32}.(x)
end
function attribute_convert(x::T, ::Val{:positions}) where T <: StaticVector
    error("Please use an array of StaticVectors for positions. Found: $T")

end

function to_positions(b, x::GeometryPrimitive)
    to_positions(b, decompose(Point, x))
end

function to_positions(b, x::SimpleRectangle)
    # TODO fix the order of decompose
    to_positions(b, decompose(Point, x)[[1, 2, 4, 3, 1]])
end

function to_positions(b, x)
    error("Not a valid position type: $(typeof(x)). Please read the documentation of [`to_positions`](@ref)")
end
