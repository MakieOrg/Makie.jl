module MakieRecipes

# using RecipesBase, MakieCore
# using RecipesBase: @recipe
# using MakieCore: Palette, to_color

# using RecipesPipeline
# using Colors


# # ## Palette
# # The default palette is defined here.

# expand_palette(palette, n = 20; kwargs...) = RGBA.(distinguishable_colors(n, palette; kwargs...))

# const wong = copy(wong_colors)
# begin
#     global wong
#     tmp = wong[1]
#     wong[1] = wong[2]
#     wong[2] = tmp
# end
# const rwong = expand_palette(wong, 50)
# const default_palette = Palette(rwong)

# include("bezier.jl")
# include("pipeline_integration.jl")
# include("attribute_table.jl")
# include("recipeplot.jl")

# # TODO FIXME
# RecipesBase.is_key_supported(::Symbol) = false
# plots(la::MakieLayout.LAxis) = plots(la.scene)
# # FIXME TODO

# function tomakie!(sc::AbstractScene, args...; attrs...)
#     RecipesPipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(attrs), args)
# end

# tomakie!(args...; attrs...) = tomakie!(current_scene(), args...; attrs...)

# tomakie(args...; attrs...) = tomakie!(Scene(), args...; attrs...)


# export tomakie, tomakie!, recipeplot, recipeplot!

end
