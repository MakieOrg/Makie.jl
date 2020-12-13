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

struct LimitReset end

mutable struct RectangleZoom
    active::Bool
    restrict_x::Bool
    restrict_y::Bool
    from::Union{Nothing, Point2f0}
    to::Union{Nothing, Point2f0}
    rectnode::Observable{FRect2D}
    plots::Vector{AbstractPlot}
end

struct ScrollZoom
    speed::Float32
    reset_timer::Ref{Any}
    prev_xticklabelspace::Ref{Any}
    prev_yticklabelspace::Ref{Any}
    reset_delay::Float32
end

struct DragPan
    reset_timer::Ref{Any}
    prev_xticklabelspace::Ref{Any}
    prev_yticklabelspace::Ref{Any}
    reset_delay::Float32
end

struct ScrollEvent
    x::Float32
    y::Float32
end

struct KeysEvent
    keys::Set{AbstractPlotting.Keyboard.Button}
end

abstract type LObject end

mutable struct LAxis <: AbstractPlotting.AbstractScene
    figure::Figure
    scene::Scene
    xaxislinks::Vector{LAxis}
    yaxislinks::Vector{LAxis}
    limits::Node{FRect2D}
    layoutobservables::LayoutObservables
    attributes::Attributes
    block_limit_linking::Node{Bool}
    decorations::Dict{Symbol, Any}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
end

# mutable struct LColorbar <: LObject
#     parent::Scene
#     layoutobservables::LayoutObservables
#     attributes::Attributes
#     decorations::Dict{Symbol, Any}
# end

@Layoutable LColorbar

@Layoutable LText

# mutable struct LText <: LObject
#     parent::Scene
#     layoutobservables::LayoutObservables
#     textobject::AbstractPlotting.Text
#     attributes::Attributes
# end

@Layoutable LRect

# mutable struct LRect <: LObject
#     parent::Scene
#     layoutobservables::LayoutObservables
#     rect::AbstractPlotting.Poly
#     attributes::Attributes
# end

@Layoutable LSlider

# struct LSlider <: LObject
#     parent::Scene
#     layoutobservables::LayoutObservables
#     attributes::Attributes
#     decorations::Dict{Symbol, Any}
# end

@Layoutable LButton

# struct LButton <: LObject
#     parent::Scene
#     layoutobservables::LayoutObservables
#     attributes::Attributes
#     decorations::Dict{Symbol, Any}
# end

@Layoutable LToggle

# struct LToggle <: LObject
#     parent::Scene
#     layoutobservables::LayoutObservables
#     attributes::Attributes
#     decorations::Dict{Symbol, Any}
# end

@Layoutable LMenu

# struct LMenu <: LObject
#     scene::Scene
#     attributes::Attributes
#     layoutobservables::GridLayoutBase.LayoutObservables
#     decorations::Dict{Symbol, Any}
# end

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

@Layoutable LLegend begin
    entrygroups::Node{Vector{EntryGroup}}
end

# struct LLegend <: LObject
#     scene::Scene
#     entrygroups::Node{Vector{EntryGroup}}
#     layoutobservables::LayoutObservables
#     attributes::Attributes
#     decorations::Dict{Symbol, Any}
# end

struct LScene <: AbstractPlotting.AbstractScene
    scene::Scene
    attributes::Attributes
    layoutobservables::MakieLayout.LayoutObservables
end

@Layoutable LTextbox begin
    cursorindex::Node{Int}
    cursoranimtask
end

# mutable struct LTextbox <: LObject
#     scene::Scene
#     attributes::Attributes
#     layoutobservables::GridLayoutBase.LayoutObservables
#     decorations::Dict{Symbol, Any}
#     cursorindex::Node{Int}
#     cursoranimtask
# end
