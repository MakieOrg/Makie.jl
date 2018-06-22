module StructsOfArrays

export StructOfArrays, ScalarRepeat

struct StructOfArrays{T,N,U<:Tuple} <: AbstractArray{T,N}
    arrays::U
end


mutable struct ScalarRepeat{T}
    scalar::T
end
Base.ndims(::ScalarRepeat) = 1
Base.getindex(s::ScalarRepeat, i...) = s.scalar
#should setindex! really be allowed? It will set the index for the whole row...
Base.setindex!(s::ScalarRepeat{T}, value, i...) where {T} = (s.scalar = T(value))
Base.eltype(::ScalarRepeat{T}) where {T} = T

Base.start(::ScalarRepeat) = 1
Base.next(sr::ScalarRepeat, i) = sr.scalar, i+1
Base.done(sr::ScalarRepeat, i) = false


# since this is used in hot loops, and T.types[.] doesn't play well with compiler
# this needs to be a generated function
@generated function is_tuple_struct(::Type{T}) where T
    is_ts = length(T.types) == 1 && T.types[1] <: Tuple
    :($is_ts)
end
struct_eltypes(::T) where {T} = struct_eltypes(T)
function struct_eltypes(::Type{T}) where T
    if is_tuple_struct(T) #special case tuple types (E.g. FixedSizeVectors)
        return eltypes = T.types[1].parameters
    else
        return eltypes = T.types
    end
end

make_iterable(x::AbstractArray) = x
make_iterable(x) = ScalarRepeat(x)

@generated function StructOfArrays(::Type{T}, dim1::Integer, rest::Integer...) where T
    (!isleaftype(T) || T.mutable) && return :(throw(ArgumentError("can only create an StructOfArrays of leaf type immutables")))
    isempty(T.types) && return :(throw(ArgumentError("cannot create an StructOfArrays of an empty or bitstype")))
    dims = (dim1, rest...)
    N = length(dims)
    eltypes  = struct_eltypes(T)
    arrtuple = Tuple{[Array{eltypes[i],N} for i = 1:length(eltypes)]...}

    :(StructOfArrays{T,$N,$arrtuple}(
        ($([:(Array($(eltypes[i]), (dim1, rest...))) for i = 1:length(eltypes)]...),)
    ))
end
StructOfArrays(T::Type, dims::Tuple{Vararg{Integer}}) = StructOfArrays(T, dims...)

function StructOfArrays(T::Type, a, rest...)
    arrays = map(make_iterable, (a, rest...))
    N = ndims(arrays[1])
    eltypes = map(eltype, arrays)
    s_eltypes = struct_eltypes(T)
    any(ix->ix[1]!=ix[2], zip(eltypes,s_eltypes)) && throw(ArgumentError(
        "fieldtypes of $T must be equal to eltypes of arrays: $eltypes"
    ))
    any(x->ndims(x)!=N, arrays) && throw(ArgumentError(
        "cannot create an StructOfArrays from arrays with different ndims"
    ))
    arrtuple = Tuple{map(typeof, arrays)...}
    StructOfArrays{T, N, arrtuple}(arrays)
end

Base.IndexStyle(::Type{<:StructOfArrays}) = IndexLinear()

@generated function Base.similar(A::StructOfArrays, ::Type{T}, dims::Dims) where T
    if isbits(T) && length(T.types) > 1
        :(StructOfArrays(T, dims))
    else
        :(Array(T, dims))
    end
end

Base.convert(::Type{StructOfArrays{T,N}}, A::AbstractArray{S,N}) where {T,S,N} =
    copy!(StructOfArrays(T, size(A)), A)
Base.convert(::Type{StructOfArrays{T}}, A::AbstractArray{S,N}) where {T,S,N} =
    convert(StructOfArrays{T,N}, A)
Base.convert(::Type{StructOfArrays}, A::AbstractArray{T,N}) where {T,N} =
    convert(StructOfArrays{T,N}, A)

function Base.size(A::StructOfArrays{T, N, U}) where {T, N, U}
    for elem in A.arrays
        if isa(elem, AbstractArray)
            return size(elem)
        end
    end
    # if none has a size, size is inf!
    ntuple(Val{N}) do i
        typemax(Int)
    end
end

@generated function Base.getindex(A::StructOfArrays{T}, i::Integer...) where T
    n = length(struct_eltypes(T))
    Expr(:block, Expr(:meta, :inline),
         :($T($([:(A.arrays[$j][i...]) for j = 1:n]...)))
    )
end

function _getindex(x::T, i) where T
    is_tuple_struct(T) ? x[i] : getfield(x, i)
end
@generated function Base.setindex!(A::StructOfArrays{T}, x, i::Integer...) where T
    n = length(struct_eltypes(T))
    quote
        $(Expr(:meta, :inline))
        v = convert(T, x)
        $([:(A.arrays[$j][i...] = _getindex(v, $j)) for j = 1:n]...)
        x
    end
end
end # module
