cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates, CairoMakie

include("benchmark-library.jl")


function create_project_info(branch)
    project = "current-pr-project/"
    # It seems, that between julia versions, the manifest must be deleted to not get problems
    isdir(project) && rm(project; force=true, recursive=true)
    mkdir(project)
    cd("../../") do
        println("######################")
        run(`git status`)
        run(`git checkout $(branch)`)
        run(`git status`)
    end
    Pkg.activate(project)
    pkgs = [(;path="../../MakieCore"), (;path="../../"), (;path="../../CairoMakie")]
    if branch in ["sd/better-cm-draw", "sd/no-static-arrays"]
        println("checking out GeometryBasics as well")
        push!(pkgs, (;path="../../../GeometryBasics"))
    end
    @show string(current_commit())
    Pkg.develop(pkgs)
    this_pr = BenchInfo(
        project=project,
        branch=branch,
        commit=string(current_commit())
    )
    Pkg.activate(".")
    return this_pr
end



ctx = github_context()

branches = ["sd/better-cm-draw", "sd/no-static-arrays", "master", "sd/remove-lift", "sd/replace-attribute-theme"]
for branch in branches
    create_project_info(branch)
end

i1 = BenchInfo(commit="444eae5ce174d23d53c181144b357382bd57afa8", branch="julia1.9+this-pr")
i2 = BenchInfo(commit="7ccf35e789fccdda2429b39b6b10f4e91adcc5fd", branch="julia1.9+no-static-arrays")
i3 = BenchInfo(commit="f04ea93cde4384bad3f008bddf291a15ac35774a", branch="julia1.7+more-precompiles")
i4 = BenchInfo(commit="4a127bfd8dee589bbc3c2da1c91573a73752f36c", branch="julia1.7+v0.16.5")
i5 = BenchInfo(commit="7841b37e84921c4be8ec028b6aeb6cd12c036650", branch="master-yesterday")


plot_url = run_benchmarks(ctx, [i2, i1])
