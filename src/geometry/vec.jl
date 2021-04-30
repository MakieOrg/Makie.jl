struct Vec{N,T}
    coords::NTuple{N,T}
end
# convenience constructors
Vec{Dim,T}(coords...) where {Dim,T} = Vec{Dim,T}(NTuple{Dim,T}(coords))
Vec(coords::AbstractVector{T}) where {T} = Vec{length(coords),T}(coords)
Vec(coords...) = Vec(promote(coords...))
Vec(coords::Tuple) = Vec(promote(coords...))
Vec{Dim}(one::Number) where {Dim} = Vec(ntuple(x -> one, Dim))
Vec{Dim,T}(one::Number) where {Dim,T} = Vec(ntuple(x -> convert(T, one), Dim))
Base.eltype(::Vec{N,T}) where {N,T} = T
# coordinate type conversions
Base.convert(::Type{Vec{Dim,T}}, coords) where {Dim,T} = Vec{Dim,T}(coords)
Base.convert(::Type{Vec{Dim,T}}, p::Vec) where {Dim,T} = Vec{Dim,T}(p.coords)
Base.convert(::Type{Vec}, coords) = Vec{length(coords),eltype(coords)}(coords)

Base.@propagate_inbounds Base.getindex(v::Vec, i::Int) = v.coords[i]
Base.@propagate_inbounds Base.getindex(v::Vec, i::Vec{N,Int}) where {N} = map(i -> v[i], i)

Base.map(f, x::Vec) = Vec(map(f, x.coords))
Base.map(f, a::Vec, b::Vec) = Vec(map(f, a.coords, b.coords))
-(a::Vec) = map(-, a)
+(a::Vec, b::Vec) = map(+, a, b)
+(a::Vec, b::Number) = Vec(a.coords .+ b)
-(a::Vec, b::Vec) = map(-, a, b)
*(a::Vec, b::Vec) = map(*, a, b)
*(a::Number, b::Vec) = Vec(a .* b.coords)
*(a::Vec, b::Number) = Vec(a.coords .* b)
/(a::Vec, b::Number) = Vec(a.coords ./ b)
