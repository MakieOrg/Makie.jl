function attribute_examples(::Type{Box})
    return Dict(
        :color => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], color = :red)
                Box(fig[1, 2], color = (:red, 0.5))
                Box(fig[2, 1], color = RGBf(0.2, 0.5, 0.7))
                Box(fig[2, 2], color = RGBAf(0.2, 0.5, 0.7, 0.5))
                fig
                """
            ),
        ],
        :strokecolor => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], strokecolor = :red)
                Box(fig[1, 2], strokecolor = (:red, 0.5))
                Box(fig[2, 1], strokecolor = RGBf(0.2, 0.5, 0.7))
                Box(fig[2, 2], strokecolor = RGBAf(0.2, 0.5, 0.7, 0.5))
                fig
                """
            ),
        ],
        :strokewidth => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], strokewidth = 1)
                Box(fig[1, 2], strokewidth = 10)
                Box(fig[1, 3], strokewidth = 0)
                fig
                """
            ),
        ],
        :linestyle => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], linestyle = :solid)
                Box(fig[1, 2], linestyle = :dot)
                Box(fig[1, 3], linestyle = :dash)
                fig
                """
            ),
        ],
        :cornerradius => [
            Example(
                code = """
                fig = Figure()
                Box(fig[1, 1], cornerradius = 0)
                Box(fig[1, 2], cornerradius = 20)
                Box(fig[1, 3], cornerradius = (0, 10, 20, 30))
                fig
                """
            ),
        ],
    )
end
