################################################################################
### Block Macro
################################################################################

function is_attribute end
function default_attribute_values end
function attribute_types end
function attribute_default_expressions end
function _attribute_docs end
function has_forwarded_layout end

symbol_to_block(symbol::Symbol) = symbol_to_block(Val(symbol))
symbol_to_block(::Val) = nothing

"""
Creates a new `Block` implementation which represents content within a layout.
The content may draw to the slot in the layout directly, or represent a layout
itself, containing more blocks.

## Usage

```
@Block TypeName <: OptionalParent optional_args begin
    optional_field1::OptionalType
    optional_field2
    @attributes begin
        "docstring"
        attribute1::OptionalType = value1
        attribute2 = value2
    end
end
```

The macro generates a `mutable struct` with the name `TypeName`, which always
needs to be given in the macro. If a parent type `<: OptionalParent` is given,
the struct will inherit from that type. Otherwise it will inherit from `Block`.
Note that the parent should also inherit from `Block`.

The content of the struct **always** includes:
- `parent::Union{Figure, Scene, Nothing}` which refers back to the figure or
    scene the block is placed in
- `layoutobservables::Makie.LayoutObservables{GridLayout}` which handle the
    placement into the parent layout
- `attributes::Makie.ComputeGraph` which contains the attributes and
    computations that use them
- `blockscene::Scene` which acts as a container for the inner layout and can be
    used for decoration plots
- `layout::GridLayout` which represents an optional internal layout used when
    implementing a `Block` as a container for more blocks.

Optionally you may also add fields by declaring them in the `begin ... end`
block, outside the `@attributes begin ... end` block. Each line will be treated
as a new field to add, with an optional type. You can have any number of fields.
Note that you will need to initialize them yourself in `initialize_block!()`.

The `@attributes begin ... end` block is necessary but can be empty. Each entry
needs to have at least a name and value given as `name = value`. Optionally, the
attribute can be typed by adding a type annotation `name::Type`. Also
optionally, the attribute can be given a docstring by adding a string in the
line above. This can also be a triple-quoted multiline string.

Note that some layouting attributes are always defined. These include:
- `halign = :center` The horizontal alignment of the block in its suggested bounding box.
- `valign = :center` The vertical alignment of the block in its suggested bounding box.
- `width = Auto()` The width setting of the block.
- `height = Auto()` The height setting of the block.
- `tellwidth::Bool = true` Controls if the parent layout can adjust to this block's width
- `tellheight::Bool = true` Controls if the parent layout can adjust to this block's height
- `alignmode = Inside()` The align mode of the block in its parent GridLayout.

All attributes are automatically collected and added to `attributes` ComputeGraph.

## `initialize_block!(block::TypeName, args...; kwargs...)`

The `initialize_block!` function should handle the non-generic parts of the
block initialization. This includes initializing added fields, handling keyword
arguments outside of attributes and building the visual aspects of the block.

If `optional_args` are given in `@Block` as a tuple `(name1, name2, ...)` the
default `initialize_block!(block, args...; kwargs...)` will handle attributes.
This is handled more or less the same as with plots. Arguments are added as
inputs `:arg1, :arg2, ...` to the compute graph. They then go through a few
computations, triggering `expand_dimensions(...)` and `convert_arguments(...)`,
before writing the converted arguments to `:name1, :name2, ...`. These can then
be grabbed from the block as `block.name1` etc.

If `optional_args` are not given the Block can be constructed with no arguments.
If arguments are given and should be handled without convert_arguments, a method
of `initialize_block!()` needs to be defined to handle them.

Other than that, the `initialize_block!()` function typically comes in one of
two forms. One is used by self-contained blocks like `Label` or `Axis`. They
don't have child blocks and instead directly define their visuals and
functionality. This may include adding plots and scenes to `block.blockscene`
and setting up interactivity. These kinds of blocks typically do not have
arguments, or handle them explicitly.

The other type defines its content through child blocks, which are added to the
parent block as if it was a figure. Plots may also be added to the child blocks.
For this, the conversion pipeline may be helpful. The blocks may also connect
to each other, e.g. with a Slider controlling a plot.

```
function Makie.initialize_block!(block::TypeName, x, y)
    ax = Axis(block[1, 1], title = block.title)
    p = scatter!(ax, x, y, color = block.color, label = "scatter 1")
    Legend(block[0, 1], ax, nbanks = 5)
    return
end
```

The blocks and plots added this way are automatically tracked in `block` and
can be queried with `block.blocks` and `block.plots` respectively. After the
block is constructed further plots can be added to the axis by plotting to its
layout slot `block[1, 1]`.
"""
macro Block(_name::Union{Expr, Symbol}, body::Expr = Expr(:block))
    return block_macro_internal(_name, nothing, body)
end

macro Block(_name::Union{Expr, Symbol}, args::Expr, body::Expr)
    return block_macro_internal(_name, args, body)
end

function block_macro_internal(_name::Union{Expr, Symbol}, args, body::Expr = Expr(:block))
    body.head === :block || error("A Block needs to be defined within a `begin end` block")

    type_expr = _name isa Expr ? _name : :($_name <: Makie.Block)
    name = _name isa Symbol ? _name : _name.args[1]
    structdef = quote
        mutable struct $(type_expr)
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::Makie.LayoutObservables{GridLayout}
            attributes::Makie.ComputeGraph
        end
    end

    fields_vector = structdef.args[2].args[3].args
    basefields = filter(x -> !(x isa LineNumberNode), fields_vector)

    push!(fields_vector, :(blockscene::Scene))
    push!(fields_vector, :(layout::Union{Nothing, GridLayout}))

    attrs = extract_attributes!(body)

    i_forwarded_layout = findfirst(
        x -> x isa Expr && x.head === :macrocall &&
            x.args[1] == Symbol("@forwarded_layout"),
        body.args
    )
    has_forwarded_layout = i_forwarded_layout !== nothing

    if has_forwarded_layout
        popat!(body.args, i_forwarded_layout)
    end

    # append remaining fields
    append!(fields_vector, body.args)

    attr_type_writes = Expr(
        :block, map(attrs) do a
            :(types[$(QuoteNode(a.symbol))] = $(a.type))
        end...
    )

    constructor = quote
        function $name($(basefields...))
            return new($(basefields...))
        end
    end

    push!(fields_vector, constructor)

    if isnothing(args)
        # If no args are provided we don't define these methods and error when
        # arguments are present and not handled explicitly
        argument_names_expr = :()
        # argument_types_expr = :()
    else
        if !Meta.isexpr(args, :tuple)
            throw(ArgumentError("Arguments must be given as a tuple `@Block Name (arg1, ...) begin ... end"))
        end
        names = map(x -> x isa Symbol ? x : x.args[1], args.args)
        types = map(x -> x isa Symbol ? :Any : x.args[2], args.args)
        argument_names_expr = :($(Makie).argument_names(::Type{$name}) = $names)
        # TODO: This is broken but also not used
        # argument_types_expr = quote
        #     $(Makie).block_argument_types(::Type{$name}) = tuple( $(esc.(types)...) )
        # end
    end

    docs_placeholder = Symbol("#__", name, "_docs_placeholder")

    q = quote
        # This part is as far as I know the only way to modify the docstring on top of the
        # recipe, so that we can offer the convenience of automatic augmented docstrings
        # but combine them with the simplicity of using a normal docstring.
        # The trick is to mark some variable with the
        # Core.@__doc__ macro, which causes this variable to get assigned the docstring on top
        # of the @recipe invocation. From there, it can then be retrieved, modified, and later
        # attached to plotting function by using @doc again. We also delete the binding to the
        # temporary variable so no unnecessary docstrings stay in place.
        Core.@__doc__ $(docs_placeholder) = nothing
        binding = Docs.Binding(@__MODULE__, $(QuoteNode(docs_placeholder)))
        user_docstring = if haskey(Docs.meta(@__MODULE__), binding)
            _docstring = @doc($docs_placeholder)
            delete!(Docs.meta(@__MODULE__), binding)
            _docstring
        else
            "No docstring defined.\n"
        end

        $structdef

        export $name
        $(Makie).symbol_to_block(::Val{$(QuoteNode(name))}) = $name
        function $(Makie).is_attribute(::Type{$(name)}, sym::Symbol)
            return sym in ($((attrs !== nothing ? [QuoteNode(a.symbol) for a in attrs] : [])...),)
        end

        function $(Makie).default_attribute_values(::Type{$(name)}, scene::Union{Scene, Nothing})
            sceneattrs = scene === nothing ? Attributes() : theme(scene)
            curdeftheme = $(Makie).fast_deepcopy($(Makie).CURRENT_DEFAULT_THEME)
            $(make_attr_dict_expr(attrs, :sceneattrs, :curdeftheme))
        end

        function $(Makie).attribute_types(::Type{$(name)})
            types = Dict{Symbol, Any}()
            $attr_type_writes
            return types
        end

        function $(Makie).attribute_default_expressions(::Type{$name})
            $(
                if attrs === nothing
                    Dict{Symbol, String}()
                else
                    Dict{Symbol, String}([a.symbol => _defaultstring(a.default) for a in attrs])
                end
            )
        end

        function $(Makie)._attribute_docs(::Type{$(name)})
            return Dict(
                $(
                    (
                        attrs !== nothing ?
                            [Expr(:call, :(=>), QuoteNode(a.symbol), a.docs) for a in attrs] :
                            []
                    )...
                )
            )
        end

        $(Makie).has_forwarded_layout(::Type{$name}) = $has_forwarded_layout

        $argument_names_expr

        docstring_modified = Makie.make_block_docstring($name, user_docstring)
        @doc docstring_modified $name
        export $name
    end

    return esc(q)
end

_defaultstring(x) = string(MacroTools.striplines(x))
_defaultstring(x::String) = repr(x)

function make_attr_dict_expr(::Nothing, sceneattrsym, curthemesym)
    return :(Dict())
end

function make_block_docstring(T::Type{<:Block}, docstring)
    return """
    **`$T <: Block`**

    $docstring

    **Attributes**

    (type `?$T.x` in the REPL for more information about attribute `x`)

    $(_attribute_list(T))
    """
end

function _attribute_list(T)
    ks = sort(collect(keys(_attribute_docs(T))))
    return join(("`$k`" for k in ks), ", ")
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

    return quote
        d = Dict{Symbol, Any}()
        $(exprs...)
        d
    end
end


function extract_attributes!(body)
    i = findfirst(
        (
            x -> x isa Expr && x.head === :macrocall && x.args[1] == Symbol("@attributes") &&
                x.args[3] isa Expr && x.args[3].head === :block
        ),
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

    attrs::Vector{Any} = map(extract_attribute_metadata, args)

    lras = map(extract_attribute_metadata, layout_related_attributes)

    for lra in lras
        i = findfirst(x -> x.symbol == lra.symbol, attrs)
        if i === nothing
            push!(attrs, lra)
        end
    end

    return attrs
end


################################################################################
### Block Construction
################################################################################


# intercept all block constructors and divert to _block(T, ...)
function (::Type{T})(args...; kwargs...) where {T <: Block}
    return _block(T, args...; kwargs...)
end

can_be_current_axis(x) = false

get_top_parent(gp::GridLayout) = GridLayoutBase.top_parent(gp)
get_top_parent(gp::GridPosition) = GridLayoutBase.top_parent(gp.layout)
get_top_parent(gp::GridSubposition) = get_top_parent(gp.parent)

function _block(
        T::Type{<:Block},
        gp::Union{GridPosition, GridSubposition}, args...; kwargs...
    )

    top_parent = get_top_parent(gp)
    if top_parent === nothing
        error("Found nothing as the top parent of this GridPosition. A GridPosition or GridSubposition needs to be connected to the top layout of a Figure, Scene or comparable object, either directly or through nested GridLayouts in order to plot into it.")
    end
    b = gp[] = _block(T, top_parent, args...; kwargs...)
    return b
end

function _block(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene}, args...; bbox = nothing, kwargs...)
    return _block(T, fig_or_scene, Any[args...], Dict{Symbol, Any}(kwargs), bbox)
end

function _block(T::Type{<:Block}, args...; bbox = nothing, kwargs...)
    kw_dict = Dict{Symbol, Any}(kwargs)
    figure_kw = extract_attributes(kw_dict, :figure)
    figure = Figure(; figure_kw...)
    b = figure[1, 1][] = _block(T, figure, Any[args...], kw_dict, bbox)
    return FigureAxis(figure, b)
end

function block_defaults(blockname::Symbol, attribute_kwargs::Dict, scene::Union{Nothing, Scene})
    return block_defaults(getfield(Makie, blockname), attribute_kwargs, scene)
end
function block_defaults(::Type{B}, attribute_kwargs::Dict, scene::Union{Nothing, Scene}) where {B <: Block}
    default_attrs = default_attribute_values(B, scene)
    blockname = nameof(B)
    typekey_scene_attrs = get(theme(scene), blockname, Attributes())
    typekey_attrs = theme(blockname; default = Attributes())::Attributes
    attributes = Dict{Symbol, Any}()
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

function InvalidAttributeError(::Type{BT}, attributes::Set{Symbol}) where {BT <: Block}
    return InvalidAttributeError(BT, "block", attributes)
end

function attribute_names(::Type{T}) where {T <: Block}
    attrs = _attribute_docs(T)
    # Some blocks have keyword arguments that are not attributes.
    # TODO: Refactor intiailize_block! to just not use kwargs?
    (T <: Axis || T <: PolarAxis) && (attrs[:palette] = "")
    T <: Legend && (attrs[:entrygroups] = "")
    T <: Menu && (attrs[:default] = "")
    T <: LScene && (attrs[:scenekw] = "")
    return keys(attrs)
end

function _check_remaining_kwargs(T::Type{<:Block}, kwdict::Dict)
    badnames = setdiff(keys(kwdict), attribute_names(T))
    if !isempty(badnames)
        throw(InvalidAttributeError(T, badnames))
    end
    return
end

function init_layout!(b)
    # create the gridlayout and set its parent to blockscene so that
    # one can create objects in the layout and scene more easily
    b.layout = GridLayout()
    b.layout.parent = b.blockscene

    lobservables = b.layoutobservables

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
    return
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
    return s
end

function register_in_figure!(fig::Figure, @nospecialize block::Block)
    if block.parent !== fig
        error("Can't register a block with a different parent in a figure.")
    end
    if !(block in fig.content)
        push!(fig.content, block)
    end
    return nothing
end

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

"""
    BlockAttributeConvert{TargetType}()

When a block attribute has a type assigned this callable struct is used to
convert the data of that attribute to the assigned type.

For example:
```julia
@Block ... begin
    @attributes begin
        attrib1::RGBAf = :black
    end
end
```
will generate a `converter = BlockAttributeConvert{RGBAf}()` and use it as a
callback for the compute graph input `add_input!(converter, :attrib1, :black)`.
Updating the input will then call
```julia
(::BlockAttributeConvert{RGBAf})(key, x) = to_color(x)::RGBAf
```
before setting a compute node strictly typed to `RGBAf`.

If no method exists for a specific target type, no conversions happen. This
means the attribute only accepts values of the given type (and its subtypes).
If no type is given `Any` is used.
"""
struct BlockAttributeConvert{Target} end

(::BlockAttributeConvert{<:Any})(key, x) = x
(::BlockAttributeConvert{T})(key, x) where {T <: Number} = T(x)
(::BlockAttributeConvert{<:RGBAf})(key, x) = to_color(x)::RGBAf
(::BlockAttributeConvert{<:Makie.FreeTypeAbstraction.FTFont})(key, x) = to_font(x)

function _block(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene}, args, kwdict::Dict, bbox; kwdict_complete = false)

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
    _check_remaining_kwargs(T, non_attribute_kwargs)

    topscene = get_topscene(fig_or_scene)
    # retrieve the default attributes for this block given the scene theme
    # and also the `Block = (...` style attributes from scene and global theme
    if kwdict_complete
        attributes = attribute_kwargs
    else
        attributes = block_defaults(T, attribute_kwargs, topscene)
    end

    graph = ComputeGraph()
    typedict = attribute_types(T)
    for (key, attrib) in attributes
        type = get(typedict, key, Any)
        add_input!(BlockAttributeConvert{type}(), graph, key, attrib)
        converted = BlockAttributeConvert{type}()(nothing, to_value(attrib))
        try
            ComputePipeline.unsafe_init!(graph[key], Ref{type}(converted))
        catch e
            @info "Failed to initialize Attribute $key with converted value $converted (input $attrib) to a type $type."
            rethrow(e)
        end
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

    # create base block with otherwise undefined fields
    b = T(fig_or_scene, lobservables, graph)

    b.blockscene = Scene(topscene, clear = false, camera = campixel!)

    if has_forwarded_layout(T)
        init_layout!(b)
    end

    # in this function, the block specific setup logic is executed and the remaining
    # uninitialized fields are filled
    # hide block while initializing, so that it doesn't show up in half a state while rendering
    # And to skip a few more updates
    hide!(b)
    initialize_block!(b, args...; non_attribute_kwargs...)

    if !isdefined(b, :layout)
        setfield!(b, :layout, nothing)
    end

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
        @warn("The following fields of $T were not assigned after `initialize_block!`: $unassigned_fields")
    end

    # forward all layout attributes to the block's layoutobservables
    connect_block_layoutobservables!(
        b, layout_width, layout_height, layout_tellwidth,
        layout_tellheight, layout_halign, layout_valign, layout_alignmode
    )

    if fig_or_scene isa Figure
        register_in_figure!(fig_or_scene, b)
        if can_be_current_axis(b)
            Makie.current_axis!(fig_or_scene, b)
        end
    end
    # Unhide it when we're done!
    unhide!(b)

    return b
end

# allow this to be overwritten for explicit argument handling (without args in @Block)
function initialize_block!(block::T, arg, _args...; kwargs...) where {T <: Block}
    args = (arg, _args...)

    if !applicable(argument_names, T)
        error("$T does not include arguments in the `@Block` macro or its `initialize_block!` method. \n Given: $args")
    end

    kw_dict = Dict{Symbol, Any}(kwargs)
    initialize_block_arguments!(block, args, kw_dict)

    initialize_block!(block; kw_dict...)

    return
end

"""
    initialize_block_arguments!(block::T, args::Tuple, kw_dict::Dict{Symbol, Any}, converted_names = argument_names(T))

Adds argument inputs and computations to generate converted arguments. The names
of the converted arguments may be passed as `converted_names`.
"""
function initialize_block_arguments!(
        block::T, args, kw_dict::Dict{Symbol, Any}, converted_names = argument_names(T)
    ) where {T <: Block}

    attr = block.attributes

    # adds inputs :arg1, :arg2, ...
    arg_names = _register_input_arguments!(attr, args)
    # applies expand_dimensions and merges :arg1, ... into one :args tuple
    _register_expand_arguments!(T, attr, arg_names)
    # We probably don't want dim_converts here, so we don't use
    # _register_argument_conversions!(T, attr, kw_dict)

    # adds used_attributes as :convert_kwargs
    add_convert_kwargs!(attr, kw_dict, T, args)

    # apply convert_arguments
    map!(attr, [:args, :convert_kwargs], :converted) do args, convert_kwargs
        x = convert_arguments(T, args...; convert_kwargs...)
        result_type = error_check_convert_arguments(T, args, convert_kwargs, x)
        return result_type === :Tuple ? x : (x,)
    end

    if length(converted_names) != length(attr.converted[])
        error(
            "Failed to construct Block: Number of arguments returned by \
            `convert_arguments` ($(length(attr.converted[]))) does not match the \
            number of expected arguments ($(length(converted_names)))."
        )
    end

    # splat to defined names
    map!(identity, attr, :converted, converted_names)

    return
end


################################################################################
### Utility functions
################################################################################


function Base.getproperty(block::T, name::Symbol) where {T <: Block}
    if hasfield(T, name)
        return getfield(block, name)
    elseif name === :blocks
        return flatten_layout_content(block)
    else
        return getindex(getfield(block, :attributes), name)
    end
end

function Base.propertynames(::T) where {T <: Block}
    return (fieldnames(T)..., :blocks, attribute_names(T)...)
end
function Base.hasproperty(block::T, name::Symbol) where {T <: Block}
    return hasfield(T, name) || (name === :block) || haskey(block.attributes, name)
end

function flatten_layout_content(block::Block)
    if isdefined(block, :layout) && !isnothing(block.layout)
        flatten_layout_content(block.layout)
    else
        return Block[]
    end
end
flatten_layout_content(layout) = append_content_to_list!(Block[], layout)

function append_content_to_list!(list, layout::GridLayout)
    for content in layout.content
        append_content_to_list!(list, content)
    end
    return list
end
function append_content_to_list!(list, content::GridLayoutBase.GridContent)
    return append_content_to_list!(list, content.content)
end
append_content_to_list!(list, content) = push!(list, content)

function Base.getindex(b::Block, i::Union{Integer, Colon, AbstractRange}, j::Union{Integer, Colon, AbstractRange})
    isdefined(b, :layout) || init_layout!(b)
    return b.layout[i, j]
end

@inline function Base.setproperty!(x::T, key::Symbol, value) where {T <: Block}
    if hasfield(T, key)
        if fieldtype(T, key) <: Observable
            if value isa Observable
                if isdefined(x, key)
                    error(
                        """It is disallowed to set `$key`, an Observable field of
                        the $T struct, to an Observable with dot notation (`setproperty!`),
                        because this would replace the existing Observable. If you really
                        want to do this, use `setfield!` instead."""
                    )
                else
                    setfield!(x, key, value)
                end
            else
                TargetType = observable_type(fieldtype(T, key))
                getfield(x, key)[] = BlockAttributeConvert{TargetType}()(nothing, value)
            end
        else
            setfield!(x, key, value)
        end
    elseif haskey(getfield(x, :attributes), key)
        update!(getfield(x, :attributes), key => value)
    else
        # this will throw correctly
        setfield!(x, key, value)
    end
    return
end

zshift!(b::Block, z) = translate!(b.blockscene, 0, 0, z)

function update_state_before_display!(block::Block)
    for child in block.blocks
        update_state_before_display!(child)
    end
    return
end

# treat all blocks as scalars when broadcasting
Base.Broadcast.broadcastable(l::Block) = Ref(l)

function Base.show(io::IO, ::T) where {T <: Block}
    return print(io, "$T()")
end

function Base.show(io::IO, ::MIME"text/plain", b::Block)
    show(io, b)
    if !isnothing(b.layout) && !isempty(b.layout.content)
        print(io, " containg ")
        show(io, MIME"text/plain"(), b.layout)
    end
end

function Base.show(io::IO, ::MIME"text/plain", ax::AbstractAxis)
    nplots = length(ax.scene.plots)
    kind = typeof(ax)
    println(io, "$kind with $nplots plots:")

    for (i, p) in enumerate(ax.scene.plots)
        println(io, (i == nplots ? " ┗━ " : " ┣━ ") * string(typeof(p)))
    end
    return
end

function Base.show(io::IO, ax::AbstractAxis)
    nplots = length(ax.scene.plots)
    kind = typeof(ax)
    return print(io, "$kind ($nplots plots)")
end

# fallback if block doesn't need specific clean up
free(::Block) = nothing

function Base.delete!(block::Block)
    foreach(delete!, block.blocks)
    free(block)
    empty!(block.attributes)

    block.parent === nothing && return
    # detach plots, cameras, transformations, viewport
    empty!(block.blockscene)
    empty!(block.attributes)

    disconnect!(block)
    block.parent = nothing
    return
end

function unhide!(block::Block)
    if !block.blockscene.visible[]
        block.blockscene.visible[] = true
    end
    if hasproperty(block, :scene) && isdefined(block, :scene) && !block.scene.visible[]
        block.scene.visible[] = true
    end
    return
end

function hide!(block::Block)
    if block.blockscene.visible[]
        block.blockscene.visible[] = false
    end
    if hasproperty(block, :scene) && isdefined(block, :scene) && block.scene.visible[]
        block.scene.visible[] = false
    end
    return
end

function disconnect!(block::Block)
    hide!(block)
    gc = GridLayoutBase.gridcontent(block)
    if gc !== nothing
        GridLayoutBase.remove_from_gridlayout!(gc)
    end

    if block.parent !== nothing
        Makie.delete_from_parent!(block.parent, block)
    end
    return
end


# do nothing for scene and nothing
function delete_from_parent!(parent, block::Block)
end

function delete_from_parent!(parent::Block, block::Block)
    filter!(x -> x !== block, parent.content)
    return
end

function delete_from_parent!(figure::Figure, block::Block)
    filter!(x -> x !== block, figure.content)
    if current_axis(figure) === block
        current_axis!(figure, nothing)
    end
    return nothing
end

function remove_element(x)
    return delete!(x)
end

function remove_element(x::AbstractPlot)
    return delete!(x.parent, x)
end

function remove_element(xs::AbstractArray)
    return foreach(remove_element, xs)
end

function remove_element(::Nothing)
end

observable_type(x::Type{Observable{T}}) where {T} = T

Base.@kwdef struct Example
    backend::Symbol = :CairoMakie # the backend that is used for rendering
    backend_using::Symbol = backend # the backend that is shown for `using` (for CairoMakie-rendered plots of interactive stuff that should show `using GLMakie`)
    svg::Bool = true # only for CairoMakie
    code::String
    caption::Union{Nothing, String} = nothing
end

function repl_docstring(type::Symbol, attr::Symbol, docs::Union{Nothing, String}, examples::Vector{Example}, default_str)
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
        println(io, "**Example $i**")
        println(io, "```julia")
        # println(io)
        # println(io, "# run in the REPL via Makie.example($type, :$attr, $i)")
        # println(io)
        println(io, example.code)
        println(io, "```")
        println(io)
    end

    return Markdown.parse(String(take!(io)))
end

# function example(type::Type{<:Block}, attr::Symbol, i::Int)
#     examples = get(attribute_examples(type), attr, Example[])
#     if !(1 <= i <= length(examples))
#         error("Invalid example number for attribute $attr of type $type.")
#     end
#     display(eval(Meta.parseall(examples[i].code)))
#     return
# end

function attribute_examples(b::Union{Type{<:Block}, Type{<:Plot}})
    return Dict{Symbol, Vector{Example}}()
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

# collect() doesn't seem to be necessary but the propertynames docstring says
# "tuple or vector" so lets not return a KeySet
Base.propertynames(::Type{T}) where {T <: Block} = collect(keys(_attribute_docs(T)))

function ComputePipeline.register_computation!(f, b::Block, inputs::Vector, outputs::Vector{Symbol})
    return register_computation!(f, b.attributes, inputs, outputs)
end
function ComputePipeline.update!(b::Block, args...; kwargs...)
    return ComputePipeline.update!(b.attributes, args...; kwargs...)
end

function Base.map!(f, b::Block, inputs::Union{Vector{Symbol}, Vector{Computed}, Symbol, Computed}, outputs::Union{Vector{Symbol}, Symbol})
    return map!(f, b.attributes, inputs, outputs)
end
