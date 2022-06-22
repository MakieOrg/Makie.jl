#= TODOs
1) Use one GH-Action job in the end to merge all results and comment in one go (instead of merging with existing comment)
2) Improve analysis of benchmark resutls to account for the variance in the benchmarks.
3) Upload raw benchmark data as artifacts to e.g. create plots from It
=#

using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using Statistics, GitHub, Printf, BenchmarkTools, Markdown, HypothesisTests
using BenchmarkTools.JSON
Package = ARGS[1]
n_samples = length(ARGS) > 1 ? parse(Int, ARGS[2]) : 7
base_branch = length(ARGS) > 2 ? ARGS[3] : "master"

# Package = "CairoMakie"
# n_samples = 2
# base_branch = "breaking-release"

@info("Benchmarking $(Package) against $(base_branch) with $(n_samples)")

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

function cohen_d(x, y)
    nx = length(x); ny = length(y)
    ddof = nx + ny - 2
    poolsd = sqrt(((nx - 1) * var(x) + (ny - 1) * var(y)) / ddof)
    d = (mean(x) - mean(y)) / poolsd
end

function analyze(pr, master)
    f, unit = best_unit(pr[1])
    pr, master = Float64.(pr) ./ f, Float64.(master) ./ f
    tt = UnequalVarianceTTest(pr, master)
    d = cohen_d(pr, master)
    std_p = (std(pr) + std(master)) / 2
    m_pr = mean(pr)
    m_m = mean(master)
    mean_diff = mean(m_pr) - mean(m_m)
    percent = (1 - (m_m / m_pr)) * 100
    p = pvalue(tt)
    mean_diff_str = string(round(mean_diff; digits=2), unit)

    result = if p < 0.05
        if abs(d) > 0.2
            s = abs(percent) < 5 ? ["✓", "X"] : ["✅", "❌"]
            d < 0 ? "**faster**$(s[1])" : "**worse**$(s[2])"
        else
            "*invariant*"
        end
    else
        if abs(percent) < 5
            "*invariant*"
        else
            "*noisy*🤷‍♀️"
        end
    end

    return @sprintf("%s%.2f%s, %s %s (%.2fd, %.2fp, %.2fstd)", percent > 0 ? "+" : "-", abs(percent), "%", mean_diff_str, result, d, p, std_p)
end

function summarize_stats(timings)
    f, unit = best_unit(timings[1])
    m = mean(timings) / f
    mini = minimum(timings) /  f
    maxi = maximum(timings) / f
    s = std(timings) / f
    @sprintf("%.2f%s (%.2f, %.2f) %.2f+-", m, unit, mini, maxi, s)
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

function run_benchmarks(projects; n=n_samples)
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
# cd("dev/Makie")
Pkg.develop(pkgs)
@time Pkg.precompile()

project2 = make_project_folder(base_branch)
Pkg.activate(project2)
pkgs = [(; rev=base_branch, name="MakieCore"), (; rev=base_branch, name="Makie"), (; rev=base_branch, name="$Package"), (;name="BenchmarkTools")]
Package == "WGLMakie" && push!(pkgs, (; name="ElectronDisplay"))
Pkg.add(pkgs)
@time Pkg.precompile()

projects = [project1, project2]

run_benchmarks(projects)

results_pr = load_results(basename(project1))
results_m = load_results(basename(project2))
benchmark_rows = get_row_values(results_pr, results_m)

pr_to_comment = get(ENV, "PR_NUMBER", nothing)

if !isnothing(pr_to_comment)
    pr = GitHub.pull_request(ctx.repo, pr_to_comment)
    make_or_edit_comment(ctx, pr, Package, benchmark_rows)
else
    @info("Not commenting, no PR found")
    println(update_comment(COMMENT_TEMPLATE, Package, benchmark_rows))
end
