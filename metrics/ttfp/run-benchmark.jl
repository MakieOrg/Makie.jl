cd(@__DIR__)
using Pkg
Pkg.activate(".")
pkg"add JSON Statistics GitHub"
pkg"dev ../../MakieCore/ ../../ ../../CairoMakie/; add JSON Statistics GitHub SHA"
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates

commit = chomp(read(`git rev-parse HEAD`, String))
repo = GitHub.Repo("JuliaPlots/Makie.jl")
pr = GitHub.PullRequest(1691)
auth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
scratch_repo = GitHub.Repo("MakieOrg/scratch")
branch_name = chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
file_name = replace("julia_$(VERSION)_$(branch_name)", r"[\.\/]" => "-")
repo_path = "benchmarks/$(file_name).png"

function get_file(repo_path)
    file = GitHub.file(scratch_repo, repo_path; auth=auth, handle_error=false)
    if isnothing(file.sha)
        return (sha=nothing, content=nothing)
    else
        return (sha=file.sha, content = base64decode(file.content))
    end
end

upload_file(file, repo_path) = upload_data(read(file), repo_path)
function upload_data(bytes_or_str, repo_path)
    b64 = Base64.base64encode(bytes_or_str)
    # see if there is an old file, (handle_error=false won't error, and instead returns file with all nothing)
    old_file = get_file(repo_path)
    params = Dict("content"=>b64, "message"=>"update benchmark for $(file_name)")
    if !isnothing(old_file.sha)
        # if there was a file already, we need to supply its sha
        params["sha"] = old_file.sha
    end
    GitHub.create_file(scratch_repo, repo_path; auth=auth, params=params)
    return "https://github.com/MakieOrg/scratch/blob/main/$(repo_path)?raw=true"
end

function make_or_edit_comment(comment)
    prev_comments, _ = GitHub.comments(repo, pr; auth=auth)
    idx = findfirst(x-> occursin("## Compile Times compared to tagged", x.body), prev_comments)
    if isnothing(idx)
        GitHub.create_comment(repo, pr; auth=auth, params=Dict("body"=>comment))
    else
        GitHub.edit_comment(repo, prev_comments[idx], :pr; auth=auth, params=Dict("body"=>comment))
    end
end

function run_bench(n=10)
    results = Tuple{Float64, Float64}[]
    for i in 1:n
        result = read(`julia --project=. ./benchmark-ttfp.jl`, String)
        tup = eval(Meta.parse(result))
        @show tup
        push!(results, tup)
    end
    return results
end

results = run_bench()
data_repo_path = "benchmarks/" * file_name * ".json"
old_file = get_file(data_repo_path)
data = if !isnothing(old_file.content)
    JSON.parse(String(old_file.content))
else
    Dict{String, Vector{Tuple{Float64, Float64}}}()
end

data[commit] = results

upload_data(JSON.json(data), data_repo_path)

tagged_repo_path = "benchmarks/julia_$(VERSION)_tagged.json"
file_tagged = get_file(tagged_repo_path)
tagged = JSON.parse(String(file_tagged.content))


function sorted_by_date(data, branch_name)
    with_date = map(collect(data)) do (commit_sha, data)
        gc = GitHub.gitcommit(repo, commit_sha)
        time = parse(DateTime, gc.author["date"][1:end-1])
        (commit_sha, data, time)
    end
    sort!(with_date, by=last)
    return map(with_date) do (commit_sha, data, time)
        (commit_sha, branch_name, last.(data))
    end
end

function create_plot()
    plot_data = sorted_by_date(data, branch_name)
    last_d = max(length(plot_data) - 6, 1)
    plot_data = plot_data[last_d:end] # only take last 6 commits
    last_tagged = sorted_by_date(tagged, "tagged")[end]

    pushfirst!(plot_data, last_tagged)

    ys = Float64[]
    xs = Float64[]
    colors = RGBAf[]
    xticks_labels = String[]
    xticks_nums = Int[]
    wcolors = Makie.wong_colors(1.0)
    legend_elems = PolyElement[]
    legend_names = String[]
    color_lookup = Dict{String, RGBAf}()
    c_idx = 0
    for (i, (commit, branch, times)) in enumerate(plot_data)
        n = length(times)
        append!(xs, fill(i, n))
        append!(ys, times)
        plot_col = get!(color_lookup, branch) do
            c_idx += 1
            col = wcolors[c_idx]
            push!(legend_elems, PolyElement(color=col))
            push!(legend_names, branch)
            return col
        end
        append!(colors, fill(plot_col, n))
        push!(xticks_nums, i)
        push!(xticks_labels, commit[1:5])
    end

    f = Figure()
    ax = Axis(f[1,1], xticks=(xticks_nums, xticks_labels), xlabel="commit", ylabel="time (s)")
    pl = violin!(ax, xs, ys, show_median=true, color=colors)
    Legend(f[1, 1], legend_elems, legend_names;
        tellheight = false,
        tellwidth = false,
        margin = (10, 10, 10, 10),
        halign = :right, valign = :bottom)

    io = IOBuffer()
    show(io, MIME"image/png"(), f)
    return take!(io)
end

using CairoMakie
image_bytes = create_plot()

image_url = upload_data(image_bytes, repo_path)

comment = """
## Compile Times compared to tagged

![]($(image_url))
"""

make_or_edit_comment(comment)
