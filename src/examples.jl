using Makie, MakieRecipes
using MakieRecipes.RecipesBase

sc = Scene()

# # The simplest example model

struct T end

RecipesBase.@recipe function plot(::T, n = 1)
    markershape --> :auto        # if markershape is unset, make it :auto
    markercolor :=  :green  # force markercolor to be customcolor
    xrotation   --> 45           # if xrotation is unset, make it 45
    zrotation   --> 90           # if zrotation is unset, make it 90
    rand(10,n)                   # return the arguments (input data) for the next recipe
end

recipeplot(T(); seriestype = :path)

RecipesBase.is_key_supported(::Symbol) = true


# AbstractPlotting.scatter!(sc, rand(10))
sc = Scene()
recipeplot!(sc, rand(10, 2); seriestype = :scatter)
recipeplot!(sc, 1:10, rand(10, 1); seriestype = :path)


using DifferentialEquations, MakieRecipes
# import Plots # we need some recipes from here

f(u,p,t) = 1.01.*u
u0 = [1/2, 1]
tspan = (0.0,1.0)
prob = ODEProblem(f,u0,tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

recipeplot(sol)

A  = [1. 0  0 -5
      4 -2  4 -3
     -4  0  0  1
      5 -2  2  3]
u0 = rand(4,2)
tspan = (0.0,1.0)
f(u,p,t) = A*u
prob = ODEProblem(f,u0,tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

recipeplot(sol)

f(du,u,p,t) = (du .= u)
g(du,u,p,t) = (du .= u)
u0 = rand(4,2)

W = WienerProcess(0.0,0.0,0.0)
prob = SDEProblem(f,g,u0,(0.0,1.0),noise=W)
sol = solve(prob,SRIW1())

recipeplot(sol)

recipeplot(AbstractPlotting.peaks(); seriestype = :surface, cgrad = :inferno)

recipeplot(AbstractPlotting.peaks(); seriestype = :heatmap, cgrad = :RdYlBu)

# # Phylogenetic tree
using Phylo
hummer = open(t -> parsenewick(t, NamedPolytomousTree), "/Users/Anshul/Downloads/hummingbirds.tree")
evolve(tree) = Phylo.map_depthfirst((val, node) -> val + randn(), 0., tree, Float64)
trait = evolve(hummer)

scp = recipeplot!(
    Scene(scale_plot = false, show_axis = false),
    hummer;
    treetype = :fan,
    line_z = trait,
    linewidth = 5,
    showtips = false,
    cgrad = :RdYlBu,
    seriestype = :path
)

# Timeseries with market data
using MarketData, TimeSeries

recipeplot(MarketData.ohlc; seriestype = :path)
# Julia AST with GraphRecipes
using GraphRecipes

code = quote
    function mysum(list)
        out = 0
        for value in list
            out += value
        end
        out
    end
end

recipeplot(code; fontsize = 12, shorten = 0.01, axis_buffer = 0.15, nodeshape = :rect)

recipeplot(AbstractFloat; method = :tree, fontsize = 10)
