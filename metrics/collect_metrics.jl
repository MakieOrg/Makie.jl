using Pkg
Pkg.activate("./metrics")
Pkg.instantiate()

using CSV
using DataFrames
using Distributed
using Dates

metric_target_raw = get(ENV, "METRIC_TARGET", "")
if isempty(metric_target_raw)
    error("No metric target set.")
end

run(`git fetch`)

metric_targets = if startswith(metric_target_raw, "regex ")
    # a workflow_dispatch input of "regex some_regex" matches tags against some_regex
    tags = strip.(split(read(`git tag`, String)))
    regex = match(r"regex (.*)", metric_target_raw)[1] |> strip
    r = Regex(regex)
    ts = filter(x -> !isnothing(match(r, x)), tags)
    @info "available tags: $tags"
    if isempty(ts)
        error("No metric targets found with regex: $r")
    end
    ts
else
    [metric_target_raw]
end

@info "metric targets: $metric_targets"

results = DataFrame()

# one vector of code parts for every file in metrics folder
parts_vectors = map(readdir(joinpath("metrics", "metrics"), join = true)) do file
    code = read(file, String)
    parts = split(code, r"^(?=## )"m, keepempty = false)
end

for metric_target in metric_targets
    @info "checking out metric target $metric_target"
    run(`git checkout $metric_target --`)

    makieversion = match(r"version = \"(.*?)\"", read("Project.toml", String))[1]
    glmakieversion = match(r"version = \"(.*?)\"", read("GLMakie/Project.toml", String))[1]
    cairomakieversion = match(r"version = \"(.*?)\"", read("CairoMakie/Project.toml", String))[1]
    commit_date = DateTime(
        strip(String(read(`git show -s --format=%ci`)))[1:(end - 6)],
        "yyyy-mm-dd HH:MM:SS"
    )

    df = DataFrame()
    date = now()

    for parts in parts_vectors

        local i_proc
        try
            i_proc = addprocs(1)[1]

            @everywhere i_proc begin
                using Pkg
            end

            @everywhere i_proc begin
                pkg"activate --temp"
                pkg"dev ./Makie GLMakie CairoMakie"
                Pkg.precompile()
                @timed begin end
            end

            for part in parts
                partname = match(r"^## (.*)", part)[1] |> strip
                @info "executing part: $partname"
                partcode = """
                    @timed begin
                        $part
                        nothing
                    end
                """
                timing = remotecall_fetch(i_proc, partcode) do p
                    include_string(Main, p)
                end

                push!(
                    df, (
                        date = date,
                        commit_date = commit_date,
                        metric_target = metric_target,
                        juliaversion = string(Sys.VERSION),
                        makie = makieversion,
                        glmakie = glmakieversion,
                        cairomakie = cairomakieversion,
                        name = partname,
                        time = timing.time,
                        allocations = timing.bytes,
                        gc_time = timing.gctime,
                    )
                )
            end

        finally
            rmprocs(i_proc)
        end
    end
    append!(results, df, cols = :union)
end

branch_name = "metrics"
remote_branch = "origin/metrics"

run(`git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"`)
run(`git config --global user.name "github-actions[bot]"`)

@info "Checking out $branch_name."
if !success(`git checkout -b $branch_name $remote_branch`)
    @info "branch $branch_name doesn't exist, creating new orphan branch"
    run(`git checkout --orphan $branch_name --`)
    run(`git rm -rf .`)
end

println("\nFiles in working directory:")
run(`ls`)

filename = "compilation_latencies.csv"

df = if !isfile(filename)
    @info "$filename doesn't exist, creating empty DataFrame."
    DataFrame()
else
    @info "Loading DataFrame from $filename."
    CSV.read(filename, DataFrame)
end

append!(df, results, cols = :union)
sort!(df, :commit_date)

@info "Writing out DataFrame to $filename."
CSV.write(filename, df)

run(`git add $filename`)
run(`git commit -m "update metrics"`)
run(`git push origin $branch_name`)
