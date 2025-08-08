abstract type PlotElement{PlotType} end

Base.parent(element::PlotElement) = element.parent

function Base.getproperty(element::T, name::Symbol) where {T <: PlotElement}
    if hasfield(T, name)
        return getfield(element, name)
    else
        plot = getfield(element, :parent)
        if haskey(plot.attributes, name)
            return element_getindex(getproperty(plot, name)[], element)
        else
            return getproperty(plot, name)
        end
    end
end

function PlotElement(plot::Plot, elem::T) where {T <: PlotElement}
    names = filter(name -> name !== :parent, fieldnames(T))
    fields = getfield.(Ref(elem), names)
    return T(plot, fields...)
end

struct TrackedPlotElement{PlotType, ElementType <: PlotElement{PlotType}} <: PlotElement{PlotType}
    element::ElementType
    accessed_fields::Vector{Symbol}
end

# Manual
track!(::PlotElement, ::Symbol...) = nothing
track!(e::TrackedPlotElement, names::Symbol...) = push!(e.accessed_fields, names...)

# Automatic
function Base.getproperty(element::T, name::Symbol) where {PT, ET, T <: TrackedPlotElement{PT, ET}}
    if hasfield(T, name)
        return getfield(element, name)
    else
        hasfield(ET, name) && track!(element, name)
        return getproperty(element.element, name)
    end
end

# Util
TrackedPlotElement(e::PlotElement) = TrackedPlotElement(e, Symbol[])
Base.empty!(e::TrackedPlotElement) = empty!(e.accessed_fields)
get_accessed_fields(e::TrackedPlotElement) = e.accessed_fields
Base.parent(e::TrackedPlotElement) = parent(e.element)

struct IndexedPlotElement{PlotType, D} <: PlotElement{PlotType}
    parent::PlotType
    index::CartesianIndex{D}
end

IndexedPlotElement(plot::Plot, idx::Integer) = IndexedPlotElement(plot, CartesianIndex(idx))
function IndexedPlotElement(plot::Plot, idx::VecTypes{N, <:Integer}) where {N}
    return IndexedPlotElement(plot, CartesianIndex(idx...))
end

struct InterpolatedPlotElement{PlotType, D} <: PlotElement{PlotType}
    parent::PlotType
    index0::CartesianIndex{D}
    index1::CartesianIndex{D}
    interpolation::Vec{D, Float32}
end

function InterpolatedPlotElement(plot::Plot, i0::Integer, i1::Integer, interpolation::AbstractFloat)
    return InterpolatedPlotElement(plot, CartesianIndex(i0), CartesianIndex(i1), Vec{1, Float32}(interpolation))
end
function InterpolatedPlotElement(plot::Plot, i0::VecTypes{D, <:Integer}, i1::VecTypes{D, <:Integer}, interpolation::VecTypes{D, <:AbstractFloat}) where {D}
    return InterpolatedPlotElement(plot, CartesianIndex(i0...), CartesianIndex(i1...), Vec{D, Float32}(interpolation))
end

struct MeshPlotElement{PlotType} <: PlotElement{PlotType}
    parent::PlotType
    face::GLTriangleFace
    uv::Vec2f

    function MeshPlotElement(plot::PlotType, face::TriangleFace, uv::VecTypes{2}) where {PlotType}
        return new{PlotType}(plot, GLTriangleFace(face), Vec2f(uv))
    end
end

function element_getindex(x, element::IndexedPlotElement)
    return sv_getindex(x, element.index)
end

function element_getindex(x, element::InterpolatedPlotElement{PlotType, 1}) where {PlotType}
    low = sv_getindex(x, element.index0)
    high = sv_getindex(x, element.index1)
    return lerp(low, high, element.interpolation[1])
end

function element_getindex(x, element::InterpolatedPlotElement{PlotType, 2}) where {PlotType}
    i0, j0 = Tuple(element.index0)
    i1, j1 = Tuple(element.index1)

    x00 = sv_getindex(x, CartesianIndex(i0, j0))
    x10 = sv_getindex(x, CartesianIndex(i1, j0))
    x01 = sv_getindex(x, CartesianIndex(i0, j1))
    x11 = sv_getindex(x, CartesianIndex(i1, j1))

    x_0 = lerp(x00, x10, element.interpolation[1])
    x_1 = lerp(x01, x11, element.interpolation[1])

    return lerp(x_0, x_1, element.interpolation[2])
end

function element_getindex(x, element::MeshPlotElement)
    i, j, k = element.face
    a = sv_getindex(x, i)
    b = sv_getindex(x, j)
    c = sv_getindex(x, k)
    u, v = element.uv
    return lerp(a, b, u) + lerp(a, c, v)
end
