
struct Point{N,T}
    coords::NTuple{N,T}
end

# convenience constructors
Point{Dim,T}(coords...) where {Dim,T} = Point{Dim,T}(NTuple{Dim,T}(coords))
Point(coords::AbstractVector{T}) where {T} = Point{length(coords),T}(coords)
Point(coords...) = Point(promote(coords...))
Base.eltype(::Point{N,T}) where {N,T} = T

# coordinate type conversions
Base.convert(::Type{Point{Dim,T}}, coords) where {Dim,T} = Point{Dim,T}(coords)
Base.convert(::Type{Point{Dim,T}}, p::Point) where {Dim,T} = Point{Dim,T}(p.coords)
Base.convert(::Type{Point}, coords) = Point{length(coords),eltype(coords)}(coords)

Base.@propagate_inbounds Base.getindex(v::Point, i::Int) = v.coords[i]

Base.map(f, x::Point) = Point(map(f, x.coords))
Base.map(f, a::Point, b::Point) = Point(map(f, a.coords, b.coords))

"""
    -(A::Point, B::Point)
Return the [`Vec`](@ref) associated with the direction
from point `A` to point `B`.
"""
-(A::Point, B::Point) = Vec(A.coords .- B.coords)

"""
    +(A::Point, v::Vec)
    +(v::Vec, A::Point)
Return the point at the end of the vector `v` placed
at a reference (or start) point `A`.
"""
+(A::Point, v::Vec) = Point(A.coords .+ v.coords)
+(v::Vec, A::Point) = A + v

"""
    -(A::Point, v::Vec)
    -(v::Vec, A::Point)
Return the point at the end of the vector `-v` placed
at a reference (or start) point `A`.
"""
-(A::Point, v::Vec) = Point(A.coords .- v.coords)
-(v::Vec, A::Point) = A - v


"""
    rand(P::Type{<:Point}, n=1)
Generates a random point of type `P`
"""
function Random.rand(
    rng::Random.AbstractRNG,
    ::Random.SamplerType{Point{Dim,T}},
) where {Dim,T}

    return Point(ntuple(i -> rand(rng, T), Dim))
end

function Base.show(io::IO, point::Point)
    print(io, "Point$(Tuple(point.coords))")
end
