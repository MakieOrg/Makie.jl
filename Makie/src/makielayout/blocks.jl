################################################################################
### Block Macro
################################################################################

function has_forwarded_layout end

symbol_to_block(symbol::Symbol) = symbol_to_block(Val(symbol))
symbol_to_block(::Val) = nothing

"""
    @Block BlockName begin ... end

Creates a new `Block` implementation which represents content within a layout.
The content may draw to the layout slot directly, or represent a layout
itself, containing more blocks.

## Usage

The absolute minimum required to define a block is:

```
@Bock MyBlock
Makie.initialize_block!(::MyBlock) = nothing
```

This will define `MyBlock` as a new empty block containing no visual or functional
components, no attributes, no arguments, no internal layout.
In contrast, this is a `@Block` definition containing all optional components:

```
@Block MyBlock <: OptionalParent (optional_arg1::OptionalType1, ...) begin
    optional_field::OptionalType
    @attributes begin
        "optional docstring"
        attribute::OptionalType = value
    end
end
```

The optional components include:

- `<: OptionalParent` a parent type for the block, i.e. `struct MyBlock <: OptionalParent`.
    The parent type must inherit from `Block`. If not given, `Block` is used as a parent type.
- `(optional_arg1::OptionalType1, ...)` an optional tuple of input arguments for the block.
    This is required for blocks that process arguments, i.e. complex recipes. Types are
    optional.
- `optional_field::OptionalType` an optional field named `optional_field` added to the block
    struct. This can optionally be typed, much like a normal struct field definition. Fields
    are generally initialized in `initialize_block!()`.
- `attribute::OptionalType = value` defines an attribute called `attribute` within a
    `@attributes begin ... end` block. The block is required to separate fields from
    attributes. Each attribute is required to define a default `value`. It may optionally
    include a type `OptionalType` and it may optionally include a docstring above it.

If the `@Block` definition includes arguments they are processed using almost the same pipeline
as plots. The only difference is the exclusion of dim converts. This means that blocks can use:

- `conversion_trait(::Type{MyBlock}, args...)` to define a conversion trait used for the
    conversion of arguments.
- `convert_arguments(::Type{MyBlock}, args...)` to define a conversion method for arguments.
- `used_attributes(::Type{MyBlock}, args...)` to mark which attributes should be passed to
        `convert_arguments()` as keyword arguments.
- `expand_dimensions(::ConversionTrait, args...)` to fill out missing arguments

The final output of the conversion pipeline will be saved to the names defined in the `@Block`
definition.

Any block eventually calls `initialize_block!(b::MyBlock; kwargs...)` to set up its visual
and functional aspects, similar to how plot recipes call `plot!(plot::MyPlot)`. The keyword
arguments passed here are any keyword arguments passed to `MyBlock()` which have not been
mapped to attributes.

For a complex recipes, the implementation of `initialize_block!(::MyBlock)` involves adding
blocks to the internal layout of `MyBlock`. For example:

```
function Makie.initialize_block!(b::MyBlock)
    ax = Axis(b[1, 1])
    # with @Block MyBlock (positions,) ...
    scatter!(ax, b.positions, label = "plot")
    Legend(b[1, 2], ax)
    return
end
```

For primitive blocks (e.g. `Axis` or `Label`) the definition is more free. They
generally don't involve other blocks and instead directly plot to `b.blockscene`
or create a child scene of `b.blockscene` to plot to. They may communicate with
`b.layoutobservables` and may react to events.

## BlockSpec

Similar to how a plot can defined by returning a `PlotSpec` from `convert_arguments`, a
`Block` can be defined by a `BlockSpec` or `GridLayoutSpec`. In this case the internal
layout of the block will be built based on the block spec. `initialize_block!(::MyBlock)`
will not be called, and the arguments section of the `@Block` macro will be ignored and
thus isn't required.

```
@Block SpecBlock
convert_arguments(::Type{<:SpecBlock}, ...) = SpecApi.Axis(...) # BlockSpec
convert_arguments(::Type{<:SpecBlock}, ...) = SpecApi.GridLayout(...) # GridLayoutSpec
```

## User Interface

- Arguments are accessible with `block.arg1` etc.
- Converted arguments are accessible using the names defined in `@Block`, e.g. `block.optional_arg1`
- Attributes are accessible with `block.attribute`
- Blocks contained within a complex recipe style block are listed in `block.blocks`
- If initialized with a layout, layout positions can be accessed with `block[i, j]`
- Plots can be accessed indirectly from an axis by retrieving it from `block.blocks` first

# Extended help

## `@Block`

The minimal example generates the following mutable struct:

```
mutable struct MyBlock <: Block
    parent::Union{Nothing, Figure, Scene}
    layoutobservables::LayoutObservables{GridLayout}
    attributes::ComputePipeline.ComputeGraph
    blockscene::Scene
    layout::Union{Nothing, GridLayout}
end
```

This includes:
- `parent` which refers back to the figure or scene the block is placed in
- `layoutobservables` which handles the placement of this block in the parent layout
- `attributes` which contain the attributes defined in `@attributes` block in the `@Block`
    macro. It also contains the computations based on those attributes and, if present,
    arguments and their computations.
- `blockscene` which is a pixel space scene owned by the Block. It may be used for
    decoration plots and as the base for child scenes owned by the block.
- `layout` which represents an optional internal layout used when implementing a `Block`
    as a container for more blocks, i.e. a complex recipe. It is initially `nothing`
    and may change to a `GridLayout` when accessed through `block[i, j]` during
    initialization. After initialization it is fixed to either a `GridLayout` or `nothing`

Any fields included in the `@Block` macro will be added directly to the struct.

## Attributes

There are a few layouting attributes that are always added, even when no `@attributes`
block is specified. These include:
- `halign = :center` The horizontal alignment of the block in its suggested bounding box.
- `valign = :center` The vertical alignment of the block in its suggested bounding box.
- `width = Auto()` The width setting of the block.
- `height = Auto()` The height setting of the block.
- `tellwidth::Bool = true` Controls if the parent layout can adjust to this block's width
- `tellheight::Bool = true` Controls if the parent layout can adjust to this block's height
- `alignmode = Inside()` The align mode of the block in its parent GridLayout.

## Attribute Conversions

Attributes may optionally define a type `attr::T = value`. This effectively results in

```
add_input!(x -> convert_for_attribute(T, x), block.attributes, :attr, value)
```

being used to create the attribute. Every time the attribute is set, the value
will be converted by `convert_for_attribute`. In the default case this will perform a type
assertion `new::T` but it can also perform a conversion. For example, if `T <: Number` a
type cast `T(new)` is performed and for `RGBAf` `to_color(new)` is called.

## Arguments

Strictly speaking arguments only need to be defined in `@Block` if the default argument
processing is used. It can be skipped/done manually by implementing
```
function initialize_block!(block::MyBlock, arg, args...; kwargs...)
    # process args...
    return initialize_block!(block; kwargs...)
end
```
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
        argument_names_expr = esc(:($(Makie).argument_names(::Type{$name}) = $names))
        # TODO: This is broken but also not used
        # argument_types_expr = quote
        #     $(Makie).block_argument_types(::Type{$name}) = tuple( $(esc.(types)...) )
        # end
    end

    docs_placeholder = Symbol("#__", name, "_docs_placeholder")
    attr_placeholder = Symbol("#__", name, "_attr_placeholder")

    BlockType = esc(name)

    q = quote
        # This part is as far as I know the only way to modify the docstring on top of the
        # recipe, so that we can offer the convenience of automatic augmented docstrings
        # but combine them with the simplicity of using a normal docstring.
        # The trick is to mark some variable with the
        # Core.@__doc__ macro, which causes this variable to get assigned the docstring on top
        # of the @recipe invocation. From there, it can then be retrieved, modified, and later
        # attached to plotting function by using @doc again. We also delete the binding to the
        # temporary variable so no unnecessary docstrings stay in place.
        Core.@__doc__ $(esc(docs_placeholder)) = nothing
        binding = Docs.Binding(@__MODULE__, $(QuoteNode(docs_placeholder)))
        user_docstring = if haskey(Docs.meta(@__MODULE__), binding)
            _docstring = @doc($docs_placeholder)
            delete!(Docs.meta(@__MODULE__), binding)
            _docstring
        else
            "No docstring defined.\n"
        end

        $(esc(structdef))

        export $BlockType
        $(Makie).symbol_to_block(::Val{$(QuoteNode(name))}) = $BlockType

        const $attr_placeholder = $attrs
        $(Makie).documented_attributes(::Type{<:$(BlockType)}) = $attr_placeholder

        $(Makie).has_forwarded_layout(::Type{$BlockType}) = $has_forwarded_layout

        $argument_names_expr

        docstring_modified = Makie.make_block_docstring($BlockType, user_docstring)
        @doc docstring_modified $name
    end

    return q
end

_defaultstring(x) = string(MacroTools.striplines(x))
_defaultstring(x::String) = repr(x)

function make_block_docstring(T::Type{<:Block}, docstring)
    return """
    **`$T <: Block`**

    $docstring

    **Attributes**

    (type `?$T.x` in the REPL for more information about attribute `x`)

    $(get_attribute_docs(T))
    """
end

attribute_groups(::Type{<:Block}) = Pair{String, Vector{Symbol}}[]

function mixin_block_layout_attributes()
    return @DocumentedAttributes begin
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
end

function extract_attributes!(body)
    i = findfirst(
        expr -> MacroTools.@capture(expr, @attributes blockexpr_),
        body.args
    )

    attr_input_expr = if i === nothing
        Expr(:block)
    else
        macroexpr = splice!(body.args, i)
        MacroTools.@capture(macroexpr, @attributes blockexpr_)
        blockexpr
    end

    # Make sure layout inputs exist by adding a mixin for them.
    # Only do this if the mixin doesn't already exist, since mixins error if
    # any of their entries already exists. Also add it as the first thing to
    # avoid this error.
    # Note that later entries can still overwrite the metadata of mixin entries
    # so custom defaults can still be set
    if !MacroTools.@capture(attr_input_expr, Makie.mixin_block_layout_attributes()...)
        pushfirst!(attr_input_expr.args, :(Makie.mixin_block_layout_attributes()...))
    end

    return build_documented_attributes(attr_input_expr)
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
    return FigureBlock(figure, b)
end

function InvalidAttributeError(::Type{BT}, attributes::Set{Symbol}) where {BT <: Block}
    return InvalidAttributeError(BT, "block", attributes)
end

"""
    block_kwargs(BlockType)

Returns a set of kwargs used by `BlockType <: Block`. Any kwargs given to the
constructor that are not listed here or in the blocks attributes will trigger
`InvalidAttributeError`s.
"""
block_kwargs(::Type{<:Block}) = Set{Symbol}()

# TODO: Should probably run recursively
function _check_remaining_kwargs(T::Type{<:Block}, kwdict::Dict)
    badnames = setdiff(keys(kwdict), block_kwargs(T))
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

# Should this be allowed?
convert_for_attribute(::UnionAll, x) = x

# If a concrete union is given, try each conversion option until one work
function convert_for_attribute(t::Union, x)
    try
        y1 = convert_for_attribute(t.a, x)
        (y1 isa t.a) && return y1
    catch e
    end

    try
        y2 = convert_for_attribute(t.b, x)
        (y2 isa t.b) && return y2
    catch e
    end

    return x
end

convert_for_attribute(::Any, x) = x
convert_for_attribute(::Type{T}, x) where {T <: VecTypes} = convert(T, x)
convert_for_attribute(::Type{T}, x) where {T <: Number} = convert(T, x)
convert_for_attribute(::Type{RGBAf}, x) = to_color(x)::RGBAf
convert_for_attribute(::Type{FreeTypeAbstraction.FTFont}, x) = to_font(x)

"""
    add_attributes(::Type{<:Block}, compute_graph, flattened_defaults)

This method may provide custom initialization of compute graph inputs (attributes)
of a block. This may be useful if the default conversions are inappropriate for
some inputs, i.e. if a different input callback is needed for a specific type
(including `Any` from entries without type annotations).

A custom implementation should use
`Makie.get_typed_default(Makie.documented_attributes(BlockType), flattened_defaults, keys...)`
to get the type defined in `@Block` as well as the initial value derived from
user kwargs, themes and the `@Block` definition. These should then be used to
initialize the input/attribute. (This is not enforced.)

After this, the default initialization will run to make sure that every attribute
defined by `@Block` has an input.

Example:
```
function Makie.add_attributes!(::Type{MyBlock}, graph, flattened_defaults)
    attr = Makie.documented_attributes(MyBlock)
    _, default = Makie.get_typed_default(attr, flattened_defaults, :colorname)
    Makie.add_input!(to_colorname, graph, :colorname, default)

    _, default = Makie.get_typed_default(attr, flattened_defaults, :nested, :attribute)
    Makie.add_input!(foo, graph, :nested, :attribute, default)
    Makie.ComputePipeline.set_type!(graph.nested.attribute, Any)

    return
end
```
"""
add_attributes!(::Type{<:Block}, graph, flattened_defaults...) = nothing

struct BlockAttributeConvert{T} <: Function end
(::BlockAttributeConvert{T})(x) where {T} = convert_for_attribute(T, x)
function (::BlockAttributeConvert{T})(x, @nospecialize(changed), @nospecialize(cached)) where {T}
    return (convert_for_attribute(T, x[1]),)
end

function _block(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene}, args, kwdict::Dict, bbox; kwdict_complete = false)

    # first sort out all user kwargs that correspond to block attributes
    check_textsize_deprecation(kwdict)

    graph = ComputeGraph()

    topscene = get_topscene(fig_or_scene)
    blockname = nameof(T)
    attr = documented_attributes(T)
    flattened_defaults = resolve_defaults(attr, topscene, blockname, kwdict, tuple(), true)

    # User overwrites
    add_attributes!(T, graph, flattened_defaults)

    # prepare after user overwrites so users can use `add_input!()`
    prepare_graph_for_attributes!(graph, attr, is_block = true)
    add_remaining_block_inputs!(graph, attr, flattened_defaults)

    # the non-attribute kwargs will be passed to the block later
    non_attribute_kwargs = kwdict
    _check_remaining_kwargs(T, non_attribute_kwargs)

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
    kw_dict = Dict{Symbol, Any}(kwargs)

    is_spec = initialize_block_arguments!(block, args, kw_dict)

    if is_spec
        initialize_specapi_block!(block, kw_dict)
    else
        initialize_block!(block; kw_dict...)
    end

    return
end

argument_names(::Type{<:Block}) = tuple()

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
    expanded = _register_expand_arguments!(T, attr, arg_names, to_value.(args))
    # We probably don't want dim_converts here, so we don't use
    # _register_argument_conversions!(T, attr, kw_dict)

    # adds used_attributes as :convert_kwargs
    add_convert_kwargs!(attr, kw_dict, T, args)

    # apply convert_arguments
    converted = convert_arguments(T, expanded...; attr.convert_kwargs[]...)

    # Special case SpecApi
    if converted isa Union{BlockSpec, GridLayoutSpec} ||
            length(converted) == 1 && converted[1] isa Union{BlockSpec, GridLayoutSpec}

        spec_init = Ref{Union{BlockSpec, GridLayoutSpec}}(
            converted isa Union{BlockSpec, GridLayoutSpec} ? converted : converted[1]
        )

        map!(attr, [:args, :convert_kwargs], :spec, init = spec_init) do args, convert_kwargs
            x = convert_arguments(T, args...; convert_kwargs...)
            if x isa Union{BlockSpec, GridLayoutSpec}
                return x
            elseif x isa Tuple{Union{BlockSpec, GridLayoutSpec}}
                return x[1]
            else
                error("`convert_arguments(::$T, ...) is not allow to switch from a BlockSpec or GridLayoutSpec to normal arguments.")
            end
        end

        return true
    end

    # Normal case - arguments
    map!(attr, [:args, :convert_kwargs], :converted) do args, convert_kwargs
        x = convert_arguments(T, args...; convert_kwargs...)
        if x isa Union{BlockSpec, GridLayoutSpec, Tuple{Union{BlockSpec, GridLayoutSpec}}}
            error("`convert_arguments(::$T, ...) is not allow to switch from normal arguments to a BlockSpec or GridLayoutSpec.")
        end
        return x
    end

    if length(converted_names) != length(attr.converted[])
        if length(converted_names) == 0
            error(
                "Failed to construct Block: Expected no arguments but got: $(attr.converted[]). \
                If $T is a primitive block, a workaround method $T(fig_or_scene, args...) maybe \
                missing or failed to be called. If $T is a Complex/Block recipe, it is likely not \
                declaring its arguments in `@Block Name (args...)."
            )
        else
            error(
                "Failed to construct Block: Expected $(length(converted_names)) converted \
                argument(s) to map to `$converted_names` but got $(length(attr.converted[])): \
                $(attr.converted[]). This means that `$T` did not correctly convert the given \
                arguments."
            )
        end
    end

    # splat to defined names
    map!(identity, attr, :converted, converted_names)

    return false
end


function initialize_specapi_block!(block, kw_dict)
    isempty(kw_dict) || @warn "Keyword Arguments are ignored with SpecApi Blocks. Skipped: $(keys(kw_dict))."

    init_layout!(block)

    # To keep things simple we wrap a BlockSpec in a GridLayoutSpec and handle
    # both the same
    spec_obs = map(block.spec) do spec
        return spec isa GridLayoutSpec ? spec : GridLayoutSpec(spec)
    end

    add_layout_updater!(block.blockscene, block.layout, spec_obs)

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
    return (fieldnames(T)..., :blocks, root_keys(documented_attributes(T))...)
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

Base.firstindex(b::Block, dim) = firstindex(b.layout, dim)
Base.lastindex(b::Block, dim) = lastindex(b.layout, dim)

function Base.getindex(
        b::Block,
        i::Union{Integer, Colon, AbstractRange},
        j::Union{Integer, Colon, AbstractRange},
        side = GridLayoutBase.Inner()
    )
    isdefined(b, :layout) || init_layout!(b)
    return b.layout[i, j, side]
end

function Base.getindex(b::T, idx::Integer) where {T <: Block}
    names = argument_names(T)
    argname = isempty(names) ? :spec : names[idx]
    return b.attributes[argname]
end

function Base.setindex!(b::Block, val, idx::Integer)
    argname = Symbol(:arg, idx)
    return update!(b.attributes, argname => val)
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
                getfield(x, key)[] = value
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
        print(io, " containing ")
        show(io, MIME"text/plain"(), b.layout)
    end
    return
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
    return default_delete_block!(block)
end

function default_delete_block!(block::Block)
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

function Base.show(io::IO, example::Example)
    if !isnothing(example.caption) && !isempty(example.caption)
        println(io, "**$(ex.caption)**\n")
    end
    println(io, "```julia")
    println(io, example.code)
    println(io, "```")
    return nothing
end

# Fallback for Block types (not yet moved to markdown)
function attribute_examples(::Type{BT}) where {BT <: Block}
    return Dict{Symbol, Vector{Example}}()
end

attribute_examples(::Type{T}, attr::Symbol) where {T <: Union{Block, Plot}} = get(attribute_examples(T), attr, Example[])

# collect() doesn't seem to be necessary but the propertynames docstring says
# "tuple or vector" so lets not return a KeySet
Base.propertynames(::Type{T}) where {T <: Block} = collect(root_keys(documented_attributes(T)))

function ComputePipeline.register_computation!(f, b::Block, inputs::Vector, outputs::Vector{Symbol})
    return register_computation!(f, b.attributes, inputs, outputs)
end

function Base.map!(f, b::Block, inputs::Union{Vector, ComputePipeline.InputNodeTypes}, outputs::Union{Vector, ComputePipeline.OutputNodeTypes})
    return map!(f, b.attributes, inputs, outputs)
end

function ComputePipeline.add_input!(f, b::Block, args...; kwargs...)
    return add_input!(f, b.attributes, args...; kwargs...)
end

function ComputePipeline.add_input!(b::Block, args...; kwargs...)
    return add_input!(b.attributes, args...; kwargs...)
end

function ComputePipeline.update!(b::Block, args...; kwargs...)
    return ComputePipeline.update!(b.attributes, args...; kwargs...)
end

function Base.map!(f, b::Block, inputs::Union{Vector{Symbol}, Vector{Computed}, Symbol, Computed}, outputs::Union{Vector{Symbol}, Symbol})
    return map!(f, b.attributes, inputs, outputs)
end
