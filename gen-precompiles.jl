using TracePrecompiles

precompile_file = joinpath(@__DIR__, "CairoMakie/src/all-precompiles.jl")
precomp_run_file = joinpath(@__DIR__, "metrics/ttfp/benchmark-ttfp.jl")

TracePrecompiles.trace_compiles("CairoMakie", precomp_run_file, precompile_file)
