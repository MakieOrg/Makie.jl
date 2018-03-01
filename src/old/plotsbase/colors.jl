# some type alias
const RGBAf0 = RGBA{Float32}

"""
A simple iterator that returns a new, unique color when `next(::UniqueColorIter)` is called.
"""
mutable struct UniqueColorIter{T}
    colors::T
    state::Int
end

UniqueColorIter(x::Union{Symbol, String}) = UniqueColorIter(to_colormap(x), 1)

function Base.getindex(iter::UniqueColorIter, idx::Int)
    # TODO make out of bounds more graceful? But hooow
    iter.colors[mod1(idx, length(iter.colors))]
end

Base.start(iter::UniqueColorIter) = (iter.state = 1; (iter, iter))

function Base.next(iter::UniqueColorIter)
    result = iter[iter.state]
    iter.state += 1
    result
end
# make the base interface happy
Base.next(iter::UniqueColorIter, iter2) = (next(iter), iter2)
