abstract type Block end

macro Block(name::Symbol, fields::Expr = Expr(:block))

    if !(fields.head == :block)
        error("Fields need to be within a begin end block")
    end

    structdef = quote
        mutable struct $name <: Block
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::LayoutObservables
            layerscene::Scene
        end
    end


    # append user defined fields to struct definition
    # linenumbernode block, struct block, fields block

    allfields = structdef.args[2].args[3].args
    basefields = filter(x -> !(x isa LineNumberNode), allfields)
    append!(allfields, fields.args)

    fieldnames = map(filter(x -> !(x isa LineNumberNode), allfields)) do field
        if field isa Symbol
            return field
        end
        if field isa Expr && field.head == Symbol("::")
            return field.args[1]
        end
        error("Unexpected field format. Neither Symbol nor x::T")
    end

    constructor = quote
        # """
        #     $name(basefields...)

        # Creates $name with all fields but the base fields uninitialized.
        # """
        function $name($(basefields...))
            new($(basefields...))
        end
    end

    push!(allfields, constructor)

    structdef
end

# intercept all block constructors and divert to _layoutable(T, ...)
function (::Type{T})(args...; kwargs...) where {T<:Block}
    _layoutable(T, args...; kwargs...)
end

can_be_current_axis(x) = false

get_top_parent(gp::GridPosition) = GridLayoutBase.top_parent(gp.layout)
get_top_parent(gp::GridSubposition) = GridLayoutBase.top_parent(gp.parent)

function _layoutable(T::Type{<:Block},
        gp::Union{GridPosition, GridSubposition}, args...; kwargs...)

    top_parent = get_top_parent(gp)
    if top_parent === nothing
        error("Found nothing as the top parent of this GridPosition. A GridPosition or GridSubposition needs to be connected to the top layout of a Figure, Scene or comparable object, either directly or through nested GridLayouts in order to plot into it.")
    end
    l = gp[] = _layoutable(T, top_parent, args...; kwargs...)
    l
end

function _layoutable(T::Type{<:Block}, fig_or_scene::Union{Figure, Scene},
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
    layerscene = Scene(topscene, lift(identity, topscene.px_area), camera = campixel!, show_axis = false, raw = true)

    # create base block with otherwise undefined fields
    l = T(fig_or_scene, lobservables, layerscene)

    non_attribute_kwargs = Dict(kwargs)
    attribute_kwargs = typeof(non_attribute_kwargs)()
    for (key, value) in non_attribute_kwargs
        if hasfield(T, key) && fieldtype(T, key) <: Observable
            attribute_kwargs[key] = pop!(non_attribute_kwargs, key)
        end
    end

    initialize_attributes!(l; attribute_kwargs...)
    initialize_layoutable!(l, args...)
    all_kwargs = Dict(kwargs)
    for (key, val) in non_attribute_kwargs
        apply_meta_kwarg!(l, Val(key), val, all_kwargs)
    end

    if fig_or_scene isa Figure
        register_in_figure!(fig_or_scene, l)
        if can_be_current_axis(l)
            Makie.current_axis!(fig_or_scene, l)
        end
    end
    l
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
    default_attrs = default_attributes(T, topscene).attributes

    for (key, val) in default_attrs

        # give kwargs priority
        if haskey(kwargs, key)
            val = kwargs[key]
        end

        OT = fieldtype(T, key)
        if !hasfield(T, key)
            @warn "Target doesn't have field $key"
        else
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
