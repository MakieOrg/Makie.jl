"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function round_to_IRect2D(r::Rect{2})
    newori = round.(Int, minimum(r))
    othercorner = round.(Int, maximum(r))
    newwidth = othercorner .- newori
    return Rect{2, Int}(newori, newwidth)
end

function sceneareanode!(finalbbox, limits, aspect)
    return map(finalbbox, limits, aspect; ignore_equal_values = true) do bbox, limits, aspect

        w = width(bbox)
        h = height(bbox)
        # as = mw / mh
        as = w / h
        mw, mh = w, h

        if aspect isa AxisAspect
            aspect = aspect.aspect
        elseif aspect isa DataAspect
            aspect = limits.widths[1] / limits.widths[2]
        end

        if !isnothing(aspect)
            if as >= aspect
                # too wide
                mw *= aspect / as
            else
                # too high
                mh *= as / aspect
            end
        end

        restw = w - mw
        resth = h - mh

        # l = left(bbox) + alignment[1] * restw
        # b = bottom(bbox) + alignment[2] * resth
        l = left(bbox) + 0.5f0 * restw
        b = bottom(bbox) + 0.5f0 * resth

        newbbox = BBox(l, l + mw, b, b + mh)

        # only update scene if pixel positions change
        return round_to_IRect2D(newbbox)
    end
end

function roundedrectvertices(rect, cornerradius, cornersegments)
    cr = cornerradius
    csegs = cornersegments

    cr = min(width(rect) / 2, height(rect) / 2, cr)

    # inner corners
    ictl = topleft(rect) .+ Point2(cr, -cr)
    ictr = topright(rect) .+ Point2(-cr, -cr)
    icbl = bottomleft(rect) .+ Point2(cr, cr)
    icbr = bottomright(rect) .+ Point2(-cr, cr)

    # check if corners touch so we can remove one vertex that is doubled
    wtouching = width(rect) / 2 == cr
    htouching = height(rect) / 2 == cr

    cstr = if wtouching
        anglepoint.(Ref(ictr), LinRange(0, pi / 2, csegs)[1:(end - 1)], cr)
    else
        anglepoint.(Ref(ictr), LinRange(0, pi / 2, csegs), cr)
    end
    cstl = if htouching
        anglepoint.(Ref(ictl), LinRange(pi / 2, pi, csegs)[1:(end - 1)], cr)
    else
        anglepoint.(Ref(ictl), LinRange(pi / 2, pi, csegs), cr)
    end
    csbl = if wtouching
        anglepoint.(Ref(icbl), LinRange(pi, 3pi / 2, csegs)[1:(end - 1)], cr)
    else
        anglepoint.(Ref(icbl), LinRange(pi, 3pi / 2, csegs), cr)
    end
    csbr = if htouching
        anglepoint.(Ref(icbr), LinRange(3pi / 2, 2pi, csegs)[1:(end - 1)], cr)
    else
        anglepoint.(Ref(icbr), LinRange(3pi / 2, 2pi, csegs), cr)
    end
    return arr = [cstr; cstl; csbl; csbr]
end

"""
    tightlimits!(la::Axis)

Sets the autolimit margins to zero on all sides.
"""
function tightlimits!(la::Axis)
    la.xautolimitmargin = (0, 0)
    la.yautolimitmargin = (0, 0)
    return reset_limits!(la)
end

"""
    tightlimits!(la::Axis, sides::Union{Left, Right, Bottom, Top}...)

Sets the autolimit margins to zero on all given sides.

Example:

```julia
tightlimits!(laxis, Bottom())
```
"""
function tightlimits!(la::Axis, sides::Union{Left, Right, Bottom, Top}...)
    for s in sides
        tightlimits!(la, s)
    end
    return
end

function tightlimits!(la::Axis, ::Left)
    la.xautolimitmargin = Base.setindex(la.xautolimitmargin[], 0.0, 1)
    return autolimits!(la)
end

function tightlimits!(la::Axis, ::Right)
    la.xautolimitmargin = Base.setindex(la.xautolimitmargin[], 0.0, 2)
    return autolimits!(la)
end

function tightlimits!(la::Axis, ::Bottom)
    la.yautolimitmargin = Base.setindex(la.yautolimitmargin[], 0.0, 1)
    return autolimits!(la)
end

function tightlimits!(la::Axis, ::Top)
    la.yautolimitmargin = Base.setindex(la.yautolimitmargin[], 0.0, 2)
    return autolimits!(la)
end

function GridLayoutBase.GridLayout(scene::Scene, args...; kwargs...)
    return GridLayout(args...; bbox = lift(Rect2f, viewport(scene)), kwargs...)
end

function axislines!(
        scene, rect, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor
    )

    bottomline = lift(scene, rect, spinewidth) do r, sw
        y = bottom(r)
        p1 = Point2(left(r) - 0.5sw, y)
        p2 = Point2(right(r) + 0.5sw, y)
        [p1, p2]
    end

    leftline = lift(scene, rect, spinewidth) do r, sw
        x = left(r)
        p1 = Point2(x, bottom(r) - 0.5sw)
        p2 = Point2(x, top(r) + 0.5sw)
        [p1, p2]
    end

    topline = lift(scene, rect, spinewidth) do r, sw
        y = top(r)
        p1 = Point2(left(r) - 0.5sw, y)
        p2 = Point2(right(r) + 0.5sw, y)
        [p1, p2]
    end

    rightline = lift(scene, rect, spinewidth) do r, sw
        x = right(r)
        p1 = Point2(x, bottom(r) - 0.5sw)
        p2 = Point2(x, top(r) + 0.5sw)
        [p1, p2]
    end

    return (
        lines!(
            scene, bottomline, linewidth = spinewidth,
            visible = bottomspinevisible, color = bottomspinecolor
        ),
        lines!(
            scene, leftline, linewidth = spinewidth,
            visible = leftspinevisible, color = leftspinecolor
        ),
        lines!(
            scene, rightline, linewidth = spinewidth,
            visible = rightspinevisible, color = rightspinecolor
        ),
        lines!(
            scene, topline, linewidth = spinewidth,
            visible = topspinevisible, color = topspinecolor
        ),
    )
end


function interleave_vectors(vec1::Vector{T}, vec2::Vector{T}) where {T}
    n = length(vec1)
    @assert n == length(vec2)

    vec = Vector{T}(undef, 2 * n)
    @inbounds for i in 1:n
        k = 2(i - 1)
        vec[k + 1] = vec1[i]
        vec[k + 2] = vec2[i]
    end
    return vec
end

"""
Take a sequence of variable definitions with docstrings above each and turn
them into Attributes, a Dict of varname => docstring pairs and a Dict of
varname => default_value pairs.

# Example

    attrs, docdict, defaultdict = @documented_attributes begin
        "The width."
        width = 10
        "The height."
        height = 20 + x
    end

    attrs == Attributes(
        width = 10,
        height = 20
    )

    docdict == Dict(
        width => "The width.",
        height => "The height."
    )

    defaultdict == Dict(
        width => "10",
        height => "20 + x"
    )
"""
macro documented_attributes(exp)
    if exp.head !== :block
        error("Not a block")
    end

    expressions = filter(x -> !(x isa LineNumberNode), exp.args)

    vars_and_exps = map(expressions) do e
        if e.head === :macrocall && e.args[1] == GlobalRef(Core, Symbol("@doc"))
            varname = e.args[4].args[1]
            var_exp = e.args[4].args[2]
            str_exp = e.args[3]
        elseif e.head == Symbol("=")
            varname = e.args[1]
            var_exp = e.args[2]
            str_exp = "no description"
        else
            error("Neither docstringed variable nor normal variable: $e")
        end
        varname, var_exp, str_exp
    end

    # make a dictionary of :variable_name => docstring_expression
    exp_docdict = Expr(
        :call, :Dict,
        (
            Expr(:call, Symbol("=>"), QuoteNode(name), strexp)
                for (name, _, strexp) in vars_and_exps
        )...
    )

    # make a dictionary of :variable_name => docstring_expression
    defaults_dict = Expr(
        :call, :Dict,
        (
            Expr(:call, Symbol("=>"), QuoteNode(name), exp isa String ? "\"$exp\"" : string(exp))
                for (name, exp, _) in vars_and_exps
        )...
    )

    # make an Attributes instance with of variable_name = variable_expression
    exp_attrs = Expr(
        :call, :Attributes,
        (
            Expr(:kw, name, exp)
                for (name, exp, _) in vars_and_exps
        )...
    )

    return esc(
        quote
            ($exp_attrs, $exp_docdict, $defaults_dict)
        end
    )
end

"""
Turn a combination of docdict and defaultdict from `@documented_attributes`
into a string to insert into a docstring.
"""
function docvarstring(docdict, defaultdict)
    buffer = IOBuffer()
    maxwidth = maximum(length ∘ string, keys(docdict))
    for (var, doc) in sort(collect(pairs(docdict)))
        print(buffer, "`$var`\\\nDefault: `$(defaultdict[var])`\\\n$doc\n\n")
    end
    return String(take!(buffer))
end


function subtheme(scene, key::Symbol)
    sub = haskey(theme(scene), key) ? theme(scene, key) : Attributes()
    if !(sub isa Attributes)
        error("Subtheme is not of type Attributes but is $sub")
    end
    return sub
end


"""
    labelslider!(scene, label, range; format = string, sliderkw = Dict(),
    labelkw = Dict(), valuekw = Dict(), value_column_width = automatic, layoutkw...)

**`labelslider!` is deprecated, use `SliderGrid` instead**

Construct a horizontal GridLayout with a label, a slider and a value label in `scene`.

Returns a `NamedTuple`:

`(slider = slider, label = label, valuelabel = valuelabel, layout = layout)`

Specify a format function for the value label with the `format` keyword or pass a format string used by `Format.format`.
The slider is forwarded the keywords from `sliderkw`.
The label is forwarded the keywords from `labelkw`.
The value label is forwarded the keywords from `valuekw`.
You can set the column width for the value label column with the keyword `value_column_width`.
By default, the width is determined heuristically by sampling a few values from the slider range.
All other keywords are forwarded to the `GridLayout`.

Example:

```julia
ls = labelslider!(scene, "Voltage:", 0:10; format = x -> "\$(x)V")
layout[1, 1] = ls.layout
```
"""
function labelslider!(
        scene, label, range; format = string,
        sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(), value_column_width = automatic, layoutkw...
    )
    slider = Slider(scene; range = range, sliderkw...)
    label = Label(scene, label; labelkw...)
    valuelabel = Label(scene, lift(x -> apply_format(x, format), scene, slider.value); valuekw...)
    layout = hbox!(label, slider, valuelabel; layoutkw...)

    Base.depwarn("labelslider! is deprecated and will be removed in the future. Use SliderGrid instead.", :labelslider!, force = true)

    if value_column_width === automatic
        maxwidth = 0.0
        initial_value = slider.value[]
        a = first(slider.range[])
        b = last(slider.range[])
        for frac in (0.0, 0.5, 1.0)
            fracvalue = a + frac * (b - a)
            set_close_to!(slider, fracvalue)
            labelwidth = GridLayoutBase.computedbboxobservable(valuelabel)[].widths[1]
            maxwidth = max(maxwidth, labelwidth)
        end
        set_close_to!(slider, initial_value)
        colsize!(layout, 3, maxwidth)
    else
        colsize!(layout, 3, value_column_width)
    end

    return (slider = slider, label = label, valuelabel = valuelabel, layout = layout)
end


"""
    labelslidergrid!(scene, labels, ranges; formats = [string],
        sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(),
        value_column_width = automatic, layoutkw...)

**`labelslidergrid!` is deprecated, use `SliderGrid` instead**

Construct a GridLayout with a column of label, a column of sliders and a column of value labels in `scene`.
The argument values are broadcast, so you can use scalars if you want to keep labels, ranges or formats constant across rows.

Returns a `NamedTuple`:

`(sliders = sliders, labels = labels, valuelabels = valuelabels, layout = layout)`

Specify format functions for the value labels with the `formats` keyword or pass format strings used by `Format.format`.
The sliders are forwarded the keywords from `sliderkw`.
The labels are forwarded the keywords from `labelkw`.
The value labels are forwarded the keywords from `valuekw`.
You can set the column width for the value label column with the keyword `value_column_width`.
By default, the width is determined heuristically by sampling a few values from the slider ranges.
All other keywords are forwarded to the `GridLayout`.

Example:

```julia
ls = labelslidergrid!(scene, ["Voltage", "Ampere"], Ref(0:0.1:100); format = x -> "\$(x)V")
layout[1, 1] = ls.layout
```
"""
function labelslidergrid!(
        scene, labels, ranges; formats = [string], value_column_width = automatic,
        sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(), layoutkw...
    )

    Base.depwarn("labelslidergrid! is deprecated and will be removed in the future. Use SliderGrid instead.", :labelslidergrid!, force = true)

    elements = broadcast(labels, ranges, formats) do label, range, format
        slider = Slider(scene; range = range, sliderkw...)
        label = Label(scene, label; halign = :left, labelkw...)
        valuelabel = Label(
            scene, lift(x -> apply_format(x, format), scene, slider.value); halign = :right,
            valuekw...
        )
        (; slider = slider, label = label, valuelabel = valuelabel)
    end

    sliders = map(x -> x.slider, elements)
    labels = map(x -> x.label, elements)
    valuelabels = map(x -> x.valuelabel, elements)

    layout = grid!(hcat(labels, sliders, valuelabels); layoutkw...)

    # This is a bit of a hacky way to determine a good column width for the value labels.
    # We set each slider to the first, middle and last value, record the width of the
    # value label, and then choose the maximum overall value so that hopefully each possible
    # value fits. This can of course go wrong in many scenarios depending on the slider ranges
    # and formatters that can be used, but it's better than nothing or constant jitter.
    if value_column_width === automatic
        maxwidth = 0.0
        for e in elements
            initial_value = e.slider.value[]
            a = first(e.slider.range[])
            b = last(e.slider.range[])
            for frac in (0.0, 0.5, 1.0)
                fracvalue = a + frac * (b - a)
                set_close_to!(e.slider, fracvalue)
                labelwidth = GridLayoutBase.computedbboxobservable(e.valuelabel)[].widths[1]
                maxwidth = max(maxwidth, labelwidth)
            end
            set_close_to!(e.slider, initial_value)
        end
        colsize!(layout, 3, maxwidth)
    else
        colsize!(layout, 3, value_column_width)
    end

    return (sliders = sliders, labels = labels, valuelabels = valuelabels, layout = layout)
end

function apply_format(value, format)
    return format(value)
end

function apply_format(value, formatstring::String)
    return Format.format(formatstring, value)
end

Makie.get_scene(ax::Axis) = ax.scene
Makie.get_scene(ax::Axis3) = ax.scene
Makie.get_scene(ax::LScene) = ax.scene
