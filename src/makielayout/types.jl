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

"""
Like LinearTicks but for multiples of `multiple`.
Example where approximately 5 numbers should be found
that are multiples of pi, printed like "1π", "2π", etc.:

```
MultiplesTicks(5, pi, "π")
```
"""
struct MultiplesTicks
    n_ideal::Int
    multiple::Float64
    suffix::String
end

"""
    IntervalsBetween(n::Int, mirror::Bool = true)

Indicates to create n-1 minor ticks between every pair of adjacent major ticks.
"""
struct IntervalsBetween
    n::Int
    mirror::Bool
    function IntervalsBetween(n::Int, mirror::Bool)
        n < 2 && error("You can't have $n intervals (must be at least 2 which means 1 minor tick)")
        new(n, mirror)
    end
end
IntervalsBetween(n) = IntervalsBetween(n, true)


mutable struct LineAxis
    parent::Scene
    protrusion::Node{Float32}
    attributes::Attributes
    elements::Dict{Symbol, Any}
    tickpositions::Node{Vector{Point2f0}}
    tickvalues::Node{Vector{Float32}}
    ticklabels::Node{Vector{String}}
    minortickpositions::Node{Vector{Point2f0}}
    minortickvalues::Node{Vector{Float32}}
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

@Layoutable Axis begin
    scene::Scene
    xaxislinks::Vector{Axis}
    yaxislinks::Vector{Axis}
    limits::Node{FRect2D}
    block_limit_linking::Node{Bool}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
end

@Layoutable Colorbar

@Layoutable Label

@Layoutable Box

@Layoutable Slider

@Layoutable Button

@Layoutable Toggle

@Layoutable Menu


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

@Layoutable Legend begin
    entrygroups::Node{Vector{EntryGroup}}
end

@Layoutable LScene begin
    scene::Scene
end

@Layoutable Textbox begin
    cursorindex::Node{Int}
    cursoranimtask
end
