# LAxis and LScene currently have to be AbstractScenes because they need to work with
# the plotting pipeline, so they are not LObjects and manually get added here
const Layoutable = Union{LAxis, LScene, LObject}

# almost like in AbstractPlotting
# make fields type inferrable
# just access attributes directly instead of via indexing detour

@generated hasfield(x::T, ::Val{key}) where {T<:Layoutable, key} = :($(key in fieldnames(T)))

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
