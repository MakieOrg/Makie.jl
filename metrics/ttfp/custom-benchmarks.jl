cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates, CairoMakie

include("benchmark-library.jl")

ctx = github_context()

project = "current-pr-project/"
# It seems, that between julia versions, the manifest must be deleted to not get problems
isdir(project) && rm(project; force=true, recursive=true)
mkdir(project)

Pkg.activate(project)
Pkg.develop([(;path="../../MakieCore"), (;path="../../"), (;path="../../CairoMakie"), (;path="../../../GeometryBasics")])
this_pr = BenchInfo(
    project=project,
    branch="current-pr",
    commit=string(current_commit())
)

Pkg.activate(".")

get_benchmark_data(ctx, this_pr; n=10, force=true)

plot_url = run_benchmarks(ctx, [GitHub.branch(ctx.repo, "master"), this_pr])

i1 = BenchInfo(commit="444eae5ce174d23d53c181144b357382bd57afa8", branch="julia1.9+this-pr")
i2 = BenchInfo(commit="7ccf35e789fccdda2429b39b6b10f4e91adcc5fd", branch="julia1.9+no-static-arrays")
i3 = BenchInfo(julia="julia-1-7-1", commit="f04ea93cde4384bad3f008bddf291a15ac35774a", branch="julia1.7+more-precompiles")
i4 = BenchInfo(julia="julia-1-7-1", commit="4a127bfd8dee589bbc3c2da1c91573a73752f36c", branch="julia1.7+v0.16.5")
i5 = BenchInfo(julia="julia-1-9-0-DEV-5", commit="7841b37e84921c4be8ec028b6aeb6cd12c036650", branch="master-yesterday")

fig = run_benchmarks(ctx, [i4, i3, i5, GitHub.branch(ctx.repo, "master"), i2, i1])

resize!(fig.scene, (1500, 600))
fig
