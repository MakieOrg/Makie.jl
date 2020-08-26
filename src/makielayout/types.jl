const Optional{T} = Union{Nothing, T}



struct AxisAspect
    aspect::Float32
end

struct DataAspect end


"""
LinearTicks with ideally a number of `n_ideal` tick marks.
"""
struct LinearTicks
    n_ideal::Int

    function LinearTicks(n_ideal)
        if n_ideal <= 0
            error("Ideal number of ticks can't be smaller than 0, but is $n_ideal")
        end
        new(n_ideal)
    end
end

struct WilkinsonTicks
    k_ideal::Int
    k_min::Int
    k_max::Int
    Q::Vector{Tuple{Float64, Float64}}
    granularity_weight::Float64
    simplicity_weight::Float64
    coverage_weight::Float64
    niceness_weight::Float64
    min_px_dist::Float64
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
    limits::Node{FRect2D}
    layoutobservables::LayoutObservables
    attributes::Attributes
    block_limit_linking::Node{Bool}
    decorations::Dict{Symbol, Any}
end

mutable struct LColorbar <: LObject
    parent::Scene
    layoutobservables::LayoutObservables
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

mutable struct LText <: LObject
    parent::Scene
    layoutobservables::LayoutObservables
    textobject::AbstractPlotting.Text
    attributes::Attributes
end

mutable struct LRect <: LObject
    parent::Scene
    layoutobservables::LayoutObservables
    rect::AbstractPlotting.Poly
    attributes::Attributes
end

struct LSlider <: LObject
    parent::Scene
    scene::Scene
    layoutobservables::LayoutObservables
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LButton <: LObject
    parent::Scene
    layoutobservables::LayoutObservables
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LToggle <: LObject
    parent::Scene
    layoutobservables::LayoutObservables
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

const EntryGroup = Tuple{Optional{String}, Vector{LegendEntry}}

struct LLegend <: LObject
    scene::Scene
    entrygroups::Node{Vector{EntryGroup}}
    layoutobservables::LayoutObservables
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LScene <: AbstractPlotting.AbstractScene
    scene::Scene
    attributes::Attributes
    layoutobservables::MakieLayout.LayoutObservables
end

mutable struct LTextbox <: LObject
    scene::Scene
    attributes::Attributes
    layoutobservables::GridLayoutBase.LayoutObservables
    decorations::Dict{Symbol, Any}
    cursorindex::Node{Int}
    cursoranimtask
end
