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


i1 = BenchInfo(commit="444eae5ce174d23d53c181144b357382bd57afa8")
i2 = BenchInfo(commit="7ccf35e789fccdda2429b39b6b10f4e91adcc5fd")
plot_url = run_benchmarks(ctx, [i2, i1])
