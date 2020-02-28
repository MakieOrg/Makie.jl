const BBox = Rect2D{Float32}

const Optional{T} = Union{Nothing, T}

struct RectSides{T}
    left::T
    right::T
    bottom::T
    top::T
end

abstract type Side end

struct Left <: Side end
struct Right <: Side end
struct Top <: Side end
struct Bottom <: Side end
# for protrusion content:
struct TopLeft <: Side end
struct TopRight <: Side end
struct BottomLeft <: Side end
struct BottomRight <: Side end

struct Inner <: Side end
struct Outer <: Side end

abstract type GridDir end
struct Col <: GridDir end
struct Row <: GridDir end

struct RowCols{T <: Union{Number, Vector{Float64}}}
    lefts::T
    rights::T
    tops::T
    bottoms::T
end


"""
    struct Span

Used to specify space that is occupied in a grid. Like 1:1|1:1 for the first square,
or 2:3|1:4 for a rect over the 2nd and 3rd row and the first four columns.
"""
struct Span
    rows::UnitRange{Int64}
    cols::UnitRange{Int64}
end

"""
    mutable struct GridContent{G, T}

Wraps content elements of a `GridLayout`. It keeps track of the `parent`, the `content` and its position in the grid via `span` and `side`.
"""
mutable struct GridContent{G, T} # G should be GridLayout but can't be used before definition
    parent::Optional{G}
    content::T
    span::Span
    side::Side
    needs_update::Node{Bool}
    protrusions_handle::Optional{Function}
    computedsize_handle::Optional{Function}
end

abstract type AlignMode end

"AlignMode that excludes the protrusions from the bounding box."
struct Inside <: AlignMode end

"AlignMode that includes the protrusions within the bounding box, plus paddings."
struct Outside <: AlignMode
    padding::RectSides{Float32}
end
Outside() = Outside(0f0)
Outside(padding::Real) = Outside(RectSides{Float32}(padding, padding, padding, padding))
Outside(left::Real, right::Real, bottom::Real, top::Real) =
    Outside(RectSides{Float32}(left, right, bottom, top))

"AlignMode that is Inside where padding is Nothing and Outside where it is Real."
struct Mixed <: AlignMode
    padding::RectSides{Union{Nothing, Float32}}
end
function Mixed(; left = nothing, right = nothing, bottom = nothing, top = nothing)
    paddings = map((left, right, bottom, top)) do side
        isnothing(side) ? side : Float32(side)
    end
    Mixed(RectSides{Union{Nothing, Float32}}(paddings...))
end

abstract type ContentSize end
abstract type GapSize <: ContentSize end

"""
    struct Auto <: ContentSize

If used as a `GridLayout`'s row / column size and `trydetermine == true`, signals to the `GridLayout` that the row / column should shrink to match the largest determinable element inside.
If no size of a content element can be determined, the remaining space is split between all `Auto` rows / columns according to their `ratio`.

If used as width / height of a layoutable element and `trydetermine == true`, the element's computed width / height will report the auto width / height if it can be determined.
This enables a parent `GridLayout` to adjust its column / rowsize to the element's width / height.
If `trydetermine == false`, the element's computed width / height will report `nothing` even if an auto width / height can be determined, which will prohibit a parent `GridLayout` from adjusting a row / column to the element's width / height.
This is useful to, e.g., prohibit a `GridLayout` from shrinking a column's width to the width of a super title, even though the title's width can be auto-determined.

The `ratio` is ignored if `Auto` is used as an element size.
"""
struct Auto <: ContentSize
    trydetermine::Bool # false for determinable size content that should be ignored
    ratio::Float64 # float ratio in case it's not determinable

    Auto(trydetermine::Bool = true, ratio::Real = 1.0) = new(trydetermine, ratio)
end
Auto(ratio::Real) = Auto(true, ratio)

struct Fixed <: GapSize
    x::Float64
end
struct Relative <: GapSize
    x::Float64
end
struct Aspect <: ContentSize
    index::Int
    ratio::Float64
end

"""
    mutable struct LayoutNodes{T, G}

`T` is the same type parameter of contained `GridContent`, `G` is `GridLayout` which is defined only after `LayoutNodes`.

A collection of `Node`s and an optional `GridContent` that are needed to interface with the MakieLayout layouting system.

- `suggestedbbox::Node{BBox}`: The bounding box that an element should place itself in. Depending on the element's `width` and `height` attributes, this is not necessarily equal to the computedbbox.
- `protrusions::Node{RectSides{Float32}}`: The sizes of content "sticking out" of the main element into the `GridLayout` gaps.
- `computedsize::Node{NTuple{2, Optional{Float32}}}`: The width and height that the element computes for itself if possible (else `nothing`).
- `autosize::Node{NTuple{2, Optional{Float32}}}`: The width and height that the element reports to its parent `GridLayout`. If the element doesn't want to cause the parent to adjust to its size, autosize can hide the computedsize from it by being set to `nothing`.
- `computedbbox::Node{BBox}`: The bounding box that the element computes for itself after it has received a suggestedbbox.
- `gridcontent::Optional{GridContent{G, T}}`: A reference of a `GridContent` if the element is currently placed in a `GridLayout`. This can be used to retrieve the parent layout, remove the element from it or change its position, and assign it to a different layout.
"""
mutable struct LayoutNodes{T, G} # G again GridLayout
    suggestedbbox::Node{BBox}
    protrusions::Node{RectSides{Float32}}
    computedsize::Node{NTuple{2, Optional{Float32}}}
    autosize::Node{NTuple{2, Optional{Float32}}}
    computedbbox::Node{BBox}
    gridcontent::Optional{GridContent{G, T}} # the connecting link to the gridlayout
end

mutable struct GridLayout
    content::Vector{GridContent}
    nrows::Int
    ncols::Int
    rowsizes::Vector{ContentSize}
    colsizes::Vector{ContentSize}
    addedrowgaps::Vector{GapSize}
    addedcolgaps::Vector{GapSize}
    alignmode::AlignMode
    equalprotrusiongaps::Tuple{Bool, Bool}
    needs_update::Node{Bool}
    block_updates::Bool
    layoutnodes::LayoutNodes
    attributes::Attributes
    parentscene::Optional{AbstractPlotting.Scene}
    _update_func_handle::Optional{Function} # stores a reference to the result of on(obs)

    function GridLayout(
        content, nrows, ncols, rowsizes, colsizes,
        addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update,
        layoutnodes, attributes, parentscene)

        gl = new(content, nrows, ncols, rowsizes, colsizes,
            addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps,
            needs_update, false, layoutnodes, attributes, parentscene, nothing)

        validategridlayout(gl)

        # attach_parent!(gl, parent)

        # on(needs_update) do update
        #     request_update(gl)
        # end

        gl
    end
end


struct AxisAspect
    aspect::Float32
end

struct DataAspect end

abstract type Ticks end

struct AutoLinearTicks{T<:Union{Int, Float32}} <: Ticks
    target::T
end

struct ManualTicks <: Ticks
    values::Vector{Float32}
    labels::Vector{String}
end

"""
    struct CustomTicks{F1<:Function, F2<:Function} <: Ticks

For the use of custom functions that compute tick values and labels in an `LAxis`.

- `f_tickvalues::F1`: A function that takes minimum_value, maximum_value, and pixelwidth as arguments and returns a `Float` array of tick values.
- `f_ticklabels::F2`: A function that takes in an array of `Float`s and returns an array of `String` labels.
"""
struct CustomTicks{F1<:Function, F2<:Function} <: Ticks
    f_tickvalues::F1
    f_ticklabels::F2
end

mutable struct LineAxis
    parent::Scene
    protrusion::Node{Float32}
    attributes::Attributes
    decorations::Dict{Symbol, Any}
    tickpositions::Node{Vector{Point2f0}}
    tickvalues::Node{Vector{Float32}}
    ticklabels::Node{Vector{String}}
end

abstract type LObject end

mutable struct LAxis <: AbstractPlotting.AbstractScene
    parent::Scene
    scene::Scene
    xaxislinks::Vector{LAxis}
    yaxislinks::Vector{LAxis}
    limits::Node{BBox}
    layoutnodes::LayoutNodes
    needs_update::Node{Bool}
    attributes::Attributes
    block_limit_linking::Node{Bool}
    decorations::Dict{Symbol, Any}
end

mutable struct LColorbar <: LObject
    parent::Scene
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

mutable struct LText <: LObject
    parent::Scene
    layoutnodes::LayoutNodes
    textobject::AbstractPlotting.Text
    attributes::Attributes
end

mutable struct LRect <: LObject
    parent::Scene
    layoutnodes::LayoutNodes
    rect::AbstractPlotting.Poly
    attributes::Attributes
end

struct LSlider <: LObject
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LButton <: LObject
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LToggle <: LObject
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

abstract type LegendElement end

struct LineElement <: LegendElement
    attributes::Attributes
end

struct MarkerElement <: LegendElement
    attributes::Attributes
end

struct PolyElement <: LegendElement
    attributes::Attributes
end

struct LegendEntry
    elements::Vector{LegendElement}
    attributes::Attributes
end

struct LLegend <: LObject
    scene::Scene
    entries::Node{Vector{LegendEntry}}
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
    entrytexts::Vector{LText}
    entryplots::Vector{Vector{AbstractPlot}}
end

const Indexables = Union{UnitRange, Int, Colon}

struct GridPosition
    layout::GridLayout
    rows::Indexables # this doesn't warrant type parameters I think
    cols::Indexables # as these objects will only be used briefly
end

struct LScene <: AbstractPlotting.AbstractScene
    scene::Scene
    attributes::Attributes
    layoutnodes::MakieLayout.LayoutNodes
end
