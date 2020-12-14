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

@Layoutable LAxis begin
    scene::Scene
    xaxislinks::Vector{LAxis}
    yaxislinks::Vector{LAxis}
    limits::Node{FRect2D}
    block_limit_linking::Node{Bool}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
end

@Layoutable LColorbar

@Layoutable LText

@Layoutable LRect

@Layoutable LSlider

@Layoutable LButton

@Layoutable LToggle

@Layoutable LMenu


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

@Layoutable LScene begin
    scene::Scene
end

@Layoutable LTextbox begin
    cursorindex::Node{Int}
    cursoranimtask
end
