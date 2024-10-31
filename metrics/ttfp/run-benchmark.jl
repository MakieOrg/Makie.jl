#= TODOs
1) Use one GH-Action job in the end to merge all results and comment in one go (instead of merging with existing comment)
2) Improve analysis of benchmark resutls to account for the variance in the benchmarks.
3) Upload raw benchmark data as artifacts to e.g. create plots from It
=#

using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
pkg"registry up"
Pkg.update()

using JSON, AlgebraOfGraphics, CairoMakie, DataFrames, Bootstrap
using Statistics: median
Package = ARGS[1]
n_samples = length(ARGS) > 1 ? parse(Int, ARGS[2]) : 7
base_branch = length(ARGS) > 2 ? ARGS[3] : "master"

# Package = "CairoMakie"
# n_samples = 2
# base_branch = "breaking-release"

@info("Benchmarking $(Package) against $(base_branch) with $(n_samples) samples")


function run_benchmarks(projects; n=n_samples)
    benchmark_file = joinpath(@__DIR__, "benchmark-ttfp.jl")
    # go A, B, A, B, A, etc.
    for project in repeat(projects, n)
        println(basename(project))
        run(`$(Base.julia_cmd()) --startup-file=no --project=$(project) $benchmark_file $Package`)
    end
    return
end

function make_project_folder(name)
    result = "$name-benchmark.json"
    isfile(result) && rm(result) # remove old benchmark resutls
    project = joinpath(@__DIR__, "benchmark-projects", name)
    # It seems, that between julia versions, the manifest must be deleted to not get problems
    isdir(project) && rm(project; force=true, recursive=true)
    mkpath(project)
    return project
end


ENV["JULIA_PKG_PRECOMPILE_AUTO"] = 0
project1 = make_project_folder("current-pr")
Pkg.activate(project1)
if Package == "WGLMakie"
    Pkg.add([(; name="Electron")])
end
pkgs = NamedTuple[(; path="./MakieCore"), (; path="."), (; path="./$Package")]
# cd("dev/Makie")
Pkg.develop(pkgs)
Pkg.add([(; name="JSON")])

@time Pkg.precompile()

project2 = make_project_folder(base_branch)
Pkg.activate(project2)
pkgs = [(; rev=base_branch, name="MakieCore"), (; rev=base_branch, name="Makie"), (; rev=base_branch, name="$Package"), (;name="JSON")]
Package == "WGLMakie" && push!(pkgs, (; name="Electron"))
Pkg.add(pkgs)
@time Pkg.precompile()

projects = [project1, project2]
projnames = map(basename, [project1, project2])

run_benchmarks(projects)

json_files = map(projnames) do pname
    "$(pname)-benchmark.json"
end

colnames = ["using", "first create", "first display", "create", "display"]

df = reduce(vcat, map(json_files, projnames) do filename, pname
        arrs = map(x -> map(identity, x), JSON.parsefile(filename))
        df = DataFrame(colnames .=> arrs)
        df.name .= pname
        df
    end)

##

fgrid = AlgebraOfGraphics.data(df) *
    mapping(:name, colnames .=> (x -> x / 1e9) .=> "time (s)", color = :name, layout = dims(1) => renamer(colnames)) *
    visual(RainClouds, orientation = :horizontal, markersize = 5, show_median = false, plot_boxplots = false) |>
    draw(
        scales(Color = (; legend = false)),
        facet = (; linkxaxes = false),
        axis = (; xticklabelrotation = pi/4, width = 200, height = 150),
        figure = (; title = "$Package Benchmarks")
    )

df_current_pr = df[df.name .== projnames[1], :]
df_base_branch = df[df.name .== projnames[2], :]

medians_df = map(names(df_current_pr, Not(:name))) do colname
    col_base = df_base_branch[!, colname]
    col_pr = df_current_pr[!, colname]
    medians_base = bootstrap(median, col_base, Bootstrap.BasicSampling(1000))
    medians_pr = bootstrap(median, col_pr, Bootstrap.BasicSampling(1000))
    ratios = Bootstrap.straps(medians_pr)[1] ./ Bootstrap.straps(medians_base)[1]
    colname => ratios
end |> DataFrame

specmedians = AlgebraOfGraphics.data(stack(medians_df)) *
    mapping(:variable => presorted => "", :value => "Ratios of medians\n$(projnames[1]) / $(projnames[2])") * visual(Violin, show_median = true)

AlgebraOfGraphics.draw!(fgrid.figure[2, 3], specmedians, axis = (;
    yaxisposition = :right,
    xticklabelrotation = pi/4,
    title = "Bootstrapped median ratios",
    yticks = 0:0.05:2,
))

resize_to_layout!(fgrid.figure)

##

mkpath("benchmark_results")
save(joinpath("benchmark_results", "$Package.svg"), fgrid)
