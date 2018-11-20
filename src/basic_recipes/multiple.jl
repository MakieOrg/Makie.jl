export PlotList, PlotSpecs

struct PlotSpecs{P<:AbstractPlot}
    args::Tuple
    transform_attributes::Function
end

PlotSpecs(args...) = PlotSpecs{Combined{Any}}(args...)
PlotSpecs{P}(args::Tuple) where {P} = PlotSpecs{P}(args, identity)
PlotSpecs{P}(x::PlotSpecs) where {P} = PlotSpecs{P}(x.args, x.transform_attributes)

plottype(::PlotSpecs{P}) where {P} = P

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
    function convert_series(plot::PlotSpecs)
        ptype = plottype(P, plottype(plot))
        finaltype, converted_args = to_pair(ptype, convert_arguments(ptype, plot.args...))
        PlotSpecs{finaltype}(converted_args, plot.transform_attributes)
    end
    pl = PlotList(convert_series.(m.plots)...; transform_attributes = m.transform_attributes)
    MultiplePlot => (pl,)
end

# This allows plotting an arbitrary combination of series form one argument
# The recipe framework can be constructed using this as a building block and computing
# PlotList with convert_arguments
function plot!(p::Combined{multipleplot, <:Tuple{PlotList}})
    mp = to_value(p[1]) # TODO how to preserve interactivity here, as number of series may change?
    theme = mp.transform_attributes(Theme(p))
    for s in mp.plots
        args, transform_attributes = s.args, s.transform_attributes
        attr = transform_attributes(theme)
        plot!(p, plottype(s), attr, args...)
    end
end
