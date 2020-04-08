module MakieRecipes

using RecipesBase, AbstractPlotting, MakieLayout
using RecipesBase: @recipe

using RecipesPipeline
using Colors

include("bezier.jl")
include("pipeline_integration.jl")
include("attribute_table.jl")
include("recipeplot.jl")

# TODO FIXME
RecipesBase.is_key_supported(::Symbol) = false
# FIXME TODO

function tomakie!(sc::Scene, args...; attrs...)
    RecipesPipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(attrs), args)
end

tomakie!(args...; attrs...) = tomakie!(AbstractPlotting.current_scene(), args...; attrs...)

tomakie(args...; attrs...) = tomakie!(Scene(), args...; attrs...)

export tomakie, tomakie!, recipeplot, recipeplot!

end
