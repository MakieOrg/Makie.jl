function attribute_examples(::Type{Lines})
    return Dict(
        :linestyle => [
            Example(
                code = """
                linestyles = [:solid, :dot, :dash, :dashdot, :dashdotdot]
                gapstyles = [:normal, :dense, :loose, 10]
                fig = Figure()
                with_updates_suspended(fig.layout) do
                    for (i, ls) in enumerate(linestyles)
                        for (j, gs) in enumerate(gapstyles)
                            title = gs === :normal ? repr(ls) : "\$((ls, gs))"
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
                    text!(ax, (1.5, -i), text = "Linestyle(\$pattern)",
                        align = (:center, :bottom), offset = (0, 10))
                end
                hidedecorations!(ax)
                fig
                """
            ),
        ],
        :joinstyle => [
            Example(
                code = """                    
                fig = Figure()
                ax = Axis(fig[1, 1], yautolimitmargin = (0.05, 0.15))
                hidedecorations!(ax)

                joinstyles = [:miter, :bevel, :round]
                for (i, joinstyle) in enumerate(joinstyles)
                    x = (1:3) .+ 5 * (i - 1)
                    ys = [[0.5, 3.5, 0.5], [3, 5, 3], [5, 6, 5], [6.5, 7, 6.5]]
                    for y in ys
                        lines!(ax, x, y; linewidth = 15, joinstyle, color = :black)
                    end
                    text!(ax, x[2], ys[end][2], text = ":\$joinstyle",
                        align = (:center, :bottom), offset = (0, 15), font = :bold)
                end

                text!(ax, 4.5, 4.5, text = "for angles\nbelow miter_limit,\n:miter == :bevel",
                    align = (:center, :center))

                fig
                """
            ),
        ],
        :linecap => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2), xautolimitmargin = (0.2, 0.2))
                hidedecorations!(ax)

                linecaps = [:butt, :square, :round]
                for (i, linecap) in enumerate(linecaps)
                    lines!(ax, [i, i]; color = :tomato, linewidth = 15, linecap)
                    lines!(ax, [i, i]; color = :black, linewidth = 15, linecap = :butt)
                    text!(1.5, i, text = ":\$linecap", font = :bold,
                        align = (:center, :bottom), offset = (0, 15))
                end
                fig
                """
            ),
        ],
        :color => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
                hidedecorations!(ax)

                lines!(ax, 1:9, iseven.(1:9) .- 0; color = :tomato)
                lines!(ax, 1:9, iseven.(1:9) .- 1; color = (:tomato, 0.5))
                lines!(ax, 1:9, iseven.(1:9) .- 2; color = 1:9)
                lines!(ax, 1:9, iseven.(1:9) .- 3; color = 1:9, colormap = :plasma)
                lines!(ax, 1:9, iseven.(1:9) .- 4; color = RGBf.(0, (0:8) ./ 8, 0))
                fig
                """
            ),
        ],
        :linewidth => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2), xautolimitmargin = (0.1, 0.1))
                hidedecorations!(ax)

                for linewidth in 1:10
                    lines!(ax, iseven.(1:9) .+ linewidth, 1:9; color = :black, linewidth)
                    text!(ax, linewidth + 0.5, 9; text = "\$linewidth", font = :bold,
                        align = (:center, :bottom), offset = (0, 15))
                end
                fig
                """
            ),
        ],
    )
end
