function attribute_groups(::Type{Axis3})
    groups = default_block_attribute_groups()

    push!(only(groups)[2], :protrusions)

    attr = documented_attributes(Axis3)
    str_keys = string.(keys(attr))
    title = filter(k -> startswith(k, "title"), str_keys)
    subtitle = filter(k -> startswith(k, "subtitle"), str_keys)
    xlabel = filter(k -> startswith(k, "xlabel"), str_keys)
    ylabel = filter(k -> startswith(k, "ylabel"), str_keys)
    zlabel = filter(k -> startswith(k, "zlabel"), str_keys)
    xtick = filter(k -> startswith(k, "xtick"), str_keys)
    ytick = filter(k -> startswith(k, "ytick"), str_keys)
    ztick = filter(k -> startswith(k, "ztick"), str_keys)
    xgrid = filter(k -> startswith(k, "xgrid"), str_keys)
    ygrid = filter(k -> startswith(k, "ygrid"), str_keys)
    zgrid = filter(k -> startswith(k, "zgrid"), str_keys)
    xminortick = filter(k -> startswith(k, "xminortick"), str_keys)
    yminortick = filter(k -> startswith(k, "yminortick"), str_keys)
    zminortick = filter(k -> startswith(k, "zminortick"), str_keys)
    xminorgrid = filter(k -> startswith(k, "xminorgrid"), str_keys)
    yminorgrid = filter(k -> startswith(k, "yminorgrid"), str_keys)
    zminorgrid = filter(k -> startswith(k, "zminorgrid"), str_keys)
    panel = filter(k -> contains(k, "panel"), str_keys)
    spine = filter(k -> contains(k, "spine"), str_keys)
    interactive = filter(k -> contains(k, r"key|button|zoom|lock"), str_keys)
    push!(interactive, "axis_translation_mod")
    dimconvert = [
        :dim1_conversion, :dim2_conversion, :dim3_conversion,
        :x_unit_in_ticklabel, :y_unit_in_ticklabel, :z_unit_in_ticklabel,
        :x_unit_in_label, :y_unit_in_label, :z_unit_in_label,
        :xlabel_suffix, :ylabel_suffix, :zlabel_suffix,
    ]

    # Note xlabel_suffix and ylabel_suffix are in xlabel and ylabel too. They
    # will be associated with the first group in groups.

    push!(
        groups,
        "Dim Convert Attributes" => sort!(dimconvert),
        "Interaction Attributes" => Symbol.(sort!(interactive)),
        "Title Attributes" => Symbol.(sort!(vcat(title, subtitle))),
        "Tick Attributes" => Symbol.(sort!(vcat(xtick, ytick, ztick))),
        "Minor Tick Attributes" => Symbol.(sort!(vcat(xminortick, yminortick, zminortick))),
        "Grid Attributes" => Symbol.(vcat(sort!(xgrid), sort!(ygrid), sort!(zgrid), sort!(xminorgrid), sort!(yminorgrid), sort!(zminorgrid))),
        "Label Attributes" => Symbol.(sort!(vcat(xlabel, ylabel, zlabel))),
        "Spine Attributes" => Symbol.(sort!(spine)),
        "Panel Attributes" => Symbol.(sort!(panel))
    )

    return groups
end


function attribute_examples(::Type{Axis3})
    return Dict(
        :aspect => [
            Example(
                code = """
                fig = Figure()

                Axis3(fig[1, 1], aspect = (1, 1, 1), title = "aspect = (1, 1, 1)")
                Axis3(fig[1, 2], aspect = (2, 1, 1), title = "aspect = (2, 1, 1)")
                Axis3(fig[2, 1], aspect = (1, 2, 1), title = "aspect = (1, 2, 1)")
                Axis3(fig[2, 2], aspect = (1, 1, 2), title = "aspect = (1, 1, 2)")

                fig
                """
            ),
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], aspect = :equal, title = "aspect = :equal")
                ax2 = Axis3(fig[1, 2], aspect = :data, title = "aspect = :data")

                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = :gray80)
                end

                fig
                """
            ),
        ],
        :viewmode => [
            Example(
                code = """
                fig = Figure()

                for (i, viewmode) in enumerate([:fit, :fitzoom, :stretch])
                    for (j, elevation) in enumerate([0.1, 0.2, 0.3] .* pi)

                        Label(fig[i, 1:3, Top()], "viewmode = \$(repr(viewmode))", font = :bold)

                        # show the extent of each cell using a box
                        Box(fig[i, j], strokewidth = 0, color = :gray95)

                        ax = Axis3(fig[i, j]; viewmode, elevation, protrusions = 0, aspect = :equal)
                        hidedecorations!(ax)

                    end
                end

                fig
                """
            ),
        ],
        :perspectiveness => [
            Example(
                code = """
                fig = Figure()

                for (i, perspectiveness) in enumerate(range(0, 1, length = 6))
                    ax = Axis3(fig[fldmod1(i, 3)...]; perspectiveness, protrusions = (0, 0, 0, 15),
                        title = ":perspectiveness = \$(perspectiveness)")
                    hidedecorations!(ax)
                end

                fig
                """
            ),
        ],
        :azimuth => [
            Example(
                code = """
                fig = Figure()

                for (i, azimuth) in enumerate([0, 0.1, 0.2, 0.3, 0.4, 0.5])
                    Axis3(fig[fldmod1(i, 3)...], azimuth = azimuth * pi,
                        title = "azimuth = \$(azimuth)π", viewmode = :fit)
                end

                fig
                """
            ),
        ],
        :elevation => [
            Example(
                code = """
                fig = Figure()

                for (i, elevation) in enumerate([0, 0.05, 0.1, 0.15, 0.2, 0.25])
                    Axis3(fig[fldmod1(i, 3)...], elevation = elevation * pi,
                        title = "elevation = \$(elevation)π", viewmode = :fit)
                end

                fig
                """
            ),
        ],
        :xreversed => [
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], title = "xreversed = false")
                ax2 = Axis3(fig[2, 1], title = "xreversed = true", xreversed = true)
                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = getindex.(brain.position, 1))
                end

                fig
                    """
            ),
        ],
        :yreversed => [
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], title = "yreversed = false")
                ax2 = Axis3(fig[2, 1], title = "yreversed = true", yreversed = true)
                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = getindex.(brain.position, 2))
                end

                fig
                """
            ),
        ],
        :zreversed => [
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], title = "zreversed = false")
                ax2 = Axis3(fig[2, 1], title = "zreversed = true", zreversed = true)
                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = getindex.(brain.position, 3))
                end

                fig
                """
            ),
        ],
        :protrusions => [
            Example(
                code = """
                    fig = Figure(backgroundcolor = :gray97)
                    Box(fig[1, 1], strokewidth = 0) # visualizes the layout cell
                    Axis3(fig[1, 1], protrusions = 100, viewmode = :stretch,
                        title = "protrusions = 100")
                    fig
                """
            ),
            Example(
                code = """
                    fig = Figure(backgroundcolor = :gray97)
                    Box(fig[1, 1], strokewidth = 0) # visualizes the layout cell
                    ax = Axis3(fig[1, 1], protrusions = (0, 0, 0, 20), viewmode = :stretch,
                        title = "protrusions = (0, 0, 0, 20)")
                    hidedecorations!(ax)
                    fig
                """
            ),
        ]
    )
end
