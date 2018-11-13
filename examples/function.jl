using KernelDensity, AbstractPlotting, Makie
import AbstractPlotting: convert_arguments, PlotFunc, plottype
to_tuple(t::Tuple) = t
to_tuple(t) = (t,)


function convert_arguments(P::PlotFunc, f::Function, args...; kwargs...)
    tmp = f(args...; Iterators.filter(t -> last(t) != automatic, kwargs)...) |> to_tuple
    convert_arguments(P, tmp...)
end

# remove convert_arguments(P, f, x) = (x, f.(x))
function convert_arguments(P::PlotFunc, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    ptype => convert_arguments(ptype, d.x, d.density)
end

function convert_arguments(P::Type{<: Combined{T}}, d::KernelDensity.BivariateKDE) where T
    ptype = plottype(P, Heatmap)
    ptype => convert_arguments(ptype, d.x, d.y, d.density)
end

plot(kde, rand(100)) #line plot
scatter(kde, rand(100), markersize = 0.02, color = (:black, 0.1))

plot(kde, rand(100, 2)) #heatmap
surface(kde, rand(100, 2))
