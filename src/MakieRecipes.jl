module MakieRecipes

using RecipesBase, AbstractPlotting, GLMakie
using RecipesBase: @recipe

# Our user-defined data type
struct T end

# This is all we define.  It uses a familiar signature, but strips it apart
# in order to add a custom definition to the internal method `RecipesBase.apply_recipe`
@recipe function plot(::T, n = 1; customcolor = :green)
    markershape --> :auto        # if markershape is unset, make it :auto
    markercolor :=  customcolor  # force markercolor to be customcolor
    xrotation   --> 45           # if xrotation is unset, make it 45
    zrotation   --> 90           # if zrotation is unset, make it 90
    rand(10,n)                   # return the arguments (input data) for the next recipe
end

apply_recipe(args...; kw...) = RecipesBase.apply_recipe(Dict{Symbol, Any}(kw), args...)

RecipesBase.is_key_supported(k::Symbol) = true


function tomakie(vector::Vector{RecipeData})
    scene = Scene()
    for recipe in vector
        tomakie!(scene, recipe)
    end
    return scene
end

function tomakie!(scene::Scene, recipe::RecipeData)
    series!(scene, recipe.args...)
end

tomakie(apply_recipe(T(), 3))


end

end # module
