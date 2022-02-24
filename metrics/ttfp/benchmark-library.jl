using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates

function cpu_key()
    cpus = map(Sys.cpu_info()) do cpu
        replace(cpu.model, " " => "")
    end
    return join(unique(cpus), "")
end
julia_key() = "julia-" * replace(string(VERSION), "."=>"-")
tag_commit(ctx, tag) = GitHub.tag(ctx.repo, tag).object["sha"]
current_commit() =  chomp(read(`git rev-parse HEAD`, String))
latest_commit(ctx, branch) = GitHub.branch(ctx.repo, branch)

struct BenchInfo
    julia::String
    cpu::String
    branch::String
    commit::String
    commit_message::String
    project::String
end

function best_name(info::BenchInfo)
    isempty(info.branch) || return info.branch
    return info.commit[1:5]
end

function BenchInfo(commit::GitHub.Commit;
        julia::String=julia_key(),
        cpu::String=cpu_key(),
        branch::String="",
        commit_message::String="",
        project=""
    )
    isnothing(commit.commit) && error("Invalid commit")
    return BenchInfo(
        julia,
        cpu,
        branch,
        commit.sha,
        commit.commit.message,
        project
    )
end

function BenchInfo(repo, commit_sha::AbstractString; kw...)
    commit = GitHub.commit(repo, commit_sha)
    return BenchInfo(commit; kw...)
end

function get_tag_info(tag::GitHub.Tag)
    str = sprint() do io
        Downloads.download(tag.object["url"], io)
    end
    dict = JSON.parse(str)
    parts = splitpath(tag.url.path) # why is this not straight-forward?
    repo = GitHub.Repo(parts[3] * "/" * parts[4])
    return (
        commit = dict["object"]["sha"],
        name = dict["tag"],
        repo = repo,
        message = dict["message"],
    )
end

function BenchInfo(tag::GitHub.Tag; kw...)
    info = get_tag_info(tag)
    return BenchInfo(info.repo, info.commit; branch=info.name, kw...)
end

function get_file(ctx, repo_path)
    file = GitHub.file(ctx.scratch_repo, repo_path; auth=ctx.auth, handle_error=false)
    if isnothing(file.sha)
        return (sha=nothing, content=nothing)
    else
        return (sha=file.sha, content = base64decode(file.content))
    end
end

upload_file(ctx, file, repo_path) = upload_data(ctx, read(file), repo_path, file)
function upload_data(ctx, bytes_or_str::Union{AbstractString, AbstractVector{UInt8}}, repo_path, file_name="data")
    b64 = Base64.base64encode(bytes_or_str)
    # see if there is an old file, (handle_error=false won't error, and instead returns file with all nothing)
    old_file = get_file(ctx, repo_path)
    params = Dict("content"=>b64, "message"=>"update benchmark for $(file_name)")
    if !isnothing(old_file.sha)
        # if there was a file already, we need to supply its sha
        params["sha"] = old_file.sha
    end
    GitHub.create_file(ctx.scratch_repo, repo_path; auth=ctx.auth, params=params)
    return "https://github.com/MakieOrg/scratch/blob/main/$(repo_path)?raw=true"
end

function make_or_edit_comment(ctx, pr, comment)
    prev_comments, _ = GitHub.comments(ctx.repo, pr; auth=ctx.auth)
    idx = findfirst(x-> occursin("## Compile Times compared to tagged", x.body), prev_comments)
    if isnothing(idx)
        GitHub.create_comment(ctx.repo, pr; auth=ctx.auth, params=Dict("body"=>comment))
    else
        GitHub.edit_comment(ctx.repo, prev_comments[idx], :pr; auth=ctx.auth, params=Dict("body"=>comment))
    end
end

function run_bench(info::BenchInfo; n=1)
    commit = info.commit
    if info.cpu != cpu_key()
        error("Not running on requested CPU. Request: $(info.cpu), actual: $(cpu_key())")
    end
    if info.julia != julia_key()
        error("Not running on requested Julia. Requested: $(info.julia), actual: $(julia_key())")
    end

    @info("run benchmark for $(commit)")
    if isdir(info.project)
        project = info.project
    else
        project = "benchmark-project"
        isdir(project) && rm(project; force=true, recursive=true)
        Pkg.activate(project)
        pkgs = ["MakieCore", "Makie", "CairoMakie"]
        pkgs = [PackageSpec(name=pkg, rev=commit) for pkg in pkgs]
        Pkg.add(pkgs)
    end

    results = Vector{Float64}[]
    for i in 1:n
        result = read(`$(Base.julia_cmd()) --project=$(project) ./benchmark-ttfp.jl`, String)
        tup = eval(Meta.parse(result))
        @show tup
        push!(results, [tup...])
    end
    Pkg.activate(".") # activate the main project
    return results
end

bench_info(ctx, gh_typ::GitHub.GitHubType) = BenchInfo(gh_typ)
bench_info(ctx, commit_or_smth) = BenchInfo(ctx.repo, commit_or_smth)

function get_benchmark_data(ctx, info::BenchInfo)
    commit = info.commit
    repo_dir_path = "benchmarks/$(julia_key())/$(cpu_key())"
    repo_base_path = "$(repo_dir_path)/$(commit)"
    repo_data_path = "$(repo_base_path).json"
    @info("Getting $(repo_data_path)")
    old_file = get_file(ctx, repo_data_path)
    if !isnothing(old_file.content)
        @info("Benchmark already exists, loading from file")
        return JSON.parse(String(old_file.content))
    else
        @info("Benchmarkdoesn't exist, run benchmark")
        global results = run_bench(info)

        result_with_info = Dict(
            "branch" => info.branch,
            "message" => info.commit_message,
            "date" => string(now()),
            "results" => results
        )
        upload_data(ctx, JSON.json(result_with_info), repo_data_path, "for commit $(commit[1:5])")
        return result_with_info
    end
end

function github_context()
    owner = "JuliaPlots"
    return (
        owner = owner,
        repo = GitHub.Repo("$(owner)/Makie.jl"),
        auth = GitHub.authenticate(ENV["GITHUB_TOKEN"]),
        scratch_repo = GitHub.Repo("MakieOrg/scratch")
    )
end

function plot_benchmark!(ax, data, pos, width=0.9)
    used = first.(data)
    ttfp = last.(data)
    sum_t = used .+ ttfp
    n = length(data)
    bplot!(d, c) = scatter!(ax, fill(pos, n), d, marker=Rect, markerspace=:data, markersize=Vec2f(width, 0.2), color=(c, 0.2))

    bplot!(used, :darkred)
    bplot!(ttfp, :blue)
    bplot!(sum_t, :black)
    hwidth = (width / 2) .+ 0.01
    vlines!(ax, [pos - hwidth, pos + hwidth], linewidth=0.5, color=(:black, 0.5))
    return (used, ttfp, sum_t)
end

function plot_benchmarks(benchmarks)
    f = Figure()
    ax = Axis(f[1,1]; ylabel="median time (s)")
    mdata = Vector{Float64}[]
    xticks = Int[]
    xticklabels = String[]
    for (i, data) in enumerate(benchmarks)
        pdata = data["results"]
        push!(mdata, plot_benchmark!(ax, pdata, i)...)
        push!(xticks, i)
        push!(xticklabels, data["branch"])
    end
    medians = median.(mdata)
    medians = unique(round.(median.(mdata)))
    ax.yticks = medians
    ax.xticks = (xticks, xticklabels)
    hidexdecorations!(ax, ticklabels=false)
    f
end

function upload_data(ctx, fig, repo_path)
    io = IOBuffer()
    show(io, MIME"image/png"(), fig)
    bytes = take!(io)
    upload_data(ctx, bytes, repo_path, "plot")
end
