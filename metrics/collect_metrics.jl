using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV
using DataFrames
using Distributed
using Dates

metric_target = get(ENV, "METRIC_TARGET", "")
if isempty(metric_target)
    error("No metric target set (commit or tag)")
end

@info "checking out metric target $metric_target"
run(`git checkout $metric_target`)

makieversion = match(r"version = \"(.*?)\"", read("../Project.toml", String))[1]
glmakieversion = match(r"version = \"(.*?)\"", read("../GLMakie/Project.toml", String))[1]
cairomakieversion = match(r"version = \"(.*?)\"", read("../CairoMakie/Project.toml", String))[1]
commit_date = DateTime(
    strip(String(read(`git show -s --format=%ci`)))[1:end-6],
    "yyyy-mm-dd HH:MM:SS")

new_results = begin
    df = DataFrame()
    date = now()

    # one process for every file in metrics folder
    for file in readdir("metrics", join = true)

        code = read(file, String)
        parts = split(code, r"^(?=## )"m, keepempty = false)

        local i_proc
        try
            i_proc = addprocs(1)[1]

            @everywhere i_proc begin
                using Pkg
            end

            @everywhere i_proc begin
                pkg"activate --temp"
                pkg"dev .. MakieCore GLMakie CairoMakie"
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

                push!(df, (
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
                ))
            end

        finally
            rmprocs(i_proc)
        end
    end
    df
end

@show new_results

branch_name = "metrics"

# move to top folder
cd("..")

branch_exists = success(`git rev-parse --verify --quiet $branch_name`)

run(`git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"`)
run(`git config --global user.name "github-actions[bot]"`)

if branch_exists
    @info "branch $branch_name exists, checking out"
    run(`git checkout $branch_name`)
    run(`git pull origin $branch_name`)
else
    @info "branch $branch_name doesn't exist, creating new orphan branch"
    run(`git checkout --orphan $branch_name`)
    run(`git rm -rf .`)
end

filename = "compilation_latencies.csv"

df = if !isfile(filename)
    @info "$filename doesn't exist, creating empty DataFrame."
    DataFrame()
else
    @info "Loading DataFrame from $filename."
    CSV.read(filename, DataFrame)
end

df = vcat(df, new_results, cols = :union)
sort!(df, :commit_date)

@info "Writing out DataFrame to $filename."
CSV.write(filename, df)

run(`git add $filename`)
run(`git commit -m "update metrics"`)
run(`git push -u origin $branch_name`)
