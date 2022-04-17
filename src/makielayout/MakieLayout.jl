import Formatting
using Match
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
include("blocks/box.jl")
include("blocks/button.jl")
include("blocks/colorbar.jl")
include("blocks/intervalslider.jl")
include("blocks/label.jl")
include("blocks/legend.jl")
include("blocks/menu.jl")
include("blocks/polaraxis.jl")
include("blocks/scene.jl")
include("blocks/slider.jl")
include("blocks/slidergrid.jl")
include("blocks/toggle.jl")
include("blocks/textbox.jl")

export Axis
export Axis3
export AxisAspect, DataAspect
export Box
export Button
export Colorbar
export Cycle
export Cycled
export IntervalSlider
export LScene
export Label
export Legend, axislegend
export LegendEntry, MarkerElement, PolyElement, LineElement, LegendElement
export LinearTicks, WilkinsonTicks, MultiplesTicks, IntervalsBetween, LogTicks
export Menu
export MouseEventTypes, MouseEvent, ScrollEvent, KeysEvent
export PolarAxis2
export Slider
export SliderGrid
export Textbox
export Toggle
export addmouseevents!
export autolimits!, limits!, reset_limits!
export hidexdecorations!, hideydecorations!, hidedecorations!, hidespines!
export hlines!, vlines!, abline!, hspan!, vspan!
export interactions, register_interaction!, deregister_interaction!, activate_interaction!, deactivate_interaction!
export labelslider!, labelslidergrid!
export linkxaxes!, linkyaxes!, linkaxes!
export set_close_to!
export tight_xticklabel_spacing!, tight_yticklabel_spacing!, tight_ticklabel_spacing!, tightlimits!

# from GridLayoutBase
export GridLayout, GridPosition, GridSubposition
export GridLayoutSpec
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

Base.@deprecate_binding MakieLayout Makie true "The module `MakieLayout` has been removed and integrated into Makie, so simply replace all usage of `MakieLayout` with `Makie`."
