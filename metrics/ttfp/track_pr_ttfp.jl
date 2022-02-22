using Pkg
cd(@__DIR__)
Pkg.activate(".")
pkg"dev ../../MakieCore/ ../../ ../../CairoMakie/; add GeometryBasics#sd/no-sarray"

using Pkg
Pkg.activate("./makie-tagged")
pkg"add CairoMakie"
Pkg.precompile("CairoMakie")

result_1_7 = read(`julia --project=. ./benchmark-ttfp.jl`, String)
result_th = read(`./../../../../julia_th/julia --project=. ./benchmark-ttfp.jl`, String)
result_1_7_tagged = read(`julia --project=makie-tagged ./benchmark-ttfp.jl`, String)
result_th_tagged = read(`./../../../../julia_th/julia --project=makie-tagged ./benchmark-ttfp.jl`, String)

@show result_1_7
@show result_th
@show result_1_7_tagged
@show result_th_tagged
