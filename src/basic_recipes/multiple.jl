export PlotList

abstract type AbstractPlotList{T, S} <: AbstractVector{T} end

to_vector(v::AbstractVector, n) = convert(Vector, v)
to_vector(v, n) = fill(v, n)

function tuple_type(v::AbstractVector)
    vec = unique(first(el) for el in v if el isa Pair)
    Tuple{vec...}
end

tuple_type(::Type{<:AbstractPlotList{T, S}}) where {T, S} = S

struct PlotList{T, S} <: AbstractPlotList{T, S}
    plots::Vector{T}
    transform_attributes::AbstractVector
    PlotList(plots::AbstractVector{T}; transform_attributes = identity) where {T} =
        new{T, tuple_type(plots)}(convert(Vector{T}, plots), to_vector(transform_attributes, length(plots)))
end

PlotList(args...; kwargs...) = PlotList(collect(args); kwargs...)

Base.parent(p::PlotList) = p.plots

Base.getindex(m::AbstractPlotList, I...) = getindex(parent(m), I...)
Base.size(m::AbstractPlotList) = size(parent(m))

@recipe(MultiplePlot) do scene
    default_theme(scene)
end

function default_theme(scene, ::Type{<:Combined{multipleplot, Tuple{P}}}) where {P<:AbstractPlotList}
    merge((default_theme(scene, pt) for pt in tuple_type(P).parameters)...)
end
# Allow MultiplePlot to prevail on user input: the plot type of each series will be defined in convert_arguments
plottype(::Type{<: Combined{Any}}, A::Type{<:MultiplePlot}, argvalues...) = A
plottype(::Type{<: Combined{T}}, A::Type{<:MultiplePlot}, argvalues...) where T = A

function convert_arguments(P::PlotFunc, m::PlotList)
    function convert_series(s)
        ptype, args = to_pair(P, s)
        to_pair(ptype, convert_arguments(ptype, args...))
    end
    MultiplePlot => (PlotList(convert_series.(m); transform_attributes = m.transform_attributes),)
end

to_pair(P, t) = P => t
to_pair(P, p::Pair) = to_pair(plottype(P, first(p)), last(p))

# This allows plotting an arbitrary combination of series form one argument
# The recipe framework can be constructed using this as a building block and computing
# PlotList with convert_arguments
function plot!(p::Combined{multipleplot, <:Tuple{PlotList}})
    mp = to_value(p[1]) # TODO how to preserve interactivity here, as number of series may change?
    for (i, s) in enumerate(mp)
        PlotType, args = s
        attr = mp.transform_attributes[i](Theme(p))
        plot!(p, PlotType, attr, args...)
    end
end
