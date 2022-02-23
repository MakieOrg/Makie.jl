using Pkg
cd(@__DIR__)
Pkg.activate(".")
pkg"dev ../../MakieCore/ ../../ ../../CairoMakie/; add GeometryBasics#sd/no-sarray"

using Pkg
Pkg.activate("./makie-tagged")
pkg"add CairoMakie"
Pkg.precompile("CairoMakie")

function run_bench(julia, project, n=10)
    results = Tuple{Float64, Float64}[]
    for i in 1:n
        result = read(`$(julia) --project=$(project) ./benchmark-ttfp.jl`, String)
        tup = eval(Meta.parse(result))
        @show tup
        push!(results, tup)
    end
    return results
end

julia_th = "./../../../../julia_th/julia"
julia_17 = "julia"

result_1_7 = run_bench(julia_17, ".")
result_th = run_bench(julia_th, ".")
result_1_7_tagged = run_bench(julia_17, "makie-tagged")
result_th_tagged = run_bench(julia_th, "makie-tagged")

using Pkg
Pkg.activate("./makie-precompile")
pkg"add Makie#sd/more-precompile CairoMakie#sd/more-precompile"
Pkg.precompile("CairoMakie")

result_1_7_precompile = run_bench(julia_17, "makie-precompile")
result_th_precompile = run_bench(julia_th, "makie-precompile")

using Serialization

open("./data/julia_19_precompile.jls", "w") do io
    Serialization.serialize(io, result_th_precompile)
end

open("./data/julia_19_latency.jls", "w") do io
    Serialization.serialize(io, result_th)
end

open("./data/julia_17_latency.jls", "w") do io
    Serialization.serialize(io, result_1_7)
end
