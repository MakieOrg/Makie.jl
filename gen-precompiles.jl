using TracePrecompiles

precompile_file = joinpath(@__DIR__, "CairoMakie/src/all-precompiles.jl")
precomp_run_file = joinpath(@__DIR__, "metrics/ttfp/benchmark-ttfp.jl")
isfile(precompile_file) && rm(precompile_file)
TracePrecompiles.trace_compiles("CairoMakie", precomp_run_file, precompile_file)
