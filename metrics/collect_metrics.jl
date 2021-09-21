using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV
using DataFrames
using Distributed
using Dates

new_results = begin
    df = DataFrame()
    date = now()

    # for file in readdir("metrics", join = true)
    for file in []

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
                    juliaversion = string(Sys.VERSION),
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

branch_exists = String(read(`git ls-remote --heads git@github.com:JuliaPlots/Makie.jl.git $branch_name`)) != ""

run(`git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"`)
run(`git config --global user.name "github-actions[bot]"`)

if branch_exists
    @info "branch $branch_name exists, checking out"
    run(`git checkout $branch_name`)
else
    @info "branch $branch_name doesn't exist, creating new orphan branch"
    run(`git checkout --orphan $branch_name`)
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

@info "Writing out DataFrame to $filename."
CSV.write(filename, df)

run(`git add $filename`)
run(`git commit -m "update metrics"`)
run(`git push -u origin $branch_name`)
