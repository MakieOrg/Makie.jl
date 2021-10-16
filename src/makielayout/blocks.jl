abstract type Block end

macro Block(name::Symbol, body::Expr = Expr(:block))

    if !(body.head == :block)
        error("A Block needs to be defined within a `begin end` block")
    end

    structdef = quote
        mutable struct $name <: Block
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::LayoutObservables
            blockscene::Scene
        end
    end

    fields_vector = structdef.args[2].args[3].args
    basefields = filter(x -> !(x isa LineNumberNode), fields_vector)

    attrs = extract_attributes!(body)
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

        function is_attribute(::Type{$(name)}, sym::Symbol)
            sym in ($((attrs !== nothing ? [QuoteNode(a.symbol) for a in attrs] : [])...),)
        end

        function default_attribute_values(::Type{$(name)}, scene::Union{Scene, Nothing})
            sceneattrs = scene === nothing ? Attributes() : scene.attributes

            $(make_attr_dict_expr(attrs, :sceneattrs))
        end

        function _attribute_docs(::Type{$(name)})
            Dict(
                $(
                    (attrs !== nothing ?
                        [Expr(:call, :(=>), QuoteNode(a.symbol), a.docs) for a in attrs] :
                        [])...
                )
            )
        end
    end

    esc(q)
end

function make_attr_dict_expr(::Nothing, sceneattrsym)
    :(Dict())
end

function make_attr_dict_expr(attrs, sceneattrsym)

    pairs = map(attrs) do a

        d = a.default
        if d isa Expr && d.head == :macrocall && d.args[1] == Symbol("@inherit")
            if length(d.args) != 4
                error("@inherit works with exactly 2 arguments, expression was $d")
            end
            if !(d.args[3] isa QuoteNode)
                error("Argument 1 of @inherit must be a :symbol, got $(d.args[3])")
            end
            d = :(get($sceneattrsym, $(d.args[3]), $(d.args[4])))
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

    args = filter(x -> !(x isa LineNumberNode), attrs_block.args)
    attrs = map(args) do arg
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
end

# intercept all block constructors and divert to _block(T, ...)
function (::Type{T})(args...; kwargs...) where {T<:Block}
    _block(T, args...; kwargs...)
end

can_be_current_axis(x) = false

get_top_parent(gp::GridPosition) = GridLayoutBase.top_parent(gp.layout)
get_top_parent(gp::GridSubposition) = GridLayoutBase.top_parent(gp.parent)

function _block(T::Type{<:Block},
        gp::Union{GridPosition, GridSubposition}, args...; kwargs...)

    top_parent = get_top_parent(gp)
    if top_parent === nothing
        error("Found nothing as the top parent of this GridPosition. A GridPosition or GridSubposition needs to be connected to the top layout of a Figure, Scene or comparable object, either directly or through nested GridLayouts in order to plot into it.")
    end
    b = gp[] = _block(T, top_parent, args...; kwargs...)
    b
end

function _block(T::Type{<:Block}, args...; bbox = BBox(100, 400, 100, 400), kwargs...)
    blockscene = Scene(camera = campixel!, show_axis = false, raw = true)

    # create basic layout observables
    lobservables = LayoutObservables{T}(
        Observable{Any}(nothing),
        Observable{Any}(nothing),
        Observable(true),
        Observable(true),
        Observable(:center),
        Observable(:center),
        Observable(Inside());
        suggestedbbox = bbox
    )

    # create base block with otherwise undefined fields
    b = T(nothing, lobservables, blockscene)

    non_attribute_kwargs = Dict(kwargs)
    attribute_kwargs = typeof(non_attribute_kwargs)()
    for (key, value) in non_attribute_kwargs
        if hasfield(T, key) && fieldtype(T, key) <: Observable
            attribute_kwargs[key] = pop!(non_attribute_kwargs, key)
        end
    end

    initialize_attributes!(b; attribute_kwargs...)
    initialize_block!(b, args...)
    all_kwargs = Dict(kwargs)
    for (key, val) in non_attribute_kwargs
        apply_meta_kwarg!(b, Val(key), val, all_kwargs)
    end

    b
end

function _block(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene},
        args...; bbox = nothing, kwargs...)

    # create basic layout observables
    lobservables = LayoutObservables{T}(
        Observable{Any}(nothing),
        Observable{Any}(nothing),
        Observable(true),
        Observable(true),
        Observable(:center),
        Observable(:center),
        Observable(Inside());
        suggestedbbox = bbox
    )

    topscene = get_topscene(fig_or_scene)
    blockscene = Scene(topscene, lift(identity, topscene.px_area), camera = campixel!, show_axis = false, raw = true)

    # create base block with otherwise undefined fields
    b = T(fig_or_scene, lobservables, blockscene)

    non_attribute_kwargs = Dict(kwargs)
    attribute_kwargs = typeof(non_attribute_kwargs)()
    for (key, value) in non_attribute_kwargs
        if hasfield(T, key) && fieldtype(T, key) <: Observable
            attribute_kwargs[key] = pop!(non_attribute_kwargs, key)
        end
    end

    initialize_attributes!(b; attribute_kwargs...)
    initialize_block!(b, args...)
    all_kwargs = Dict(kwargs)
    for (key, val) in non_attribute_kwargs
        apply_meta_kwarg!(b, Val(key), val, all_kwargs)
    end

    if fig_or_scene isa Figure
        register_in_figure!(fig_or_scene, b)
        if can_be_current_axis(b)
            Makie.current_axis!(fig_or_scene, b)
        end
    end
    b
end

function apply_meta_kwarg!(@nospecialize(x), key::Val{S}, @nospecialize(val), all_kwargs) where S
    error("Keyword :$S not implemented for $(typeof(x))")
end


"""
Get the scene which blocks need from their parent to plot stuff into
"""
get_topscene(f::Figure) = f.scene
function get_topscene(s::Scene)
    if !(s.camera_controls[] isa Makie.PixelCamera)
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


# almost like in Makie
# make fields type inferrable
# just access attributes directly instead of via indexing detour

# @generated Base.hasfield(x::T, ::Val{key}) where {T<:Block, key} = :($(key in fieldnames(T)))

# @inline function Base.getproperty(x::T, key::Symbol) where T <: Block
#     if hasfield(x, Val(key))
#         getfield(x, key)
#     else
#         x.attributes[key]
#     end
# end

@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Block
    if hasfield(T, key)
        if fieldtype(T, key) <: Observable
            if value isa Observable
                error("It is disallowed to set an Observable field of a $T struct to an Observable, because this would replace the existing Observable. If you really want to do this, use `setfield!` instead.")
            end
            obs = getfield(x, key)
            obs[] = convert_for_attribute(observable_type(obs), value)
        else
            setfield!(x, key, value)
        end
    else
        # this will throw correctly
        getfield(x, key)
    end
end

# propertynames should list fields and attributes
# function Base.propertynames(block::T) where T <: Block
#     [fieldnames(T)..., keys(block.attributes)...]
# end

# treat all blocks as scalars when broadcasting
Base.Broadcast.broadcastable(l::Block) = Ref(l)


function Base.show(io::IO, ::T) where T <: Block
    print(io, "$T()")
end



function Base.delete!(block::Block)
    for (key, d) in block.elements
        try
            remove_element(d)
        catch e
            @info "Failed to remove element $key of $(typeof(block))."
            rethrow(e)
        end
    end

    if hasfield(typeof(block), :scene)
        delete_scene!(block.scene)
    end

    GridLayoutBase.remove_from_gridlayout!(GridLayoutBase.gridcontent(block))

    on_delete(block)
    delete_from_parent!(block.parent, block)
    block.parent = nothing

    nothing
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



function initialize_attributes!(@nospecialize x; kwargs...)
    T = typeof(x)

    topscene = get_topscene(x.parent)
    default_attrs = default_attribute_values(T, topscene)

    typekey_attrs = get(Makie.current_default_theme(), nameof(T), Attributes())

    for (key, val) in default_attrs

        # give kwargs priority
        if haskey(kwargs, key)
            val = kwargs[key]
        # otherwise global theme
        elseif haskey(typekey_attrs, key)
            val = typekey_attrs[key]
        end

        OT = fieldtype(T, key)
        if !hasfield(T, key)
            error("Type $T doesn't have field $key but it exists in its default attributes.")
        else
            # TODO: shouldn't an observable get connected here?
            if val isa Observable
                init_observable!(x, key, OT, val[])
            elseif val isa Attributes
                setfield!(x, key, val)
            else
                init_observable!(x, key, OT, val)
            end
        end
    end
    return x
end

function init_observable!(@nospecialize(x), key, @nospecialize(OT), @nospecialize(value))
    o = convert_for_attribute(observable_type(OT), value)
    setfield!(x, key, OT(o))
    return x
end

observable_type(x::Type{Observable{T}}) where T = T
observable_type(x::Observable{T}) where T = T

convert_for_attribute(t::Type{T}, value::T) where T = value
convert_for_attribute(t::Type{Float64}, x) = convert(Float64, x)
convert_for_attribute(t::Type{RGBAf}, x) = to_color(x)::RGBAf
convert_for_attribute(t::Type{RGBAf}, x::RGBAf) = x
convert_for_attribute(t::Any, x) = x
convert_for_attribute(t::Type{Makie.FreeTypeAbstraction.FTFont}, x) = to_font(x)
