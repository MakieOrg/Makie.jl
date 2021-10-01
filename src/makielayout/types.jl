const Optional{T} = Union{Nothing, T}



struct AxisAspect
    aspect::Float32
end

struct DataAspect end


struct Cycler
    counters::Dict{Type, Int}
end

Cycler() = Cycler(Dict{Type, Int}())


struct Cycle
    cycle::Vector{Pair{Vector{Symbol}, Symbol}}
    covary::Bool
end

Cycle(cycle; covary = false) = Cycle(to_cycle(cycle), covary)

to_cycle(single) = [to_cycle_single(single)]
to_cycle(::Nothing) = []
to_cycle(symbolvec::Vector) = map(to_cycle_single, symbolvec)
to_cycle_single(sym::Symbol) = [sym] => sym
to_cycle_single(pair::Pair{Symbol, Symbol}) = [pair[1]] => pair[2]
to_cycle_single(pair::Pair{Vector{Symbol}, Symbol}) = pair



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


# """
#     LogitTicks{T}(linear_ticks::T)

# Wraps any other tick object.
# Used to apply a linear tick searching algorithm on a logit-transformed interval.
# """
# struct LogitTicks{T}
#     linear_ticks::T
# end

"""
    LogTicks{T}(linear_ticks::T)

Wraps any other tick object.
Used to apply a linear tick searching algorithm on a log-transformed interval.
"""
struct LogTicks{T}
    linear_ticks::T
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
    tickpositions::Node{Vector{Point2f}}
    tickvalues::Node{Vector{Float32}}
    ticklabels::Node{Vector{String}}
    minortickpositions::Node{Vector{Point2f}}
    minortickvalues::Node{Vector{Float32}}
end

struct LimitReset end

mutable struct RectangleZoom
    callback::Function
    active::Observable{Bool}
    restrict_x::Bool
    restrict_y::Bool
    from::Union{Nothing, Point2f}
    to::Union{Nothing, Point2f}
    rectnode::Observable{Rect2f}
end

function RectangleZoom(callback::Function; restrict_x=false, restrict_y=false)
    return RectangleZoom(callback, Observable(false), restrict_x, restrict_y,
                         nothing, nothing, Observable(Rect2f(0, 0, 1, 1)))
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

struct DragRotate
end

struct ScrollEvent
    x::Float32
    y::Float32
end

struct KeysEvent
    keys::Set{Makie.Keyboard.Button}
end

@Layoutable Axis begin
    scene::Scene
    xlabel::Observable{String}
    ylabel::Observable{String}
    title::Observable{String}
    titlefont::Observable{Makie.FreeTypeAbstraction.FTFont}
    titlesize::Observable{Float64}
    titlegap::Observable{Float64}
    titlevisible::Observable{Bool}
    titlealign::Observable{Symbol}
    titlecolor::Observable{RGBAf0}
    xlabelfont::Observable{Makie.FreeTypeAbstraction.FTFont}
    ylabelfont::Observable{Makie.FreeTypeAbstraction.FTFont}
    xlabelcolor::Observable{RGBAf0}
    ylabelcolor::Observable{RGBAf0}
    xlabelsize::Observable{Float64}
    ylabelsize::Observable{Float64}
    xlabelvisible::Observable{Bool}
    ylabelvisible::Observable{Bool}
    xlabelpadding::Observable{Float64}
    ylabelpadding::Observable{Float64}
    xticklabelfont::Observable{Makie.FreeTypeAbstraction.FTFont}
    yticklabelfont::Observable{Makie.FreeTypeAbstraction.FTFont}
    xticklabelcolor::Observable{RGBAf0}
    yticklabelcolor::Observable{RGBAf0}
    xticklabelsize::Observable{Float64}
    yticklabelsize::Observable{Float64}
    xticklabelsvisible::Observable{Bool}
    yticklabelsvisible::Observable{Bool}
    xticklabelspace::Observable{Union{Makie.Automatic, Float64}}
    yticklabelspace::Observable{Union{Makie.Automatic, Float64}}
    xticklabelpad::Observable{Float64}
    yticklabelpad::Observable{Float64}
    xticklabelrotation::Observable{Float64}
    yticklabelrotation::Observable{Float64}
    xticklabelalign::Observable{Union{Makie.Automatic, Float64}}
    yticklabelalign::Observable{Union{Makie.Automatic, Float64}}
    xticksize::Observable{Float64}
    yticksize::Observable{Float64}
    xticksvisible::Observable{Bool}
    yticksvisible::Observable{Bool}
    xtickalign::Observable{Float64}
    ytickalign::Observable{Float64}
    xtickwidth::Observable{Float64}
    ytickwidth::Observable{Float64}
    xtickcolor::Observable{RGBAf0}
    ytickcolor::Observable{RGBAf0}
    xpanlock::Observable{Bool}
    ypanlock::Observable{Bool}
    xzoomlock::Observable{Bool}
    yzoomlock::Observable{Bool}
    xrectzoom::Observable{Bool}
    yrectzoom::Observable{Bool}
    spinewidth::Observable{Float64}
    xgridvisible::Observable{Bool}
    ygridvisible::Observable{Bool}
    xgridwidth::Observable{Float64}
    ygridwidth::Observable{Float64}
    xgridcolor::Observable{RGBAf0}
    ygridcolor::Observable{RGBAf0}
    xgridstyle::Observable{Any}
    ygridstyle::Observable{Any}
    xminorgridvisible::Observable{Bool}
    yminorgridvisible::Observable{Bool}
    xminorgridwidth::Observable{Float64}
    yminorgridwidth::Observable{Float64}
    xminorgridcolor::Observable{RGBAf0}
    yminorgridcolor::Observable{RGBAf0}
    xminorgridstyle::Observable{Any}
    yminorgridstyle::Observable{Any}
    bottomspinevisible::Observable{Bool}
    leftspinevisible::Observable{Bool}
    topspinevisible::Observable{Bool}
    rightspinevisible::Observable{Bool}
    bottomspinecolor::Observable{RGBAf0}
    leftspinecolor::Observable{RGBAf0}
    topspinecolor::Observable{RGBAf0}
    rightspinecolor::Observable{RGBAf0}
    aspect::Observable{Any}
    valign::Observable{Any}
    halign::Observable{Any}
    width::Observable{Any}
    height::Observable{Any}
    tellwidth::Observable{Bool}
    tellheight::Observable{Bool}
    xautolimitmargin::Observable{Tuple{Float64, Float64}}
    yautolimitmargin::Observable{Tuple{Float64, Float64}}
    xticks::Observable{Any}
    xtickformat::Observable{Any}
    yticks::Observable{Any}
    ytickformat::Observable{Any}
    panbutton::Observable{Makie.Mouse.Button}
    xpankey::Observable{Makie.Keyboard.Button}
    ypankey::Observable{Makie.Keyboard.Button}
    xzoomkey::Observable{Makie.Keyboard.Button}
    yzoomkey::Observable{Makie.Keyboard.Button}
    xaxisposition::Observable{Symbol}
    yaxisposition::Observable{Symbol}
    xtrimspine::Observable{Bool}
    ytrimspine::Observable{Bool}
    backgroundcolor::Observable{RGBAf0}
    flip_ylabel::Observable{Bool}
    autolimitaspect::Observable{Any}
    limits::Observable{Any}
    alignmode::Observable{Any}
    yreversed::Observable{Bool}
    xreversed::Observable{Bool}
    xminorticksvisible::Observable{Bool}
    xminortickalign::Observable{Float64}
    xminorticksize::Observable{Float64}
    xminortickwidth::Observable{Float64}
    xminortickcolor::Observable{RGBAf0}
    xminorticks::Observable{Any}
    yminorticksvisible::Observable{Bool}
    yminortickalign::Observable{Float64}
    yminorticksize::Observable{Float64}
    yminortickwidth::Observable{Float64}
    yminortickcolor::Observable{RGBAf0}
    yminorticks::Observable{Any}
    xscale::Observable{Function}
    yscale::Observable{Function}
    xaxislinks::Vector{Axis}
    yaxislinks::Vector{Axis}
    targetlimits::Observable{Rect2f}
    finallimits::Observable{Rect2f}
    cycler::Cycler
    palette::Attributes
    block_limit_linking::Observable{Bool}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
end

function RectangleZoom(f::Function, ax::Axis; kw...)
    r = RectangleZoom(f; kw...)
    selection_vertices = lift(_selection_vertices, ax.finallimits, r.rectnode)
    # manually specify correct faces for a rectangle with a rectangle hole inside
    faces = [1 2 5; 5 2 6; 2 3 6; 6 3 7; 3 4 7; 7 4 8; 4 1 8; 8 1 5]
    # fxaa false seems necessary for correct transparency
    mesh = mesh!(ax.scene, selection_vertices, faces, color = (:black, 0.2), shading = false,
                 fxaa = false, inspectable = false, visible=r.active, transparency=true)
    # translate forward so selection mesh and frame are never behind data
    translate!(mesh, 0, 0, 100)
    return r
end

function RectangleZoom(ax::Axis; kw...)
    return RectangleZoom(ax; kw...) do newlims
        if !(0 in widths(newlims))
            ax.targetlimits[] = newlims
        end
        return
    end
end

@Layoutable Colorbar

@Layoutable Label

@Layoutable Box

@Layoutable Slider

@Layoutable IntervalSlider

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

const EntryGroup = Tuple{Optional{<:AbstractString}, Vector{LegendEntry}}

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

@Layoutable Axis3 begin
    scene::Scene
    finallimits::Node{Rect3f}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
    cycler::Cycler
end
