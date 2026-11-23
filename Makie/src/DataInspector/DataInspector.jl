# Wrapper to allow and handle PlotElements with tooltips
@recipe_internal DataInspectorTooltip (elements::Vector{<:PlotElement},) begin
    documented_attributes(Tooltip)...
end

mutable struct DataInspector
    parent::Scene

    persistent_tooltips::Dict{UInt64, DataInspectorTooltip}
    dynamic_tooltip::Tooltip
    indicator_cache::Dict{Type, Plot}

    last_mouseposition::Tuple{Float64, Float64}
    last_selection::UInt64
    last_plot_element::PlotElement

    attributes::ComputeGraph

    obsfuncs::Vector{Any}
    update_channel::Channel{Nothing}

    function DataInspector(
            parent, persistent, dynamic, plot_cache,
            attributes,
            obsfuncs, channel
        )

        inspector = new(
            parent,
            persistent, dynamic, plot_cache,
            (0.0, 0.0), 0x00, PlotElement((persistent,), IndexedAccessor(0, 0)),
            attributes, obsfuncs, channel
        )

        finalizer(destroy!, inspector)

        return inspector
    end
end

function default_tooltip_formatter end

const __DATAINSPECTOR_ATTRIBUTES = @DocumentedAttributes begin
    """
    Sets the (maximum) range of plot picking. This sets the maximum
    distance between the cursor and a plot element for which a tooltip shows up.
    """
    range::Int = 10
    "Sets the key/button combination for creating and deleting persistent tooltips."
    persistent_tooltip_key = Keyboard.left_shift & Mouse.left
    """
    Sets the pixel distance to the left/right/bottom/top side of the axis/scene
    below which the tooltip will change its placement to avoid the edge.
    """
    dodge_margins::VecTypes{4, Real} = (30, 30, 30, 30)
    """
    Allows disabling all indicators for this DataInspector.
    Note that plots can disable indicators individually by setting `show_indicator = false`.
    """
    show_indicators::Bool = true
    "When set to true any tick update triggers a tooltip update."
    no_tick_discard::Bool = false
    """
    Sets the formatter for tooltip labels. This formatter applies to single values
    by default. For example it applies per field for a `RGBf`, converting the
    red, green and blue values to strings. `apply_tooltip_format(formatter, value)`
    can be extended to change this behavior. The default implementation works with
    callback functions and Format.jl compatible strings.
    """
    formatter = default_tooltip_formatter

    "Collection of attributes passed to indicator plots"
    indicator = @attributes begin
        "Sets the color of indicator plots."
        color = :red
        "Sets the linewidth of indicator plots."
        linewidth = 2
        "Sets the linestyle of indicator plots."
        linestyle = nothing
    end

    "Collection of attributes passed on to tooltips."
    tooltip = @attributes begin
        filtered_attributes(
            Tooltip, exclude = [
                :visible, :xautolimits, :yautolimits, :zautolimits, :transformation,
                :space, :placement, :text,
            ]
        )...
        draw_on_top = true
    end

    "DataInspector indicator attributes moved to nested attributes. Set them with `attr.indicator.color = ...` and initialize them with `indicator = Attributes(color = ...)`."
    @deprecate indicator_color (indicator, color)
    "DataInspector indicator attributes moved to nested attributes. Set them with `attr.indicator.linewidth = ...` and initialize them with `indicator = Attributes(linewidth = ...)`."
    @deprecate indicator_linewidth (indicator, linewidth)
    "DataInspector indicator attributes moved to nested attributes. Set them with `attr.indicator.linestyle = ...` and initialize them with `indicator = Attributes(linestyle = ...)`."
    @deprecate indicator_linestyle (indicator, linestyle)

    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.offset = ...` and initialize them with `tooltip = Attributes(offset = ...)`"
    @deprecate offset (tooltip, offset)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.align = ...` and initialize them with `tooltip = Attributes(align = ...)`"
    @deprecate align (tooltip, align)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.textpadding = ...` and initialize them with `tooltip = Attributes(textpadding = ...)`"
    @deprecate textpadding (tooltip, textpadding)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.fontsize = ...` and initialize them with `tooltip = Attributes(fontsize = ...)`"
    @deprecate fontsize (tooltip, fontsize)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.textcolor = ...` and initialize them with `tooltip = Attributes(textcolor = ...)`"
    @deprecate textcolor (tooltip, textcolor)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.font = ...` and initialize them with `tooltip = Attributes(font = ...)`"
    @deprecate font (tooltip, font)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.backgroundcolor = ...` and initialize them with `tooltip = Attributes(backgroundcolor = ...)`"
    @deprecate backgroundcolor (tooltip, backgroundcolor)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.outline_color = ...` and initialize them with `tooltip = Attributes(outline_color = ...)`"
    @deprecate outline_color (tooltip, outline_color)
    "DataInspector tooltip attributes moved to nested attributes. Set them with `attr.tooltip.outline_linewidth = ...` and initialize them with `tooltip = Attributes(outline_linewidth = ...)`"
    @deprecate outline_linewidth (tooltip, outline_linewidth)
end
documented_attributes(::Type{DataInspector}) = __DATAINSPECTOR_ATTRIBUTES
attribute_examples(::Type{DataInspector}) = Dict{Symbol, Vector{Example}}()
function attribute_groups(::Type{DataInspector})
    main = [:range, :persistent_tooltip_key, :dodge_margins, :show_indicators, :no_tick_discard, :formatter]

    return Pair{String, Vector{Symbol}}[
        "DataInspector Attributes" => main,
        "Indicator Attributes" => Symbol[:indicator],
        "Tooltip Attributes" => Symbol[:tooltip],
        "Deprecated Attributes" => Symbol[:indicator_color, :indicator_linewidth, :indicator_linestyle],
    ]
end

Base.show(io::IO, ::MIME"text/plain", inspector::DataInspector) = print(io, "DataInspector()")

function destroy!(inspector::DataInspector)
    foreach(off, inspector.obsfuncs)
    empty!(inspector.obsfuncs)

    close(inspector.update_channel)

    foreach(tt -> delete!(inspector.parent, tt), values(inspector.persistent_tooltips))
    delete!(inspector.parent, inspector.dynamic_tooltip)
    foreach(p -> delete!(inspector.parent, p), values(inspector.indicator_cache))

    empty!(inspector.persistent_tooltips)
    empty!(inspector.indicator_cache)

    inspector.parent.data_inspector = nothing
    return
end

Base.delete!(inspector::DataInspector) = destroy!(inspector)

function Base.getproperty(inspector::DataInspector, s::Symbol)
    if hasfield(DataInspector, s)
        return getfield(inspector, s)
    else
        return getproperty(getfield(inspector, :attributes), s)
    end
end

function Base.setproperty!(inspector::DataInspector, s::Symbol, value)
    if hasfield(DataInspector, s)
        return setfield!(inspector, s, value)
    else
        return setproperty!(getfield(inspector, :attributes), s, value)
    end
end

function Base.Docs.getdoc(::Type{DataInspector})
    docstring_start = md"""
        DataInspector(axis; kwargs...)
        DataInspector(scenelike; kwargs...)

    Create a DataInspector for the given `axis` or `scene`-like object. This will
    enable tooltips for plots within the axis/parent scene.

    If the given axis or scene already has a `DataInspector` the current one will
    be returned instead. An existing `DataInspector` can be deleted by
    `delete!(inspector)`.

    Tooltips can be disabled on a per-plot basis by setting `inspectable = false`.
    The tooltip string can also be adjusted on a per plot basis using the
    `inspector_label` attribute. It can be set to:
    - a string which is used for every tooltip of the plot
    - a vector of strings where each string maps to an element of the plot. For this
        the plot needs to be treated as a discrete visualization (E.g. scatter, but not lines)
    - a callback function `(element::PlotElement, position) -> string` which builds a
        string from the selected `PlotElement` and position

    ##  DataInspector Settings

    - `tick_priority = 1000` sets the priority of the `events.tick` listener used
        for dynamic/hover tooltips
    - `button_priority = 1000` sets the priority of the `events.mousebutton` listener
        used for persistent tooltips
    - `blocking = false` when set to true tooltip updates block further event processing
        and rendering.
    """

    attribute_section = get_attribute_docs(DataInspector; full = false)
    pop!(attribute_section.content)

    docstring_tail = md"""
    ## Extension

    By default, DataInspector falls back onto known recipes to build tooltips. If
    that is not enough or produces undesirable results, the various steps in creating
    a tooltip can be extended. These include:

    - `get_accessor(plot, idx, plot_stack)` constructs a accessor which abstracts
        the picked element of a higher level plot. This is used to build the `PlotElement`.
    - `get_tooltip_position(element)` returns the transformed position of a `PlotElement`.
        (After applying the plots transform function.)
    - `get_tooltip_label([formatter,] element, position)` constructs the displayed
        string of the tooltip. Can also return data which will be converted to a string
        by the formatter.
    - `add_indicator_attributes!(attr)` adds attributes to the `indicator` section
        of the DataInspector attributes
    - `update_indicator!(inspector, element)` updates an indicator to match the
        currently selected plot element.
    - `construct_indicator_plot(inspector, PlotType)` creates a plot to be used as
        an indicator

    See the relevant functions for more detail.
    """

    combined = Markdown.MD()
    push!(combined, docstring_start, attribute_section, docstring_tail)

    return combined
end

""
function DataInspector(obj; blocking = false, kwargs...)
    parent = get_scene(obj)
    if !isnothing(parent.data_inspector)
        return parent.data_inspector
    end

    kwdict = Dict{Symbol, Any}(kwargs)

    tick_priority = pop!(kwdict, :tick_priority, 1_000)
    button_priority = pop!(kwdict, :button_priority, 1_000)

    attr = ComputeGraph(
        __DATAINSPECTOR_ATTRIBUTES,
        parent, :DataInspector, kwdict, restrict_types = true
    )

    validate_attribute_keys(DataInspector, kwdict, tuple())

    tt = tooltip!(
        obj, attr.tooltip, Point3d(0), text = "", visible = false,
        xautolimits = false, yautolimits = false, zautolimits = false,
        transformation = :nothing
    )
    register_projected_positions!(tt, input_name = :positions, output_name = :pixel_positions)

    inspector = DataInspector(
        parent, Dict{UInt64, Tooltip}(), tt, Dict{Type, Plot}(),
        attr, Any[], Channel{Nothing}(Inf)
    )

    parent.data_inspector = inspector

    # dynamic tooltip

    # We delegate the hover processing to another channel,
    # So that we can skip queued up updates with empty_channel!
    # And also not slow down the processing of e.mouseposition/e.scroll
    channel = Channel{Nothing}(blocking ? 0 : Inf) do ch
        while isopen(ch)
            take!(ch) # wait for event
            if isopen(parent)
                try
                    update_tooltip!(inspector)
                catch err
                    # Channel task may swallow errors, Julia#51597
                    @info "Error occurred in tooltip update:"
                    Base.showerror(Base.stderr, err)
                    rethrow(err)
                end
            end
        end
    end
    inspector.update_channel = channel
    e = events(parent)

    tick_listener = on(e.tick, priority = tick_priority) do tick
        # This should be one frame behind in GLMakie. Maybe we should make ticks
        # predictive based on whether renderobjects need updates.
        # Not sure if this expands to WGLMakie...
        has_rendered = attr.no_tick_discard[]::Bool || (tick.state === RegularRenderTick)
        tooltip_needs_to_move = inspector.last_mouseposition != e.mouseposition[]

        if has_rendered || tooltip_needs_to_move
            empty_channel!(channel) # remove queued up hover requests
            put!(channel, nothing)
        end

        return
    end

    # TODO: remove priority, make compatible with 3D axis
    # persistent tooltip
    mouse_listener = on(e.mousebutton, priority = button_priority) do event
        if event.action == Mouse.press
            return update_persistent_tooltips!(inspector)
        else
            return Consume(false)
        end
    end

    push!(inspector.obsfuncs, tick_listener, mouse_listener)

    return inspector
end

function InvalidAttributeError(::Type{DataInspector}, attributes::Set{Symbol})
    return InvalidAttributeError(DataInspector, "\b", attributes)
end

################################################################################
### Dynamic Tooltips
################################################################################

function update_tooltip!(di::DataInspector)
    e = events(di.parent)
    mp = e.mouseposition[]
    di.last_mouseposition = mp

    # TODO: It would be nice to discard updates where the scene hasn't changed,
    # but that's hard to do. We'd need to check for any update triggering a re-
    # render but exclude the ones caused by tooltip updates.
    # di.needs_update || return

    # Mouse outside relevant area, hide tooltip
    if !is_mouseinside(di.parent)
        hide_indicators!(di)
        update!(di.dynamic_tooltip, visible = false)
        di.last_plot_element = PlotElement((di.dynamic_tooltip,), IndexedAccessor(0, 0))
        return
    end


    for (plot, idx) in pick_sorted(di.parent, mp, di.range[]::Int)
        # Areas of scenes can overlap so we need to make sure the plot is
        # actually in the correct scene
        if parent_scene(plot) == di.parent && plot.inspectable[]
            if update_tooltip!(di, plot, idx)
                return
            end
        end
    end

    # Did not find inspectable plot, hide tooltip & indicators
    hide_indicators!(di)
    update!(di.dynamic_tooltip, visible = false)
    di.last_plot_element = PlotElement((di.dynamic_tooltip,), IndexedAccessor(0, 0))

    return
end

function update_tooltip!(di::DataInspector, source_plot::Plot, source_index::Integer)
    function border_dodging_placement(di::DataInspector, proj_pos)
        wx, wy = widths(viewport(di.parent)[])
        px, py = proj_pos
        l, r, b, t = di.dodge_margins[]::VecTypes{4, Real}

        placement = :above
        placement = ifelse(py > max(0.5wy, wy - t), :below, placement)
        placement = ifelse(px < min(0.5wx, l), :right, placement)
        placement = ifelse(px > max(0.5wx, wx - r), :left, placement)

        return placement
    end

    element = pick_element(plot_stack(source_plot), source_index)
    isnothing(element) && return false

    # If the plotelement did not change the tooltip won't change either
    di.last_plot_element == element && return true
    di.last_plot_element = element

    # We need to grab transformations and space from the plot we grab the
    # position from
    position_element = get_position_element(element)
    isnothing(position_element) && return false

    # TODO: shift pos to desired depth (or is draw_on_top enough?)
    pos = get_tooltip_position(position_element)

    plot = get_plot(position_element)
    _copy_local_model_transformations!(di.dynamic_tooltip, plot)

    itf = inverse_transform(transform_func(di.parent))
    input_pos = apply_transform(itf, pos)
    formatter = di.formatter[]
    label = get_tooltip_label(formatter, element, input_pos)

    # maybe also allow kwargs changes from plots?
    # kwargs = get_tooltip_attributes(element)

    update!(
        di.dynamic_tooltip,
        to_ndim(Point3d, pos, 0), text = label, visible = true,
        space = to_value(get(plot, :space, :data))
    )

    px_pos = di.dynamic_tooltip.pixel_positions[][1]
    update!(di.dynamic_tooltip, placement = border_dodging_placement(di, px_pos))

    apply_tooltip_overwrites!(element, di.dynamic_tooltip)

    # TODO: Why not also allow plots to disable their indicator?
    if di.show_indicators[]::Bool && get(element, :show_indicator, true)
        update_indicator_internal!(di, element, pos)
    end

    return true
end

function _copy_local_model_transformations!(target, source)
    src_t = transformation(source)
    trg_t = transformation(target)

    trg_t.parent[] = src_t
    trg_t.parent_model[] = src_t.model[]

    return
end

########################################
### Core get_tooltip_position()
########################################

function get_position_element(element::PlotElement)
    @assert !applicable(get_tooltip_position, PlotElement) "`get_tooltip_position()` must only exist for typed `PlotElement{<:SomePlot}`"
    while !isempty(element.plot_stack)
        if applicable(get_tooltip_position, element)
            return element
        else
            element = child(element)
        end
    end
    return nothing
end

# Primitives (volume skipped)
"""
    get_tooltip_position(element::PlotElement{PlotType})

Returns the transformed position (after `transform_func` is applied) corresponding
to a `PlotElement`. The result will be used as an anchor point for the tooltip.
Its back-transformed value will also be passed to `get_tooltip_label()` and
`update_indicator!()`.

This function typically needs to be implemented when the position returned by
`get_tooltip_position(child(element))` is not appropriate for the recipe, or if
the `PlotElement` is incompatible with the child plot.

For example, `arrows3d` relies on a meshscatter plots to display the head, shaft
and tail components of arrows. Without extending `get_tooltip_position()` the
tooltips would be relative to these components, rather than the arrow as a
whole. So an overload is needed to get the appropriate positions.

For `arrows2d` all the components are merged into one array passed to poly. In
order to be able to address arrows by index, a custom `get_accessor()` method is
implemented for `Arrows2D`. These indices are neither compatible with the
component nor the merged mesh poly produces, so a `get_tooltip_position()`
overload is needed here too.

Since both cases represent their data the same way, we can have one method
addressing both:

```
function get_tooltip_position(element::PlotElement{<:Union{Arrows2D, Arrows3D}})
    # `element.startpoints` essentially calls `get_plot(element).startpoints[][idx]`
    # where the `idx` relates to the picked arrow
    return 0.5 * (element.startpoints + element.endpoints)
end
```
"""
function get_tooltip_position(element::PlotElement{<:HeatmapShader})
    return get_tooltip_position(child(element))
end

function get_tooltip_position(element::PlotElement{<:Heatmap})
    # This is a getindex, not an interpolation, so we can transform after
    plot = get_plot(element)
    x = dimensional_element_getindex(plot.x[], element, 1)
    y = dimensional_element_getindex(plot.y[], element, 2)
    tf = element.transform_func
    return apply_transform(tf, Point2f(x, y))
end

# Interpolations are calculated after transform func is applied, so they are
# appropriate for transformed data. We need to back transform here to get pre-
# transform data
function get_tooltip_position(element::PlotElement{<:Image})
    plot = get_plot(element)
    p00, _, p11, _ = plot.positions_transformed[]
    x = dimensional_element_getindex((p00[1], p11[1]), element, 1)
    y = dimensional_element_getindex((p00[2], p11[2]), element, 2)
    return Point2f(x, y)
end

function get_tooltip_position(
        element::PlotElement{<:Union{Scatter, MeshScatter, Lines, LineSegments, Text, Mesh, Surface}}
    )
    return get_post_transform(element, :positions)
end

function get_tooltip_position(element::PlotElement{<:Voxels})
    # assuming no transform_func (would that even work with voxels?)
    i, j, k = Tuple(accessor(element).index)
    return voxel_position(get_plot(element), i, j, k)
end

########################################
### Label generation + default formatting
########################################

# TODO: Consider renaming this and using the name for `get_default_tooltip_label` instead
function get_tooltip_label(formatter, element::PlotElement, pos)
    label = get(element, :inspector_label, automatic)

    if label isa String
        # TODO: Can this double as a formatting string? Seems difficult to handle
        # the various types that label data can be...
        return label
    elseif label isa Function
        return label(element, pos)
    elseif label === automatic
        maybe_data = get_default_tooltip_label(formatter, element, pos)
        return apply_tooltip_format(formatter, maybe_data)
    end
end

"""
    get_default_tooltip_label([formatter,] element::PlotElement{PlotType}, position)

Returns either a string or data that will be used as the tooltip label for the
given `PlotElement`.

The `formatter` can be used with `apply_tooltip_format(formatter, data)` when
constructing a string directly. If it is not used it can be omitted from the
function arguments. The `position` is the (input space) position generated by
`get_tooltip_position()`.

This function typically needs to be implemented when the data shown for a recipe
should different from its child plot, or more rarely if the `PlotElement` is
incompatible with the child plot.

Continuing the `arrows` example from `get_tooltip_position()`, we get the mid-
point of an arrow as the `position`. By default this position would be displayed
for `arrows2d` and `arrows3d`, as the fallbacks to `Mesh` and `Lines` return the
passed position. Arrows should however also report their directions, so we want
a custom method returning them:

```
function get_default_tooltip_label(element::PlotElement{<:Union{Arrows2D, Arrows3D}}, pos)
    return pos, element.endpoints - element.startpoints
end
```
"""
function get_default_tooltip_label(formatter, element, pos)
    if Base.applicable(get_default_tooltip_label, element, pos)
        return get_default_tooltip_label(element, pos)
    else
        return get_default_tooltip_label(formatter, child(element), pos)
    end
end

get_default_tooltip_label(element::PlotElement{<:PrimitivePlotTypes}, pos) = pos
get_default_tooltip_label(element::PlotElement{<:Union{Image, Heatmap}}, pos) = element.image
function get_default_tooltip_label(element::PlotElement{<:HeatmapShader}, pos)
    return get_default_tooltip_label(child(element), pos)
end

function apply_tooltip_format(fmt, data::Tuple)
    return mapreduce(x -> apply_tooltip_format(fmt, x), (a, b) -> "$a\n$b", data)
end

apply_tooltip_format(fmt, data::String) = data

function apply_tooltip_format(fmt, data::VecTypes)
    return '(' * mapreduce(x -> apply_tooltip_format(fmt, x), (a, b) -> "$a, $b", data) * ')'
end

function apply_tooltip_format(fmt, c::RGB)
    return "RGB" * apply_tooltip_format(fmt, Vec(red(c), green(c), blue(c)))
end

function apply_tooltip_format(fmt, c::RGBA)
    return "RGBA" * apply_tooltip_format(fmt, Vec(red(c), green(c), blue(c), alpha(c)))
end

function apply_tooltip_format(fmt, c::Gray)
    return "Gray(" * apply_tooltip_format(fmt, gray(c)) * ')'
end

apply_tooltip_format(fmt, x::Symbol) = apply_tooltip_format(fmt, ":$x")

apply_tooltip_format(fmt::String, x::Number) = Format.format(fmt, x)
apply_tooltip_format(fmt::Function, x::Number) = fmt(x)
apply_tooltip_format(fmt::String, x::String) = Format.format(fmt, x)
apply_tooltip_format(fmt::Function, x::String) = fmt(x)

function default_tooltip_formatter(x::Real)
    if 1.0e-3 <= abs(x) < 1.0e-1
        return @sprintf("%0.6f", x)
    elseif 1.0e-1 <= abs(x) < 1.0e3
        return @sprintf("%0.3f", x)
    elseif 1.0e3 <= abs(x) < 1.0e5
        return @sprintf("%0.0f", x)
    elseif iszero(x)
        return "0"
    else
        return @sprintf("%0.3e", x)
    end
end

default_tooltip_formatter(x::String) = x

apply_tooltip_overwrites!(::PlotElement, tt) = nothing

################################################################################
### Indicator infrastructure
################################################################################

function update_indicator_internal!(di::DataInspector, element::PlotElement, pos)
    hide_indicators!(di)
    maybe_indicator = update_indicator!(di, element, pos)
    # TODO: Are these really things that should always happen?
    if maybe_indicator isa Plot
        _copy_local_model_transformations!(maybe_indicator, get_plot(element))
        update!(maybe_indicator, space = element.space)
    end
    return
end

update_indicator!(di::DataInspector, element::PlotElement, pos) = nothing

function hide_indicators!(di::DataInspector)
    foreach(values(di.indicator_cache)) do plot
        update!(plot, visible = false)
    end
    return
end

"""
    get_indicator_plot(inspector, PlotType)

Returns a cached indicator plot of the given `PlotType`. If the plot has not yet
been initialized `construct_indicator_plot(inspector, PlotType)` will be called
to do so.
"""
function get_indicator_plot(di::DataInspector, PlotType)
    return get!(di.indicator_cache, PlotType) do
        # Band-aid for LScene where a new plot triggers re-centering of the scene
        cc = cameracontrols(di.parent)
        if cc isa Camera3D
            eyeposition = cc.eyeposition[]
            lookat = cc.lookat[]
            upvector = cc.upvector[]
        end

        plot = construct_indicator_plot(di, PlotType)

        # Restore camera
        cc isa Camera3D && update_cam!(di.parent, eyeposition, lookat, upvector)

        return plot
    end
end

########################################
### cached indicator plots
########################################

"""
    add_indicator_attributes!(attr::DocumentedAttributes)

Adds the given `DocumentedAttributes` to the default attributes of `DataInspector`
under `indicator`. Existing attributes will not be overwritten.

This should be called if a new indicator plot needs extra/more user accessible
attributes.

## Example

This would add `inspector.indicator.myattrib` and `inspector.indicator.mygroup.color`:

```
Makie.add_indicator_attributes!(
    @DocumentedAttributes begin
        "Sets something for my indicator plot type"
        myattrib = :red
        "Sets attributes for my indicator plot type"
        mygroup = @attributes begin
            "Sets the color for my indicator plot type to avoid collisions with other indicator colors"
            color = :red
        end
    end
)
```
"""
function add_indicator_attributes!(attr::DocumentedAttributes)
    merge_documented_attributes!(
        __DATAINSPECTOR_ATTRIBUTES, :indicator, attr, on_collision = :skip
    )
    return
end

"""
    construct_indicator_plot(inspector, PlotType)

Constructs a reusable indicator plot of a given PlotType.

This function should be extended when implementing a tooltip indicator that
needs a plot that does not yet have a `construct_indicator_plot()` method. The
method should plot to `inspector.parent` and return the created plot. Each
method should only handle one plot. Attributes may be sourced from the
DataInspector.

```julia
function construct_indicator_plot(di::DataInspector, ::Type{<:PlotType})
    return plot!(di.parent, Point3d[], visible = false, inspectable = false, ...)
end
```
"""
function construct_indicator_plot(di::DataInspector, ::Type{<:LineSegments})
    a = di.indicator
    return linesegments!(
        di.parent, Point3d[], color = a.color,
        linewidth = a.linewidth, linestyle = a.linestyle,
        visible = false, inspectable = false, depth_shift = -1.0f-6,
        transformation = :nothing
    )
end

function construct_indicator_plot(di::DataInspector, ::Type{<:Lines})
    a = di.indicator
    return lines!(
        di.parent, Point3d[], color = a.color,
        linewidth = a.linewidth, linestyle = a.linestyle,
        visible = false, inspectable = false, depth_shift = -1.0f-6,
        transformation = :nothing
    )
end

function construct_indicator_plot(di::DataInspector, ::Type{<:Scatter})
    a = di.indicator
    # draw marker occupies (markersize + 2 * strokewidth + ~1 AA pixel)
    # To be able to pick the plot behind the indicator, this needs to be < 2 * range
    map!(di.attributes.indicator, [di.range, :linewidth], :shrunk_markersize) do r, w
        return 2r - 4 - 2w
    end
    return scatter!(
        di.parent, Point3d(0), color = RGBAf(0, 0, 0, 0),
        marker = Rect,
        markersize = a.shrunk_markersize,
        strokecolor = a.color,
        strokewidth = a.linewidth,
        inspectable = false, visible = false,
        depth_shift = -1.0f-6,
        transformation = :nothing
    )
end

"""
    update_indicator!(inspector, element::PlotElement, position)

Update the indicator plot relevant to the given `PlotElement`.

This function should be extended to implement indicators for specific plot types.

```
function update_indicator!(inspector, element::PlotElement{<:InspectedPlotType}, pos)
    # Calculate whatever is needed to place the indicator...

    # Get the plot(s) necessary to draw the indicator
    indicator_plot = get_indicator_plot(inspector, IndicatorPlotType)

    # Update the plot with the new data
    Makie.update!(indicator_plot, arg1 = new_position, ..., visible = true)

    # If the indicator plot is returned, space and transformations are matched to
    # the PlotElement
    return indicator_plot
end
```
"""
function update_indicator!(di::DataInspector, element::PlotElement{<:MeshScatter}, pos)
    # Attribute based transformations of scattered mesh
    translation = to_ndim(Point3d, pos, 0)
    rotation = to_rotation(element.rotation)
    scale = inv_f32_scale(get_plot(element), element.markersize)

    # get transformed bbox
    bbox = Rect3d(convert_attribute(element.marker, Key{:marker}(), Key{:meshscatter}()))
    ps = convert_arguments(LineSegments, bbox)[1]
    ps = map(ps) do p
        p3d = to_ndim(Point3d, p, 0)
        return rotation * (scale .* p3d) + translation
    end

    # get and update indicator
    indicator = get_indicator_plot(di, LineSegments)
    update!(indicator, arg1 = ps, visible = true)

    return indicator
end

function update_indicator!(di::DataInspector, element::PlotElement{<:Mesh}, pos)
    # get and update indicator
    bbox = data_limits(get_plot(element))
    indicator = get_indicator_plot(di, LineSegments)
    ps = convert_arguments(LineSegments, bbox)[1]
    ps = apply_transform(element.transform_func, ps)
    update!(indicator, arg1 = ps, visible = true)

    return indicator
end

function update_indicator!(di::DataInspector, element::PlotElement{<:HeatmapShader}, pos)
    return update_indicator!(di, child(element), pos)
end
function update_indicator!(di::DataInspector, element::PlotElement{<:Union{Image, Heatmap}}, pos)
    if element.interpolate[]
        indicator = get_indicator_plot(di, Scatter)
        p3d = to_ndim(Point3d, pos, 0)
        color = sample_color(element, element.image)
        update!(indicator; arg1 = p3d, color = color, visible = true)
        return indicator
    else
        # TODO: Should this be a function?
        i, j = Tuple(accessor(element).index)

        plot = get_plot(element)
        if !haskey(plot, :x_transformed)
            add_computation!(plot.attributes, parent_scene(plot), Val(:heatmap_transform))
        end
        bbox = _pixelated_image_bbox(
            plot.x_transformed[], plot.y_transformed[], plot.image[], i, j, plot isa Heatmap
        )
        ps = to_ndim.(Point3d, convert_arguments(Lines, bbox)[1], 0)
        indicator = get_indicator_plot(di, Lines)
        update!(indicator, arg1 = ps, visible = true)
        return indicator
    end

    return
end

################################################################################
### persistent tooltips
################################################################################

function update_persistent_tooltips!(di::DataInspector)
    e = events(di.parent)

    if !ispressed(e, di.persistent_tooltip_key[]) || !is_mouseinside(di.parent)
        return Consume(false)
    end

    mp = e.mouseposition[]
    for (plot, idx) in pick_sorted(di.parent, mp, di.range[]::Int)
        (parent_scene(plot) != di.parent) && continue

        if plot.inspectable[]
            element = pick_element(plot_stack(plot), idx)
            add_persistent_tooltip!(di, element)
            return Consume(true)
        elseif rootparent_plot(plot) isa DataInspectorTooltip
            element = pick_element(plot_stack(plot), idx)
            if remove_persistent_tooltip!(di, element)
                return Consume(true)
            end
        end
    end

    return Consume(false)
end

function plot!(plot::DataInspectorTooltip{<:Tuple{<:Vector{<:PlotElement}}})
    if isempty(plot.arg1[])
        error("tooltip(::Vector{PlotElement}) must not be initialized with an empty list.")
    end

    element = TrackedPlotElement(first(plot.arg1[]))

    # get list of inputs used for positions
    position_element = get_position_element(element)
    empty!(position_element)
    pos = get_tooltip_position(position_element)

    position_parent = get_plot(position_element)
    inputs = [plot.arg1, get_accessed_nodes(position_element)...]

    map!(plot, inputs, :element_positions) do elements, triggers...
        return map(elements) do element
            position_element = get_position_element(element)
            return get_tooltip_position(position_element)
        end
    end

    # get list of inputs used for labels
    empty!(element)
    get_tooltip_label(plot._formatter[], element, pos)

    inputs = [
        plot._formatter, plot.arg1, plot.element_positions,
        get_accessed_nodes(element)...,
    ]

    map!(plot, inputs, :element_labels) do formatter, elements, positions, triggers...
        return get_tooltip_label.(Ref(formatter), elements, positions)
    end

    tooltip!(
        plot, Attributes(plot), plot.element_positions; text = plot.element_labels,
        transformation = Transformation(position_parent.transformation),
        space = position_parent.space
    )
    return plot
end

# Produce useful PlotElements for tooltips (text already does, just need to handle Poly branch)
function get_accessor(plot::TextLabel, idx, plot_stack::Tuple{<:Poly, Vararg{Plot}})
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedAccessor(idx, N)
end

function add_persistent_tooltip!(di::DataInspector, element::PlotElement{PT}) where {PT}
    id = objectid(get_plot(element))
    if haskey(di.persistent_tooltips, id)
        tt = di.persistent_tooltips[id]
        elements = push!(tt.arg1[], element)
        update!(tt, arg1 = elements)
        apply_tooltip_overwrites!(element, tt)
    else
        tt = datainspectortooltip!(
            di.parent, di.tooltip, PlotElement{PT}[element],
            _formatter = di.formatter[]
        )
        apply_tooltip_overwrites!(element, tt)
        di.persistent_tooltips[id] = tt
    end
    return true
end

function remove_persistent_tooltip!(di::DataInspector, tooltip_element::PlotElement{<:DataInspectorTooltip})
    tt = get_plot(tooltip_element)
    key = findfirst(==(tt), di.persistent_tooltips)

    # If we don't find the tooltip plot then we don't own it and shouldn't touch it
    if key !== nothing
        idx = accessor(tooltip_element).index[1]
        elements = tt.arg1[]
        deleteat!(elements, idx)

        if length(elements) == 0
            tt = pop!(di.persistent_tooltips, key)
            delete!(di.parent, tt)
        else
            update!(tt, arg1 = elements)
        end

        return true
    end

    return false
end
