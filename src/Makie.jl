module Makie

using AbstractPlotting, GLMakie, StatsMakie
import FileIO
using GLMakie
using GLMakie: assetpath, loadasset

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
    @eval export $(name)
end

for name in names(StatsMakie)
    @eval import StatsMakie: $(name)
    @eval export $(name)
end

function logo()
    FileIO.load(joinpath(@__DIR__, "..", "assets", "logo.png"))
end

end
