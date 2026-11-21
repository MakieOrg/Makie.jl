using JSON, AlgebraOfGraphics, CairoMakie, DataFrames
import Bootstrap
using Statistics: median

const SIDES = ["merged", "base"]
const TIMING_STAGES = ["using", "first create", "first display", "create", "display"]
const COUNTER_STAGES = ["using", "first create", "first display"]

function load_results(dir, Package)
    rows = map(SIDES) do side
        map(JSON.parsefile(joinpath(dir, "$Package-$side.json"))) do row
            (; name = side, run = row["run"], stage = row["stage"], quantity = row["quantity"], value = Float64(row["value"]))
        end
    end
    return DataFrame(reduce(vcat, rows))
end

const side_mapping = :name => sorter(SIDES) => ""
const timing_layout = :stage => sorter(TIMING_STAGES)
const seconds = :value => (x -> x / 1.0e9) => "time (s)"
const side_colors = Makie.wong_colors()[1:2]
# 5 timing facets in a landscape 2 × 3 layout, leaving [2, 3] free for a summary panel.
const timing_palette = [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2)]
const timing_axis = (; xticklabelrotation = pi / 4, width = 200, height = 150)

function plot_distributions!(pos, timings)
    spec = data(timings) *
        mapping(side_mapping, seconds, color = side_mapping, layout = timing_layout) *
        visual(RainClouds, orientation = :horizontal, markersize = 5, show_median = false, plot_boxplots = false)
    draw!(pos, spec, scales(Color = (; legend = false, palette = side_colors), Layout = (; palette = timing_palette)); facet = (; linkxaxes = false), axis = timing_axis)

    ratios = map(TIMING_STAGES) do stage
        stage_timings = timings[timings.stage .== stage, :]
        medians = map(SIDES) do side
            values = stage_timings.value[stage_timings.name .== side]
            Bootstrap.straps(Bootstrap.bootstrap(median, values, Bootstrap.BasicSampling(1000)))[1]
        end
        stage => medians[1] ./ medians[2]
    end |> DataFrame

    band_edges = [0.0; 0.8:0.05:1.2; 100.0]
    background_bands = pregrouped([band_edges[1:(end - 1)]], [band_edges[2:end]]) *
        visual(HSpan, color = range(-1, 1, length = 10), colormap = [:green, :white, :tomato], alpha = 0.5)
    all_ratios = reduce(vcat, eachcol(ratios))
    padding = 0.05 * (maximum(all_ratios) - minimum(all_ratios))
    ylimits = (min(0.75, minimum(all_ratios) - padding), max(1.25, maximum(all_ratios) + padding))
    zeroline = pregrouped([1]) * visual(HLines, color = :gray60)
    violins = data(stack(ratios)) *
        mapping(:variable => presorted => "", :value => "Ratios of medians\n$(SIDES[1]) / $(SIDES[2])") *
        visual(Violin, show_median = true, datalimits = extrema)
    draw!(
        pos[2, 3], background_bands + zeroline + violins, axis = (;
            yaxisposition = :right,
            xticklabelrotation = pi / 4,
            title = "Bootstrapped median ratios",
            limits = (nothing, ylimits),
            yticks = WilkinsonTicks(7, k_min = 5),
        )
    )
    return
end

function plot_counters!(pos, counters)
    scaled = transform(counters, [:quantity, :value] => ByRow((q, v) -> q == "alloc" ? v / 2^20 : v) => :value)
    spec = data(scaled) *
        mapping(:value => "", side_mapping, color = side_mapping, row = :quantity => renamer("alloc" => "allocated MiB", "inferred" => "inferred methods"), col = :stage => sorter(COUNTER_STAGES)) *
        visual(Scatter, markersize = 7, alpha = 0.6)
    draw!(pos, spec, scales(Color = (; legend = false, palette = side_colors)); facet = (; linkxaxes = false), axis = (; width = 200, height = 60, xticklabelrotation = pi / 4))
    return
end

function plot_results(df, Package)
    timings = df[df.quantity .== "time", :]
    counters = df[in.(df.quantity, Ref(["alloc", "inferred"])), :]

    fig = Figure()
    sections = [
        "$Package: timings" => pos -> plot_distributions!(pos, timings),
        "Counters" => pos -> plot_counters!(pos, counters),
    ]
    for (i, (title, plot!)) in enumerate(sections)
        Label(fig[2i - 1, 1], title; font = :bold, fontsize = 18, halign = :left, tellwidth = false)
        plot!(fig[2i, 1])
    end
    resize_to_layout!(fig)
    return fig
end
