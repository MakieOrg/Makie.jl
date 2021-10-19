abstract type Layoutable end

macro Layoutable(name::Symbol, fields::Expr = Expr(:block))

    if !(fields.head == :block)
        error("Fields need to be within a begin end block")
    end

    structdef = quote
        mutable struct $name <: Layoutable
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::LayoutObservables
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

# intercept all layoutable constructors and divert to _layoutable(T, ...)
function (::Type{T})(args...; kwargs...) where {T<:Layoutable}
    _layoutable(T, args...; kwargs...)
end

can_be_current_axis(x) = false

get_top_parent(gp::GridPosition) = GridLayoutBase.top_parent(gp.layout)
get_top_parent(gp::GridSubposition) = GridLayoutBase.top_parent(gp.parent)

function _layoutable(T::Type{<:Layoutable},
        gp::Union{GridPosition, GridSubposition}, args...; kwargs...)

    top_parent = get_top_parent(gp)
    if top_parent === nothing
        error("Found nothing as the top parent of this GridPosition. A GridPosition or GridSubposition needs to be connected to the top layout of a Figure, Scene or comparable object, either directly or through nested GridLayouts in order to plot into it.")
    end
    l = gp[] = _layoutable(T, top_parent, args...; kwargs...)
    l
end

function _layoutable(T::Type{<:Layoutable}, fig::Figure, args...; kwargs...)
    l = layoutable(T, fig, args...; kwargs...)
    register_in_figure!(fig, l)
    if can_be_current_axis(l)
        Makie.current_axis!(fig, l)
    end
    l
end

function _layoutable(T::Type{<:Layoutable}, scene::Scene, args...; kwargs...)
    layoutable(T, scene, args...; kwargs...)
end


"""
Get the scene which layoutables need from their parent to plot stuff into
"""
get_topscene(f::Figure) = f.scene
function get_topscene(s::Scene)
    if !(Makie.cameracontrols(s) isa Makie.PixelCamera)
        error("Can only use scenes with PixelCamera as topscene")
    end
    s
end

function register_in_figure!(fig::Figure, @nospecialize layoutable::Layoutable)
    if layoutable.parent !== fig
        error("Can't register a layoutable with a different parent in a figure.")
    end
    if !(layoutable in fig.content)
        push!(fig.content, layoutable)
    end
    nothing
end


# almost like in Makie
# make fields type inferrable
# just access attributes directly instead of via indexing detour

@generated Base.hasfield(x::T, ::Val{key}) where {T<:Layoutable, key} = :($(key in fieldnames(T)))

@inline function Base.getproperty(x::T, key::Symbol) where T <: Layoutable
    if hasfield(x, Val(key))
        getfield(x, key)
    else
        x.attributes[key]
    end
end

@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Layoutable
    if hasfield(x, Val(key))
        setfield!(x, key, value)
    else
        x.attributes[key][] = value
    end
end

# propertynames should list fields and attributes
function Base.propertynames(layoutable::T) where T <: Layoutable
    [fieldnames(T)..., keys(layoutable.attributes)...]
end

# treat all layoutables as scalars when broadcasting
Base.Broadcast.broadcastable(l::Layoutable) = Ref(l)


function Base.show(io::IO, ::T) where T <: Layoutable
    print(io, "$T()")
end



function Base.delete!(layoutable::Layoutable)
    for (key, d) in layoutable.elements
        try
            remove_element(d)
        catch e
            @info "Failed to remove element $key of $(typeof(layoutable))."
            rethrow(e)
        end
    end

    if hasfield(typeof(layoutable), :scene)
        delete_scene!(layoutable.scene)
    end

    GridLayoutBase.remove_from_gridlayout!(GridLayoutBase.gridcontent(layoutable))

    on_delete(layoutable)
    delete_from_parent!(layoutable.parent, layoutable)
    layoutable.parent = nothing

    nothing
end

# do nothing for scene and nothing
function delete_from_parent!(parent, layoutable::Layoutable)
end

function delete_from_parent!(figure::Figure, layoutable::Layoutable)
    filter!(x -> x !== layoutable, figure.content)
    if current_axis(figure) === layoutable
        current_axis!(figure, nothing)
    end
    nothing
end

"""
Overload to execute cleanup actions for specific layoutables that go beyond
deleting elements and removing from gridlayout
"""
function on_delete(layoutable)
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
