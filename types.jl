const BBox = Rect2D{Float32}

const Optional{T} = Union{Nothing, T}

struct RectSides{T<:Real}
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

abstract type AbstractLayout end

"""
Used to specify space that is occupied in a grid. Like 1:1|1:1 for the first square,
or 2:3|1:4 for a rect over the 2nd and 3rd row and the first four columns.
"""
struct Span
    rows::UnitRange{Int64}
    cols::UnitRange{Int64}
end

"""
An object that can be aligned that also specifies how much space it occupies in
a grid via its span.
"""
struct SpannedLayout{T <: AbstractLayout}
    al::T
    sp::Span
    side::Side
end

abstract type AlignMode end

struct Inside <: AlignMode end
struct Outside <: AlignMode
    padding::RectSides{Float32}
end
Outside() = Outside(0f0)
Outside(padding::Real) = Outside(RectSides{Float32}(padding, padding, padding, padding))
Outside(left::Real, right::Real, bottom::Real, top::Real) =
    Outside(RectSides{Float32}(left, right, bottom, top))

abstract type ContentSize end
abstract type GapSize <: ContentSize end

struct Auto <: ContentSize
    trydetermine::Bool # false for determinable size content that should be ignored
    ratio::Float64 # float ratio in case it's not determinable

    Auto(trydetermine::Bool = true, ratio::Real = 1.0) = new(trydetermine, ratio)
end

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

mutable struct GridLayout <: AbstractLayout
    parent::Union{Nothing, Scene, GridLayout, Node{<:Rect2D}}
    content::Vector{SpannedLayout}
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
    valign::Node{Symbol}
    halign::Node{Symbol}
    _update_func_handle::Optional{Function} # stores a reference to the result of on(obs)

    function GridLayout(
        parent, content, nrows, ncols, rowsizes, colsizes,
        addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update,
        valign, halign)

        gl = new(nothing, content, nrows, ncols, rowsizes, colsizes,
            addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps,
            needs_update, false, valign, halign, nothing)

        validategridlayout(gl)

        attach_parent!(gl, parent)

        on(needs_update) do update
            request_update(gl)
        end

        gl
    end
end


struct SolvedGridLayout <: AbstractLayout
    bbox::BBox
    content::Vector{SpannedLayout}
    nrows::Int
    ncols::Int
    grid::RowCols{Vector{Float64}}
end

struct AxisAspect
    aspect::Float32
end

struct DataAspect end

mutable struct ProtrusionLayout{T} <: AbstractLayout
    parent::Union{Nothing, GridLayout}
    protrusions::Node{RectSides{Float32}}
    computedsize::Node{NTuple{2, Optional{Float32}}}
    needs_update::Node{Bool}
    content::T
end

struct SolvedProtrusionLayout{T} <: AbstractLayout
    bbox::BBox
    content::T
end

abstract type Ticks end

struct AutoLinearTicks <: Ticks
    idealtickdistance::Float32
end

struct ManualTicks <: Ticks
    values::Vector{Float32}
    labels::Vector{String}
end

struct AxisContent{T}
    content::T
    attributes::Attributes
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

struct LayoutNodes
    suggestedbbox::Node{BBox}
    protrusions::Node{RectSides{Float32}}
    computedsize::Node{NTuple{2, Optional{Float32}}}
    computedbbox::Node{BBox}
end

abstract type LObject end

mutable struct LAxis <: AbstractPlotting.AbstractScene
    parent::Scene
    scene::Scene
    plots::Vector{AxisContent}
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
    text::AbstractPlotting.Text
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

struct PatchElement <: LegendElement
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
