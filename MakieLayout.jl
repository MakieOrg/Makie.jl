module MakieLayout

using AbstractPlotting
using AbstractPlotting: Rect2D
import AbstractPlotting: IRect2D
using AbstractPlotting.Keyboard
using AbstractPlotting.Mouse
using AbstractPlotting: ispressed, is_mouseinside
using Observables: onany
import Formatting
using Match

include("types.jl")
include("helpers.jl")
include("mousestatemachine.jl")
include("geometry_integration.jl")
include("layout_engine.jl")
include("makie_integration.jl")
include("ticklocators/linear.jl")
include("defaultattributes.jl")
include("lineaxis.jl")
include("layoutedobjects/layoutedaxis.jl")
include("layoutedobjects/layoutedcolorbar.jl")
include("layoutedobjects/layoutedtext.jl")
include("layoutedobjects/layoutedslider.jl")
include("layoutedobjects/layoutedbutton.jl")
include("layoutedobjects/layoutedrect.jl")

export LayoutedAxis
export LayoutedSlider
export LayoutedButton
export LayoutedColorbar
export LayoutedText
export LayoutedRect
export linkxaxes!
export linkyaxes!
export GridLayout
export ProtrusionLayout
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
export hidexdecorations!, hideydecorations!
export tight_xticklabel_spacing!, tight_yticklabel_spacing!, tight_ticklabel_spacing!
export colsize!, rowsize!

end # module
