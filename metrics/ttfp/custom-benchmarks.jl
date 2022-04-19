using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates, CairoMakie

include("benchmark-library.jl")

ctx = github_context()

projects = [
    "MakieDev" => "prio-obs-precompiles",
    "Latency" => "prio-obs-more",
    # "MakieMesh" => "mesh-precompiles",
    "MakieCompiled" => "moah-precompiles]",
    # "MakieMaster" => "master",
    # "MakieAttributes" => "attribute-precompiles",
    # "MakieBlock" => "blocks-precompile",
]
using Pkg

for (name, _) in projects
    Pkg.activate(joinpath(raw"D:\Projects", name))
    Pkg.update()
end

infos = map(projects) do (name, branch)
    return BenchInfo(
        project=joinpath(raw"D:\Projects", name),
        branch=branch,
        commit=branch * "-desktop-1.9"
    )
end
to_benchmark = [GitHub.tag(ctx.repo, "v0.16.3"), infos...]

bench_infos = bench_info.(Ref(ctx), to_benchmark)
benchmarks = get_benchmark_data.(Ref(ctx), bench_infos; force=true)
plot_benchmarks(benchmarks, bench_infos)
map(x-> last.(x["results"]) |> minimum, benchmarks) |> findmin

bench_infos[4]
