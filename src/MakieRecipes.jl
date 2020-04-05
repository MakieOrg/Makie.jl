module MakieRecipes

using RecipesBase, AbstractPlotting
using RecipesBase: @recipe

include("pipeline_integration.jl")
include("attribute_table.jl")

end # module
