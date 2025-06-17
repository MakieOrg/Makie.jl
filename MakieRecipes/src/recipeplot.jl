@recipe(RecipePlot) do scene
    th = merge(
        default_theme(scene),
        Attributes(palette = Palette(rwong))
    )
    th.color = automatic
    return th
end

function plot!(p::T) where {T <: RecipePlot}

    # What happens here is that I want to lift on every available observable,
    # so they need to be splatted.  This also means that nested attributes
    # will not be lifted on, but that's an acceptable tradeoff.
    #
    # After lifting on everything,

    # Observable(1) is a dummy observable for dispatch.
    lift(Observable(1), p.attributes, p.converted, p.converted..., values(p.attributes)...) do _, attrs, args, __lifted...

        !isempty(p.plots) && empty!(p.plots)

        RecipesPipeline.recipe_pipeline!(
            p,
            Dict{Symbol, Any}(keys(attrs) .=> to_value.(values(attrs))),
            to_value.(args)
        )

    end

    return nothing

end
