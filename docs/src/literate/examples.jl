using AbstractPlotting, CairoMakie, MakieRecipes; nothing# hide
# ```julia
# using Makie, MakieRecipes
# ```

# ## The simplest example model
using MakieRecipes.RecipesBase

struct T end

RecipesBase.@recipe function plot(::T, n = 1; customcolor = :green)
    markershape --> :auto        # if markershape is unset, make it :auto
    markercolor :=  customcolor       # force markercolor to be customcolor
    xrotation   --> 45           # if xrotation is unset, make it 45
    zrotation   --> 90           # if zrotation is unset, make it 90
    rand(10,n)                   # return the arguments (input data) for the next recipe
end

recipeplot(T(); seriestype = :path)

AbstractPlotting.save("basic.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](basic.svg)

# ## Testing out series decomposition

sc = Scene()
recipeplot!(sc, rand(10, 2); seriestype = :scatter)
recipeplot!(sc, 1:10, rand(10, 1); seriestype = :path)

AbstractPlotting.save("series.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](series.svg)

# ## Differential Equations

using OrdinaryDiffEq, StochasticDiffEq

# ### A simple exponential growth model

f(u,p,t) = 1.01.*u
u0 = [1/2, 1]
tspan = (0.0,1.0)
prob = ODEProblem(f,u0,tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

recipeplot(sol)

AbstractPlotting.save("exp.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](exp.svg)

# ### Matrix DiffEq

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

AbstractPlotting.save("mat.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](mat.svg)

# ### Stochastic DiffEq

f(du,u,p,t) = (du .= u)
g(du,u,p,t) = (du .= u)
u0 = rand(4,2)

W = WienerProcess(0.0,0.0,0.0)
prob = SDEProblem(f,g,u0,(0.0,1.0),noise=W)
sol = solve(prob,SRIW1())

recipeplot(sol)

AbstractPlotting.save("stochastic.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](stochastic.svg)

# ## Phylogenetic tree
using Phylo
assetpath = joinpath(dirname(pathof(MakieRecipes)), "..", "docs", "src", "assets")
hummer = open(t -> parsenewick(t, NamedPolytomousTree), joinpath(assetpath, "hummingbirds.tree"))
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

AbstractPlotting.save("phylo.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](phylo.svg)

# ## GraphRecipes
using GraphRecipes

# ### Julia AST with GraphRecipes

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
AbstractPlotting.save("ast.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](ast.svg)

# ### Type tree with GraphRecipes

recipeplot(AbstractFloat; method = :tree, fontsize = 10)
AbstractPlotting.save("typetree.svg", AbstractPlotting.current_scene()); nothing #hide
# ![](typetree.svg)
