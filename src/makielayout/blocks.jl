abstract type Block end

macro Block(name::Symbol, fields::Expr = Expr(:block))

    if !(fields.head == :block)
        error("Fields need to be within a begin end block")
    end

    structdef = quote
        mutable struct $name <: Block
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::LayoutObservables{GridLayout}
            attributes::Attributes
            elements::Dict{Symbol, Any}
        end
    end


    # append user defined fields to struct definition
    # linenumbernode block, struct block, fields block

    allfields = structdef.args[2].args[3].args

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
        function $name($(fieldnames...))
            new($(fieldnames...))
        end
    end

    push!(allfields, constructor)

    structdef
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
    l = gp[] = _block(T, top_parent, args...; kwargs...)
    l
end

function _block(T::Type{<:Block}, fig::Figure, args...; kwargs...)
    l = block(T, fig, args...; kwargs...)
    register_in_figure!(fig, l)
    if can_be_current_axis(l)
        Makie.current_axis!(fig, l)
    end
    l
end

function _block(T::Type{<:Block}, scene::Scene, args...; kwargs...)
    block(T, scene, args...; kwargs...)
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


# almost like in Makie
# make fields type inferrable
# just access attributes directly instead of via indexing detour

@generated Base.hasfield(x::T, ::Val{key}) where {T<:Block, key} = :($(key in fieldnames(T)))

@inline function Base.getproperty(x::T, key::Symbol) where T <: Block
    if hasfield(x, Val(key))
        getfield(x, key)
    else
        x.attributes[key]
    end
end

@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Block
    if hasfield(x, Val(key))
        setfield!(x, key, value)
    else
        x.attributes[key][] = value
    end
end

# propertynames should list fields and attributes
function Base.propertynames(block::T) where T <: Block
    [fieldnames(T)..., keys(block.attributes)...]
end

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
