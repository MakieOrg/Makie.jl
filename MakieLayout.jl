module MakieLayout

using Random
using PlotUtils
using AbstractPlotting
using AbstractPlotting: Rect2D
import AbstractPlotting: IRect2D
using AbstractPlotting.Keyboard
using AbstractPlotting.Mouse
using AbstractPlotting: ispressed, is_mouseinside
using Printf
import Showoff
using Observables: onany

include("types.jl")
include("geometry_integration.jl")
include("layout_engine.jl")
include("makie_integration.jl")
include("ticklocators/linear.jl")
include("defaultattributes.jl")
include("layoutedobjects/layoutedaxis.jl")
include("layoutedobjects/layoutedcolorbar.jl")
include("layoutedobjects/layoutedtext.jl")

export LayoutedAxis
export LayoutedSlider
export LayoutedButton
export LayoutedColorbar
export LayoutedText
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
export with_updates_suspended
export appendcols!, appendrows!, prependcols!, prependrows!
export nest_content_into_gridlayout!
export AxisAspect, DataAspect
export autolimits!
export AutoLinearTicks, ManualTicks
end # module
