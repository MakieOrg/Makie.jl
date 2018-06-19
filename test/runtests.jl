using AbstractPlotting

if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

include("quaternions.jl")

# TODO write some AbstractPlotting specific tests... So far functionality is tested in Makie.jl
