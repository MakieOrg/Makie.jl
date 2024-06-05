function attribute_examples(::Type{Scatter})
    Dict(
        :linestyle => [
            Example(
                code = """
                    linestyles = [:solid, :dot, :dash, :dashdot, :dashdotdot]
                    gapstyles = [:normal, :dense, :loose, 10]
                    fig = Figure()
                    with_updates_suspended(fig.layout) do
                        for (i, ls) in enumerate(linestyles)
                            for (j, gs) in enumerate(gapstyles)
                                title = gs === :normal ? repr(ls) : "$((ls, gs))"
                                ax = Axis(fig[i, j]; title, yautolimitmargin = (0.2, 0.2))
                                hidedecorations!(ax)
                                hidespines!(ax)
                                linestyle = (ls, gs)
                                for linewidth in 1:3
                                    lines!(ax, 1:10, fill(linewidth, 10); linestyle, linewidth)
                                end
                            end
                        end
                    end
                    fig
                    """
            ),
            Example(
                code = """
                    fig = Figure()
                    patterns = [
                        [0, 1, 2],
                        [0, 20, 22],
                        [0, 2, 4, 12, 14],
                        [0, 2, 4, 6, 8, 10, 20],
                        [0, 1, 2, 4, 6, 9, 12],
                        [0.0, 4.0, 6.0, 9.5],
                    ]
                    ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2))
                    for (i, pattern) in enumerate(patterns)
                        lines!(ax, [-i, -i], linestyle = Linestyle(pattern), linewidth = 4)
                        text!(ax, (1.5, -i), text = "Linestyle($pattern)",
                            align = (:center, :bottom), offset = (0, 10))
                    end
                    hidedecorations!(ax)
                    fig
                    """
            ),
        ],
    )
end