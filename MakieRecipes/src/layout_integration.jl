function tomakie!(sc::AbstractScene, layout::Makie.GridLayout, args...; attrs...)
    # TODO create a finalizer for a Tuple{Scene, Layout, Vector{LAxis}}
    return RecipesPipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(attrs), args)
end
