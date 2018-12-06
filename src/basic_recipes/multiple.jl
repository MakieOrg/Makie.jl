abstract type AbstractPlotList{T<:Tuple} end

plottype(::Type{<:AbstractPlotList{T}}) where {T} = T.parameters

"""
`Plotlist(plots...)`

Experimental feature. Create an object that can encode multiple series.
"""
struct PlotList{T<:Tuple} <: AbstractPlotList{T}
    plots::Tuple
    function PlotList(plots...)
        T = Tuple{unique(plottype.(plots))...}
        new{T}(plots)
    end
end


Base.getindex(m::PlotList, i) = getindex(m.plots, i)
Base.length(m::PlotList) = length(m.plots)
Base.iterate(m::PlotList, args...) = iterate(m.plots, args...)

@recipe(MultiplePlot) do scene
    default_theme(scene)
end

function default_theme(scene, ::Type{<:Combined{multipleplot, Tuple{P}}}) where {P<:AbstractPlotList}
    merge((default_theme(scene, pt) for pt in plottype(P))...)
end
# Allow MultiplePlot to prevail on user input: the plot type of each series will be defined in convert_arguments
plottype(::Type{<: Combined{Any}}, A::Type{<:MultiplePlot}, argvalues...) = A
plottype(::Type{<: Combined{T}}, A::Type{<:MultiplePlot}, argvalues...) where T = A

function convert_arguments(P::PlotFunc, m::PlotList)
    function convert_series(plot::PlotSpec)
        ptype = plottype(P, plottype(plot))
        to_plotspec(ptype, convert_arguments(ptype, plot.args...); plot.kwargs...)
    end
    pl = PlotList(convert_series.(m.plots)...)
    PlotSpec{MultiplePlot}(pl)
end

combine(val1, val2; palette = nothing) = val2

function combine!(theme1::Theme, theme2::Theme)
    palette = get(theme1, :palette, current_default_theme()[:palette])
    for (key, val) in theme2
        tv = get(theme1, key, nothing) |> to_node
        pv = get(palette, key, nothing) |> to_node
        theme1[key] = lift((t, p, v) -> combine(t, v, palette = p), tv, pv, val)
    end
    theme1
end
combine(theme1::Theme, theme2) = combine!(copy(theme1), theme2)

# This allows plotting an arbitrary combination of series form one argument
# The recipe framework can be constructed using this as a building block and computing
# PlotList with convert_arguments
function plot!(p::Combined{multipleplot, <:Tuple{PlotList}})
    mp = to_value(p[1]) # TODO how to preserve interactivity here, as number of series may change?
    theme = Theme(p)
    for s in mp.plots
        attr = combine(theme, Theme(; s.kwargs...))
        plot!(p, plottype(s), attr, s.args...)
    end
end

function default_theme(scene, ::Type{<:Combined{S, T}}) where {S<:Tuple, T}
    merge((default_theme(scene, Combined{pt}) for pt in S.parameters)...)
end

function plot!(p::Combined{S, <:Tuple{Vararg{Any, N}}}) where {S <: Tuple, N}
    for pt in S.parameters
        plot!(p, Combined{pt}, Theme(p), p[1:N]...)
    end
end

function Base.:*(::Type{<:Combined{S}}, ::Type{<:Combined{T}}) where {S, T}
    params1 = S isa Type{<:Tuple} ? S.parameters : [S]
    params2 = T isa Type{<:Tuple} ? T.parameters : [T]
    params = union(params1, params2)
    Combined{Tuple{params...}}
end
