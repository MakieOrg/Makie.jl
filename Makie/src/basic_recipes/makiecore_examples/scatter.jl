function attribute_examples(::Type{Scatter})
    return Dict(
        :color => [
            Example(
                code = """
                fig = Figure()
                kwargs = (; markersize = 30, axis = (; limits = (0, 4, 0, 4)))
                scatter(fig[1, 1], 1:3; kwargs..., color = :tomato)
                scatter(fig[1, 2], 1:3; kwargs..., color = [RGBf(1, 0, 0), RGBf(0, 1, 0), RGBf(0, 0, 1)])
                scatter(fig[2, 1], 1:3; kwargs..., color = [10, 20, 30])
                scatter(fig[2, 2], 1:3; kwargs..., color = [10, 20, 30], colormap = :plasma)
                fig
                """
            ),
        ],
        :colormap => [
            Example(
                code = """
                fig = Figure()
                kwargs = (; markersize = 30, axis = (; limits = (0, 6, 0, 6)))
                scatter(fig[1, 1], 1:5; kwargs..., color = 1:5, colormap = :viridis)
                scatter(fig[1, 2], 1:5; kwargs..., color = 1:5, colormap = :plasma)
                scatter(fig[2, 1], 1:5; kwargs..., color = 1:5, colormap = Reverse(:viridis))
                scatter(fig[2, 2], 1:5; kwargs..., color = 1:5, colormap = [:tomato, :slategray2])
                fig
                """
            ),
        ],
        :markersize => [
            Example(
                code = """
                fig = Figure()
                kwargs = (; marker = Rect, axis = (; limits = (0, 4, 0, 4)))
                scatter(fig[1, 1], 1:3; kwargs..., markersize = 30)
                scatter(fig[1, 2], 1:3; kwargs..., markersize = (30, 20))
                scatter(fig[2, 1], 1:3; kwargs..., markersize = [10, 20, 30])
                scatter(fig[2, 2], 1:3; kwargs..., markersize = [(10, 20), (20, 30), (40, 30)])
                fig
                """
            ),
        ],
        :marker_offset => [
            Example(
                code = """
                fig = Figure()
                scatter(fig[1, 1], [Point2f(0) for _ in 1:5]; marker = Circle, markersize = 30,
                    marker_offset = [(0, 0), (-50, 0), (0, -50), (50, 0), (0, 50)],
                    color = [:black, :blue, :green, :red, :orange])
                scatter(fig[1, 2], [Point3f(0) for _ in 1:7]; marker = :ltriangle, markersize = 0.2, markerspace = :data,
                    marker_offset = Vec3f[(0, 0, 0), (-1, 0, 0), (0, -1, 0), (1, 0, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1)],
                    color = [:black, :blue, :green, :red, :orange, :cyan, :purple])
                fig
                """
            ),
        ],
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
            ),
        ],
        :strokecolor => [
            Example(
                code = """
                fig = Figure()
                kwargs = (; markersize = 30, strokewidth = 3)
                scatter(fig[1, 1], 1:3; kwargs..., strokecolor = :tomato)
                scatter(fig[1, 2], 1:3; kwargs..., strokecolor = [RGBf(1, 0, 0), RGBf(0, 1, 0), RGBf(0, 0, 1)])
                fig
                """
            ),
        ],
        :strokewidth => [
            Example(
                code = """
                fig = Figure()
                kwargs = (; markersize = 30, strokecolor = :tomato)
                scatter(fig[1, 1], 1:3; kwargs..., strokewidth = 3)
                scatter(fig[1, 2], 1:3; kwargs..., strokewidth = [0, 3, 6])
                fig
                """
            ),
        ],
    )
end
