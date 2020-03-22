module MakieLayout

using AbstractPlotting
using AbstractPlotting: Rect2D
import AbstractPlotting: IRect2D
using AbstractPlotting.Keyboard
using AbstractPlotting.Mouse
using AbstractPlotting: ispressed, is_mouseinside
using Observables: onany
import Observables
import Formatting
using Match
import Animations
import PlotUtils
using GridLayoutBase

include("types.jl")
include("gridlayout.jl")
include("helpers.jl")
include("mousestatemachine.jl")
include("geometry_integration.jl")
include("makie_integration.jl")
include("ticklocators/linear.jl")
include("ticklocators/wilkinson.jl")
include("defaultattributes.jl")
include("lineaxis.jl")
include("lobjects/laxis.jl")
include("lobjects/lcolorbar.jl")
include("lobjects/ltext.jl")
include("lobjects/lslider.jl")
include("lobjects/lbutton.jl")
include("lobjects/lrect.jl")
include("lobjects/ltoggle.jl")
include("lobjects/llegend.jl")
include("lobjects/lobject.jl")
include("lobjects/lscene.jl")

export LAxis
export LSlider
export LButton
export LColorbar
export LText
export LRect
export LToggle
export LLegend
export LScene
export linkxaxes!, linkyaxes!, linkaxes!
export AxisAspect, DataAspect
export autolimits!
export AutoLinearTicks, ManualTicks, CustomTicks, WilkinsonTicks
export hidexdecorations!, hideydecorations!
export tight_xticklabel_spacing!, tight_yticklabel_spacing!, tight_ticklabel_spacing!, tightlimits!
export layoutscene
export set_close_to!

const FPS = Node(30)
const COLOR_ACCENT = Ref(RGBf0(((79, 122, 214) ./ 255)...))
const COLOR_ACCENT_DIMMED = Ref(RGBf0(((174, 192, 230) ./ 255)...))

end # module
