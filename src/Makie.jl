module Makie

using AbstractPlotting, GLMakie
import FileIO
using GLMakie
using GLMakie: assetpath, loadasset

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
    @eval export $(name)
end

function logo()
    FileIO.load(joinpath(@__DIR__, "..", "assets", "logo.png"))
end

end
