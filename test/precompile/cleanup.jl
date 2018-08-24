cd(@__DIR__)
str = read("raw.jl", String);

exprlins = split(str, '\n');

imports = filter(x-> startswith(x, "using"), exprlins)
rest = filter(x-> !startswith(x, "using"), exprlins)
N = 6
open("makie_precompile.jl", "w") do io
    println(io, "using Pkg, Test, LinearAlgebra, Random, Statistics, Dates, BinaryProvider")
    for elem in imports
        println(io, elem)
    end
    for line in rest
        x = Meta.parse(line, raise = true) # is parseable?
        Meta.isexpr(x, :incomplete) && continue
        line = string("try;", line, "; catch; end")
        println(io, line)
    end
end
