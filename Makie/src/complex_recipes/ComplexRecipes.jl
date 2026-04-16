# ComplexRecipes module
# Provides infrastructure for multi-axis, layout-based recipes
# Use `@recipe complex MyRecipe (args...) begin ... end` to define complex recipes

include("complex_recipes.jl")
include("plotting.jl")

export ComplexRecipe, RecipeSubfig
