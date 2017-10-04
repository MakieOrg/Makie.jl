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

"""
A color can be defined in the following way:
    * All Colors.Colorants
    * A symbol or string referencing a color like :black, :white
    * a string or symbol in hex form e.g. `#aabb11` or `#aaa` for gray
"""
to_color(c::Colorant) = RGBA{Float32}(c)
to_color(c::Symbol) = to_color(string(c))
to_color(c::String) = parse(RGBA{Float32}, c)
to_color(c::UniqueColorIter) = to_color(next(c))


const colorbrewer_names = Symbol[
    # All sequential color schemes can have between 3 and 9 colors. The available sequential color schemes are:
    :Blues,
    :Oranges,
    :Greens,
    :Reds,
    :Purples,
    :Greys,
    :OrRd,
    :GnBu,
    :PuBu,
    :PuRd,
    :BuPu,
    :BuGn,
    :YlGn,
    :RdPu,
    :YlOrBr,
    :YlGnBu,
    :YlOrRd,
    :PuBuGn,

    # All diverging color schemes can have between 3 and 11 colors. The available diverging color schemes are:
    :Spectral,
    :RdYlGn,
    :RdBu,
    :PiYG,
    :PRGn,
    :RdYlBu,
    :BrBG,
    :RdGy,
    :PuOr,

    #The number of colors a qualitative color scheme can have depends on the scheme. The available qualitative color schemes are:
    :Name,
    :Set1,
    :Set2,
    :Set3,
    :Dark2,
    :Accent,
    :Paired,
    :Pastel1,
    :Pastel2
]

function available_gradients()
    println("Gradient Symbol/Strings:")
    for name in colorbrewer_names
        println("    ", name)
    end
end

"""
Color gradients can be:
    * Symbol/String naming the gradient. For more info on whats available please call: `available_gradients()`
    * Vector{Colors.Colorant}
    * tuple(A, B), Pair{A, B} or Vector{T} with any object that [to_color](@ref) accepts. You can find the documentation of to_color with `help(to_color)` or in the REPL with `?to_color`
"""
to_colormap(cm::Vector{<: Colorant}) = RGBA{Float32}.(cm)
function to_colormap(cs::Union{Tuple, Vector, Pair})
    [to_color.(cs)...]
end

function to_colormap(cs::Union{String, Symbol})
    cs_sym = Symbol(cs)
    if cs_sym in colorbrewer_names
        ColorBrewer.palette(string(cs_sym), 9)
    else
        #TODO integrate PlotUtils color gradients
        error("There is no color gradient named: $cs")
    end
end
