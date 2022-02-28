cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates, CairoMakie

include("benchmark-library.jl")

ctx = try
     github_context()
catch e
    @warn "Not authorized" exception=e
    # bad credentials because PR isn't from a contributor
    exit()
end

project = "current-pr-project/"
# It seems, that between julia versions, the manifest must be deleted to not get problems
isdir(project) && rm(project; force=true, recursive=true)
mkdir(project)

Pkg.activate(project)
Pkg.develop([(;path="../../MakieCore"), (;path="../../"), (;path="../../CairoMakie")])
this_pr = BenchInfo(
    project=project,
    branch="current-pr",
    commit=current_commit()
)

Pkg.activate(".")

fig = run_benchmarks(ctx, [GitHub.branch(ctx.repo, "master"), this_pr]; force=true, n=5)
