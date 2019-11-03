module MakieLayout

using Random
using PlotUtils
using AbstractPlotting
using Printf
import Showoff

include("geometry_integration.jl")
include("layout_engine.jl")
include("makie_integration.jl")

export LayoutedAxis
export linkxaxes!
export linkyaxes!
export GridLayout
export AxisLayout
export BBox
export outersolve
export shrinkbymargin
export applylayout

end # module
