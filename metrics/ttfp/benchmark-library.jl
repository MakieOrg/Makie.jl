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
latest_commit(branch) = chomp(read(`git log -n 1 $branch --pretty=format:"%H"`, String))

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

function run_bench(commit; n=10)
    @info("run benchmark for $(commit)")
    rm("benchmark-project/Manifest.toml")
    Pkg.activate("benchmark-project")
    pkgs = ["MakieCore", "Makie", "CairoMakie"]
    pkgs = [PackageSpec(name=pkg, rev=commit) for pkg in pkgs]
    Pkg.add(pkgs)
    results = Vector{Float64}[]
    for i in 1:n
        result = read(`$(Base.julia_cmd()) --project=benchmark-project ./benchmark-ttfp.jl`, String)
        tup = eval(Meta.parse(result))
        @show tup
        push!(results, [tup...])
    end
    Pkg.activate(".") # activate the main project
    return results
end

function get_benchmark_data(ctx, commit)
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
        global results = run_bench(commit)
        branch_name = chomp(read(`git describe --all --contains $(commit)`, String))
        head="$(owner):$(branch_name)"
        params = Dict("state" => "all", "head" => head);
        prs, page_data = GitHub.pull_requests(ctx.repo; auth=ctx.auth, params = params);
        pr_number = isempty(prs) ? nothing : prs[1].number
        commit_info = GitHub.commit(ctx.repo, commit; handle_error=false)
        message = isnothing(commit_info.commit) ? "" : commit_info.commit.message
        result_with_info = Dict(
            "branch" => branch_name,
            "pr" => pr_number,
            "message" => message,
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
