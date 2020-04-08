
@AbstractPlotting.recipe(RecipePlot) do scene
    default_theme(scene)
end

function AbstractPlotting.plot!(p::T) where T <: RecipePlot

    # Node(1) is a dummy observable for dispatch

    lift(Node(1), p.attributes, p.converted, p.converted..., values(p.attributes)...) do _, attrs, args, __lifted...

        !isempty(p.plots) && empty!(p.plots)

        RecipesPipeline.recipe_pipeline!(
            p,
            Dict{Symbol, Any}(keys(attrs) .=> to_value.(values(attrs))),
            to_value.(args)
        )

    end

    return nothing

end
