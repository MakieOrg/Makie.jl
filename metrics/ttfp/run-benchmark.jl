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

|               | using     | ttfp     | runtime  |
|--------------:|:----------|:---------|:---------|
| PR GLMakie    | --        | --       | --       |
|    master     | --        | --       | --       |
| PR CairoMakie | --        | --       | --       |
|    master     | --        | --       | --       |
| PR WGLMakie   | --        | --       | --       |
|    master     | --        | --       | --       |
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

function prettytime(trial)
    t = time(median(trial))
    # Taken from Benchmarktools, since we only want two digits
    if t < 1e3
        value, units = t, "ns"
    elseif t < 1e6
        value, units = t / 1e3, "μs"
    elseif t < 1e9
        value, units = t / 1e6, "ms"
    else
        value, units = t / 1e9, "s"
    end
    return string(@sprintf("%.2f", value), units)
end

function speedup(t1, t2)
    t = judge(median(t2), median(t1))
    return sprint() do io
        print(io, prettytime(t2), " ", BenchmarkTools.prettydiff(time(ratio(t))), " ")
        if t.time == :invariant
            print(io, "**invariant**")
        elseif t.time == :improvement
            print(io, "**improvement** :)")
        else
            print(io, "**worse**")
        end
    end
end

function get_row_values(results_pr, results_m)
    master_row = []
    pr_row = []
    n = length(results_pr)
    for i in 1:n
        push!(pr_row, speedup(results_m[i], results_pr[i]))
        push!(master_row, prettytime(results_m[i]))
    end

    return pr_row, master_row
end

function update_comment(old_comment, package_name, pr_bench, master_bench)
    md = Markdown.parse(old_comment)
    rows = md.content[end].rows
    idx = findfirst(rows) do row
        cell = first(row)
        isempty(cell) && return false
        return first(cell) == "PR " * package_name
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
    return sprint(show, md)
end

function make_or_edit_comment(ctx, pr, package_name, pr_bench, master_bench)
    prev_comments, _ = GitHub.comments(ctx.repo, pr; auth=ctx.auth)
    idx = findfirst(c-> c.user.login == "MakieBot", prev_comments)
    if isnothing(idx)
        comment = update_comment(COMMENT_TEMPLATE, package_name, pr_bench, master_bench)
        println(comment)
        GitHub.create_comment(ctx.repo, pr; auth=ctx.auth, params=Dict("body"=>comment))
    else
        old_comment = prev_comments[idx].body
        comment = update_comment(old_comment, package_name, pr_bench, master_bench)
        println(comment)
        GitHub.edit_comment(ctx.repo, prev_comments[idx], :pr; auth=ctx.auth, params=Dict("body" => comment))
    end
end

function run_benchmarks(projects; n=7)
    benchmark_file = joinpath(@__DIR__, "benchmark-ttfp.jl")
    for project in repeat(projects; outer=n)
        run(`$(Base.julia_cmd()) --startup-file=no --project=$(project) $benchmark_file $Package`)
        project_name = basename(project)
    end
    return
end

function create_trial(numbers)
    params = BenchmarkTools.Parameters(gctrial=false, gcsample=false, evals=length(numbers))
    trial = BenchmarkTools.Trial(params)
    for number in numbers
        push!(trial, number * 1e9, 0, 0, 0)
    end
    return trial
end

function make_project_folder(name)
    project = joinpath(@__DIR__, "benchmark-projects", name)
    # It seems, that between julia versions, the manifest must be deleted to not get problems
    isdir(project) && rm(project; force=true, recursive=true)
    mkpath(project)
    return project
end

function load_results(name)
    result = "$name-ttfp-result.json"
    runtime_file = "$name-runtime-result.json"
    runtime = BenchmarkTools.load(runtime_file)[1]
    ttfp = JSON.parse(read(result, String))
    return [create_trial(first.(ttfp)), create_trial(last.(ttfp)), runtime]
end

ctx = try
    github_context()
catch e
   @warn "Not authorized" exception=e
   # bad credentials because PR isn't from a contributor
   exit()
end

project1 = make_project_folder("current-pr")
Pkg.activate(project1)
pkgs = [(; path="./MakieCore"), (; path="."), (; path="./$Package"), (;name="BenchmarkTools")]
Package == "WGLMakie" && push!(pkgs, (; name="ElectronDisplay"))
Pkg.develop(pkgs)
precompile_pr = @elapsed Pkg.precompile()

project2 = make_project_folder("makie-master")
Pkg.activate(project2)
pkgs = [(; rev="master", name="MakieCore"), (; rev="master", name="Makie"), (; rev="master", name="$Package"), (;name="BenchmarkTools")]
Package == "WGLMakie" && push!(pkgs, (; name="ElectronDisplay"))
Pkg.add(pkgs)
precompile_master = @elapsed Pkg.precompile()

projects = [project1, project2]

run_benchmarks(projects)

results_pr = load_results(basename(project1))
results_m = load_results(basename(project2))

pr_bench, master_bench = get_row_values(results_pr, results_m)
println(update_comment(COMMENT_TEMPLATE, Package, pr_bench, master_bench))

pr_to_comment = get(ENV, "PR_NUMBER", nothing)

if !isnothing(pr_to_comment)
    pr = GitHub.pull_request(ctx.repo, pr_to_comment)
    make_or_edit_comment(ctx, pr, Package, pr_bench, master_bench)
else
    @info("Not commenting, no PR found")
end
