using Pkg, JSON, Statistics
cd(@__DIR__)
Pkg.activate(".")
pkg"dev ../../MakieCore/ ../../ ../../CairoMakie/; add JSON Statistics"

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

branch = chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
commit = chomp(read(`git rev-parse HEAD`, String))
file = replace("julia_$(VERSION)_$(branch)", r"[\.\/]" => "-")
path = "./data/" * file * ".json"

data = if isfile(path)
    JSON.parsefile(path)
else
    Dict{String, Vector{Tuple{Float64, Float64}}}()
end
data[commit] = results

open(path, "w") do io
    JSON.print(io, data)
end

using CairoMakie

scatter(last.(results))
tagged = JSON.parsefile("./data/julia_$(VERSION)_tagged.json")

begin
    pr_times = last.(results)
    f, ax, p = scatter(pr_times, label=branch)
    hlines!(ax, mean(pr_times))
    bp = band!(ax, 1:length(pr_times), minimum(pr_times), maximum(pr_times))
    bp.color[] = RGBAf(Makie.color(bp.color[]), 0.2)

    com, tagged_d = first(tagged)
    tagged_times = last.(tagged_d)
    scatter!(ax, tagged_times, label="tagged")
    hlines!(ax, mean(tagged_times))
    bp = band!(ax, 1:length(tagged_times), minimum(tagged_times), maximum(tagged_times))
    bp.color[] = RGBAf(Makie.color(bp.color[]), 0.2)
    axislegend(ax)
    save("./data/plots/pr.png", f)
end
