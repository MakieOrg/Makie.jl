using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using Statistics, GitHub, Printf, BenchmarkTools, Markdown
using BenchmarkTools.JSON
Package = ARGS[1]
@info("Benchmarking $(Package)")

COMMENT_TEMPLATE = """
## Compile Times benchmark

Note, that these numbers may fluctuate on the CI servers, so take them with a grain of salt.
All benchmark results are based on the mean time and negative percent mean faster than master.
Note, that GLMakie + WGLMakie run on an emulated GPU, so the runtime benchmark is much slower.
Results are from running:

```julia
using_time = @ctime using Backend
# Compile time
create_time = @ctime fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @ctime Makie.colorbuffer(display(fig))
# Runtime
create_time = @benchmark fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @benchmark Makie.colorbuffer(display(fig))
```

|               | using     | create   | display  | create   | display  |
|--------------:|:----------|:---------|:---------|:---------|:---------|
| GLMakie       | --        | --       | --       | --       | --       |
| master        | --        | --       | --       | --       | --       |
| evaluation    | --        | --       | --       | --       | --       |
| CairoMakie    | --        | --       | --       | --       | --       |
| master        | --        | --       | --       | --       | --       |
| evaluation    | --        | --       | --       | --       | --       |
| WGLMakie      | --        | --       | --       | --       | --       |
| master        | --        | --       | --       | --       | --       |
| evaluation    | --        | --       | --       | --       | --       |
"""

function github_context()
    owner = "JuliaPlots"
    return (
        owner = owner,
        repo = GitHub.Repo("$(owner)/Makie.jl"),
        auth = GitHub.authenticate(ENV["GITHUB_TOKEN"]),
        scratch_repo = GitHub.Repo("MakieOrg/scratch")
    )
end

function best_unit(m)
    if m < 1e3
        return 1, "ns"
    elseif m < 1e6
        return 1e3, "μs"
    elseif m < 1e9
        return 1e6, "ms"
    else
        return 1e9, "s"
    end
end

function analyze(pr, master)
    f, unit = best_unit(pr[1])
    method = length(pr) > 100 ? minimum : median
    pr_res = method(Float64.(pr) ./ f)
    master_res = method(Float64.(master) ./ f)
    percent = (1 - pr_res / master_res) * 100
    result = if abs(percent) < 2
        "*invariant*"
    else
        percent > 0 ? "**worse**❌" : "**improvement**✅"
    end
    return @sprintf("%s: %s%.2f%s, %s", string(method), percent > 0 ? "+" : "-", abs(percent), "%", result)
end


function summarize_stats(timings)
    m = median(timings)
    f, unit = best_unit(m)
    mini = minimum(timings ./ f)
    maxi = maximum(timings ./ f)
    s = std(timings ./ f)
    @sprintf("%.2f%s (%.2f, %.2f) %.2f+-", m / f, unit, mini, maxi, s)
end

function get_row_values(results_pr, results_m)
    master_row = []
    pr_row = []
    evaluation_row = []
    n = length(results_pr)
    for i in 1:n
        push!(pr_row, summarize_stats(results_pr[i]))
        push!(master_row, summarize_stats(results_m[i]))
        push!(evaluation_row, analyze(results_pr[i], results_m[i]))
    end

    return pr_row, master_row, evaluation_row
end

function update_comment(old_comment, package_name, (pr_bench, master_bench, evaluation))
    md = Markdown.parse(old_comment)
    rows = md.content[end].rows
    idx = findfirst(rows) do row
        cell = first(row)
        isempty(cell) && return false
        return first(cell) == package_name
    end
    if isnothing(idx)
        @warn("Could not find $package_name in $(md). Not updating benchmarks")
        return old_comment
    end
    for (i, value) in enumerate(pr_bench)
        rows[idx][i + 1] = [value]
    end
    for (i, value) in enumerate(master_bench)
        rows[idx + 1][i + 1] = [value]
    end
    for (i, value) in enumerate(evaluation)
        rows[idx + 2][i + 1] = [value]
    end
    return sprint(show, md)
end

function make_or_edit_comment(ctx, pr, package_name, benchmarks)
    prev_comments, _ = GitHub.comments(ctx.repo, pr; auth=ctx.auth)
    idx = findfirst(c-> c.user.login == "MakieBot", prev_comments)
    if isnothing(idx)
        comment = update_comment(COMMENT_TEMPLATE, package_name, benchmarks)
        println(comment)
        GitHub.create_comment(ctx.repo, pr; auth=ctx.auth, params=Dict("body"=>comment))
    else
        old_comment = prev_comments[idx].body
        comment = update_comment(old_comment, package_name, benchmarks)
        println(comment)
        GitHub.edit_comment(ctx.repo, prev_comments[idx], :pr; auth=ctx.auth, params=Dict("body" => comment))
    end
end

function run_benchmarks(projects; n=10)
    benchmark_file = joinpath(@__DIR__, "benchmark-ttfp.jl")
    for project in repeat(projects; outer=n)
        run(`$(Base.julia_cmd()) --startup-file=no --project=$(project) $benchmark_file $Package`)
        project_name = basename(project)
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

function load_results(name)
    result = "$name-benchmark.json"
    return JSON.parse(read(result, String))
end

ctx = try
    github_context()
catch e
   @warn "Not authorized" exception=e
   # bad credentials because PR isn't from a contributor
   exit()
end

ENV["JULIA_PKG_PRECOMPILE_AUTO"] = 0

project1 = make_project_folder("current-pr")
Pkg.activate(project1)
pkgs = [(; path="./MakieCore"), (; path="."), (; path="./$Package"), (;name="BenchmarkTools")]
Package == "WGLMakie" && push!(pkgs, (; name="ElectronDisplay"))
Pkg.develop(pkgs)
@time Pkg.precompile()

project2 = make_project_folder("makie-master")
Pkg.activate(project2)
pkgs = [(; rev="master", name="MakieCore"), (; rev="master", name="Makie"), (; rev="master", name="$Package"), (;name="BenchmarkTools")]
Package == "WGLMakie" && push!(pkgs, (; name="ElectronDisplay"))
Pkg.add(pkgs)
@time Pkg.precompile()

projects = [project1, project2]

run_benchmarks(projects)

results_pr = load_results(basename(project1))
results_m = load_results(basename(project2))
benchmark_rows = get_row_values(results_pr, results_m)

pr_to_comment = get(ENV, "PR_NUMBER", nothing)
pr_to_comment = 2026#get(ENV, "PR_NUMBER", nothing)

if !isnothing(pr_to_comment)
    pr = GitHub.pull_request(ctx.repo, pr_to_comment)
    make_or_edit_comment(ctx, pr, Package, benchmark_rows)
else
    @info("Not commenting, no PR found")
    println(update_comment(COMMENT_TEMPLATE, Package, benchmark_rows))
end
