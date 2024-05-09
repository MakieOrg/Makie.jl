

function is_attribute end
function default_attribute_values end
function attribute_default_expressions end
function _attribute_docs end
function has_forwarded_layout end

macro Block(_name::Union{Expr, Symbol}, body::Expr = Expr(:block))

    body.head === :block || error("A Block needs to be defined within a `begin end` block")

    type_expr = _name isa Expr ? _name : :($_name <: Makie.Block)
    name = _name isa Symbol ? _name : _name.args[1]
    structdef = quote
        mutable struct $(type_expr)
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::Makie.LayoutObservables{GridLayout}
            blockscene::Scene
        end
    end

    fields_vector = structdef.args[2].args[3].args
    basefields = filter(x -> !(x isa LineNumberNode), fields_vector)

    attrs = extract_attributes!(body)

    i_forwarded_layout = findfirst(
        x -> x isa Expr && x.head === :macrocall &&
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
        $structdef

        export $name

        function Makie.is_attribute(::Type{$(name)}, sym::Symbol)
            sym in ($((attrs !== nothing ? [QuoteNode(a.symbol) for a in attrs] : [])...),)
        end

        function Makie.default_attribute_values(::Type{$(name)}, scene::Union{Scene, Nothing})
            sceneattrs = scene === nothing ? Attributes() : theme(scene)
            curdeftheme = Makie.fast_deepcopy($(Makie).CURRENT_DEFAULT_THEME)
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

_defaultstring(x) = string(MacroTools.striplines(x))
_defaultstring(x::String) = repr(x)

function make_attr_dict_expr(::Nothing, sceneattrsym, curthemesym)
    :(Dict())
end

block_docs(x) = ""

function Docs.getdoc(@nospecialize T::Type{<:Block})
    if T === Block
        Markdown.parse("""
            abstract type Block

        `Block` is an abstract type that groups objects which can be placed in a `Figure`
        and positioned in its `GridLayout` as rectangular objects.

        Concrete `Block` types should only be defined via the `@Block` macro.
        """)
    else
        s = """
        **`$T <: Block`**

        $(block_docs(T))

        **Attributes**

        (type `?$T.x` in the REPL for more information about attribute `x`)

        $(_attribute_list(T))
        """
        Markdown.parse(s)
    end
end

function _attribute_list(T)
    ks = sort(collect(keys(_attribute_docs(T))))
    join(("`$k`" for k in ks), ", ")
end

function make_attr_dict_expr(attrs, sceneattrsym, curthemesym)

    exprs = map(attrs) do a

        d = a.default
        if d isa Expr && d.head === :macrocall && d.args[1] == Symbol("@inherit")
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
                    to_value($sceneattrsym[$key]) # only use value of theme entry
                elseif haskey($curthemesym, $key)
                    to_value($curthemesym[$key]) # only use value of theme entry
                else
                    $default
                end
            end
        end

        :(d[$(QuoteNode(a.symbol))] = $d)
    end

    quote
        d = Dict{Symbol,Any}()
        $(exprs...)
        d
    end
end


function extract_attributes!(body)
    i = findfirst(
        (x -> x isa Expr && x.head === :macrocall && x.args[1] == Symbol("@attributes") &&
            x.args[3] isa Expr && x.args[3].head === :block),
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

    attrs::Vector{Any} = map(MakieCore.extract_attribute_metadata, args)

    lras = map(MakieCore.extract_attribute_metadata, layout_related_attributes)

    for lra in lras
        i = findfirst(x -> x.symbol == lra.symbol, attrs)
        if i === nothing
            push!(attrs, lra)
        end
    end

    attrs
end

# intercept all block constructors and divert to _block(T, ...)
function (::Type{T})(args...; kwargs...) where {T<:Block}
    _block(T, args...; kwargs...)
end

can_be_current_axis(x) = false

get_top_parent(gp::GridLayout) = GridLayoutBase.top_parent(gp)
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


function _block(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene}, args...; bbox = nothing, kwargs...)
    return _block(T, fig_or_scene, Any[args...], Dict{Symbol,Any}(kwargs), bbox)
end

function block_defaults(blockname::Symbol, attribute_kwargs::Dict, scene::Union{Nothing, Scene})
    return block_defaults(getfield(Makie, blockname), attribute_kwargs, scene)
end
function block_defaults(::Type{B}, attribute_kwargs::Dict, scene::Union{Nothing, Scene}) where {B <: Block}
    default_attrs = default_attribute_values(B, scene)
    blockname = nameof(B)
    typekey_scene_attrs = get(theme(scene), blockname, Attributes())
    typekey_attrs = theme(blockname; default=Attributes())::Attributes
    attributes = Dict{Symbol,Any}()
    # make a final attribute dictionary using different priorities
    # for the different themes
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
    return attributes
end

function _block(T::Type{<:Block}, fig_or_scene::Union{Figure,Scene}, args, kwdict::Dict, bbox; kwdict_complete=false)

    # first sort out all user kwargs that correspond to block attributes
    check_textsize_deprecation(kwdict)

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
    if kwdict_complete
        attributes = attribute_kwargs
    else
        attributes = block_defaults(T, attribute_kwargs, topscene)
    end
    # create basic layout observables and connect attribute observables further down
    # after creating the block with its observable fields

    layout_width = Observable{Any}(nothing)
    layout_height = Observable{Any}(nothing)
    layout_tellwidth = Observable(true)
    layout_tellheight = Observable(true)
    layout_halign = Observable{GridLayoutBase.HorizontalAlignment}(:center)
    layout_valign = Observable{GridLayoutBase.VerticalAlignment}(:center)
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

    blockscene = Scene(topscene, clear=false, camera = campixel!)

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
get_topscene(f::Union{GridPosition, GridSubposition}) = get_topscene(get_top_parent(f))
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

# fallback if block doesn't need specific clean up
free(::Block) = nothing

function Base.delete!(block::Block)
    free(block)
    block.parent === nothing && return
    # detach plots, cameras, transformations, viewport
    empty!(block.blockscene)

    gc = GridLayoutBase.gridcontent(block)
    if gc !== nothing
        GridLayoutBase.remove_from_gridlayout!(gc)
    end

    if block.parent !== nothing
        delete_from_parent!(block.parent, block)
        block.parent = nothing
    end
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

# if a non-observable is passed, its value is converted and placed into an observable of
# the correct type which is then used as the block field
function init_observable!(@nospecialize(block), key::Symbol, @nospecialize(OT), @nospecialize(value))
    o = convert_for_attribute(observable_type(OT), value)
    setfield!(block, key, OT(o))
    return block
end

# if an observable is passed, a converted type is lifted off of it, so it is
# not used directly as a block field
function init_observable!(@nospecialize(block), key::Symbol, @nospecialize(OT), @nospecialize(value::Observable))
    obstype = observable_type(OT)
    o = Observable{obstype}()
    map!(block.blockscene, o, value) do v
        convert_for_attribute(obstype, v)
    end
    setfield!(block, key, o)
    return block
end

observable_type(x::Type{Observable{T}}) where T = T

convert_for_attribute(t::Any, x) = x
convert_for_attribute(t::Type{Float64}, x) = convert(Float64, x)
convert_for_attribute(t::Type{RGBAf}, x) = to_color(x)::RGBAf
convert_for_attribute(t::Type{Makie.FreeTypeAbstraction.FTFont}, x) = to_font(x)

Base.@kwdef struct Example
    name::String
    backend::Symbol = :CairoMakie # the backend that is used for rendering
    backend_using::Symbol = backend # the backend that is shown for `using` (for CairoMakie-rendered plots of interactive stuff that should show `using GLMakie`)
    svg::Bool = true # only for CairoMakie
    code::String
end

function repl_docstring(type::Symbol, attr::Symbol, docs::Union{Nothing,String}, examples::Vector{Example}, default_str)
    io = IOBuffer()

    println(io, "Default value: `$default_str`")
    println(io)

    if docs === nothing
        println(io, "No docstring defined for `$attr`.")
    else
        println(io, docs)
    end
    println(io)

    for (i, example) in enumerate(examples)
        println(io, "**Example $i**: $(example.name)")
        println(io, "```julia")
        # println(io)
        # println(io, "# run in the REPL via Makie.example($type, :$attr, $i)")
        # println(io)
        println(io, example.code)
        println(io, "```")
        println(io)
    end

    Markdown.parse(String(take!(io)))
end

# function example(type::Type{<:Block}, attr::Symbol, i::Int)
#     examples = get(attribute_examples(type), attr, Example[])
#     if !(1 <= i <= length(examples))
#         error("Invalid example number for attribute $attr of type $type.")
#     end
#     display(eval(Meta.parseall(examples[i].code)))
#     return
# end

function attribute_examples(b::Type{<:Block})
    Dict{Symbol,Vector{Example}}()
end

# overrides `?Axis.xticks` and similar lookups in the REPL
function REPL.fielddoc(t::Type{<:Block}, s::Symbol)
    if !is_attribute(t, s)
        return Markdown.parse("`$s` is not an attribute of type `$t`. Type `?$t` in the REPL to see the list of available attributes.")
    end
    docs = get(_attribute_docs(t), s, nothing)
    examples = get(attribute_examples(t), s, Example[])
    default_str = Makie.attribute_default_expressions(t)[s]
    return repl_docstring(nameof(t), s, docs, examples, default_str)
end
