module MakieLayout

using ..AbstractPlotting
using ..AbstractPlotting: Rect2D
import ..AbstractPlotting: IRect2D
using ..AbstractPlotting.Keyboard
using ..AbstractPlotting.Mouse
using ..AbstractPlotting: ispressed, is_mouseinside
using Observables: onany
import Observables
import Formatting
using Match
import Animations
import PlotUtils
using GridLayoutBase
import Showoff
using Colors

const FPS = Node(30)
const COLOR_ACCENT = Ref(RGBf0(((79, 122, 214) ./ 255)...))
const COLOR_ACCENT_DIMMED = Ref(RGBf0(((174, 192, 230) ./ 255)...))

# Make GridLayoutBase default row and colgaps themeable when using MakieLayout
# This mutates module-level state so it could mess up other libraries using
# GridLayoutBase at the same time as MakieLayout, which is unlikely, though
function __init__()
    GridLayoutBase.DEFAULT_COLGAP_GETTER[] = function()
        ct = AbstractPlotting.current_default_theme()
        if haskey(ct, :colgap)
            ct[:colgap][]
        else
            GridLayoutBase.DEFAULT_COLGAP[]
        end
    end
    GridLayoutBase.DEFAULT_ROWGAP_GETTER[] = function()
        ct = AbstractPlotting.current_default_theme()
        if haskey(ct, :rowgap)
            ct[:rowgap][]
        else
            GridLayoutBase.DEFAULT_ROWGAP[]
        end
    end
end

include("geometrybasics_extension.jl")
include("types.jl")
include("helpers.jl")
include("mousestatemachine.jl")
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
include("lobjects/lmenu.jl")
include("lobjects/ltextbox.jl")

export LAxis
export LSlider
export LButton
export LColorbar
export LText
export LRect
export LToggle
export LLegend
export LegendEntry, MarkerElement, PolyElement, LineElement, LegendElement
export LScene
export LMenu
export LTextbox
export linkxaxes!, linkyaxes!, linkaxes!
export AxisAspect, DataAspect
export autolimits!, limits!
export LinearTicks, WilkinsonTicks
export hidexdecorations!, hideydecorations!, hidedecorations!, hidespines!
export tight_xticklabel_spacing!, tight_yticklabel_spacing!, tight_ticklabel_spacing!, tightlimits!
export layoutscene
export set_close_to!
export xaxis_bottom!, xaxis_top!, yaxis_left!, yaxis_right!
export labelslider!
export addmousestate!


# from GridLayoutBase
export GridLayout, GridPosition
export GridLayoutSpec
export BBox
export LayoutObservables
export Inside, Outside, Mixed
export Fixed, Auto, Relative, Aspect
export width, height, top, bottom, left, right
export with_updates_suspended
export appendcols!, appendrows!, prependcols!, prependrows!, deletecol!, deleterow!, trim!
export gridnest!
export AxisAspect, DataAspect
export colsize!, rowsize!, colgap!, rowgap!
export Left, Right, Top, Bottom, TopLeft, BottomLeft, TopRight, BottomRight
export grid!, hbox!, vbox!
export swap!
export ncols, nrows
export contents

end # module
