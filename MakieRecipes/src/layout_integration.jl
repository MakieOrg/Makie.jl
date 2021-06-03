function tomakie!(sc::AbstractScene, layout::MakieLayout.GridLayout, args...; attrs...)
    # TODO create a finalizer for a Tuple{Scene, Layout, Vector{LAxis}}
    RecipesPipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(attrs), args)
end
