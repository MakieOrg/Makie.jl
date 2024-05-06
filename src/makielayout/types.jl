const Optional{T} = Union{Nothing, T}



struct AxisAspect
    aspect::Float32
end

struct DataAspect end

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
    Cycled(i::Int)

If a `Cycled` value is passed as an attribute to a plotting function,
it is replaced with the value from the cycler for this attribute (as
long as there is one defined) at the index `i`.
"""
struct Cycled
    i::Int
end

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
    AngularTicks(label_factor, suffix[, n_ideal::Vector{Vec2f}])

Sets up AngularTicks with a predetermined amount of ticks. `label_factor` can be
used to transform the tick labels from radians to degree. `suffix` is added to
the end of the generated label strings. `n_ideal` can be used to affect the ideal
number of ticks. It represents a set of linear function which are combined using
`mapreduce(v -> v[1] * delta + v[2], min, m.n_ideal)` where
`delta = maximum(limits) - minimum(limits)`.
"""
struct AngularTicks
    label_factor::Float64
    suffix::String
    n_ideal::Vector{Vec2f}
    function AngularTicks(label_factor, suffix, n_ideal = [Vec2f(0, 9), Vec2f(3.8, 4)])
        return new(label_factor, suffix, n_ideal)
    end
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
    protrusion::Observable{Float32}
    attributes::Attributes
    elements::Dict{Symbol, Any}
    tickpositions::Observable{Vector{Point2f}}
    tickvalues::Observable{Vector{Float32}}
    ticklabels::Observable{Vector{Any}}
    minortickpositions::Observable{Vector{Point2f}}
    minortickvalues::Observable{Vector{Float32}}
end

struct LimitReset end

mutable struct RectangleZoom
    callback::Function
    active::Observable{Bool}
    restrict_x::Bool
    restrict_y::Bool
    from::Union{Nothing, Point2d}
    to::Union{Nothing, Point2d}
    rectnode::Observable{Rect2d}
    modifier::Any # e.g. Keyboard.left_alt, or some other button that needs to be pressed to start rectangle... Defaults to `true`, which means no modifier needed
end

function RectangleZoom(callback::Function; restrict_x=false, restrict_y=false, modifier=true)
    return RectangleZoom(callback, Observable(false), restrict_x, restrict_y,
                         nothing, nothing, Observable(Rect2d(0, 0, 1, 1)), modifier)
end

struct ScrollZoom
    speed::Float32
    reset_timer::RefValue{Union{Nothing, Timer}}
    prev_xticklabelspace::RefValue{Union{Automatic, Float64}}
    prev_yticklabelspace::RefValue{Union{Automatic, Float64}}
    reset_delay::Float32
end

function ScrollZoom(speed, reset_delay)
    return ScrollZoom(speed, RefValue{Union{Nothing, Timer}}(nothing), RefValue{Union{Automatic, Float64}}(0.0), RefValue{Union{Automatic, Float64}}(0.0), reset_delay)
end

struct DragPan
    reset_timer::RefValue{Union{Nothing, Timer}}
    prev_xticklabelspace::RefValue{Union{Automatic, Float64}}
    prev_yticklabelspace::RefValue{Union{Automatic, Float64}}
    reset_delay::Float32
end

function DragPan(reset_delay)
    return DragPan(RefValue{Union{Nothing, Timer}}(nothing), RefValue{Union{Automatic, Float64}}(0.0), RefValue{Union{Automatic, Float64}}(0.0), reset_delay)
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

@Block Axis <: AbstractAxis begin
    scene::Scene
    xaxislinks::Vector{Axis}
    yaxislinks::Vector{Axis}
    targetlimits::Observable{Rect2d}
    finallimits::Observable{Rect2d}
    block_limit_linking::Observable{Bool}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
    xaxis::LineAxis
    yaxis::LineAxis
    elements::Dict{Symbol, Any}
    @attributes begin
        """
        Global state for the x dimension conversion.
        """
        dim1_conversion = nothing
        """
        Global state for the y dimension conversion.
        """
        dim2_conversion = nothing

        """
        The content of the x axis label.
        The value can be any non-vector-valued object that the `text` primitive supports.
        """
        xlabel = ""
        """
        The content of the y axis label.
        The value can be any non-vector-valued object that the `text` primitive supports.
        """
        ylabel = ""
        """
        The content of the axis title.
        The value can be any non-vector-valued object that the `text` primitive supports.
        """
        title = ""
        "The font family of the title."
        titlefont = :bold
        "The title's font size."
        titlesize::Float64 = @inherit(:fontsize, 16f0)
        "The gap between axis and title."
        titlegap::Float64 = 4f0
        "Controls if the title is visible."
        titlevisible::Bool = true
        """
        The horizontal alignment of the title.
        The subtitle always follows this alignment setting.

        Options are `:center`, `:left` or `:right`.
        """
        titlealign::Symbol = :center
        "The color of the title"
        titlecolor::RGBAf = @inherit(:textcolor, :black)
        "The axis title line height multiplier."
        titlelineheight::Float64 = 1
        """
        The content of the axis subtitle.
        The value can be any non-vector-valued object that the `text` primitive supports.
        """
        subtitle = ""
        "The font family of the subtitle."
        subtitlefont = :regular
        "The subtitle's font size."
        subtitlesize::Float64 = @inherit(:fontsize, 16f0)
        "The gap between subtitle and title."
        subtitlegap::Float64 = 0
        "Controls if the subtitle is visible."
        subtitlevisible::Bool = true
        "The color of the subtitle"
        subtitlecolor::RGBAf = @inherit(:textcolor, :black)
        "The axis subtitle line height multiplier."
        subtitlelineheight::Float64 = 1
        "The font family of the xlabel."
        xlabelfont = :regular
        "The font family of the ylabel."
        ylabelfont = :regular
        "The color of the xlabel."
        xlabelcolor::RGBAf = @inherit(:textcolor, :black)
        "The color of the ylabel."
        ylabelcolor::RGBAf = @inherit(:textcolor, :black)
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
        ylabelpadding::Float64 = 5f0 # xlabels usually have some more visual padding because of ascenders, which are larger than the hadvance gaps of ylabels
        "The xlabel rotation in radians."
        xlabelrotation = Makie.automatic
        "The ylabel rotation in radians."
        ylabelrotation = Makie.automatic
        "The font family of the xticklabels."
        xticklabelfont = :regular
        "The font family of the yticklabels."
        yticklabelfont = :regular
        "The color of xticklabels."
        xticklabelcolor = @inherit(:textcolor, :black)
        "The color of yticklabels."
        yticklabelcolor = @inherit(:textcolor, :black)
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
        xticklabelalign::Union{Makie.Automatic, Tuple{Symbol, Symbol}} = Makie.automatic
        "The horizontal and vertical alignment of the yticklabels."
        yticklabelalign::Union{Makie.Automatic, Tuple{Symbol, Symbol}} = Makie.automatic
        "The size of the xtick marks."
        xticksize::Float64 = 5f0
        "The size of the ytick marks."
        yticksize::Float64 = 5f0
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
        xtickcolor = RGBf(0, 0, 0)
        "The color of the ytick marks."
        ytickcolor = RGBf(0, 0, 0)
        "Controls if the x ticks and minor ticks are mirrored on the other side of the Axis."
        xticksmirrored::Bool = false
        "Controls if the y ticks and minor ticks are mirrored on the other side of the Axis."
        yticksmirrored::Bool = false
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
        xgridcolor = RGBAf(0, 0, 0, 0.12)
        "The color of the y grid lines."
        ygridcolor = RGBAf(0, 0, 0, 0.12)
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
        xminorgridcolor = RGBAf(0, 0, 0, 0.05)
        "The color of the y minor grid lines."
        yminorgridcolor = RGBAf(0, 0, 0, 0.05)
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
        bottomspinecolor::RGBAf = :black
        "The color of the left axis spine."
        leftspinecolor::RGBAf = :black
        "The color of the top axis spine."
        topspinecolor::RGBAf = :black
        "The color of the right axis spine."
        rightspinecolor::RGBAf = :black
        """
        Controls the forced aspect ratio of the axis.

        The default `nothing` will not constrain the aspect ratio.
        The axis area will span the available width and height in the layout.

        `DataAspect()` reduces the effective axis size within the available layout space
        so that the axis aspect ratio width/height matches that of the data limits.
        For example, if the x limits range from 0 to 300 and the y limits from 100 to 250, `DataAspect()` will result
        in an aspect ratio of `(300 - 0) / (250 - 100) = 2`.
        This can be useful when plotting images, because the image will be displayed unsquished.

        `AxisAspect(ratio)` reduces the effective axis size within the available layout space
        so that the axis aspect ratio width/height matches `ratio`.

        Note that both `DataAspect` and `AxisAspect` can result in excess whitespace around the axis.
        To make a `GridLayout` aware of aspect ratio constraints, refer to the `Aspect` column or row size setting.
        """
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
        """
        Controls what numerical tick values are calculated for the x axis.

        To determine tick values and labels, Makie first calls `Makie.get_ticks(xticks, xscale, xtickformat, xmin, xmax)`.
        If there is no special method defined for the current combination of
        ticks, scale and formatter which returns both tick values and labels at once,
        then the numerical tick values will be determined using
        `xtickvalues = Makie.get_tickvalues(xticks, xscale, xmin, xmax)` after which the labels are determined using
        `Makie.get_ticklabels(xtickformat, xtickvalues)`.

        Common objects that can be used as ticks are:
        - A vector of numbers
        - A tuple with two vectors `(numbers, labels)` where `labels` can be any objects that `text` can handle.
        - `WilkinsonTicks`, the default tick finder for linear ticks
        - `LinearTicks`, an alternative tick finder for linear ticks
        - `LogTicks`, a wrapper that applies any other wrapped tick finder on log-transformed values
        - `MultiplesTicks`, for finding ticks at multiples of a given value, such as `π`
        """
        xticks = Makie.automatic
        """
        The formatter for the ticks on the x axis.

        Usually, the tick values are determined first using `Makie.get_tickvalues`, after which
        `Makie.get_ticklabels(xtickformat, xtickvalues)` is called. If there is a special method defined,
        tick values and labels can be determined together using `Makie.get_ticks` instead. Check the
        docstring for `xticks` for more information.

        Common objects that can be used for tick formatting are:
        - A `Function` that takes a vector of numbers and returns a vector of labels. A label can be anything
          that can be plotted by the `text` primitive.
        - A `String` which is used as a format specifier for `Format.jl`. For example, `"{:.2f}kg"`
          formats numbers rounded to 2 decimal digits and with the suffix `kg`.
        """
        xtickformat = Makie.automatic
        """
        Controls what numerical tick values are calculated for the y axis.

        To determine tick values and labels, Makie first calls `Makie.get_ticks(yticks, yscale, ytickformat, ymin, ymax)`.
        If there is no special method defined for the current combination of
        ticks, scale and formatter which returns both tick values and labels at once,
        then the numerical tick values will be determined using
        `ytickvalues = Makie.get_tickvalues(yticks, yscale, ymin, ymax)` after which the labels are determined using
        `Makie.get_ticklabels(ytickformat, ytickvalues)`.

        Common objects that can be used as ticks are:
        - A vector of numbers
        - A tuple with two vectors `(numbers, labels)` where `labels` can be any objects that `text` can handle.
        - `WilkinsonTicks`, the default tick finder for linear ticks
        - `LinearTicks`, an alternative tick finder for linear ticks
        - `LogTicks`, a wrapper that applies any other wrapped tick finder on log-transformed values
        - `MultiplesTicks`, for finding ticks at multiples of a given value, such as `π`
        """
        yticks = Makie.automatic
        """
        The formatter for the ticks on the y axis.

        Usually, the tick values are determined first using `Makie.get_tickvalues`, after which
        `Makie.get_ticklabels(ytickformat, ytickvalues)` is called. If there is a special method defined,
        tick values and labels can be determined together using `Makie.get_ticks` instead. Check the
        docstring for `yticks` for more information.

        Common objects that can be used for tick formatting are:
        - A `Function` that takes a vector of numbers and returns a vector of labels. A label can be anything
          that can be plotted by the `text` primitive.
        - A `String` which is used as a format specifier for `Format.jl`. For example, `"{:.2f}kg"`
          formats numbers rounded to 2 decimal digits and with the suffix `kg`.
        """
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
        """
        If `true`, limits the x axis spine's extent to the outermost major tick marks.
        Can also be set to a `Tuple{Bool,Bool}` to control each side separately.
        """
        xtrimspine::Union{Bool, Tuple{Bool,Bool}}  = false
        """
        If `true`, limits the y axis spine's extent to the outermost major tick marks.
        Can also be set to a `Tuple{Bool,Bool}` to control each side separately.
        """
        ytrimspine::Union{Bool, Tuple{Bool,Bool}} = false
        "The background color of the axis."
        backgroundcolor::RGBAf = :white
        "Controls if the ylabel's rotation is flipped."
        flip_ylabel::Bool = false
        """
        If `autolimitaspect` is set to a number, the limits of the axis
        will autoadjust such that the ratio of the limits to the axis size equals
        that number.

        For example, if the axis size is 100 x 200, then with `autolimitaspect = 1`,
        the autolimits will also have a ratio of 1 to 2. The setting `autolimitaspect = 1`
        is the complement to `aspect = AxisAspect(1)`, but while `aspect` changes the axis
        size, `autolimitaspect` changes the limits to achieve the desired ratio.
        """
        autolimitaspect = nothing
        """
        Can be used to manually specify which axis limits are desired.

        The `limits` attribute cannot be used to read out the actual limits of the axis.
        The value of `limits` does not change when interactively zooming and panning and the axis can be reset
        accordingly using the function `reset_limits!`.

        The function `autolimits!` resets the value of `limits` to `(nothing, nothing)` and adjusts the axis limits according
        to the extents of the plots added to the axis.

        The value of `limits` can be a four-element tuple `(xlow, xhigh, ylow, yhigh)` where each value
        can be a real number or `nothing`.
        It can also be a tuple `(x, y)` where `x` and `y` can be `nothing` or a tuple `(low, high)`.
        In all cases, `nothing` means that the respective limit values will be automatically determined.

        Automatically determined limits are also influenced by `xautolimitmargin` and `yautolimitmargin`.

        The convenience functions `xlims!` and `ylims!` allow to set only the x or y part of `limits`.
        The function `limits!` is another option to set both x and y simultaneously.
        """
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
        xminorticksize::Float64 = 3f0
        "The tick width of x minor ticks"
        xminortickwidth::Float64 = 1f0
        "The tick color of x minor ticks"
        xminortickcolor = :black
        """
        The tick locator for the minor ticks of the x axis.

        Common objects that can be used are:
        - `IntervalsBetween`, divides the space between two adjacent major ticks into `n` intervals
          for `n-1` minor ticks
        - A vector of numbers
        """
        xminorticks = IntervalsBetween(2)
        "Controls if minor ticks on the y axis are visible"
        yminorticksvisible::Bool = false
        "The alignment of y minor ticks on the axis spine"
        yminortickalign::Float64 = 0f0
        "The tick size of y minor ticks"
        yminorticksize::Float64 = 3f0
        "The tick width of y minor ticks"
        yminortickwidth::Float64 = 1f0
        "The tick color of y minor ticks"
        yminortickcolor = :black
        """
        The tick locator for the minor ticks of the y axis.

        Common objects that can be used are:
        - `IntervalsBetween`, divides the space between two adjacent major ticks into `n` intervals
          for `n-1` minor ticks
        - A vector of numbers
        """
        yminorticks = IntervalsBetween(2)
        """
        The scaling function for the x axis.

        Can be any invertible function, some predefined options are
        `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.
        To use a custom function, you have to define appropriate methods for `Makie.inverse_transform`,
        `Makie.defaultlimits` and `Makie.defined_interval`.

        If the scaling function is only defined over a limited interval,
        no plot object may have a source datum that lies outside of that range.
        For example, there may be no x value lower than or equal to 0 when `log`
        is selected for `xscale`. What matters are the source data, not the user-selected
        limits, because all data have to be transformed, irrespective of whether they
        lie inside or outside of the current limits.

        The axis scale may affect tick finding and formatting, depending
        on the values of `xticks` and `xtickformat`.
        """
        xscale = identity
        """
        The scaling function for the y axis.

        Can be any invertible function, some predefined options are
        `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.
        To use a custom function, you have to define appropriate methods for `Makie.inverse_transform`,
        `Makie.defaultlimits` and `Makie.defined_interval`.

        If the scaling function is only defined over a limited interval,
        no plot object may have a source datum that lies outside of that range.
        For example, there may be no y value lower than or equal to 0 when `log`
        is selected for `yscale`. What matters are the source data, not the user-selected
        limits, because all data have to be transformed, irrespective of whether they
        lie inside or outside of the current limits.

        The axis scale may affect tick finding and formatting, depending
        on the values of `yticks` and `ytickformat`.
        """
        yscale = identity
    end
end

function RectangleZoom(f::Function, ax::Axis; kw...)
    r = RectangleZoom(f; kw...)
    selection_vertices = lift(_selection_vertices, ax.blockscene, Observable(ax.scene), ax.finallimits,
                              r.rectnode)
    # manually specify correct faces for a rectangle with a rectangle hole inside
    faces = [1 2 5; 5 2 6; 2 3 6; 6 3 7; 3 4 7; 7 4 8; 4 1 8; 8 1 5]
    # plot to blockscene, so ax.scene stays exclusive for user plots
    # That's also why we need to pass `ax.scene` to _selection_vertices, so it can project to that space
    mesh = mesh!(ax.blockscene, selection_vertices, faces, color = (:black, 0.2), shading = NoShading,
                 inspectable = false, visible=r.active, transparency=true)
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

@Block Colorbar begin
    axis::LineAxis
    @attributes begin
        "The color bar label string."
        label = ""
        "The label color."
        labelcolor = @inherit(:textcolor, :black)
        "The label font family."
        labelfont = :regular
        "The label font size."
        labelsize = @inherit(:fontsize, 16f0)
        "Controls if the label is visible."
        labelvisible = true
        "The gap between the label and the ticks."
        labelpadding = 5f0
        "The label rotation in radians."
        labelrotation = Makie.automatic
        "The font family of the tick labels."
        ticklabelfont = :regular
        "The font size of the tick labels."
        ticklabelsize = @inherit(:fontsize, 16f0)
        "Controls if the tick labels are visible."
        ticklabelsvisible = true
        "The color of the tick labels."
        ticklabelcolor = @inherit(:textcolor, :black)
        "The size of the tick marks."
        ticksize = 5f0
        "Controls if the tick marks are visible."
        ticksvisible = true
        "The ticks."
        ticks = Makie.automatic
        "Format for ticks."
        tickformat = Makie.automatic
        "The space reserved for the tick labels."
        ticklabelspace = Makie.automatic
        "The gap between tick labels and tick marks."
        ticklabelpad = 3f0
        "The alignment of the tick marks relative to the axis spine (0 = out, 1 = in)."
        tickalign = 0f0
        "The line width of the tick marks."
        tickwidth = 1f0
        "The color of the tick marks."
        tickcolor = RGBf(0, 0, 0)
        "The horizontal and vertical alignment of the tick labels."
        ticklabelalign = Makie.automatic
        "The rotation of the ticklabels."
        ticklabelrotation = 0f0
        "The line width of the spines."
        spinewidth = 1f0
        "Controls if the top spine is visible."
        topspinevisible = true
        "Controls if the right spine is visible."
        rightspinevisible = true
        "Controls if the left spine is visible."
        leftspinevisible = true
        "Controls if the bottom spine is visible."
        bottomspinevisible = true
        "The color of the top spine."
        topspinecolor = RGBf(0, 0, 0)
        "The color of the left spine."
        leftspinecolor = RGBf(0, 0, 0)
        "The color of the right spine."
        rightspinecolor = RGBf(0, 0, 0)
        "The color of the bottom spine."
        bottomspinecolor = RGBf(0, 0, 0)
        "The vertical alignment of the colorbar in its suggested bounding box."
        valign = :center
        "The horizontal alignment of the colorbar in its suggested bounding box."
        halign = :center
        "Controls if the colorbar is oriented vertically."
        vertical = true
        "Flips the axis to the right if vertical and to the top if horizontal."
        flipaxis = true
        "Flips the colorbar label if the axis is vertical."
        flip_vertical_label = false
        "The width setting of the colorbar. Use `size` to set width or height relative to colorbar orientation instead."
        width = Auto()
        "The height setting of the colorbar."
        height = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true

        "The colormap that the colorbar uses."
        colormap = @inherit(:colormap, :viridis)
        "The range of values depicted in the colorbar."
        limits = nothing
        "The range of values depicted in the colorbar."
        colorrange = nothing
        "The color of the high clip triangle."
        highclip = nothing
        "The color of the low clip triangle."
        lowclip = nothing
        "The axis scale"
        scale = identity


        "The align mode of the colorbar in its parent GridLayout."
        alignmode = Inside()
        "The number of steps in the heatmap underlying the colorbar gradient."
        nsteps = 100

        "Controls if minor ticks are visible"
        minorticksvisible = false
        "The alignment of minor ticks on the axis spine"
        minortickalign = 0f0
        "The tick size of minor ticks"
        minorticksize = 3f0
        "The tick width of minor ticks"
        minortickwidth = 1f0
        "The tick color of minor ticks"
        minortickcolor = :black
        "The tick locator for the minor ticks"
        minorticks = IntervalsBetween(5)
        "The width or height of the colorbar, depending on if it's vertical or horizontal, unless overridden by `width` / `height`"
        size = 12
    end
end

@Block Label begin
    @attributes begin
        "The displayed text string."
        text = "Text"
        "Controls if the text is visible."
        visible::Bool = true
        "The color of the text."
        color::RGBAf = @inherit(:textcolor, :black)
        "The font size of the text."
        fontsize::Float32 = @inherit(:fontsize, 16f0)
        "The font family of the text."
        font = :regular
        "The justification of the text (:left, :right, :center)."
        justification = :center
        "The lineheight multiplier for the text."
        lineheight::Float32 = 1.0
        "The vertical alignment of the text in its suggested boundingbox"
        valign = :center
        "The horizontal alignment of the text in its suggested boundingbox"
        halign = :center
        "The counterclockwise rotation of the text in radians."
        rotation::Float32 = 0f0
        "The extra space added to the sides of the text boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The height setting of the text."
        height = Auto()
        "The width setting of the text."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The align mode of the text in its parent GridLayout."
        alignmode = Inside()
        "Enable word wrapping to the suggested width of the Label."
        word_wrap::Bool = false
    end
end

@Block Box begin
    @attributes begin
        "Controls if the rectangle is visible."
        visible = true
        "The color of the rectangle."
        color = RGBf(0.9, 0.9, 0.9)
        "The vertical alignment of the rectangle in its suggested boundingbox"
        valign = :center
        "The horizontal alignment of the rectangle in its suggested boundingbox"
        halign = :center
        "The line width of the rectangle's border."
        strokewidth = 1f0
        "Controls if the border of the rectangle is visible."
        strokevisible = true
        "The color of the border."
        strokecolor = RGBf(0, 0, 0)
        "The linestyle of the rectangle border"
        linestyle = nothing
        "The radius of the rounded corner. One number is for all four corners, four numbers for going clockwise from top-right."
        cornerradius = 0.0
        "The width setting of the rectangle."
        width = nothing
        "The height setting of the rectangle."
        height = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The align mode of the rectangle in its parent GridLayout."
        alignmode = Inside()
    end
end

@Block Slider begin
    selected_index::Observable{Int}
    @attributes begin
        "The horizontal alignment of the element in its suggested bounding box."
        halign = :center
        "The vertical alignment of the element in its suggested bounding box."
        valign = :center
        "The width setting of the element."
        width = Auto()
        "The height setting of the element."
        height = Auto()
        "The range of values that the slider can pick from."
        range = 0:0.01:10
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The start value of the slider or the value that is closest in the slider range."
        startvalue = 0
        "The current value of the slider. Don't set this manually, use the function `set_close_to!`."
        value = 0
        "The width of the slider line"
        linewidth::Float32 = 10
        "The color of the slider when the mouse hovers over it."
        color_active_dimmed::RGBAf = COLOR_ACCENT_DIMMED[]
        "The color of the slider when the mouse clicks and drags the slider."
        color_active::RGBAf = COLOR_ACCENT[]
        "The color of the slider when it is not interacted with."
        color_inactive::RGBAf = RGBf(0.94, 0.94, 0.94)
        "Controls if the slider has a horizontal orientation or not."
        horizontal::Bool = true
        "The align mode of the slider in its parent GridLayout."
        alignmode = Inside()
        "Controls if the button snaps to valid positions or moves freely"
        snap::Bool = true
    end
end

@Block SliderGrid begin
    @forwarded_layout
    sliders::Vector{Slider}
    valuelabels::Vector{Label}
    labels::Vector{Label}
    @attributes begin
        "The horizontal alignment of the block in its suggested bounding box."
        halign = :center
        "The vertical alignment of the block in its suggested bounding box."
        valign = :center
        "The width setting of the block."
        width = Auto()
        "The height setting of the block."
        height = Auto()
        "Controls if the parent layout can adjust to this block's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this block's height"
        tellheight::Bool = true
        "The align mode of the block in its parent GridLayout."
        alignmode = Inside()
        "The width of the value label column. If `automatic`, the width is determined by sampling a few values from the slider ranges and picking the largest label size found."
        value_column_width = automatic
    end
end

@Block IntervalSlider begin
    selected_indices::Observable{Tuple{Int, Int}}
    displayed_sliderfractions::Observable{Tuple{Float64, Float64}}
    @attributes begin
        "The horizontal alignment of the slider in its suggested bounding box."
        halign = :center
        "The vertical alignment of the slider in its suggested bounding box."
        valign = :center
        "The width setting of the slider."
        width = Auto()
        "The height setting of the slider."
        height = Auto()
        "The range of values that the slider can pick from."
        range = 0:0.01:10
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The start values of the slider or the values that are closest in the slider range."
        startvalues = Makie.automatic
        "The current interval of the slider. Don't set this manually, use the function `set_close_to!`."
        interval = (0, 0)
        "The width of the slider line"
        linewidth::Float64 = 10.0
        "The color of the slider when the mouse hovers over it."
        color_active_dimmed::RGBAf = COLOR_ACCENT_DIMMED[]
        "The color of the slider when the mouse clicks and drags the slider."
        color_active::RGBAf = COLOR_ACCENT[]
        "The color of the slider when it is not interacted with."
        color_inactive::RGBAf = RGBf(0.94, 0.94, 0.94)
        "Controls if the slider has a horizontal orientation or not."
        horizontal::Bool = true
        "The align mode of the slider in its parent GridLayout."
        alignmode = Inside()
        "Controls if the buttons snap to valid positions or move freely"
        snap::Bool = true
    end
end

@Block Button begin
    @attributes begin
        "The horizontal alignment of the button in its suggested boundingbox"
        halign = :center
        "The vertical alignment of the button in its suggested boundingbox"
        valign = :center
        "The extra space added to the sides of the button label's boundingbox."
        padding = (8f0, 8f0, 8f0, 8f0)
        "The font size of the button label."
        fontsize = @inherit(:fontsize, 16f0)
        "The text of the button label."
        label = "Button"
        "The font family of the button label."
        font = :regular
        "The width setting of the button."
        width = Auto()
        "The height setting of the button."
        height = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The radius of the rounded corners of the button."
        cornerradius = 4
        "The number of poly segments used for each rounded corner."
        cornersegments = 10
        "The line width of the button border."
        strokewidth = 2f0
        "The color of the button border."
        strokecolor = :transparent
        "The color of the button."
        buttoncolor = RGBf(0.94, 0.94, 0.94)
        "The color of the label."
        labelcolor = @inherit(:textcolor, :black)
        "The color of the label when the mouse hovers over the button."
        labelcolor_hover = :black
        "The color of the label when the mouse clicks the button."
        labelcolor_active = :white
        "The color of the button when the mouse clicks the button."
        buttoncolor_active = COLOR_ACCENT[]
        "The color of the button when the mouse hovers over the button."
        buttoncolor_hover = COLOR_ACCENT_DIMMED[]
        "The number of clicks that have been registered by the button."
        clicks = 0
        "The align mode of the button in its parent GridLayout."
        alignmode = Inside()
    end
end

@Block Toggle begin
    @attributes begin
        "The horizontal alignment of the toggle in its suggested bounding box."
        halign = :center
        "The vertical alignment of the toggle in its suggested bounding box."
        valign = :center
        "The width of the toggle."
        width = 32
        "The height of the toggle."
        height = 18
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The number of poly segments in each rounded corner."
        cornersegments = 15
        # strokewidth = 2f0
        # strokecolor = :transparent
        "The color of the border when the toggle is inactive."
        framecolor_inactive = RGBf(0.94, 0.94, 0.94)
        "The color of the border when the toggle is hovered."
        framecolor_active = COLOR_ACCENT_DIMMED[]
        # buttoncolor = RGBf(0.2, 0.2, 0.2)
        "The color of the toggle button."
        buttoncolor = COLOR_ACCENT[]
        "Indicates if the toggle is active or not."
        active = false
        "The duration of the toggle animation."
        toggleduration = 0.15
        "The border width as a fraction of the toggle height "
        rimfraction = 0.33
        "The align mode of the toggle in its parent GridLayout."
        alignmode = Inside()
    end
end

@Block Menu begin
    @attributes begin
        "The height setting of the menu."
        height = Auto()
        "The width setting of the menu."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the menu in its suggested bounding box."
        halign = :center
        "The vertical alignment of the menu in its suggested bounding box."
        valign = :center
        "The alignment of the menu in its suggested bounding box."
        alignmode = Inside()
        "Index of selected item. Should not be set by the user."
        i_selected = 0
        "Selected item value. This is the output observable that you should listen to to react to menu interaction. Should not be set by the user."
        selection = nothing
        "Is the menu showing the available options"
        is_open = false
        "Cell color when hovered"
        cell_color_hover = COLOR_ACCENT_DIMMED[]
        "Cell color when active"
        cell_color_active = COLOR_ACCENT[]
        "Cell color when inactive even"
        cell_color_inactive_even = RGBf(0.97, 0.97, 0.97)
        "Cell color when inactive odd"
        cell_color_inactive_odd = RGBf(0.97, 0.97, 0.97)
        "Selection cell color when inactive"
        selection_cell_color_inactive = RGBf(0.94, 0.94, 0.94)
        "Color of the dropdown arrow"
        dropdown_arrow_color = (:black, 0.2)
        "Size of the dropdown arrow"
        dropdown_arrow_size = 10
        "The list of options selectable in the menu. This can be any iterable of a mixture of strings and containers with one string and one other value. If an entry is just a string, that string is both label and selection. If an entry is a container with one string and one other value, the string is the label and the other value is the selection."
        options = ["no options"]
        "Font size of the cell texts"
        fontsize = @inherit(:fontsize, 16f0)
        "Padding of entry texts"
        textpadding = (8, 10, 8, 8)
        "Color of entry texts"
        textcolor = :black
        "The opening direction of the menu (:up or :down)"
        direction = automatic
        "The default message prompting a selection when i == 0"
        prompt = "Select..."
        "Speed of scrolling in large Menu lists."
        scroll_speed = 15.0
    end
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

const EntryGroup = Tuple{Any, Vector{LegendEntry}}

@Block Legend begin
    entrygroups::Observable{Vector{EntryGroup}}
    _tellheight::Observable{Bool}
    _tellwidth::Observable{Bool}
    grid::GridLayout
    @attributes begin
        "The horizontal alignment of the legend in its suggested bounding box."
        halign = :center
        "The vertical alignment of the legend in its suggested bounding box."
        valign = :center
        "The width setting of the legend."
        width = Auto()
        "The height setting of the legend."
        height = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = automatic
        "Controls if the parent layout can adjust to this element's height"
        tellheight = automatic
        "The font family of the legend group titles."
        titlefont = :bold
        "The font size of the legend group titles."
        titlesize = @inherit(:fontsize, 16f0)
        "The horizontal alignment of the legend group titles."
        titlehalign = :center
        "The vertical alignment of the legend group titles."
        titlevalign = :center
        "Controls if the legend titles are visible."
        titlevisible = true
        "The color of the legend titles"
        titlecolor = @inherit(:textcolor, :black)
        "The group title positions relative to their groups. Can be `:top` or `:left`."
        titleposition = :top
        "The font size of the entry labels."
        labelsize = @inherit(:fontsize, 16f0)
        "The font family of the entry labels."
        labelfont = :regular
        "The color of the entry labels."
        labelcolor = @inherit(:textcolor, :black)
        "The horizontal alignment of the entry labels."
        labelhalign = :left
        "The justification of the label text. Default is `automatic`, which will set the justification to labelhalign."
        labeljustification = automatic
        "The vertical alignment of the entry labels."
        labelvalign = :center
        "The additional space between the legend content and the border."
        padding = (6f0, 6f0, 6f0, 6f0)
        "The additional space between the legend and its suggested boundingbox."
        margin = (0f0, 0f0, 0f0, 0f0)
        "The background color of the legend. DEPRECATED - use `backgroundcolor` instead."
        bgcolor = nothing
        "The background color of the legend."
        backgroundcolor = :white
        "The color of the legend border."
        framecolor = :black
        "The line width of the legend border."
        framewidth = 1f0
        "Controls if the legend border is visible."
        framevisible = true
        "The size of the rectangles containing the legend markers. It can help to increase the width if line patterns are not clearly visible with the default size."
        patchsize = (20f0, 20f0)
        "The color of the border of the patches containing the legend markers."
        patchstrokecolor = :transparent
        "The line width of the border of the patches containing the legend markers."
        patchstrokewidth = 1f0
        "The color of the patches containing the legend markers."
        patchcolor = :transparent
        "The default entry label."
        label = "undefined"
        "The number of banks in which the legend entries are grouped. Columns if the legend is vertically oriented, otherwise rows."
        nbanks = 1
        "The gap between the label of one legend entry and the patch of the next."
        colgap = 16
        "The gap between the entry rows."
        rowgap = 3
        "The gap between the patch and the label of each legend entry."
        patchlabelgap = 5
        "The default points used for LineElements in normalized coordinates relative to each label patch."
        linepoints = [Point2f(0, 0.5), Point2f(1, 0.5)]
        "The default line width used for LineElements."
        linewidth = theme(scene, :linewidth)
        "The default line color used for LineElements"
        linecolor = theme(scene, :linecolor)
        "The default colormap for LineElements"
        linecolormap = theme(scene, :colormap)
        "The default colorrange for LineElements"
        linecolorrange = automatic
        "The default line style used for LineElements"
        linestyle = :solid
        "The default marker color for MarkerElements"
        markercolor = theme(scene, :markercolor)
        "The default marker colormap for MarkerElements"
        markercolormap = theme(scene, :colormap)
        "The default marker colorrange for MarkerElements"
        markercolorrange = automatic
        "The default marker for MarkerElements"
        marker = theme(scene, :marker)
        "The default marker points used for MarkerElements in normalized coordinates relative to each label patch."
        markerpoints = [Point2f(0.5, 0.5)]
        "The default marker size used for MarkerElements."
        markersize = theme(scene, :markersize)
        "The default marker stroke width used for MarkerElements."
        markerstrokewidth = theme(scene, :markerstrokewidth)
        "The default marker stroke color used for MarkerElements."
        markerstrokecolor = theme(scene, :markerstrokecolor)
        "The default poly points used for PolyElements in normalized coordinates relative to each label patch."
        polypoints = [Point2f(0, 0), Point2f(1, 0), Point2f(1, 1), Point2f(0, 1)]
        "The default poly stroke width used for PolyElements."
        polystrokewidth = theme(scene, :patchstrokewidth)
        "The default poly color used for PolyElements."
        polycolor = theme(scene, :patchcolor)
        "The default poly stroke color used for PolyElements."
        polystrokecolor = theme(scene, :patchstrokecolor)
        "The default colormap for PolyElements"
        polycolormap = theme(scene, :colormap)
        "The default colorrange for PolyElements"
        polycolorrange = automatic
        "The orientation of the legend (:horizontal or :vertical)."
        orientation = :vertical
        "The gap between each group title and its group."
        titlegap = 8
        "The gap between each group and the next."
        groupgap = 16
        "The horizontal alignment of entry groups in their parent GridLayout."
        gridshalign = :center
        "The vertical alignment of entry groups in their parent GridLayout."
        gridsvalign = :center
        "The align mode of the legend in its parent GridLayout."
        alignmode = Inside()
    end
end

@Block LScene <: AbstractAxis begin
    scene::Scene
    @attributes begin
        """
        Global state for the x dimension conversion.
        """
        dim1_conversion = nothing
        """
        Global state for the y dimension conversion.
        """
        dim2_conversion = nothing
        """
        Global state for the z dimension conversion.
        """
        dim3_conversion = nothing

        "The height setting of the scene."
        height = nothing
        "The width setting of the scene."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the scene in its suggested bounding box."
        halign = :center
        "The vertical alignment of the scene in its suggested bounding box."
        valign = :center
        "The alignment of the scene in its suggested bounding box."
        alignmode = Inside()
        "Controls the visibility of the 3D axis plot object."
        show_axis::Bool = true
    end
end

@Block Textbox begin
    cursorindex::Observable{Int}
    cursoranimtask
    @attributes begin
        "The height setting of the textbox."
        height = Auto()
        "The width setting of the textbox."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width."
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height."
        tellheight = true
        "The horizontal alignment of the textbox in its suggested bounding box."
        halign = :center
        "The vertical alignment of the textbox in its suggested bounding box."
        valign = :center
        "The alignment of the textbox in its suggested bounding box."
        alignmode = Inside()
        "A placeholder text that is displayed when the saved string is nothing."
        placeholder = "Click to edit..."
        "The currently stored string."
        stored_string = nothing
        "The currently displayed string (for internal use)."
        displayed_string = nothing
        "Controls if the displayed text is reset to the stored text when defocusing the textbox without submitting."
        reset_on_defocus = false
        "Controls if the textbox is defocused when a string is submitted."
        defocus_on_submit = true
        "Text size."
        fontsize = @inherit(:fontsize, 16f0)
        "Text color."
        textcolor = @inherit(:textcolor, :black)
        "Text color for the placeholder."
        textcolor_placeholder = RGBf(0.5, 0.5, 0.5)
        "Font family."
        font = :regular
        "Color of the box."
        boxcolor = :transparent
        "Color of the box when focused."
        boxcolor_focused = :transparent
        "Color of the box when focused."
        boxcolor_focused_invalid = RGBAf(1, 0, 0, 0.3)
        "Color of the box when hovered."
        boxcolor_hover = :transparent
        "Color of the box border."
        bordercolor = RGBf(0.80, 0.80, 0.80)
        "Color of the box border when hovered."
        bordercolor_hover = COLOR_ACCENT_DIMMED[]
        "Color of the box border when focused."
        bordercolor_focused = COLOR_ACCENT[]
        "Color of the box border when focused and invalid."
        bordercolor_focused_invalid = RGBf(1, 0, 0)
        "Width of the box border."
        borderwidth = 1f0
        "Padding of the text against the box."
        textpadding = (8, 8, 8, 8)
        "If the textbox is focused and receives text input."
        focused = false
        "Corner radius of text box."
        cornerradius = 5
        "Corner segments of one rounded corner."
        cornersegments = 20
        "Validator that is called with validate_textbox(string, validator) to determine if the current string is valid. Can by default be a RegEx that needs to match the complete string, or a function taking a string as input and returning a Bool. If the validator is a type T (for example Float64), validation will be `tryparse(T, string)`."
        validator = str -> true
        "Restricts the allowed unicode input via is_allowed(char, restriction)."
        restriction = nothing
        "The color of the cursor."
        cursorcolor = :transparent
    end
end

@Block Axis3 <: AbstractAxis begin
    scene::Scene
    finallimits::Observable{Rect3f}
    mouseeventhandle::MouseEventHandle
    scrollevents::Observable{ScrollEvent}
    keysevents::Observable{KeysEvent}
    interactions::Dict{Symbol, Tuple{Bool, Any}}
    @attributes begin
        """
        Global state for the x dimension conversion.
        """
        dim1_conversion = nothing
        """
        Global state for the y dimension conversion.
        """
        dim2_conversion = nothing
        """
        Global state for the z dimension conversion.
        """
        dim3_conversion = nothing
        "The height setting of the scene."
        height = nothing
        "The width setting of the scene."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the scene in its suggested bounding box."
        halign = :center
        "The vertical alignment of the scene in its suggested bounding box."
        valign = :center
        "The alignment of the scene in its suggested bounding box."
        alignmode = Inside()
        "The elevation (up / down) angle of the camera. Possible values are between -pi/2 (looking from the bottom up) and +pi/2 (looking from the top down)."
        elevation = pi/8
        """
        The azimuth (left / right) angle of the camera.

        At `azimuth = 0`, the camera looks at the axis from a point on the positive x axis, and rotates to the right from there
        with increasing values. At the default value 1.275π, the x axis goes to the right and the y axis to the left.
        """
        azimuth = 1.275 * pi
        """
        This setting offers a simple scale from 0 to 1, where 0 looks like an orthographic projection (no perspective)
        and 1 is a strong perspective look. For most data visualization applications, perspective should
        be avoided because it makes interpreting the data correctly harder. It can be of use, however,
        if aesthetics are more important than neutral presentation.
        """
        perspectiveness = 0f0
        """
        Controls the lengths of the three axes relative to each other.

        Options are:
          - A three-tuple of numbers, which sets the relative lengths of the x, y and z axes directly
          - `:data` which sets the length ratios equal to the limit ratios of the axes. This results in an "unsquished" look
            where a cube in data space looks like a cube and not a cuboid.
          - `:equal` which is a shorthand for `(1, 1, 1)`
        """
        aspect = (1.0, 1.0, 2/3) # :data :equal
        """
        The view mode affects the final projection of the axis by fitting the axis cuboid into the available
        space in different ways.

          - `:fit` uses a fixed scaling such that a tight sphere around the cuboid touches the frame edge.
            This means that the scaling doesn't change when rotating the axis (the apparent size
            of the axis stays the same), but not all available space is used.
            The chosen `aspect` is maintained using this setting.
          - `:fitzoom` uses a variable scaling such that the closest cuboid corner touches the frame edge.
            When rotating the axis, the apparent size of the axis changes which can result in a "pumping" visual effect.
            The chosen `aspect` is also maintained using this setting.
          - `:stretch` pulls the cuboid corners to the frame edges such that the available space is filled completely.
            The chosen `aspect` is not maintained using this setting, so `:stretch` should not be used
            if a particular aspect is needed.
        """
        viewmode = :fitzoom # :fit :fitzoom :stretch
        "The background color"
        backgroundcolor = :transparent
        "The x label"
        xlabel = "x"
        "The y label"
        ylabel = "y"
        "The z label"
        zlabel = "z"
        "The x label color"
        xlabelcolor = @inherit(:textcolor, :black)
        "The y label color"
        ylabelcolor = @inherit(:textcolor, :black)
        "The z label color"
        zlabelcolor = @inherit(:textcolor, :black)
        "Controls if the x label is visible"
        xlabelvisible = true
        "Controls if the y label is visible"
        ylabelvisible = true
        "Controls if the z label is visible"
        zlabelvisible = true
        "Controls if the x ticklabels are visible"
        xticklabelsvisible = true
        "Controls if the y ticklabels are visible"
        yticklabelsvisible = true
        "Controls if the z ticklabels are visible"
        zticklabelsvisible = true
        "Controls if the x ticks are visible"
        xticksvisible = true
        "Controls if the y ticks are visible"
        yticksvisible = true
        "Controls if the z ticks are visible"
        zticksvisible = true
        "The x label size"
        xlabelsize = @inherit(:fontsize, 16f0)
        "The y label size"
        ylabelsize = @inherit(:fontsize, 16f0)
        "The z label size"
        zlabelsize = @inherit(:fontsize, 16f0)
        "The x label font"
        xlabelfont = :regular
        "The y label font"
        ylabelfont = :regular
        "The z label font"
        zlabelfont = :regular
        "The x label rotation in radians"
        xlabelrotation = Makie.automatic
        "The y label rotation in radians"
        ylabelrotation = Makie.automatic
        "The z label rotation in radians"
        zlabelrotation = Makie.automatic
        "The x label align"
        xlabelalign = Makie.automatic
        "The y label align"
        ylabelalign = Makie.automatic
        "The z label align"
        zlabelalign = Makie.automatic
        "The x label offset"
        xlabeloffset = 40
        "The y label offset"
        ylabeloffset = 40
        "The z label offset"
        zlabeloffset = 50
        "The x ticklabel color"
        xticklabelcolor = @inherit(:textcolor, :black)
        "The y ticklabel color"
        yticklabelcolor = @inherit(:textcolor, :black)
        "The z ticklabel color"
        zticklabelcolor = @inherit(:textcolor, :black)
        "The x ticklabel size"
        xticklabelsize = @inherit(:fontsize, 16f0)
        "The y ticklabel size"
        yticklabelsize = @inherit(:fontsize, 16f0)
        "The z ticklabel size"
        zticklabelsize = @inherit(:fontsize, 16f0)
        "The x ticklabel pad"
        xticklabelpad = 5
        "The y ticklabel pad"
        yticklabelpad = 5
        "The z ticklabel pad"
        zticklabelpad = 10
        "The x ticklabel font"
        xticklabelfont = :regular
        "The y ticklabel font"
        yticklabelfont = :regular
        "The z ticklabel font"
        zticklabelfont = :regular
        "The x grid color"
        xgridcolor = RGBAf(0, 0, 0, 0.12)
        "The y grid color"
        ygridcolor = RGBAf(0, 0, 0, 0.12)
        "The z grid color"
        zgridcolor = RGBAf(0, 0, 0, 0.12)
        "The x grid width"
        xgridwidth = 1
        "The y grid width"
        ygridwidth = 1
        "The z grid width"
        zgridwidth = 1
        "The x tick color"
        xtickcolor = :black
        "The y tick color"
        ytickcolor = :black
        "The z tick color"
        ztickcolor = :black
        "The x tick width"
        xtickwidth = 1
        "The y tick width"
        ytickwidth = 1
        "The z tick width"
        ztickwidth = 1
        "The size of the xtick marks."
        xticksize::Float64 = 6
        "The size of the ytick marks."
        yticksize::Float64 = 6
        "The size of the ztick marks."
        zticksize::Float64 = 6
        "The color of x spine 1 where the ticks are displayed"
        xspinecolor_1 = :black
        "The color of y spine 1 where the ticks are displayed"
        yspinecolor_1 = :black
        "The color of z spine 1 where the ticks are displayed"
        zspinecolor_1 = :black
        "The color of x spine 2 towards the center"
        xspinecolor_2 = :black
        "The color of y spine 2 towards the center"
        yspinecolor_2 = :black
        "The color of z spine 2 towards the center"
        zspinecolor_2 = :black
        "The color of x spine 3 opposite of the ticks"
        xspinecolor_3 = :black
        "The color of y spine 3 opposite of the ticks"
        yspinecolor_3 = :black
        "The color of z spine 3 opposite of the ticks"
        zspinecolor_3 = :black
        "The x spine width"
        xspinewidth = 1
        "The y spine width"
        yspinewidth = 1
        "The z spine width"
        zspinewidth = 1
        "Controls if the x spine is visible"
        xspinesvisible = true
        "Controls if the y spine is visible"
        yspinesvisible = true
        "Controls if the z spine is visible"
        zspinesvisible = true
        "Controls if the x grid is visible"
        xgridvisible = true
        "Controls if the y grid is visible"
        ygridvisible = true
        "Controls if the z grid is visible"
        zgridvisible = true
        """
        The protrusions control how much gap space is reserved for labels etc. on the sides of the `Axis3`.
        Unlike `Axis`, `Axis3` currently does not set these values automatically depending on the properties
        of ticks and labels. This is because the effective protrusions also depend on the rotation and scaling
        of the axis cuboid, which changes whenever the `Axis3` shifts in the layout. Therefore, auto-updating
        protrusions could lead to an endless layout update cycle.

        The default value of `30` for all sides is just a heuristic and might lead to collisions of axis
        decorations with the `Figure` boundary or other plot elements. If that's the case, you can try increasing
        the value(s).

        The `protrusions` attribute accepts a single number for all sides, or a tuple of `(left, right, bottom, top)`.
        """
        protrusions = 30
        "The x ticks"
        xticks = WilkinsonTicks(5; k_min = 3)
        "The y ticks"
        yticks = WilkinsonTicks(5; k_min = 3)
        "The z ticks"
        zticks = WilkinsonTicks(5; k_min = 3)
        "The x tick format"
        xtickformat = Makie.automatic
        "The y tick format"
        ytickformat = Makie.automatic
        "The z tick format"
        ztickformat = Makie.automatic
        "The axis title string."
        title = ""
        "The font family of the title."
        titlefont = :bold
        "The title's font size."
        titlesize = @inherit(:fontsize, 16f0)
        "The gap between axis and title."
        titlegap = 4f0
        "Controls if the title is visible."
        titlevisible = true
        "The horizontal alignment of the title."
        titlealign = :center
        "The color of the title"
        titlecolor = @inherit(:textcolor, :black)
        "The color of the xy panel"
        xypanelcolor = :transparent
        "The color of the yz panel"
        yzpanelcolor = :transparent
        "The color of the xz panel"
        xzpanelcolor = :transparent
        "Controls if the xy panel is visible"
        xypanelvisible = true
        "Controls if the yz panel is visible"
        yzpanelvisible = true
        "Controls if the xz panel is visible"
        xzpanelvisible = true
        "The limits that the axis tries to set given other constraints like aspect. Don't set this directly, use `xlims!`, `ylims!` or `limits!` instead."
        targetlimits = Rect3f(Vec3f(0, 0, 0), Vec3f(1, 1, 1))
        "The limits that the user has manually set. They are reinstated when calling `reset_limits!` and are set to nothing by `autolimits!`. Can be either a tuple (xlow, xhigh, ylow, high, zlow, zhigh) or a tuple (nothing_or_xlims, nothing_or_ylims, nothing_or_zlims). Are set by `xlims!`, `ylims!`, `zlims!` and `limits!`."
        limits = (nothing, nothing, nothing)
        "The relative margins added to the autolimits in x direction."
        xautolimitmargin = (0.05, 0.05)
        "The relative margins added to the autolimits in y direction."
        yautolimitmargin = (0.05, 0.05)
        "The relative margins added to the autolimits in z direction."
        zautolimitmargin = (0.05, 0.05)
        "Controls if the x axis goes rightwards (false) or leftwards (true) in default camera orientation."
        xreversed::Bool = false
        "Controls if the y axis goes leftwards (false) or rightwards (true) in default camera orientation."
        yreversed::Bool = false
        "Controls if the z axis goes upwards (false) or downwards (true) in default camera orientation."
        zreversed::Bool = false
    end
end

@Block PolarAxis <: AbstractAxis begin
    scene::Scene
    overlay::Scene
    target_rlims::Observable{Tuple{Float64, Float64}}
    target_thetalims::Observable{Tuple{Float64, Float64}}
    target_theta_0::Observable{Float32}
    target_r0::Observable{Float32}
    @attributes begin
        # Generic
        """
        Global state for the x dimension conversion.
        """
        dim1_conversion = nothing
        """
        Global state for the y dimension conversion.
        """
        dim2_conversion = nothing


        "The height setting of the scene."
        height = nothing
        "The width setting of the scene."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The horizontal alignment of the scene in its suggested bounding box."
        halign = :center
        "The vertical alignment of the scene in its suggested bounding box."
        valign = :center
        "The alignment of the scene in its suggested bounding box."
        alignmode = Inside()

        # Background / clip settings

        "The background color of the axis."
        backgroundcolor = inherit(scene, :backgroundcolor, :white)
        "The density at which curved lines are sampled. (grid lines, spine lines, clip)"
        sample_density::Int = 120
        "Controls whether to activate the nonlinear clip feature. Note that this should not be used when the background is ultimately transparent."
        clip::Bool = true
        "Sets the color of the clip polygon. Mainly for debug purposes."
        clipcolor = automatic

        # Limits & transformation settings

        "The radial limits of the PolarAxis. "
        rlimits = (:origin, nothing)
        "The angle limits of the PolarAxis. (0.0, 2pi) results a full circle. (nothing, nothing) results in limits picked based on plot limits."
        thetalimits = (0.0, 2pi)
        "The direction of rotation. Can be -1 (clockwise) or 1 (counterclockwise)."
        direction::Int = 1
        "The angular offset for (1, 0) in the PolarAxis. This rotates the axis."
        theta_0::Float32 = 0f0
        "Sets the radius at the origin of the PolarAxis such that `r_out = r_in - radius_at_origin`. Can be set to `automatic` to match rmin. Note that this will affect the shape of plotted objects."
        radius_at_origin = automatic
        "Controls the argument order of the Polar transform. If `theta_as_x = true` it is (θ, r), otherwise (r, θ)."
        theta_as_x::Bool = true
        "Controls whether `r < 0` (after applying `radius_at_origin`) gets clipped (true) or not (false)."
        clip_r::Bool = true
        "The relative margins added to the autolimits in r direction."
        rautolimitmargin::Tuple{Float64, Float64} = (0.05, 0.05)
        "The relative margins added to the autolimits in theta direction."
        thetaautolimitmargin::Tuple{Float64, Float64} = (0.05, 0.05)

        # Spine

        "The width of the spine."
        spinewidth::Float32 = 2
        "The color of the spine."
        spinecolor = :black
        "Controls whether the spine is visible."
        spinevisible::Bool = true
        "The linestyle of the spine."
        spinestyle = nothing

        # r ticks

        "The specifier for the radial (`r`) ticks, similar to `xticks` for a normal Axis."
        rticks = LinearTicks(4)
        "The specifier for the minor `r` ticks."
        rminorticks = IntervalsBetween(2)
        "The formatter for the `r` ticks"
        rtickformat = Makie.automatic
        "The fontsize of the `r` tick labels."
        rticklabelsize::Float32 = inherit(scene, (:Axis, :xticklabelsize), 16)
        "The font of the `r` tick labels."
        rticklabelfont = inherit(scene, (:Axis, :xticklabelfont), inherit(scene, :font, Makie.defaultfont()))
        "The color of the `r` tick labels."
        rticklabelcolor = inherit(scene, (:Axis, :xticklabelcolor), inherit(scene, :textcolor, :black))
        "The width of the outline of `r` ticks. Setting this to 0 will remove the outline."
        rticklabelstrokewidth::Float32 = 0.0
        "The color of the outline of `r` ticks. By default this uses the background color."
        rticklabelstrokecolor = automatic
        "Padding of the `r` ticks label."
        rticklabelpad::Float32 = 4f0
        "Controls if the `r` ticks are visible."
        rticklabelsvisible::Bool = inherit(scene, (:Axis, :xticklabelsvisible), true)
        "The angle in radians along which the `r` ticks are printed."
        rtickangle = automatic
        """
        Sets the rotation of `r` tick labels.

        Options:
        - `:radial` rotates labels based on the angle they appear at
        - `:horizontal` keeps labels at a horizontal orientation
        - `:aligned` rotates labels based on the angle they appear at but keeps them up-right and close to horizontal
        - `automatic` uses `:horizontal` when theta limits span >1.9pi and `:aligned` otherwise
        - `::Real` sets the label rotation to a specific value
        """
        rticklabelrotation = automatic

        # Theta ticks

        "The specifier for the angular (`theta`) ticks, similar to `yticks` for a normal Axis."
        thetaticks = AngularTicks(180/pi, "°") # ((0:45:315) .* pi/180, ["$(x)°" for x in 0:45:315])
        "The specifier for the minor `theta` ticks."
        thetaminorticks = IntervalsBetween(2)
        "The formatter for the `theta` ticks."
        thetatickformat = Makie.automatic
        "The fontsize of the `theta` tick labels."
        thetaticklabelsize::Float32 = inherit(scene, (:Axis, :yticklabelsize), 16)
        "The font of the `theta` tick labels."
        thetaticklabelfont = inherit(scene, (:Axis, :yticklabelfont), inherit(scene, :font, Makie.defaultfont()))
        "The color of the `theta` tick labels."
        thetaticklabelcolor = inherit(scene, (:Axis, :yticklabelcolor), inherit(scene, :textcolor, :black))
        "Padding of the `theta` ticks label."
        thetaticklabelpad::Float32 = 4f0
        "The width of the outline of `theta` ticks. Setting this to 0 will remove the outline."
        thetaticklabelstrokewidth::Float32 = 0.0
        "The color of the outline of `theta` ticks. By default this uses the background color."
        thetaticklabelstrokecolor = automatic
        "Controls if the `theta` ticks are visible."
        thetaticklabelsvisible::Bool = inherit(scene, (:Axis, :yticklabelsvisible), true)
        "Sets whether shown theta ticks get normalized to a -2pi to 2pi range. If not, the limits such as (2pi, 4pi) will be shown as that range."
        normalize_theta_ticks::Bool = true

        # r minor and major grid

        "Sets the z value of grid lines. To place the grid above plots set this to a value between 1 and 8999."
        gridz::Float32 = -100

        "The color of the `r` grid."
        rgridcolor = inherit(scene, (:Axis, :xgridcolor), (:black, 0.5))
        "The linewidth of the `r` grid."
        rgridwidth::Float32 = inherit(scene, (:Axis, :xgridwidth), 1)
        "The linestyle of the `r` grid."
        rgridstyle = inherit(scene, (:Axis, :xgridstyle), nothing)
        "Controls if the `r` grid is visible."
        rgridvisible::Bool = inherit(scene, (:Axis, :xgridvisible), true)

        "The color of the `r` minor grid."
        rminorgridcolor = inherit(scene, (:Axis, :xminorgridcolor), (:black, 0.2))
        "The linewidth of the `r` minor grid."
        rminorgridwidth::Float32 = inherit(scene, (:Axis, :xminorgridwidth), 1)
        "The linestyle of the `r` minor grid."
        rminorgridstyle = inherit(scene, (:Axis, :xminorgridstyle), nothing)
        "Controls if the `r` minor grid is visible."
        rminorgridvisible::Bool = inherit(scene, (:Axis, :xminorgridvisible), false)

        # Theta minor and major grid

        "The color of the `theta` grid."
        thetagridcolor = inherit(scene, (:Axis, :ygridcolor), (:black, 0.5))
        "The linewidth of the `theta` grid."
        thetagridwidth::Float32 = inherit(scene, (:Axis, :ygridwidth), 1)
        "The linestyle of the `theta` grid."
        thetagridstyle = inherit(scene, (:Axis, :ygridstyle), nothing)
        "Controls if the `theta` grid is visible."
        thetagridvisible::Bool = inherit(scene, (:Axis, :ygridvisible), true)


        "The color of the `theta` minor grid."
        thetaminorgridcolor = inherit(scene, (:Axis, :yminorgridcolor), (:black, 0.2))
        "The linewidth of the `theta` minor grid."
        thetaminorgridwidth::Float32 = inherit(scene, (:Axis, :yminorgridwidth), 1)
        "The linestyle of the `theta` minor grid."
        thetaminorgridstyle = inherit(scene, (:Axis, :yminorgridstyle), nothing)
        "Controls if the `theta` minor grid is visible."
        thetaminorgridvisible::Bool = inherit(scene, (:Axis, :yminorgridvisible), false)

        # Title

        "The title of the plot"
        title = ""
        "The gap between the title and the top of the axis"
        titlegap::Float32 = inherit(scene, (:Axis, :titlesize), map(x -> x / 2, inherit(scene, :fontsize, 16)))
        "The alignment of the title.  Can be any of `:center`, `:left`, or `:right`."
        titlealign = :center
        "The fontsize of the title."
        titlesize::Float32 = inherit(scene, (:Axis, :titlesize), map(x -> 1.2x, inherit(scene, :fontsize, 16)))
        "The font of the title."
        titlefont = inherit(scene, (:Axis, :titlefont), inherit(scene, :font, Makie.defaultfont()))
        "The color of the title."
        titlecolor = inherit(scene, (:Axis, :titlecolor), inherit(scene, :textcolor, :black))
        "Controls if the title is visible."
        titlevisible::Bool = inherit(scene, (:Axis, :titlevisible), true)

        # Interactive Controls

        "Sets the speed of scroll based zooming. Setting this to 0 effectively disables zooming."
        zoomspeed::Float32 = 0.1
        "Sets the key used to restrict zooming to the r-direction. Can be set to `true` to always restrict zooming or `false` to disable the interaction."
        rzoomkey = Keyboard.r
        "Sets the key used to restrict zooming to the theta-direction. Can be set to `true` to always restrict zooming or `false` to disable the interaction."
        thetazoomkey = Keyboard.t
        "Controls whether rmin remains fixed during zooming and translation. (The latter will be turned off by setting this to true.)"
        fixrmin::Bool = true
        "Controls whether adjusting the rlimits through interactive zooming is blocked."
        rzoomlock::Bool = false
        "Controls whether adjusting the thetalimits through interactive zooming is blocked."
        thetazoomlock::Bool = true
        "Sets the mouse button for translating the plot in r-direction."
        r_translation_button = Mouse.right
        "Sets the mouse button for translating the plot in theta-direction. Note that this can be the same as `radial_translation_button`."
        theta_translation_button = Mouse.right
        "Sets the button for rotating the PolarAxis as a whole. This replaces theta translation when triggered and must include a mouse button."
        axis_rotation_button = Keyboard.left_control & Mouse.right
        "Sets the button or button combination for resetting the axis view. (This should be compatible with `ispressed`.)"
        reset_button = Keyboard.left_control & Mouse.left
        "Sets whether the axis orientation (changed with the axis_rotation_button) gets reset when resetting the axis. If set to false only the limits will reset."
        reset_axis_orientation::Bool = false
    end
end
