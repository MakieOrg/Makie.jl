"""
    Between(lo, hi)

Constraint for a numeric field: valid values must satisfy `lo ≤ value ≤ hi`.
`ParamForm` renders such fields as [`Slider`](@ref)s.
"""
struct Between{T}
    lo::T
    hi::T
    Between{T}(lo, hi) where {T} = new{T}(lo, hi)
end
Between(lo::T, hi::T) where {T} = Between{T}(lo, hi)
Between(lo, hi) = Between(promote(lo, hi)...)
(c::Between)(v) = c.lo <= v <= c.hi
Base.show(io::IO, c::Between) = print(io, "Between(", c.lo, ", ", c.hi, ")")

"""
    OneOf(options)

Constraint for a field whose value must be one of a fixed set of options.
`ParamForm` renders such fields as [`Menu`](@ref)s.
"""
struct OneOf
    options::Vector
end
(c::OneOf)(v) = v in c.options
Base.show(io::IO, c::OneOf) = print(io, "OneOf(", c.options, ")")

"""
    FilePath(; extension = nothing)

Constraint for a string-valued field that holds a file path. `ParamForm` renders
it as a text entry with a "…" browse button backed by [`choose_file_dialogue`](@ref).
Pass `extension` (e.g. `"csv,tsv"`) to filter the native file picker.
"""
struct FilePath
    extension::Union{String, Nothing}
    FilePath(; extension = nothing) = new(extension)
end
(::FilePath)(v) = true
Base.show(io::IO, c::FilePath) = print(io, "FilePath(", c.extension === nothing ? "" : c.extension, ")")

"""
    convert_form_input(spec::NamedTuple) -> Vector{NamedTuple}

Normalise a `NamedTuple` form specification to one
`(; field, type, default, constraint)` per field.  Each key maps to a
`(default, constraint)` pair; `type` is inferred from `typeof(default)`.

```julia
spec = (
    alpha = (0.5,  Between(0.0, 1.0)),
    mode  = ("fast", OneOf(["fast", "slow"])),
    notes = ("",   nothing),
)
fields = convert_form_input(spec)
```
"""
convert_form_input(spec::NamedTuple) =
    [(; field = k, type = typeof(v[1]), default = v[1], constraint = v[2]) for (k, v) in pairs(spec)]

"""
    widget_for(gridpos, T::Type, constraint, default, width) -> AbstractBlock

Create the input widget for a field of declared type `T` with the given
constraint, seeded with `default` and sized to `width` pixels. Dispatches
on the constraint type:

- [`OneOf`](@ref) → [`Menu`](@ref)
- [`Between`](@ref) → [`Slider`](@ref)
- [`FilePath`](@ref) → [`Textbox`](@ref) with a browse button
- `Bool` → [`Toggle`](@ref)
- anything else → [`Textbox`](@ref)
"""
widget_for(gridpos, ::Type, c::OneOf, default, width) =
    Menu(gridpos; options = c.options, default = default, width = width)

function widget_for(gridpos, ::Type{<:Real}, c::Between, default, width)
    step = (c.hi - c.lo) / 100
    return Slider(gridpos; range = c.lo:step:c.hi, startvalue = default, width = width)
end

function widget_for(gridpos, ::Type, c::FilePath, default, width)
    sub = GridLayout(gridpos)
    default_str = string(default)
    tb = Textbox(sub[1, 1]; stored_string = isempty(default_str) ? nothing : default_str,
                 placeholder = default_str, width = width - 30)
    # Textbox editing is disabled; the browse button is the only write path.
    on(tb.focused) do focused
        focused && defocus!(tb)
    end
    btn = Button(sub[1, 2]; label = "…")
    colgap!(sub, 5)
    on(btn.clicks) do _
        path = choose_file_dialogue(c.extension)
        isnothing(path) || set!(tb, path)
    end
    return tb
end

widget_for(gridpos, T::Type, constraint, default, width) =
    scalar_widget(gridpos, T, constraint, default, width)

"""
    scalar_widget(gridpos, T::Type, constraint, default, width) -> AbstractBlock

Fallback widget: a [`Toggle`](@ref) for `Bool` fields, otherwise a
[`Textbox`](@ref) pre-filled with `string(default)`. The textbox's `validator`
rejects input that would fail [`try_field_value`](@ref), so invalid values can
never be committed at the widget level.
"""
scalar_widget(gridpos, ::Type{Bool}, constraint, default, width) =
    Toggle(gridpos; active = default)

function scalar_widget(gridpos, ::Type{T}, constraint, default, width) where {T}
    tb = Textbox(gridpos; stored_string = string(default), placeholder = string(default), width = width)
    tb.validator[] = s -> try_field_value(tb, s, T, constraint) !== nothing
    return tb
end

"""
    value_observable(widget) -> Observable

The observable carrying a widget's current value, wired into the form's
compute graph as an input node.
"""
value_observable(m::Menu) = m.selection
value_observable(s::Slider) = s.value
value_observable(t::Toggle) = t.active
value_observable(tb::Textbox) = tb.stored_string

"""
    raw_value(widget, raw, T::Type)

Convert the widget's raw observable value toward field type `T`. Menu, Slider
and Toggle values are already typed; Textbox values are parsed via `parse`.
"""
raw_value(::Union{Menu, Slider, Toggle}, raw, ::Type) = raw
raw_value(::Textbox, s::AbstractString, ::Type{T}) where {T <: Number} = parse(T, s)
raw_value(::Textbox, s::AbstractString, ::Type) = s
raw_value(::Textbox, ::Nothing, ::Type{<:AbstractString}) = ""
raw_value(::Textbox, ::Nothing, ::Type) = throw(ArgumentError("empty input"))

"""
    validate_value(T::Type, constraint, parsed)

Convert `parsed` to `T` and check it against `constraint` (a callable, or
`nothing`), throwing `ArgumentError` if the constraint is violated.
"""
function validate_value(::Type{T}, constraint, parsed) where {T}
    v = convert(T, parsed)
    if constraint !== nothing && !constraint(v)
        throw(ArgumentError("$v does not satisfy constraint $constraint"))
    end
    return v
end

"""
    try_field_value(widget, raw, T::Type, constraint) -> Union{T, Nothing}

Return the validated value for `widget`'s raw input, or `nothing` if the input
is invalid. Only `ArgumentError` (bad parse or violated constraint) and
`InexactError` (value doesn't fit the numeric type) are treated as invalid;
other exceptions propagate so genuine bugs surface rather than silently
going dead.
"""
function try_field_value(w, raw, ::Type{T}, constraint) where {T}
    try
        return validate_value(T, constraint, raw_value(w, raw, T))
    catch e
        e isa Union{ArgumentError, InexactError} || rethrow()
        return nothing
    end
end

"""
    ParamForm(gridpos, spec; title = nothing, kwargs...) -> ParamForm

A themeable Makie `Block` that builds a labelled form of input widgets.

`spec` is a `NamedTuple` of `field = (default, constraint)` pairs, processed
by [`convert_form_input`](@ref):

```julia
pf = ParamForm(fig[1, 1], (
    alpha = (0.5,   Between(0.0, 1.0)),
    mode  = ("fast", OneOf(["fast", "slow"])),
    notes = ("",    nothing),
))
```

Each field renders as a right-aligned label and a widget chosen by
[`widget_for`](@ref). `pf.graph[:values]` is the live `NamedTuple` of
validated current values; read it with `pf.graph[:values][]`. The individual
widget blocks are available by field name in `pf.widgets` (e.g.
`pf.widgets[:alpha]`).

With a `title` keyword, a bold section header is added above the fields.
"""
@Block ParamForm begin
    @forwarded_layout
    # Compute graph filled by initialize_block!; pf.graph[:values][] is the
    # current validated NamedTuple.
    graph::ComputeGraph
    # Field name => the widget block created for it, e.g. pf.widgets[:alpha].
    widgets::Dict{Symbol, Any}
    @attributes begin
        "The horizontal alignment of the block in its suggested bounding box."
        halign = :center
        "The vertical alignment of the block in its suggested bounding box."
        valign = :center
        "The width setting of the block."
        width = Auto()
        "The height setting of the block."
        height = Auto()
        "Controls if the parent layout can adjust to this block's width."
        tellwidth = false
        "Controls if the parent layout can adjust to this block's height."
        tellheight = true
        "The align mode of the block in its parent GridLayout."
        alignmode = Inside()
        "Optional section title drawn above the fields (spans both columns). `nothing` = no title."
        title = nothing
        "Colour of the field-name labels."
        labelcolor = @inherit((:colors, :text))
        "Font of the field-name labels."
        labelfont = :bold
        "Colour of the section title."
        titlecolor = @inherit((:colors, :text))
        "Fixed pixel width of the right-aligned field-name column."
        labelwidth = 88
        "Fixed pixel width of the widget column."
        widgetwidth = 175
        "Vertical gap between rows in pixels."
        rowgap = 6
        "Horizontal gap between the label and widget columns in pixels."
        colgap = 8
    end
end

"""
    build_field!(pf, field, T, constraint, default, row)

Build one form row (label + widget) at `row` in `pf.layout` and wire the
widget into `pf.graph`: the widget's value observable becomes input
`Symbol(field, "__raw")`, and a node named `field` converts + validates it via
[`try_field_value`](@ref), returning `nothing` on invalid input so the graph
keeps its last valid value.
"""
function build_field!(pf::ParamForm, field, ::Type{T}, constraint, default, row) where {T}
    Label(pf.layout[row, 1], string(field); halign = :right,
          font = pf.labelfont[], color = pf.labelcolor)
    w = widget_for(pf.layout[row, 2], T, constraint, default, pf.widgetwidth[])
    pf.widgets[field] = w
    raw = Symbol(field, "__raw")
    add_input!(pf.graph, raw, value_observable(w))
    register_computation!(pf.graph, [raw], [field]) do inputs, _, _
        v = try_field_value(w, inputs[1], T, constraint)
        return v === nothing ? nothing : (v,)
    end
    return
end

function initialize_block!(pf::ParamForm, spec)
    fields = convert_form_input(spec)
    pf.graph = ComputeGraph()
    pf.widgets = Dict{Symbol, Any}()
    row = 1
    if pf.title[] !== nothing
        Label(pf.layout[row, 1:2], pf.title[]; font = :bold, halign = :left, color = pf.titlecolor)
        row += 1
    end
    for f in fields
        build_field!(pf, f.field, f.type, f.constraint, f.default, row)
        row += 1
    end
    if isempty(fields)
        add_constant!(pf.graph, :values, NamedTuple())
    else
        register_computation!(pf.graph, [f.field for f in fields], [:values]) do inputs, _, _
            return (inputs,)
        end
    end
    if row == 1
        # Nothing was added: pin the single default cell to zero size so an
        # empty form reports a determinate height instead of an indeterminate
        # flexible row.
        rowsize!(pf.layout, 1, Fixed(0))
        colsize!(pf.layout, 1, Fixed(0))
    else
        colsize!(pf.layout, 1, Fixed(pf.labelwidth[]))
        colsize!(pf.layout, 2, Fixed(pf.widgetwidth[]))
        rowgap!(pf.layout, pf.rowgap[])
        colgap!(pf.layout, pf.colgap[])
    end
    return
end

free(pf::ParamForm) = clear!(pf.layout)

"""
    clear!(x)

Remove GUI content. A Makie `Block` is deleted from its figure; a `GridLayout`
is cleared recursively (blocks and nested layouts removed). `nothing` is
ignored. Replaces ad-hoc `hasmethod` reflection with plain dispatch.
"""
clear!(block::Block) = (delete!(block); nothing)

function clear!(gl::GridLayout)
    for gc in reverse(copy(gl.content))
        obj = gc.content
        if obj isa GridLayout
            clear!(obj)
            GridLayoutBase.remove_from_gridlayout!(gc)
        else
            clear!(obj)
        end
    end
    GridLayoutBase.trim!(gl)
    return nothing
end

clear!(::Nothing) = nothing
clear!(::Any) = nothing
