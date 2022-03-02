precompile_file = joinpath(@__DIR__, "CairoMakie/src/all-precompiles.jl")
current_proj = unsafe_string(Base.JLOptions().project)
precomp_run_file = joinpath(@__DIR__, "metrics/ttfp/benchmark-ttfp.jl")
run(`julia --project=$(current_proj) --trace-compile=$(precompile_file) $precomp_run_file`)

precomps = read(precompile_file, String)
precomps_macro = replace(precomps, "precompile(" => "@precompile(")

pkgs = Set{Base.PkgId}()
push!(Base.package_callbacks, pkg-> push!(pkgs, pkg))
using CairoMakie

open("test.jl", "w") do io
    write(io, read(joinpath(@__DIR__, "precomp-utils.jl")))
    println(io)
    for p in collect(pkgs)
        println(io, "@import $(p.name) $(repr(p.uuid))")
    end
    println(io)
    println(io, precomps_macro)
end

using MakieCore
