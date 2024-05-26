function attribute_examples(::Type{Scatter})
    Dict(
        :rotation => [
            Example(
                code = """
                    fig = Figure()
                    kwargs = (; marker = :utriangle, markersize = 30, axis = (; limits = (0, 4, 0, 4)))
                    scatter(fig[1, 1], 1:3; kwargs...)
                    scatter(fig[1, 2], 1:3; kwargs..., rotation = deg2rad(45))
                    scatter(fig[1, 3], 1:3; kwargs..., rotation = deg2rad.([0, 45, 90]))
                    fig
                    """
            )
        ]
    )
end