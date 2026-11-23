function attribute_groups(::Type{Legend})
    groups = default_block_attribute_groups()

    attr = documented_attributes(Legend)
    str_keys = string.(keys(attr))
    title = filter(k -> startswith(k, "title"), str_keys)
    label = filter(k -> startswith(k, "label"), str_keys)
    inner_layout = [:padding, :margin, :nbanks, :colgap, :rowgap, :patchlabelgap, :groupgap, :gridshalign, :gridsvalign]

    # MarkerELement Attributes
    line = [:linepoints, :linewidth, :linecolor, :linecolormap, :linecolorrange, :linestyle, :linecap, :joinstyle]
    marker = [:markercolor, :markercolormap, :markercolorrange, :marker, :markerpoints, :markersize, :markerstrokewidth, :markerstrokecolor]
    poly = [:polypoints, :polystrokewidth, :polycolor, :polystrokecolor, :polycolormap, :polycolorrange]
    mesh = [:mesh, :meshcolor, :meshcolormap, :meshcolorrange]
    surface = [:surfacedata, :surfacevalues, :surfacecolormap, :surfacecolorrange]
    image = [:imagelimits, :imagevalues, :imagecolorrange]
    heatmap = [:heatmaplimits, :heatmapvalues, :heatmapcolorrange]
    meshscatter = [:meshscattercolor, :meshscattercolormap, :meshscattercolorrange, :meshscattermarker, :meshscatterpoints, :meshscattersize, :meshscatterrotation]

    push!(
        groups,
        "Line Element Attributes" => sort!(line),
        "Marker Element Attributes" => sort!(marker),
        "Poly Element Attributes" => sort!(poly),
        "Mesh Element Attributes" => sort!(mesh),
        "Surface Element Attributes" => sort!(surface),
        "Image Element Attributes" => sort!(image),
        "Heatmap Element Attributes" => sort!(heatmap),
        "Meshscatter Element Attributes" => sort!(meshscatter),
        "Inner Layout Attributes" => sort!(inner_layout),
        "Title Attributes" => Symbol.(sort!(title)),
        "Label Attributes" => Symbol.(sort!(label)),
    )

    return groups
end

function attribute_examples(::Type{Legend})
    return Dict(
        :colgap => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                Legend(fig[1, 2], ax, "Default", nbanks = 2)
                Legend(fig[1, 3], ax, "colgap = 40", nbanks = 2, colgap = 40)
                fig
                """
            ),
        ],
        :groupgap => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lin = lines!(ax, 1:10, linestyle = :dash)
                pol = poly!(ax, [(5, 0), (10, 0), (7.5, 5)])
                sca = scatter!(ax, 4:13)
                Legend(fig[1, 2],
                    [[lin], [pol], [sca]],
                    [["Line"], ["Poly"], ["Scatter"]],
                    ["Default", "Group 2", "Group 3"];

                )
                Legend(fig[1, 3],
                    [[lin], [pol], [sca]],
                    [["Line"], ["Poly"], ["Scatter"]],
                    ["groupgap = 30", "Group 2", "Group 3"];
                    groupgap = 30,
                )
                fig
                """
            ),
        ],
        :patchsize => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                Legend(fig[1, 2], ax, "Default")
                Legend(fig[1, 3], ax, "(40, 20)", patchsize = (40, 20))
                fig
                """
            ),
        ],
        :patchlabelgap => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                Legend(fig[1, 2], ax, "Default")
                Legend(fig[1, 3], ax, "patchlabelgap\n= 20", patchlabelgap = 20)
                fig
                """
            ),
        ],
        :orientation => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                Legend(fig[2, 1], ax, "orientation\n= :horizontal", orientation = :horizontal)
                Legend(fig[1, 2], ax, "orientation\n= :vertical", orientation = :vertical)
                fig
                """
            ),
        ],
        :nbanks => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                grid = GridLayout(fig[1, 2], tellheight = false)
                Legend(grid[1, 1], ax, "nbanks = 1", nbanks = 1, tellheight = true)
                Legend(grid[1, 2], ax, "nbanks = 2", nbanks = 2, tellheight = true)
                Legend(grid[2, :], ax, "nbanks = 3", nbanks = 3, tellheight = true)
                fig
                """
            ),
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                grid = GridLayout(fig[2, 1], tellwidth = false)
                Legend(grid[1, 1], ax, "nbanks = 1", nbanks = 1,
                    orientation = :horizontal, tellwidth = true)
                Legend(grid[2, 1], ax, "nbanks = 2", nbanks = 2,
                    orientation = :horizontal, tellwidth = true)
                Legend(grid[:, 2], ax, "nbanks = 3", nbanks = 3,
                    orientation = :horizontal, tellwidth = true)
                fig
                """
            ),
        ],
        :titleposition => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                Legend(fig[1, 2], ax, "titleposition\n= :top", titleposition = :top)
                Legend(fig[1, 3], ax, "titleposition\n= :left", titleposition = :left)
                fig
                """
            ),
        ],
        :rowgap => [
            Example(
                code = """
                fig = Figure()
                ax = Axis(fig[1, 1])
                lines!(ax, 1:10, linestyle = :dash, label = "Line")
                poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                scatter!(ax, 4:13, label = "Scatter")
                Legend(fig[1, 2], ax, "Default")
                Legend(fig[1, 3], ax, "rowgap = 10", rowgap = 10)
                fig
                """
            ),
        ],
    )
end
