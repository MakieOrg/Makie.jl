module Makie

using AbstractPlotting, GeometryTypes
import IntervalSets, FileIO
using IntervalSets: ClosedInterval, (..)

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
    @eval export $(name)
end

export (..), GLNormalUVMesh
# conflicting identifiers
using GeometryTypes: widths
export widths, decompose

function logo()
    FileIO.load(joinpath(@__DIR__, "..", "assets", "logo.png"))
end

using GLMakie
using GLMakie: assetpath, loadasset

end
