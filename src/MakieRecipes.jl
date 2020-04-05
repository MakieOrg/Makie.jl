module MakieRecipes

using RecipesBase, AbstractPlotting
using RecipesBase: @recipe

include("pipeline_integration.jl")
include("attribute_table.jl")

function tomakie!(sc::Scene, args...; attrs...)
    RecipesPipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(attrs), args)
end

tomakie!(args...; attrs...) = tomakie!(AbstractPlotting.current_scene(), args...; attrs...)


tomakie(args...; attrs...) = tomakie!(Scene(), args...; attrs...)

recipeplot = tomakie
recipeplot! = tomakie!

export tomakie, tomakie!, recipeplot, recipeplot!

end
