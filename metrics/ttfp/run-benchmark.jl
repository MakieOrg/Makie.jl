using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using Statistics, GitHub, Printf, BenchmarkTools

function github_context()
    owner = "JuliaPlots"
    return (
        owner = owner,
        repo = GitHub.Repo("$(owner)/Makie.jl"),
        auth = GitHub.authenticate(ENV["GITHUB_TOKEN"]),
        scratch_repo = GitHub.Repo("MakieOrg/scratch")
    )
end

function make_or_edit_comment(ctx, pr, comment)
    prev_comments, _ = GitHub.comments(ctx.repo, pr; auth=ctx.auth)
    idx = findfirst(c-> c.user.login == "MakieBot", prev_comments)
    if isnothing(idx)
        GitHub.create_comment(ctx.repo, pr; auth=ctx.auth, params=Dict("body"=>comment))
    else
        GitHub.edit_comment(ctx.repo, prev_comments[idx], :pr; auth=ctx.auth, params=Dict("body"=>comment))
    end
end

function run_benchmarks(projects; n=7)
    results = Dict{String, Vector{NTuple{2, Float64}}}()
    benchmark_file = joinpath(@__DIR__, "benchmark-ttfp.jl")
    for project in repeat(projects; outer=n)
        result = read(`$(Base.julia_cmd()) --startup-file=no --project=$(project) $benchmark_file`, String)
        tup = eval(Meta.parse(result))
        project_name = basename(project)
        println("$project_name: $(tup)")
        result = get!(results, project_name, NTuple{2, Float64}[])
        push!(result, tup)
    end
    return results
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

ctx = try
    github_context()
catch e
   @warn "Not authorized" exception=e
   # bad credentials because PR isn't from a contributor
   exit()
end

project1 = pwd()
Pkg.activate(project1)
# Pkg.develop([(; path="./MakieCore"), (; path="."), (; path="./CairoMakie")])
Pkg.precompile()

project2 = make_project_folder("makie-master")
Pkg.activate(project2)
Pkg.add([(; rev="master", name="MakieCore"), (; rev="master", name="Makie"), (; rev="master", name="CairoMakie")])
Pkg.precompile()

projects = [project1, project2]

results = run_benchmarks(projects)

function all_stats(io, name, numbers)
    mini = minimum(numbers)
    maxi = maximum(numbers)
    m = median(numbers)
    s = std(numbers)
    @printf(io, "    %s %.2f < %.2f > %.2f, %.2f+-\n", name, mini, m, maxi, s)
end

function speedup(io, name, master, pr)
    t1 = create_trial(master)
    t2 = create_trial(pr)
    t = judge(median(t2), median(t1))
    print(io, "    median:  ", BenchmarkTools.prettydiff(time(ratio(t))), " => ")
    BenchmarkTools.printtimejudge(io, t)
    println(io)
    if t.time == :invariant
        println(io, "This PR does **not** change the $(name) time.")
    elseif t.time == :improvement
        println(io, "This PR **improves** the $(name) time.")
    else
        println(io, "This PR makes the $(name) time **worse**.")
    end
end

function print_analysis(io, results)
    master = results["makie-master"]
    pr = results["MakieDev"]
    println(io, "### using time")
    all_stats(io, "master: ", first.(master))
    all_stats(io, "pr:     ", first.(pr))
    all_stats(io, "speedup:", first.(master) ./ first.(pr))
    speedup(io, "using", first.(master), first.(pr))
    println(io)

    println(io, "### ttfp time")
    all_stats(io, "master  ", last.(master))
    all_stats(io, "pr      ", last.(pr))
    all_stats(io, "speedup:", last.(master) ./ last.(pr))
    speedup(io, "ttfp", last.(master), last.(pr))
end

c = sprint() do io
    println(io, "## Compile Times benchmark\n")
    println(io, "Note, that these numbers may fluctuate on the CI servers, so take them with a grain of salt.\n")
    print_analysis(io, results)
end
println(c)
pr_to_comment = get(ENV, "PR_NUMBER", nothing)
if !isnothing(pr_to_comment)
    pr = GitHub.pull_request(ctx.repo, pr_to_comment)
    make_or_edit_comment(ctx, pr, comment)
else
    @info("Not commenting, no PR found")
end
