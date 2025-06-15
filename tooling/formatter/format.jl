using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using Runic

dir = joinpath(@__DIR__, "..", "..")
Runic.main(["--verbose", "--inplace", dir])
