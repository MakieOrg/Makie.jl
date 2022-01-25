using Test, MakieCore

# Main tests live in Makie.jl, but we should write some unit tests going forward!
using MakieCore: @recipe, Attributes, Plot
import MakieCore: plot!, convert_arguments, used_attributes, plot
import MakieCore: Observable, PointBased

struct AbstractTimeseriesSolution
    results::Vector{Float32}
end

function plot!(plot::Plot(AbstractTimeseriesSolution))
    # plot contains any keyword arguments that you pass to plot(series; kw...)
    var = get(plot, :var, ChangeObservable(5))
    density!(plot, map((v, r)-> v .* r.results, var, plot[1]))
end

struct Test2
    series::Any
end

struct Solution
    data::Any
end

function plot!(plot::Plot(Test2))
    arg1 = plot[1]
    scatter!(plot, arg1[].series)
    ser = AbstractTimeseriesSolution(arg1[].series)
    sol = Solution(arg1[].series)
    plot!(plot, ser, var = 10)
    scatter!(plot, sol, attribute = 3, color=:red)
end

used_attributes(::Any, x::Solution) = (:attribute,)

# Convert for all point based types (lines, scatter)
function convert_arguments(p::MakieCore.PointBased, x::Solution; attribute = 1.0)
    return convert_arguments(p, x.data .* attribute)
end
