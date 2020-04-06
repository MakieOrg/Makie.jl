module MakieRecipes

using RecipesBase, AbstractPlotting
using RecipesBase: @recipe

using RecipesPipeline
using Colors

include("bezier.jl")
include("pipeline_integration.jl")
include("attribute_table.jl")

# TODO FIXME
RecipesBase.is_key_supported(::Symbol) = false
# FIXME TODO

function tomakie!(sc::Scene, args...; attrs...)
    RecipesPipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(attrs), args)
end

tomakie!(args...; attrs...) = tomakie!(AbstractPlotting.current_scene(), args...; attrs...)


tomakie(args...; attrs...) = tomakie!(Scene(), args...; attrs...)

recipeplot = tomakie
recipeplot! = tomakie!

export tomakie, tomakie!, recipeplot, recipeplot!

#  @AbstractPlotting.recipe(RecipePlot) do scene
#     merge(
#         default_theme(scene),
#         Theme(seriestype = :path)
#     )
# end
#
# function plot!(p::RecipePlot)
#
#     RecipePipeline.recipe_pipeline!(
#         p,
#     )
#
end
