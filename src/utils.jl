function to_ndim(T::Type{<: StaticVector{N,ET}}, vec::StaticVector{N2}, fillval) where {N,ET,N2}
    T(ntuple(Val(N)) do i
        i > N2 && return ET(fillval)
        @inbounds return vec[i]
    end)
end

# bs_length(x::NativeFont) = 1 # these are our rules, and for what we do, Vecs are usually scalars
bs_length(x::StaticArray) = 1 # these are our rules, and for what we do, Vecs are usually scalars
bs_length(x::Tuple) = 1 # these are our rules, and for what we do, Vecs are usually scalars
bs_length(x::AbstractArray) = length(x)
bs_length(x::AbstractString) = length(x)
bs_length(x) = 1

# bs_getindex(x::NativeFont, i) = x # these are our rules, and for what we do, Vecs are usually scalars
bs_getindex(x::StaticArray, i) = x # these are our rules, and for what we do, Vecs are usually scalars
bs_getindex(x::Tuple, i) = x # these are our rules, and for what we do, Vecs are usually scalars
bs_getindex(x::AbstractArray, i) = x[i]
bs_getindex(x::AbstractString, i) = x[i]
bs_getindex(x, i) = x

function extract_expr(extract_func, dictlike, args)
    if args.head != :tuple
        error("Usage: args need to be a tuple. Found: $args")
    end
    expr = Expr(:block)
    for elem in args.args
        push!(expr.args, :($(esc(elem)) = $(extract_func)($(esc(dictlike)), $(QuoteNode(elem)))))
    end
    push!(expr.args, esc(args))
    expr
end

"""
usage @exctract scene (a, b, c, d)
"""
macro extract(scene, args)
    extract_expr(getfield, scene, args)
end

"""
Like broadcast but for foreach. Doesn't care about shape and treats Tuples && StaticVectors as scalars.
"""
function broadcast_foreach(f, args...)
    lengths = bs_length.(args)
    maxlen = maximum(lengths)

    # all non scalars should have same length
    if any(x -> !(x in (0, 1, maxlen)), lengths)
        error("All non scalars need same length, Found lengths for each argument: $lengths, $(typeof.(args))")
    end

    # skip if there's a zero length element (like an empty annotations collection, etc)
    # this differs from standard broadcasting logic in which all non-scalar shapes have to match
    0 in lengths && return

    for i in 1:maxlen
        f(bs_getindex.(args, i)...)
    end
    return
end
