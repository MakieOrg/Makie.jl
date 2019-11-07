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
export LayoutedSlider
export linkxaxes!
export linkyaxes!
export GridLayout
export AxisLayout
export BBox
export solve
export shrinkbymargin
export applylayout
export Inside, Outside
export Fixed, Auto, Relative, Aspect
export FixedSizeBox
export FixedHeightBox
export width, height, top, bottom, left, right

end # module
