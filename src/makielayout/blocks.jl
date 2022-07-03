abstract type Block end

function is_attribute end
function default_attribute_values end
function attribute_default_expressions end
function _attribute_docs end
function has_forwarded_layout end


macro Block(name::Symbol, body::Expr = Expr(:block))

    if !(body.head == :block)
        error("A Block needs to be defined within a `begin end` block")
    end

    structdef = quote
        mutable struct $name <: Makie.Block
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::Makie.LayoutObservables{GridLayout}
            blockscene::Scene
        end
    end

    fields_vector = structdef.args[2].args[3].args
    basefields = filter(x -> !(x isa LineNumberNode), fields_vector)

    attrs = extract_attributes!(body)

    i_forwarded_layout = findfirst(
        x -> x isa Expr && x.head == :macrocall &&
            x.args[1] == Symbol("@forwarded_layout"),
        body.args
    )
    has_forwarded_layout = i_forwarded_layout !== nothing

    if has_forwarded_layout
        splice!(body.args, i_forwarded_layout, [:(layout::GridLayout)])
    end

    # append remaining fields
    append!(fields_vector, body.args)

    if attrs !== nothing
        attribute_fields = map(attrs) do a
            :($(a.symbol)::Observable{$(a.type)})
        end
        append!(fields_vector, attribute_fields)
    end

    constructor = quote
        function $name($(basefields...))
            new($(basefields...))
        end
    end

    push!(fields_vector, constructor)

    q = quote
        """
        For information about attributes, use `attribute_help($($name))`.
        """
        $structdef

        export $name

        function Makie.is_attribute(::Type{$(name)}, sym::Symbol)
            sym in ($((attrs !== nothing ? [QuoteNode(a.symbol) for a in attrs] : [])...),)
        end

        function Makie.default_attribute_values(::Type{$(name)}, scene::Union{Scene, Nothing})
            sceneattrs = scene === nothing ? Attributes() : theme(scene)
            curdeftheme = Makie.current_default_theme()

            $(make_attr_dict_expr(attrs, :sceneattrs, :curdeftheme))
        end

        function Makie.attribute_default_expressions(::Type{$name})
            $(
                if attrs === nothing
                    Dict{Symbol, String}()
                else
                    Dict{Symbol, String}([a.symbol => _defaultstring(a.default) for a in attrs])
                end
            )
        end

        function Makie._attribute_docs(::Type{$(name)})
            Dict(
                $(
                    (attrs !== nothing ?
                        [Expr(:call, :(=>), QuoteNode(a.symbol), a.docs) for a in attrs] :
                        [])...
                )
            )
        end

        Makie.has_forwarded_layout(::Type{$name}) = $has_forwarded_layout
    end

    esc(q)
end

_defaultstring(x) = string(x)
_defaultstring(x::String) = repr(x)

function make_attr_dict_expr(::Nothing, sceneattrsym, curthemesym)
    :(Dict())
end

block_docs(x) = ""

function Docs.getdoc(@nospecialize T::Type{<:Block})

    s = """
    # `$T <: Block`

    $(block_docs(T))

    ## Attributes

    $(_attribute_list(T))
    """
    Markdown.parse(s)
end

function _attribute_list(T)
    ks = sort(collect(keys(default_attribute_values(T, nothing))))
    default_exprs = attribute_default_expressions(T)
    layout_attrs = Set([:tellheight, :tellwidth, :height, :width,
        :valign, :halign, :alignmode])
    """

    **$T attributes**:

    $(join(["  - `$k`: $(_attribute_docs(T)[k]) Default: `$(default_exprs[k])`" for k in ks if k ∉ layout_attrs], "\n"))

    **Layout attributes**:

    $(join(["  - `$k`: $(_attribute_docs(T)[k]) Default: `$(default_exprs[k])`" for k in ks if k in layout_attrs], "\n"))
    """
end

function make_attr_dict_expr(attrs, sceneattrsym, curthemesym)

    pairs = map(attrs) do a

        d = a.default
        if d isa Expr && d.head == :macrocall && d.args[1] == Symbol("@inherit")
            if length(d.args) != 4
                error("@inherit works with exactly 2 arguments, expression was $d")
            end
            if !(d.args[3] isa QuoteNode)
                error("Argument 1 of @inherit must be a :symbol, got $(d.args[3])")
            end
            key, default = d.args[3:4]
            # first check scene theme
            # then current_default_theme
            # then default value
            d = quote
                if haskey($sceneattrsym, $key)
                    $sceneattrsym[$key]
                elseif haskey($curthemesym, $key)
                    $curthemesym[$key]
                else
                    $default
                end
            end
        end

        Expr(:call, :(=>), QuoteNode(a.symbol), d)
    end

    :(Dict($(pairs...)))
end

function attribute_help(T)
    println("Available attributes for $T (use attribute_help($T, key) for more information):")
    foreach(sort(collect(keys(_attribute_docs(T))))) do key
        println(key)
    end
end

function attribute_help(T, key)
    println(_attribute_docs(T)[key])
end

function extract_attributes!(body)
    i = findfirst(
        (x -> x isa Expr && x.head == :macrocall && x.args[1] == Symbol("@attributes") &&
            x.args[3] isa Expr && x.args[3].head == :block),
        body.args
    )
    if i === nothing
        return nothing
    end

    macroexpr = splice!(body.args, i)
    attrs_block = macroexpr.args[3]

    layout_related_attribute_block = quote
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
    end
    layout_related_attributes = filter(
        x -> !(x isa LineNumberNode),
        layout_related_attribute_block.args
    )

    args = filter(x -> !(x isa LineNumberNode), attrs_block.args)

    function extract_attr(arg)
        has_docs = arg isa Expr && arg.head == :macrocall && arg.args[1] isa GlobalRef

        if has_docs
            docs = arg.args[3]
            attr = arg.args[4]
        else
            docs = nothing
            attr = arg
        end

        if !(attr isa Expr && attr.head == :(=) && length(attr.args) == 2)
            error("$attr is not a valid attribute line like :x[::Type] = default_value")
        end
        left = attr.args[1]
        default = attr.args[2]
        if left isa Symbol
            attr_symbol = left
            type = Any
        else
            if !(left isa Expr && left.head == :(::) && length(left.args) == 2)
                error("$left is not a Symbol or an expression such as x::Type")
            end
            attr_symbol = left.args[1]::Symbol
            type = left.args[2]
        end

        (docs = docs, symbol = attr_symbol, type = type, default = default)
    end

    attrs = map(extract_attr, args)

    lras = map(extract_attr, layout_related_attributes)

    for lra in lras
        i = findfirst(x -> x.symbol == lra.symbol, attrs)
        if i === nothing
            push!(attrs, extract_attr(lra))
        end
    end

    attrs
end

# intercept all block constructors and divert to _block(T, ...)
function (::Type{T})(args...; kwargs...) where {T<:Block}
    _block(T, args...; kwargs...)
end

can_be_current_axis(x) = false

get_top_parent(gp::GridPosition) = GridLayoutBase.top_parent(gp.layout)
get_top_parent(gp::GridSubposition) = get_top_parent(gp.parent)

function _block(T::Type{<:Block},
        gp::Union{GridPosition, GridSubposition}, args...; kwargs...)

    top_parent = get_top_parent(gp)
    if top_parent === nothing
        error("Found nothing as the top parent of this GridPosition. A GridPosition or GridSubposition needs to be connected to the top layout of a Figure, Scene or comparable object, either directly or through nested GridLayouts in order to plot into it.")
    end
    b = gp[] = _block(T, top_parent, args...; kwargs...)
    b
end

function _block(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene},
        args...; bbox = nothing, kwargs...)

    # first sort out all user kwargs that correspond to block attributes
    kwdict = Dict(kwargs)
    attribute_kwargs = Dict{Symbol, Any}()
    for (key, value) in kwdict
        if is_attribute(T, key)
            attribute_kwargs[key] = pop!(kwdict, key)
        end
    end
    # the non-attribute kwargs will be passed to the block later
    non_attribute_kwargs = kwdict

    topscene = get_topscene(fig_or_scene)
    # retrieve the default attributes for this block given the scene theme
    # and also the `Block = (...` style attributes from scene and global theme
    default_attrs = default_attribute_values(T, topscene)
    typekey_scene_attrs = get(theme(topscene), nameof(T), Attributes())::Attributes
    typekey_attrs = get(Makie.current_default_theme(), nameof(T), Attributes())::Attributes

    # make a final attribute dictionary using different priorities
    # for the different themes
    attributes = Dict{Symbol, Any}()
    for (key, val) in default_attrs
        # give kwargs priority
        if haskey(attribute_kwargs, key)
            attributes[key] = attribute_kwargs[key]
        # otherwise scene theme
        elseif haskey(typekey_scene_attrs, key)
            attributes[key] = typekey_scene_attrs[key]
        # otherwise global theme
        elseif haskey(typekey_attrs, key)
            attributes[key] = typekey_attrs[key]
        # otherwise its the value from the type default theme
        else
            attributes[key] = val
        end
    end

    # create basic layout observables and connect attribute observables further down
    # after creating the block with its observable fields

    layout_width = Observable{Any}(nothing)
    layout_height = Observable{Any}(nothing)
    layout_tellwidth = Observable(true)
    layout_tellheight = Observable(true)
    layout_halign = Observable{Union{Symbol, Float64}}(:center)
    layout_valign = Observable{Union{Symbol, Float64}}(:center)
    layout_alignmode = Observable{Any}(Inside())

    lobservables = LayoutObservables(
        layout_width,
        layout_height,
        layout_tellwidth,
        layout_tellheight,
        layout_halign,
        layout_valign,
        layout_alignmode,
        suggestedbbox = bbox
    )

    blockscene = Scene(
        topscene,
        # the block scene tracks the parent scene exactly
        # for this it seems to be necessary to zero-out a possible non-zero
        # origin of the parent
        lift(Makie.zero_origin, topscene.px_area),
        camera = campixel!
    )

    # create base block with otherwise undefined fields
    b = T(fig_or_scene, lobservables, blockscene)

    for (key, val) in attributes
        OT = fieldtype(T, key)
        init_observable!(b, key, OT, val)
    end

    if has_forwarded_layout(T)
        # create the gridlayout and set its parent to blockscene so that
        # one can create objects in the layout and scene more easily
        b.layout = GridLayout()
        b.layout.parent = blockscene

        # the gridlayout needs to forward its autosize and protrusions to
        # the block's layoutobservables so from the outside, it looks like
        # the block has the same layout behavior as its internal encapsulated
        # gridlayout
        connect!(lobservables.autosize, b.layout.layoutobservables.autosize)
        connect!(lobservables.protrusions, b.layout.layoutobservables.protrusions)
        # this is needed so that the update mechanism works, because the gridlayout's
        # suggestedbbox is not connected to anything
        on(b.layout.layoutobservables.suggestedbbox) do _
            notify(lobservables.suggestedbbox)
        end
        # disable the GridLayout's own computedbbox's effect
        empty!(b.layout.layoutobservables.computedbbox.listeners)
        # connect the block's layoutobservables.computedbbox to the align action that
        # usually the GridLayout executes itself
        onany(GridLayoutBase.align_to_bbox!, b.layout, lobservables.computedbbox)
    end

    # in this function, the block specific setup logic is executed and the remaining
    # uninitialized fields are filled
    initialize_block!(b, args...; non_attribute_kwargs...)
    unassigned_fields = filter(collect(fieldnames(T))) do fieldname
        try
            getfield(b, fieldname)
        catch e
            if e isa UndefRefError
                return true
            else
                rethrow(e)
            end
        end
        false
    end
    if !isempty(unassigned_fields)
        error("The following fields of $T were not assigned after `initialize_block!`: $unassigned_fields")
    end

    # forward all layout attributes to the block's layoutobservables
    connect_block_layoutobservables!(b, layout_width, layout_height, layout_tellwidth,
        layout_tellheight, layout_halign, layout_valign, layout_alignmode)

    if fig_or_scene isa Figure
        register_in_figure!(fig_or_scene, b)
        if can_be_current_axis(b)
            Makie.current_axis!(fig_or_scene, b)
        end
    end
    b
end


"""
Get the scene which blocks need from their parent to plot stuff into
"""
get_topscene(f::Figure) = f.scene
function get_topscene(s::Scene)
    if !(Makie.cameracontrols(s) isa Makie.PixelCamera)
        error("Can only use scenes with PixelCamera as topscene")
    end
    s
end

function register_in_figure!(fig::Figure, @nospecialize block::Block)
    if block.parent !== fig
        error("Can't register a block with a different parent in a figure.")
    end
    if !(block in fig.content)
        push!(fig.content, block)
    end
    nothing
end

zshift!(b::Block, z) = translate!(b.blockscene, 0, 0, z)

function connect_block_layoutobservables!(@nospecialize(block), layout_width, layout_height, layout_tellwidth, layout_tellheight, layout_halign, layout_valign, layout_alignmode)
    connect!(layout_width, block.width)
    connect!(layout_height, block.height)
    connect!(layout_tellwidth, block.tellwidth)
    connect!(layout_tellheight, block.tellheight)
    connect!(layout_halign, block.halign)
    connect!(layout_valign, block.valign)
    connect!(layout_alignmode, block.alignmode)
    return
end

@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Block
    if hasfield(T, key)
        if fieldtype(T, key) <: Observable
            if value isa Observable
                error("It is disallowed to set `$key`, an Observable field of the $T struct, to an Observable with dot notation (`setproperty!`), because this would replace the existing Observable. If you really want to do this, use `setfield!` instead.")
            end
            obs = fieldtype(T, key)
            getfield(x, key)[] = convert_for_attribute(observable_type(obs), value)
        else
        setfield!(x, key, value)
        end
    else
        # this will throw correctly
        setfield!(x, key, value)
    end
end

# treat all blocks as scalars when broadcasting
Base.Broadcast.broadcastable(l::Block) = Ref(l)

function Base.show(io::IO, ::T) where T <: Block
    print(io, "$T()")
end

function Base.delete!(block::Block)
    block.parent === nothing && return

    s = get_topscene(block.parent)
    deleteat!(
        s.children,
        findfirst(x -> x === block.blockscene, s.children)
    )
    # TODO: what about the lift of the parent scene's
    # `px_area`, should this be cleaned up as well?

    GridLayoutBase.remove_from_gridlayout!(GridLayoutBase.gridcontent(block))

    on_delete(block)
    delete_from_parent!(block.parent, block)
    block.parent = nothing

    return
end

# do nothing for scene and nothing
function delete_from_parent!(parent, block::Block)
end

function delete_from_parent!(figure::Figure, block::Block)
    filter!(x -> x !== block, figure.content)
    if current_axis(figure) === block
        current_axis!(figure, nothing)
    end
    nothing
end

"""
Overload to execute cleanup actions for specific blocks that go beyond
deleting elements and removing from gridlayout
"""
function on_delete(block)
end

function remove_element(x)
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

# if a non-observable is passed, its value is converted and placed into an observable of
# the correct type which is then used as the block field
function init_observable!(@nospecialize(x), key, @nospecialize(OT), @nospecialize(value))
    o = convert_for_attribute(observable_type(OT), value)
    setfield!(x, key, OT(o))
    return x
end

# if an observable is passed, a converted type is lifted off of it, so it is
# not used directly as a block field
function init_observable!(@nospecialize(x), key, @nospecialize(OT), @nospecialize(value::Observable))
    obstype = observable_type(OT)
    o = Observable{obstype}()
    map!(o, value) do v
        convert_for_attribute(obstype, v)
    end
    setfield!(x, key, o)
    return x
end

observable_type(x::Type{Observable{T}}) where T = T

convert_for_attribute(t::Any, x) = x
convert_for_attribute(t::Type{Float64}, x) = convert(Float64, x)
convert_for_attribute(t::Type{RGBAf}, x) = to_color(x)::RGBAf
convert_for_attribute(t::Type{Makie.FreeTypeAbstraction.FTFont}, x) = to_font(x)
