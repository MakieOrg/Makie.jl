@enum Shape CIRCLE RECTANGLE ROUNDED_RECTANGLE DISTANCEFIELD TRIANGLE
@enum CubeSides TOP BOTTOM FRONT BACK RIGHT LEFT

struct Grid{N, T <: AbstractRange}
    dims::NTuple{N, T}
end
Base.ndims(::Grid{N,T}) where {N,T} = N

Grid(ranges::AbstractRange...) = Grid(ranges)
function Grid(a::Array{T, N}) where {N, T}
    s = Vec{N, Float32}(size(a))
    smax = maximum(s)
    s = s./smax
    Grid(ntuple(Val{N}) do i
        range(0, stop=s[i], length=size(a, i))
    end)
end

Grid(a::AbstractArray, ranges...) = Grid(a, ranges)

"""
This constructor constructs a grid from ranges given as a tuple.
Due to the approach, the tuple `ranges` can consist of NTuple(2, T)
and all kind of range types. The constructor will make sure that all ranges match
the size of the dimension of the array `a`.
"""
function Grid(a::AbstractArray{T, N}, ranges::Tuple) where {T, N}
    length(ranges) =! N && throw(ArgumentError(
        "You need to supply a range for every dimension of the array. Given: $ranges
        given Array: $(typeof(a))"
    ))
    Grid(ntuple(Val(N)) do i
        range(first(ranges[i]), stop=last(ranges[i]), length=size(a, i))
    end)
end

Base.length(p::Grid) = prod(size(p))
Base.size(p::Grid) = map(length, p.dims)
function Base.getindex(p::Grid{N,T}, i) where {N,T}
    inds = ind2sub(size(p), i)
    return Point{N, eltype(T)}(ntuple(Val(N)) do i
        p.dims[i][inds[i]]
    end)
end

Base.iterate(g::Grid, i = 1) = i <= length(g) ? (g[i], i + 1) : nothing

GLAbstraction.isa_gl_struct(x::Grid) = true
GLAbstraction.toglsltype_string(t::Grid{N,T}) where {N,T} = "uniform Grid$(N)D"
function GLAbstraction.gl_convert_struct(g::Grid{N, T}, uniform_name::Symbol) where {N,T}
    return Dict{Symbol, Any}(
        Symbol("$uniform_name.start") => Vec{N, Float32}(minimum.(g.dims)),
        Symbol("$uniform_name.stop") => Vec{N, Float32}(maximum.(g.dims)),
        Symbol("$uniform_name.lendiv") => Vec{N, Cint}(length.(g.dims) .- 1),
        Symbol("$uniform_name.dims") => Vec{N, Cint}(map(length, g.dims))
    )
end
function GLAbstraction.gl_convert_struct(g::Grid{1, T}, uniform_name::Symbol) where T
    x = g.dims[1]
    return Dict{Symbol, Any}(
        Symbol("$uniform_name.start") => Float32(minimum(x)),
        Symbol("$uniform_name.stop") => Float32(maximum(x)),
        Symbol("$uniform_name.lendiv") => Cint(length(x) - 1),
        Symbol("$uniform_name.dims") => Cint(length(x))
    )
end
import Base: getindex, length, iterate, ndims, setindex!, eltype

struct GridZRepeat{G, T, N} <: AbstractArray{Point{3, T}, N}
    grid::G
    z::Array{T, N}
end
Base.size(g::GridZRepeat) = size(g.z)
Base.size(g::GridZRepeat, i) = size(g.z, i)
Base.IndexStyle(::Type{<:GridZRepeat}) = Base.IndexLinear()

function Base.getindex(g::GridZRepeat{G, T}, i) where {G,T}
    pxy = g.grid[i]
    Point{3, T}(pxy[1], pxy[2], g.z[i])
end

struct GLVisualizeShader <: AbstractLazyShader
    paths::Tuple
    kw_args::Dict{Symbol, Any}
    function GLVisualizeShader(paths::String...; view = Dict{String, String}(), kw_args...)
        # TODO properly check what extensions are available
        @static if !Sys.isapple()
            view["GLSL_EXTENSIONS"] = "#extension GL_ARB_conservative_depth: enable"
            view["SUPPORTED_EXTENSIONS"] = "#define DETPH_LAYOUT"
        end
        args = Dict{Symbol, Any}(kw_args)
        args[:view] = view
        args[:fragdatalocation] = [(0, "fragment_color"), (1, "fragment_groupid")]
        new(map(x-> assetpath("shader", x), paths), args)
    end
end
