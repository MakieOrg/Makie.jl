using Pkg
Pkg.activate(@__DIR__)
Pkg.update()
using Runic

dir = joinpath(@__DIR__, "..", "..")
Runic.main(["--verbose", "--inplace", dir])
