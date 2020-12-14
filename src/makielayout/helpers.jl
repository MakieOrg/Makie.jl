"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function round_to_IRect2D(r::Rect{2})
    newori = round.(Int, minimum(r))
    othercorner = round.(Int, maximum(r))
    newwidth = othercorner .- newori
    Rect{2, Int}(newori, newwidth)
end

function sceneareanode!(finalbbox, limits, aspect)

    scenearea = Node(IRect(0, 0, 100, 100))

    onany(finalbbox, limits, aspect) do bbox, limits, aspect

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
        new_scenearea = round_to_IRect2D(newbbox)
        if new_scenearea != scenearea[]
            scenearea[] = new_scenearea
        end
    end

    scenearea
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
        anglepoint.(Ref(ictr), LinRange(0, pi/2, csegs), cr)
    else
        anglepoint.(Ref(ictr), LinRange(0, pi/2, csegs)[1:end-1], cr)
    end
    cstl = if htouching
        anglepoint.(Ref(ictl), LinRange(pi/2, pi, csegs), cr)
    else
        anglepoint.(Ref(ictl), LinRange(pi/2, pi, csegs)[1:end-1], cr)
    end
    csbl = if wtouching
        anglepoint.(Ref(icbl), LinRange(pi, 3pi/2, csegs), cr)
    else
        anglepoint.(Ref(icbl), LinRange(pi, 3pi/2, csegs)[1:end-1], cr)
    end
    csbr = if htouching
        anglepoint.(Ref(icbr), LinRange(3pi/2, 2pi, csegs), cr)
    else
        anglepoint.(Ref(icbr), LinRange(3pi/2, 2pi, csegs)[1:end-1], cr)
    end
    arr = [cstr; cstl; csbl; csbr]
end

"""
    tightlimits!(la::LAxis)

Sets the autolimit margins to zero on all sides.
"""
function tightlimits!(la::LAxis)
    la.xautolimitmargin = (0, 0)
    la.yautolimitmargin = (0, 0)
    autolimits!(la)
end

"""
    tightlimits!(la::LAxis, sides::Union{Left, Right, Bottom, Top}...)

Sets the autolimit margins to zero on all given sides.

Example:

```
tightlimits!(laxis, Bottom())
```
"""
function tightlimits!(la::LAxis, sides::Union{Left, Right, Bottom, Top}...)
    for s in sides
        tightlimits!(la, s)
    end
end

function tightlimits!(la::LAxis, ::Left)
    la.xautolimitmargin = Base.setindex(la.xautolimitmargin[], 0.0, 1)
    autolimits!(la)
end

function tightlimits!(la::LAxis, ::Right)
    la.xautolimitmargin = Base.setindex(la.xautolimitmargin[], 0.0, 2)
    autolimits!(la)
end

function tightlimits!(la::LAxis, ::Bottom)
    la.yautolimitmargin = Base.setindex(la.yautolimitmargin[], 0.0, 1)
    autolimits!(la)
end

function tightlimits!(la::LAxis, ::Top)
    la.yautolimitmargin = Base.setindex(la.yautolimitmargin[], 0.0, 2)
    autolimits!(la)
end


"""
    layoutscene(padding = 30; kwargs...)

Create a `Scene` in `campixel!` mode and a `GridLayout` aligned to the scene's pixel area with `alignmode = Outside(padding)`.
"""
function layoutscene(padding = 30; kwargs...)
    scene = Scene(; camera = campixel!, kwargs...)
    gl = GridLayout(scene, alignmode = Outside(padding))
    scene, gl
end

"""
    layoutscene(nrows::Int, ncols::Int, padding = 30; kwargs...)

Create a `Scene` in `campixel!` mode and a `GridLayout` aligned to the scene's pixel area with size `nrows` x `ncols` and `alignmode = Outside(padding)`.
"""
function layoutscene(nrows::Int, ncols::Int, padding = 30; kwargs...)
    scene = Scene(; camera = campixel!, kwargs...)
    gl = GridLayout(scene, nrows, ncols, alignmode = Outside(padding))
    scene, gl
end


GridLayoutBase.GridLayout(scene::Scene, args...; kwargs...) = GridLayout(args...; bbox = lift(x -> FRect2D(x), pixelarea(scene)), kwargs...)

function axislines!(scene, rect, spinewidth, topspinevisible, rightspinevisible,
    leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
    rightspinecolor, bottomspinecolor)

    bottomline = lift(rect, spinewidth) do r, sw
        y = bottom(r)
        p1 = Point2(left(r) - 0.5sw, y)
        p2 = Point2(right(r) + 0.5sw, y)
        [p1, p2]
    end

    leftline = lift(rect, spinewidth) do r, sw
        x = left(r)
        p1 = Point2(x, bottom(r) - 0.5sw)
        p2 = Point2(x, top(r) + 0.5sw)
        [p1, p2]
    end

    topline = lift(rect, spinewidth) do r, sw
        y = top(r)
        p1 = Point2(left(r) - 0.5sw, y)
        p2 = Point2(right(r) + 0.5sw, y)
        [p1, p2]
    end

    rightline = lift(rect, spinewidth) do r, sw
        x = right(r)
        p1 = Point2(x, bottom(r) - 0.5sw)
        p2 = Point2(x, top(r) + 0.5sw)
        [p1, p2]
    end

    (lines!(scene, bottomline, linewidth = spinewidth, show_axis = false,
        visible = bottomspinevisible, color = bottomspinecolor)[end],
    lines!(scene, leftline, linewidth = spinewidth, show_axis = false,
        visible = leftspinevisible, color = leftspinecolor)[end],
    lines!(scene, rightline, linewidth = spinewidth, show_axis = false,
        visible = rightspinevisible, color = rightspinecolor)[end],
    lines!(scene, topline, linewidth = spinewidth, show_axis = false,
        visible = topspinevisible, color = topspinecolor)[end])
end


function interleave_vectors(vec1::Vector{T}, vec2::Vector{T}) where T
    n = length(vec1)
    @assert n == length(vec2)

    vec = Vector{T}(undef, 2 * n)
    @inbounds for i in 1:n
        k = 2(i - 1)
        vec[k + 1] = vec1[i]
        vec[k + 2] = vec2[i]
    end
    vec
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
    if exp.head != :block
        error("Not a block")
    end

    expressions = filter(x -> !(x isa LineNumberNode), exp.args)

    vars_and_exps = map(expressions) do e
        if e.head == :macrocall && e.args[1] == GlobalRef(Core, Symbol("@doc"))
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
    exp_docdict = Expr(:call, :Dict,
        (Expr(:call, Symbol("=>"), QuoteNode(name), strexp)
            for (name, _, strexp) in vars_and_exps)...)

    # make a dictionary of :variable_name => docstring_expression
    defaults_dict = Expr(:call, :Dict,
        (Expr(:call, Symbol("=>"), QuoteNode(name), exp isa String ? "\"$exp\"" : string(exp))
            for (name, exp, _) in vars_and_exps)...)

    # make an Attributes instance with of variable_name = variable_expression
    exp_attrs = Expr(:call, :Attributes,
        (Expr(:kw, name, exp)
            for (name, exp, _) in vars_and_exps)...)

    esc(quote
        ($exp_attrs, $exp_docdict, $defaults_dict)
    end)
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
    String(take!(buffer))
end

function Base.delete!(lobject::Union{LObject, LAxis})
    for (_, d) in lobject.elements
        remove_element(d)
    end

    if hasfield(typeof(lobject), :scene)
        delete_scene!(lobject.scene)
    end

    GridLayoutBase.remove_from_gridlayout!(GridLayoutBase.gridcontent(lobject))
    nothing
end

function remove_element(x::Union{LObject, LAxis, LineAxis})
    delete!(x)
end

function remove_element(x::AbstractPlot)
    delete!(x.parent, x)
end

function remove_element(xs::AbstractArray)
    foreach(remove_element, xs)
end

function remove_element(::Nothing)
end

function delete_scene!(s::Scene)
    for p in copy(s.plots)
        delete!(s, p)
    end
    deleteat!(s.parent.children, findfirst(x -> x === s, s.parent.children))
    nothing
end


function subtheme(scene, key::Symbol)
    sub = haskey(theme(scene), key) ? theme(scene, key) : Attributes()
    if !(sub isa Attributes)
        error("Subtheme is not of type Attributes but is $sub")
    end
    sub
end

"""
    xaxis_top!(la::LAxis)

Move the x-axis to the top, while correctly aligning the tick labels at the bottom.
"""
function xaxis_top!(la::LAxis)
    la.xaxisposition = :top
    la.xticklabelalign = (la.xticklabelalign[][1], :bottom)
    nothing
end

"""
    xaxis_bottom!(la::LAxis)

Move the x-axis to the bottom, while correctly aligning the tick labels at the top.
"""
function xaxis_bottom!(la::LAxis)
    la.xaxisposition = :bottom
    la.xticklabelalign = (la.xticklabelalign[][1], :top)
    nothing
end

"""
    yaxis_left!(la::LAxis)

Move the y-axis to the left, while correctly aligning the tick labels at the right.
"""
function yaxis_left!(la::LAxis)
    la.yaxisposition = :left
    la.yticklabelalign = (:right, la.yticklabelalign[][2])
    nothing
end

"""
    yaxis_right!(la::LAxis)

Move the y-axis to the right, while correctly aligning the tick labels at the left.
"""
function yaxis_right!(la::LAxis)
    la.yaxisposition = :right
    la.yticklabelalign = (:left, la.yticklabelalign[][2])
    nothing
end

"""
    labelslider!(scene, label, range; format = string, sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(), layoutkw...)

Construct a horizontal GridLayout with a label, a slider and a value label in `scene`.

Returns a `NamedTuple`:

`(slider = slider, label = label, valuelabel = valuelabel, layout = layout)`

Specify a format function for the value label with the `format` keyword.
The slider is forwarded the keywords from `sliderkw`.
The label is forwarded the keywords from `labelkw`.
The value label is forwarded the keywords from `valuekw`.
All other keywords are forwarded to the `GridLayout`.

Example:

```
ls = labelslider!(scene, "Voltage:", 0:10; format = x -> "\$(x)V")
layout[1, 1] = ls.layout
```
"""
function labelslider!(scene, label, range; format = string,
        sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(), layoutkw...)
    slider = LSlider(scene; range = range, sliderkw...)
    label = LText(scene, label; labelkw...)
    valuelabel = LText(scene, lift(format, slider.value); valuekw...)
    layout = hbox!(label, slider, valuelabel; layoutkw...)
    (slider = slider, label = label, valuelabel = valuelabel, layout = layout)
end


"""
    labelslidergrid!(scene, labels, ranges; formats = [string],
        sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(), layoutkw...)

Construct a GridLayout with a column of label, a column of sliders and a column of value labels in `scene`.
The argument values are broadcast, so you can use scalars if you want to keep labels, ranges or formats constant across rows.

Returns a `NamedTuple`:

`(sliders = sliders, labels = labels, valuelabels = valuelabels, layout = layout)`

Specify format functions for the value labels with the `formats` keyword.
The sliders are forwarded the keywords from `sliderkw`.
The labels are forwarded the keywords from `labelkw`.
The value labels are forwarded the keywords from `valuekw`.
All other keywords are forwarded to the `GridLayout`.

Example:

```
ls = labelslidergrid!(scene, ["Voltage", "Ampere"], Ref(0:0.1:100); format = x -> "\$(x)V")
layout[1, 1] = ls.layout
```
"""
function labelslidergrid!(scene, labels, ranges; formats = [string],
        sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(), layoutkw...)

    elements = broadcast(labels, ranges, formats) do label, range, format
        slider = LSlider(scene; range = range, sliderkw...)
        label = LText(scene, label; halign = :left, labelkw...)
        valuelabel = LText(scene, lift(format, slider.value); halign = :right, valuekw...)
        (; slider = slider, label = label, valuelabel = valuelabel)
    end

    sliders = map(x -> x.slider, elements)
    labels = map(x -> x.label, elements)
    valuelabels = map(x -> x.valuelabel, elements)
    
    layout = grid!(hcat(labels, sliders, valuelabels); layoutkw...)
    
    (sliders = sliders, labels = labels, valuelabels = valuelabels, layout = layout)
end



# helper function to create either h or vlines depending on `direction`
# this works only with LAxes because it needs to react to limit changes
function hvlines!(ax::LAxis, direction::Int, datavals, axmins, axmaxs; attributes...)

    datavals, axmins, axmaxs = map(x -> x isa Observable ? x : Observable(x), (datavals, axmins, axmaxs))

    linesegs = lift(ax.limits, ax.scene.px_area, datavals, axmins, axmaxs) do lims, pxa,
            datavals, axmins, axmaxs

        xlims = (minimum(lims)[direction], maximum(lims)[direction])
        xfrac(f) = xlims[1] + f * (xlims[2] - xlims[1])
        segs = broadcast(datavals, axmins, axmaxs) do dataval, axmin, axmax
            if direction == 1
                (Point2f0(xfrac(axmin), dataval), Point2f0(xfrac(axmax), dataval))
            elseif direction == 2
                (Point2f0(dataval, xfrac(axmin)), Point2f0(dataval, xfrac(axmax)))
            else
                error("direction must be 1 or 2")
            end
        end
        # handle case that none of the inputs is an array, but we need an array for linesegments!
        if segs isa Tuple
            segs = [segs]
        end
        segs
    end

    linesegments!(ax, linesegs; xautolimits = direction == 2, yautolimits = direction == 1, attributes...)
end

"""
    hlines!(ax::LAxis, ys; xmin = 0.0, xmax = 1.0, attrs...)

Create horizontal lines across `ax` at `ys` in data coordinates and `xmin` to `xmax`
in axis coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.
"""
hlines!(ax::LAxis, ys; xmin = 0.0, xmax = 1.0, attrs...) =
    hvlines!(ax, 1, ys, xmin, xmax; attrs...)

"""
    vlines!(ax::LAxis, xs; ymin = 0.0, ymax = 1.0, attrs...)

Create vertical lines across `ax` at `xs` in data coordinates and `ymin` to `ymax`
in axis coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.
"""
vlines!(ax::LAxis, xs; ymin = 0.0, ymax = 1.0, attrs...) = 
    hvlines!(ax, 2, xs, ymin, ymax; attrs...)