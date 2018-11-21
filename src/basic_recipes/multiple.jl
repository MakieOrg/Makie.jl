export PlotList, PlotSpec

struct PlotSpec{P<:AbstractPlot}
    args::Tuple
    kwargs::NamedTuple
    PlotSpec{P}(args...; kwargs...) where {P<:AbstractPlot} = new{P}(args, values(kwargs))
end

PlotSpec(args...; kwargs...) = PlotSpec{Combined{Any}}(args...; kwargs...)

to_plotspec(::Type{P}, args; kwargs...) where {P} =
    PlotSpec{P}(args...; kwargs...)

to_plotspec(::Type{P}, p::PlotSpec{S}; kwargs...) where {P, S} =
    PlotSpec{plottype(P, S)}(p.args...; p.kwargs..., kwargs...)

plottype(::PlotSpec{P}) where {P} = P

abstract type AbstractPlotList{T<:Tuple} end

plottype(::Type{<:AbstractPlotList{T}}) where {T} = T.parameters

struct PlotList{T<:Tuple} <: AbstractPlotList{T}
    plots::Tuple
    transform_attributes::Function
    function PlotList(plots...; transform_attributes::Function = identity)
        T = Tuple{unique(plottype.(plots))...}
        new{T}(plots, transform_attributes)
    end
end


Base.parent(p::PlotList) = p.plots

Base.getindex(m::AbstractPlotList, I...) = getindex(parent(m), I...)
Base.size(m::AbstractPlotList) = size(parent(m))

@recipe(MultiplePlot) do scene
    default_theme(scene)
end

function default_theme(scene, ::Type{<:Combined{multipleplot, Tuple{P}}}) where {P<:AbstractPlotList}
    merge((default_theme(scene, pt) for pt in plottype(P))...)
end
# Allow MultiplePlot to prevail on user input: the plot type of each series will be defined in convert_arguments
plottype(::Type{<: Combined{Any}}, A::Type{<:MultiplePlot}, argvalues...) = A
plottype(::Type{<: Combined{T}}, A::Type{<:MultiplePlot}, argvalues...) where T = A

to_pair(P, t) = P => t
to_pair(P, p::Pair) = to_pair(plottype(P, first(p)), last(p))

function convert_arguments(P::PlotFunc, m::PlotList)
    function convert_series(plot::PlotSpec)
        ptype = plottype(P, plottype(plot))
        to_plotspec(ptype, convert_arguments(ptype, plot.args...); plot.kwargs...)
    end
    pl = PlotList(convert_series.(m.plots)...; transform_attributes = m.transform_attributes)
    PlotSpec{MultiplePlot}(pl)
end

# This allows plotting an arbitrary combination of series form one argument
# The recipe framework can be constructed using this as a building block and computing
# PlotList with convert_arguments
function plot!(p::Combined{multipleplot, <:Tuple{PlotList}})
    mp = to_value(p[1]) # TODO how to preserve interactivity here, as number of series may change?
    theme = mp.transform_attributes(Theme(p))
    for s in mp.plots
        attr = copy(theme)
        ptype, args = apply_convert!(Combined{Any}, attr, s)
        plot!(p, ptype, attr, args...)
    end
end
