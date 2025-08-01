import Format
import Animations
using GridLayoutBase
using GridLayoutBase: GridSubposition
import Showoff

const FPS = Observable(30)
const COLOR_ACCENT = Ref(RGBf(((79, 122, 214) ./ 255)...))
const COLOR_ACCENT_DIMMED = Ref(RGBf(((174, 192, 230) ./ 255)...))

include("blocks.jl")
include("geometrybasics_extension.jl")
include("mousestatemachine.jl")
include("types.jl")
include("helpers.jl")
include("ticklocators/linear.jl")
include("ticklocators/wilkinson.jl")
include("defaultattributes.jl")
include("lineaxis.jl")
include("interactions.jl")
include("blocks/axis.jl")
include("blocks/axis3d.jl")
include("blocks/polaraxis.jl")
include("blocks/colorbar.jl")
include("blocks/label.jl")
include("blocks/slider.jl")
include("blocks/slidergrid.jl")
include("blocks/intervalslider.jl")
include("blocks/button.jl")
include("blocks/checkbox.jl")
include("blocks/box.jl")
include("blocks/toggle.jl")
include("blocks/legend.jl")
include("blocks/scene.jl")
include("blocks/menu.jl")
include("blocks/textbox.jl")

export Axis
export Axis3
export PolarAxis
export Slider
export SliderGrid
export IntervalSlider
export Button
export Checkbox
export Colorbar
export Label
export Box
export Toggle
export Legend, axislegend
export LegendEntry, MarkerElement, PolyElement, LineElement, LegendElement
export LScene
export Menu
export Textbox
export linkxaxes!, linkyaxes!, linkaxes!
export AxisAspect, DataAspect
export autolimits!, limits!, reset_limits!, rlims!, thetalims!
export LinearTicks, WilkinsonTicks, MultiplesTicks, IntervalsBetween, LogTicks, AngularTicks
export hidexdecorations!, hideydecorations!, hidezdecorations!, hidedecorations!, hidespines!
export hiderdecorations!, hidethetadecorations!
export tight_xticklabel_spacing!, tight_yticklabel_spacing!, tight_ticklabel_spacing!, tightlimits!
export set_close_to!
export labelslider!, labelslidergrid!
export addmouseevents!
export interactions, register_interaction!, deregister_interaction!, activate_interaction!, deactivate_interaction!
export MouseEventTypes, MouseEvent, ScrollEvent, KeysEvent
export hlines!, vlines!, abline!, hspan!, vspan!
export Cycle
export Cycled

# from GridLayoutBase
export GridLayout, GridPosition, GridSubposition
export BBox
export LayoutObservables
export Inside, Outside, Mixed
export Fixed, Auto, Relative, Aspect
export width, height, top, bottom, left, right
export with_updates_suspended
export trim!
# these might conflict with other packages and are not used that often
# insertcols! does already conflict with DataFrames
# export appendcols!, appendrows!, prependcols!, prependrows!, deletecol!, deleterow!, insertrows!, insertcols!
export gridnest!
export AxisAspect, DataAspect
export colsize!, rowsize!, colgap!, rowgap!
export Left, Right, Top, Bottom, TopLeft, BottomLeft, TopRight, BottomRight

# hbox and vbox shadow Makie functions
const hgrid! = GridLayoutBase.hbox!
const vgrid! = GridLayoutBase.vbox!

export grid!, hgrid!, vgrid!

export swap!
export ncols, nrows
export contents, content
