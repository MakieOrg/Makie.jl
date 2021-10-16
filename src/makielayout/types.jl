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

@Block Axis begin
    scene::Scene
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
    xaxis::LineAxis
    yaxis::LineAxis
    @attributes begin
        "The xlabel string."
        xlabel::String = ""
        "The ylabel string."
        ylabel::String = ""
        "The axis title string."
        title::String = ""
        "The font family of the title."
        titlefont::Makie.FreeTypeAbstraction.FTFont = @inherit(:font, "DejaVu Sans")
        "The title's font size."
        titlesize::Float64 = @inherit(:fontsize, 16f0)
        "The gap between axis and title."
        titlegap::Float64 = 4f0
        "Controls if the title is visible."
        titlevisible::Bool = true
        "The horizontal alignment of the title."
        titlealign::Symbol = :center
        "The color of the title"
        titlecolor::RGBAf0 = @inherit(:textcolor, :black)
        "The font family of the xlabel."
        xlabelfont::Makie.FreeTypeAbstraction.FTFont = @inherit(:font, "DejaVu Sans")
        "The font family of the ylabel."
        ylabelfont::Makie.FreeTypeAbstraction.FTFont = @inherit(:font, "DejaVu Sans")
        "The color of the xlabel."
        xlabelcolor::RGBAf0 = @inherit(:textcolor, :black)
        "The color of the ylabel."
        ylabelcolor::RGBAf0 = @inherit(:textcolor, :black)
        "The font size of the xlabel."
        xlabelsize::Float64 = @inherit(:fontsize, 16f0)
        "The font size of the ylabel."
        ylabelsize::Float64 = @inherit(:fontsize, 16f0)
        "Controls if the xlabel is visible."
        xlabelvisible::Bool = true
        "Controls if the ylabel is visible."
        ylabelvisible::Bool = true
        "The padding between the xlabel and the ticks or axis."
        xlabelpadding::Float64 = 3f0
        "The padding between the ylabel and the ticks or axis."
        ylabelpadding::Float64 = 5f0 # because of boundingbox inaccuracies of ticklabels
        "The font family of the xticklabels."
        xticklabelfont::Makie.FreeTypeAbstraction.FTFont = @inherit(:font, "DejaVu Sans")
        "The font family of the yticklabels."
        yticklabelfont::Makie.FreeTypeAbstraction.FTFont = @inherit(:font, "DejaVu Sans")
        "The color of xticklabels."
        xticklabelcolor::RGBAf0 = @inherit(:textcolor, :black)
        "The color of yticklabels."
        yticklabelcolor::RGBAf0 = @inherit(:textcolor, :black)
        "The font size of the xticklabels."
        xticklabelsize::Float64 = @inherit(:fontsize, 16f0)
        "The font size of the yticklabels."
        yticklabelsize::Float64 = @inherit(:fontsize, 16f0)
        "Controls if the xticklabels are visible."
        xticklabelsvisible::Bool = true
        "Controls if the yticklabels are visible."
        yticklabelsvisible::Bool = true
        "The space reserved for the xticklabels."
        xticklabelspace::Union{Makie.Automatic, Float64} = Makie.automatic
        "The space reserved for the yticklabels."
        yticklabelspace::Union{Makie.Automatic, Float64} = Makie.automatic
        "The space between xticks and xticklabels."
        xticklabelpad::Float64 = 2f0
        "The space between yticks and yticklabels."
        yticklabelpad::Float64 = 4f0
        "The counterclockwise rotation of the xticklabels in radians."
        xticklabelrotation::Float64 = 0f0
        "The counterclockwise rotation of the yticklabels in radians."
        yticklabelrotation::Float64 = 0f0
        "The horizontal and vertical alignment of the xticklabels."
        xticklabelalign::Union{Makie.Automatic, Float64} = Makie.automatic
        "The horizontal and vertical alignment of the yticklabels."
        yticklabelalign::Union{Makie.Automatic, Float64} = Makie.automatic
        "The size of the xtick marks."
        xticksize::Float64 = 6f0
        "The size of the ytick marks."
        yticksize::Float64 = 6f0
        "Controls if the xtick marks are visible."
        xticksvisible::Bool = true
        "Controls if the ytick marks are visible."
        yticksvisible::Bool = true
        "The alignment of the xtick marks relative to the axis spine (0 = out, 1 = in)."
        xtickalign::Float64 = 0f0
        "The alignment of the ytick marks relative to the axis spine (0 = out, 1 = in)."
        ytickalign::Float64 = 0f0
        "The width of the xtick marks."
        xtickwidth::Float64 = 1f0
        "The width of the ytick marks."
        ytickwidth::Float64 = 1f0
        "The color of the xtick marks."
        xtickcolor::RGBAf0 = RGBf(0, 0, 0)
        "The color of the ytick marks."
        ytickcolor::RGBAf0 = RGBf(0, 0, 0)
        "Locks interactive panning in the x direction."
        xpanlock::Bool = false
        "Locks interactive panning in the y direction."
        ypanlock::Bool = false
        "Locks interactive zooming in the x direction."
        xzoomlock::Bool = false
        "Locks interactive zooming in the y direction."
        yzoomlock::Bool = false
        "Controls if rectangle zooming affects the x dimension."
        xrectzoom::Bool = true
        "Controls if rectangle zooming affects the y dimension."
        yrectzoom::Bool = true
        "The width of the axis spines."
        spinewidth::Float64 = 1f0
        "Controls if the x grid lines are visible."
        xgridvisible::Bool = true
        "Controls if the y grid lines are visible."
        ygridvisible::Bool = true
        "The width of the x grid lines."
        xgridwidth::Float64 = 1f0
        "The width of the y grid lines."
        ygridwidth::Float64 = 1f0
        "The color of the x grid lines."
        xgridcolor::RGBAf0 = RGBAf(0, 0, 0, 0.12)
        "The color of the y grid lines."
        ygridcolor::RGBAf0 = RGBAf(0, 0, 0, 0.12)
        "The linestyle of the x grid lines."
        xgridstyle = nothing
        "The linestyle of the y grid lines."
        ygridstyle = nothing
        "Controls if the x minor grid lines are visible."
        xminorgridvisible::Bool = false
        "Controls if the y minor grid lines are visible."
        yminorgridvisible::Bool = false
        "The width of the x minor grid lines."
        xminorgridwidth::Float64 = 1f0
        "The width of the y minor grid lines."
        yminorgridwidth::Float64 = 1f0
        "The color of the x minor grid lines."
        xminorgridcolor::RGBAf0 = RGBAf(0, 0, 0, 0.05)
        "The color of the y minor grid lines."
        yminorgridcolor::RGBAf0 = RGBAf(0, 0, 0, 0.05)
        "The linestyle of the x minor grid lines."
        xminorgridstyle = nothing
        "The linestyle of the y minor grid lines."
        yminorgridstyle = nothing
        "Controls if the bottom axis spine is visible."
        bottomspinevisible::Bool = true
        "Controls if the left axis spine is visible."
        leftspinevisible::Bool = true
        "Controls if the top axis spine is visible."
        topspinevisible::Bool = true
        "Controls if the right axis spine is visible."
        rightspinevisible::Bool = true
        "The color of the bottom axis spine."
        bottomspinecolor::RGBAf0 = :black
        "The color of the left axis spine."
        leftspinecolor::RGBAf0 = :black
        "The color of the top axis spine."
        topspinecolor::RGBAf0 = :black
        "The color of the right axis spine."
        rightspinecolor::RGBAf0 = :black
        "The forced aspect ratio of the axis. `nothing` leaves the axis unconstrained, `DataAspect()` forces the same ratio as the ratio in data limits between x and y axis, `AxisAspect(ratio)` sets a manual ratio."
        aspect = nothing
        "The vertical alignment of the axis within its suggested bounding box."
        valign = :center
        "The horizontal alignment of the axis within its suggested bounding box."
        halign = :center
        "The width of the axis."
        width = nothing
        "The height of the axis."
        height = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The relative margins added to the autolimits in x direction."
        xautolimitmargin::Tuple{Float64, Float64} = (0.05f0, 0.05f0)
        "The relative margins added to the autolimits in y direction."
        yautolimitmargin::Tuple{Float64, Float64} = (0.05f0, 0.05f0)
        "The xticks."
        xticks = Makie.automatic
        "Format for xticks."
        xtickformat = Makie.automatic
        "The yticks."
        yticks = Makie.automatic
        "Format for yticks."
        ytickformat = Makie.automatic
        "The button for panning."
        panbutton::Makie.Mouse.Button = Makie.Mouse.right
        "The key for limiting panning to the x direction."
        xpankey::Makie.Keyboard.Button = Makie.Keyboard.x
        "The key for limiting panning to the y direction."
        ypankey::Makie.Keyboard.Button = Makie.Keyboard.y
        "The key for limiting zooming to the x direction."
        xzoomkey::Makie.Keyboard.Button = Makie.Keyboard.x
        "The key for limiting zooming to the y direction."
        yzoomkey::Makie.Keyboard.Button = Makie.Keyboard.y
        "The position of the x axis (`:bottom` or `:top`)."
        xaxisposition::Symbol = :bottom
        "The position of the y axis (`:left` or `:right`)."
        yaxisposition::Symbol = :left
        "Controls if the x spine is limited to the furthest tick marks or not."
        xtrimspine::Bool = false
        "Controls if the y spine is limited to the furthest tick marks or not."
        ytrimspine::Bool = false
        "The background color of the axis."
        backgroundcolor::RGBAf0 = :white
        "Controls if the ylabel's rotation is flipped."
        flip_ylabel::Bool = false
        "Constrains the data aspect ratio (`nothing` leaves the ratio unconstrained)."
        autolimitaspect = nothing
        "The limits that the user has manually set. They are reinstated when calling `reset_limits!` and are set to nothing by `autolimits!`. Can be either a tuple (xlow, xhigh, ylow, high) or a tuple (nothing_or_xlims, nothing_or_ylims). Are set by `xlims!`, `ylims!` and `limits!`."
        limits = (nothing, nothing)
        "The align mode of the axis in its parent GridLayout."
        alignmode = Inside()
        "Controls if the y axis goes upwards (false) or downwards (true)"
        yreversed::Bool = false
        "Controls if the x axis goes rightwards (false) or leftwards (true)"
        xreversed::Bool = false
        "Controls if minor ticks on the x axis are visible"
        xminorticksvisible::Bool = false
        "The alignment of x minor ticks on the axis spine"
        xminortickalign::Float64 = 0f0
        "The tick size of x minor ticks"
        xminorticksize::Float64 = 4f0
        "The tick width of x minor ticks"
        xminortickwidth::Float64 = 1f0
        "The tick color of x minor ticks"
        xminortickcolor::RGBAf0 = :black
        "The tick locator for the x minor ticks"
        xminorticks = IntervalsBetween(2)
        "Controls if minor ticks on the y axis are visible"
        yminorticksvisible::Bool = false
        "The alignment of y minor ticks on the axis spine"
        yminortickalign::Float64 = 0f0
        "The tick size of y minor ticks"
        yminorticksize::Float64 = 4f0
        "The tick width of y minor ticks"
        yminortickwidth::Float64 = 1f0
        "The tick color of y minor ticks"
        yminortickcolor::RGBAf0 = :black
        "The tick locator for the y minor ticks"
        yminorticks = IntervalsBetween(2)
        "The x axis scale"
        xscale::Function = identity
        "The y axis scale"
        yscale::Function = identity
    end
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

@Block Colorbar

@Block Label

@Block Box

@Block Slider

@Block IntervalSlider

@Block Button

@Block Toggle

@Block Menu


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

@Block Legend begin
    entrygroups::Node{Vector{EntryGroup}}
end

@Block LScene begin
    scene::Scene
end

@Block Textbox begin
    cursorindex::Node{Int}
    cursoranimtask
end

@Block Axis3 begin
    scene::Scene
    finallimits::Node{Rect3f}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
    cycler::Cycler
end
