function attribute_groups(::Type{Axis})
    groups = default_block_attribute_groups()

    attr = documented_attributes(Axis)
    str_keys = string.(keys(attr))
    title = filter(k -> startswith(k, "title"), str_keys)
    subtitle = filter(k -> startswith(k, "subtitle"), str_keys)
    xlabel = filter(k -> startswith(k, "xlabel"), str_keys)
    ylabel = filter(k -> startswith(k, "ylabel"), str_keys)
    xtick = filter(k -> startswith(k, "xtick"), str_keys)
    ytick = filter(k -> startswith(k, "ytick"), str_keys)
    xgrid = filter(k -> startswith(k, "xgrid"), str_keys)
    ygrid = filter(k -> startswith(k, "ygrid"), str_keys)
    xminortick = filter(k -> startswith(k, "xminortick"), str_keys)
    yminortick = filter(k -> startswith(k, "yminortick"), str_keys)
    xminorgrid = filter(k -> startswith(k, "xminorgrid"), str_keys)
    yminorgrid = filter(k -> startswith(k, "yminorgrid"), str_keys)
    spine = filter(k -> contains(k, "spine"), str_keys)
    interactive = filter(k -> contains(k, r"key|button|zoom|lock"), str_keys)
    dimconvert = [:dim1_conversion, :dim2_conversion, :x_unit_in_ticklabel, :y_unit_in_ticklabel, :x_unit_in_label, :y_unit_in_label, :xlabel_suffix, :ylabel_suffix]

    # Note xlabel_suffix and ylabel_suffix are in xlabel and ylabel too. They
    # will be associated with the first group in groups.

    push!(
        groups,
        "Dim Convert Attributes" => sort!(dimconvert),
        "Interaction Attributes" => Symbol.(sort!(interactive)),
        "Title Attributes" => Symbol.(sort!(vcat(title, subtitle))),
        "Tick Attributes" => Symbol.(sort!(vcat(xtick, ytick))),
        "Minor Tick Attributes" => Symbol.(sort!(vcat(xminortick, yminortick))),
        "Grid Attributes" => Symbol.(vcat(sort!(xgrid), sort!(ygrid), sort!(xminorgrid), sort!(yminorgrid))),
        "Label Attributes" => Symbol.(sort!(vcat(xlabel, ylabel))),
        "Spine Attributes" => Symbol.(sort!(spine))
    )

    return groups
end

function attribute_examples(::Type{Axis})
    return Dict(
        :xticks => [
            Example(
                code = """
                fig = Figure()
                Axis(fig[1, 1], xticks = 1:10)
                Axis(fig[2, 1], xticks = (1:2:9, ["A", "B", "C", "D", "E"]))
                Axis(fig[3, 1], xticks = WilkinsonTicks(5))
                fig
                """
            ),
        ],
        :yticks => [
            Example(
                code = """
                fig = Figure()
                Axis(fig[1, 1], yticks = 1:10)
                Axis(fig[1, 2], yticks = (1:2:9, ["A", "B", "C", "D", "E"]))
                Axis(fig[1, 3], yticks = WilkinsonTicks(5))
                fig
                """
            ),
        ],
        :aspect => [
            Example(
                code = """
                using FileIO

                f = Figure()

                ax1 = Axis(f[1, 1], aspect = nothing, title = "nothing")
                ax2 = Axis(f[1, 2], aspect = DataAspect(), title = "DataAspect()")
                ax3 = Axis(f[2, 1], aspect = AxisAspect(1), title = "AxisAspect(1)")
                ax4 = Axis(f[2, 2], aspect = AxisAspect(2), title = "AxisAspect(2)")

                img = rotr90(load(assetpath("cow.png")))
                for ax in [ax1, ax2, ax3, ax4]
                    image!(ax, img)
                end

                f
                """
            ),
        ],
        :autolimitaspect => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], autolimitaspect = nothing)
                ax2 = Axis(f[1, 2], autolimitaspect = 1)

                for ax in [ax1, ax2]
                    lines!(ax, 0..10, sin)
                end

                f
                """
            ),
        ],
        :backgroundcolor => [
            Example(
                code = """
                    f = Figure()

                    ax1 = Axis(f[1, 1])
                    ax2 = Axis(f[1, 2], backgroundcolor = :gray80)

                    f
                """
            ),
        ],
        :xautolimitmargin => [
            Example(
                code = """
                    f = Figure()

                    data = 0:1

                    ax1 = Axis(f[1, 1], xautolimitmargin = (0, 0), title = "xautolimitmargin = (0, 0)")
                    ax2 = Axis(f[2, 1], xautolimitmargin = (0.05, 0.05), title = "xautolimitmargin = (0.05, 0.05)")
                    ax3 = Axis(f[3, 1], xautolimitmargin = (0, 0.2), title = "xautolimitmargin = (0, 0.2)")

                    for ax in [ax1, ax2, ax3]
                        lines!(ax, data)
                    end

                    f
                """
            ),
        ],
        :yautolimitmargin => [
            Example(
                code = """
                    f = Figure()

                    data = 0:1

                    ax1 = Axis(f[1, 1], yautolimitmargin = (0, 0), title = "yautolimitmargin = (0, 0)")
                    ax2 = Axis(f[1, 2], yautolimitmargin = (0.05, 0.05), title = "yautolimitmargin = (0.05, 0.05)")
                    ax3 = Axis(f[1, 3], yautolimitmargin = (0, 0.2), title = "yautolimitmargin = (0, 0.2)")

                    for ax in [ax1, ax2, ax3]
                        lines!(ax, data)
                    end

                    f
                """
            ),
        ],
        :xticklabelpad => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], xticklabelpad = 0, title = "xticklabelpad = 0")
                    Axis(f[1, 2], xticklabelpad = 5, title = "xticklabelpad = 5")
                    Axis(f[1, 3], xticklabelpad = 15, title = "xticklabelpad = 15")

                    f
                """
            ),
        ],
        :yticklabelpad => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], yticklabelpad = 0, title = "yticklabelpad = 0")
                    Axis(f[2, 1], yticklabelpad = 5, title = "yticklabelpad = 5")
                    Axis(f[3, 1], yticklabelpad = 15, title = "yticklabelpad = 15")

                    f
                """
            ),
        ],
        :xticklabelspace => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], xlabel = "X Label", xticklabelspace = 0.0, title = "xticklabelspace = 0.0")
                    Axis(f[1, 2], xlabel = "X Label", xticklabelspace = 30.0, title = "xticklabelspace = 30.0")
                    Axis(f[1, 3], xlabel = "X Label", xticklabelspace = Makie.automatic, title = "xticklabelspace = automatic")

                    f
                """
            ),
        ],
        :yticklabelspace => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], ylabel = "Y Label", yticklabelspace = 0.0, title = "yticklabelspace = 0.0")
                    Axis(f[2, 1], ylabel = "Y Label", yticklabelspace = 30.0, title = "yticklabelspace = 30.0")
                    Axis(f[3, 1], ylabel = "Y Label", yticklabelspace = Makie.automatic, title = "yticklabelspace = automatic")

                    f
                """
            ),
        ],
        :xlabelpadding => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], xlabel = "X Label", xlabelpadding = 0, title = "xlabelpadding = 0")
                    Axis(f[1, 2], xlabel = "X Label", xlabelpadding = 5, title = "xlabelpadding = 5")
                    Axis(f[1, 3], xlabel = "X Label", xlabelpadding = 10, title = "xlabelpadding = 10")

                    f
                """
            ),
        ],
        :ylabelpadding => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], ylabel = "Y Label", ylabelpadding = 0, title = "ylabelpadding = 0")
                    Axis(f[2, 1], ylabel = "Y Label", ylabelpadding = 5, title = "ylabelpadding = 5")
                    Axis(f[3, 1], ylabel = "Y Label", ylabelpadding = 10, title = "ylabelpadding = 10")

                    f
                """
            ),
        ],
        :title => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], title = "Title")
                Axis(f[2, 1], title = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], title = rich(
                    "Rich text title",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :titlealign => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], titlealign = :left, title = "Left aligned title")
                Axis(f[2, 1], titlealign = :center, title = "Center aligned title")
                Axis(f[3, 1], titlealign = :right, title = "Right aligned title")

                f
                """
            ),
        ],
        :subtitle => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], title = "Title", subtitle = "Subtitle")
                Axis(f[2, 1], title = "Title", subtitle = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], title = "Title", subtitle = rich(
                    "Rich text subtitle",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :xlabel => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], xlabel = "X Label")
                Axis(f[2, 1], xlabel = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], xlabel = rich(
                    "X Label",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :ylabel => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], ylabel = "Y Label")
                Axis(f[2, 1], ylabel = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], ylabel = rich(
                    "Y Label",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :xtrimspine => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], xtrimspine = false)
                ax2 = Axis(f[2, 1], xtrimspine = true)
                ax3 = Axis(f[3, 1], xtrimspine = (true, false))
                ax4 = Axis(f[4, 1], xtrimspine = (false, true))

                for ax in [ax1, ax2, ax3, ax4]
                    ax.xgridvisible = false
                    ax.ygridvisible = false
                    ax.rightspinevisible = false
                    ax.topspinevisible = false
                    xlims!(ax, 0.5, 5.5)
                end

                f
                """
            ),
        ],
        :ytrimspine => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], ytrimspine = false)
                ax2 = Axis(f[1, 2], ytrimspine = true)
                ax3 = Axis(f[1, 3], ytrimspine = (true, false))
                ax4 = Axis(f[1, 4], ytrimspine = (false, true))

                for ax in [ax1, ax2, ax3, ax4]
                    ax.xgridvisible = false
                    ax.ygridvisible = false
                    ax.rightspinevisible = false
                    ax.topspinevisible = false
                    ylims!(ax, 0.5, 5.5)
                end

                f
                """
            ),
        ],
        :xaxisposition => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], xaxisposition = :bottom)
                Axis(f[1, 2], xaxisposition = :top)

                f
                """
            ),
        ],
        :yaxisposition => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], yaxisposition = :left)
                Axis(f[2, 1], yaxisposition = :right)

                f
                """
            ),
        ],
        :limits => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], limits = (nothing, nothing), title = "(nothing, nothing)")
                ax2 = Axis(f[1, 2], limits = (0, 4pi, -1, 1), title = "(0, 4pi, -1, 1)")
                ax3 = Axis(f[2, 1], limits = ((0, 4pi), nothing), title = "((0, 4pi), nothing)")
                ax4 = Axis(f[2, 2], limits = (nothing, 4pi, nothing, 1), title = "(nothing, 4pi, nothing, 1)")

                for ax in [ax1, ax2, ax3, ax4]
                    lines!(ax, 0..4pi, sin)
                end

                f
                """
            ),
        ],
        :yscale => [
            Example(
                code = """
                f = Figure()

                for (i, scale) in enumerate([identity, log10, log2, log, sqrt, Makie.logit])
                    row, col = fldmod1(i, 3)
                    Axis(f[row, col], yscale = scale, title = string(scale),
                        yminorticksvisible = true, yminorgridvisible = true,
                        yminorticks = IntervalsBetween(5))

                    lines!(range(0.01, 0.99, length = 200))
                end

                f
                """
            ),
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1],
                    yscale = Makie.pseudolog10,
                    title = "Pseudolog scale",
                    yticks = [-100, -10, -1, 0, 1, 10, 100]
                )

                ax2 = Axis(f[2, 1],
                    yscale = Makie.Symlog10(10.0),
                    title = "Symlog10 with linear scaling between -10 and 10",
                    yticks = [-100, -10, 0, 10, 100]
                )

                ax3 = Axis(f[3, 1],
                    yscale = Makie.pseudolog10,
                    title = "Pseudolog scale with automatic decade ticks"
                )

                for ax in [ax1, ax2, ax3]
                    lines!(ax, -100:0.1:100)
                end

                f
                """
            ),
        ],
        :xscale => [
            Example(
                code = """
                f = Figure()

                for (i, scale) in enumerate([identity, log10, log2, log, sqrt, Makie.logit])
                    row, col = fldmod1(i, 2)
                    Axis(f[row, col], xscale = scale, title = string(scale),
                        xminorticksvisible = true, xminorgridvisible = true,
                        xminorticks = IntervalsBetween(5))

                    lines!(range(0.01, 0.99, length = 200), 1:200)
                end

                f
                """
            ),
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1],
                    xscale = Makie.pseudolog10,
                    title = "Pseudolog scale",
                    xticks = [-100, -10, -1, 0, 1, 10, 100]
                )

                ax2 = Axis(f[1, 2],
                    xscale = Makie.Symlog10(10.0),
                    title = "Symlog10 with linear scaling\nbetween -10 and 10",
                    xticks = [-100, -10, 0, 10, 100]
                )

                for ax in [ax1, ax2]
                    lines!(ax, -100:0.1:100, -100:0.1:100)
                end

                f
                """
            ),
        ],
        :xtickformat => [
            Example(
                code = """
                f = Figure(figure_padding = 50)

                Axis(f[1, 1], xtickformat = values -> ["\$(value)kg" for value in values])
                Axis(f[2, 1], xtickformat = "{:.2f}ms")
                Axis(f[3, 1], xtickformat = values -> [L"\\sqrt{%\$(value^2)}" for value in values])
                Axis(f[4, 1], xtickformat = values -> [rich("\$value", superscript("XY", color = :red))
                                                       for value in values])

                f
                """
            ),
        ],
        :ytickformat => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], ytickformat = values -> ["\$(value)kg" for value in values])
                Axis(f[1, 2], ytickformat = "{:.2f}ms")
                Axis(f[1, 3], ytickformat = values -> [L"\\sqrt{%\$(value^2)}" for value in values])
                Axis(f[1, 4], ytickformat = values -> [rich("\$value", superscript("XY", color = :red))
                                                       for value in values])

                f
                """
            ),
        ],
        :xticksmirrored => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], xticksmirrored = false, xminorticksvisible = true)
                Axis(f[1, 2], xticksmirrored = true, xminorticksvisible = true)

                f
                """
            ),
        ],
        :yticksmirrored => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], yticksmirrored = false, yminorticksvisible = true)
                Axis(f[2, 1], yticksmirrored = true, yminorticksvisible = true)

                f
                """
            ),
        ],
        :xminorticks => [
            Example(
                code = """
                f = Figure()

                kwargs = (; xminorticksvisible = true, xminorgridvisible = true)
                Axis(f[1, 1]; xminorticks = IntervalsBetween(2), kwargs...)
                Axis(f[2, 1]; xminorticks = IntervalsBetween(5), kwargs...)
                Axis(f[3, 1]; xminorticks = [1, 2, 3, 4], kwargs...)

                f
                """
            ),
        ],
        :yminorticks => [
            Example(
                code = """
                f = Figure()

                kwargs = (; yminorticksvisible = true, yminorgridvisible = true)
                Axis(f[1, 1]; yminorticks = IntervalsBetween(2), kwargs...)
                Axis(f[1, 2]; yminorticks = IntervalsBetween(5), kwargs...)
                Axis(f[1, 3]; yminorticks = [1, 2, 3, 4], kwargs...)

                f
                """
            ),
        ],
    )
end
