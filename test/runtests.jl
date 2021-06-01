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
    var = get(plot, :var, Observable(5))
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

# using GLMakie
# using CairoMakie
# plot(Test2(rand(Float32, 10)))


# function MakieCore.plot!(myplot::MyPlot{<:Tuple{<:AbstractVector{<:Number}}})
#     lines!(myplot, rand(10), color = myplot[:plot_color])
#     plot!(myplot, myplot[:x])
#     myplot
# end

# myplot(1:3)



# function MakieCore.plot(P::Type{<: AbstractPlot}, fig::Makie.FigurePosition, arg::Solution; axis = NamedTuple(), kwargs...)

#     menu = Menu(fig, options = ["viridis", "heat", "blues"])

#     funcs = [sqrt, x->x^2, sin, cos]

#     menu2 = Menu(fig, options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs))

#     fig[1, 1] = vgrid!(
#         Label(fig, "Colormap", width = nothing),
#         menu,
#         Label(fig, "Function", width = nothing),
#         menu2;
#         tellheight = false, width = 200)

#     ax = Axis(fig[1, 2]; axis...)

#     func = Node{Any}(funcs[1])

#     ys = @lift($func.(arg.data))

#     scat = plot!(ax, P, Attributes(color = ys), ys)

#     cb = Colorbar(fig[1, 3], scat)

#     on(menu.selection) do s
#         scat.colormap = s
#     end

#     on(menu2.selection) do s
#         func[] = s
#         autolimits!(ax)
#     end

#     menu2.is_open = true

#     return Makie.AxisPlot(ax, scat)
# end

# f = Figure();
# lines(f[1, 1], Solution(0:0.3:10))
# scatter(f[1, 2], Solution(0:0.3:10))
# f |> display



# @recipe(MyPlot, x) do scene
#     Theme(
#         plot_color = :red
#     )
# end

# function Makie.plot!(p::MyPlot)
#     @show p.transformation.transform_func[]
#     scatter!(p, p[1])
# end

# myplot(rand(4), axis=(xscale=log10,))
# using CairoMakie
# plot(Test2(rand(Float32, 10)))

# scatter(Solution(rand(4)), attribute = 10)
