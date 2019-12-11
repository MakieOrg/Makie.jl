const Layoutable = Union{LAxis, LObject}

defaultlayout(layoutable::Layoutable) = ProtrusionLayout(layoutable)

function align_to_bbox!(layoutable::Layoutable, bbox)
    layoutable.layoutnodes.suggestedbbox[] = bbox
end

computedsizenode(layoutable::Layoutable) = layoutable.layoutnodes.computedsize
protrusionnode(layoutable::Layoutable) = layoutable.layoutnodes.protrusions


function Base.getproperty(layoutable::T, s::Symbol) where T <: Layoutable
    if s in fieldnames(T)
        getfield(layoutable, s)
    else
        layoutable.attributes[s]
    end
end

function Base.setproperty!(layoutable::T, s::Symbol, value) where T <: Layoutable
    if s in fieldnames(T)
        setfield!(layoutable, s, value)
    else
        layoutable.attributes[s][] = value
    end
end

function Base.propertynames(layoutable::T) where T <: Layoutable
    [fieldnames(T)..., keys(layoutable.attributes)...]
end
