using Pkg
Pkg.add(url="https://github.com/SimonDanisch/TracePrecompiles.jl")
using TracePrecompiles, Makie

base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
isdir(base_path)

precomp_file_all = joinpath(base_path, "precompile-run.jl")

backend_src = """
using GLMakie
GLMakie.inline!(true)
macro compile(block)
    return quote
        figlike = \$(esc(block))
        screen = Makie.backend_display(Makie.get_scene(figlike))
        Makie.colorbuffer(screen)
    end
end

"""

precomp_file_cmakie = joinpath(@__DIR__, "precompile-run.jl")
open(precomp_file_cmakie, "w") do io
    write(io, backend_src)
    write(io, read(precomp_file_all))
end

precompile_file = joinpath(@__DIR__, "precompiles.jl")
isfile(precompile_file) && rm(precompile_file)
TracePrecompiles.trace_compiles("GLMakie", precomp_file_cmakie, precompile_file)
