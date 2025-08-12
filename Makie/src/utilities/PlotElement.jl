abstract type PlotElement{PlotType} end

Base.parent(element::PlotElement) = element.parent

function Base.getproperty(element::T, name::Symbol) where {T <: PlotElement}
    if hasfield(T, name)
        return getfield(element, name)
    else
        plot = parent(element)
        if haskey(plot.attributes, name)
            return element_getindex(getproperty(plot, name)[], element)
        else
            return getproperty(plot, name)
        end
    end
end

function Base.get(element::PlotElement{PT}, name::Symbol, default) where {PT}
    plot = parent(element)
    if haskey(plot.attributes, name) || hasfield(PT, name)
        getproperty(element, name)
    else
        return default
    end
end

function PlotElement(plot::Plot, elem::T) where {T <: PlotElement}
    base_type = getfield(Makie, nameof(T))
    names = filter(name -> name !== :parent, fieldnames(T))
    fields = getfield.(Ref(elem), names)
    return base_type(plot, fields...)
end

PlotElement(@nospecialize(::Plot), ::Nothing) = nothing

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
    size::Vec{D, Int64}

    function IndexedPlotElement(plot::PT, idx::CartesianIndex{N}, size::VecTypes{N, <:Integer}) where {PT <: Plot, N}
        return new{PT, N}(plot, idx, Vec{N, Int64}(size))
    end
end

function IndexedPlotElement(plot::Plot, idx::Integer, size::Integer)
    return IndexedPlotElement(plot, CartesianIndex(idx), Vec{1, Int64}(size))
end

function IndexedPlotElement(plot::Plot, idx::VecTypes{N, <:Integer}, size::VecTypes{N, <:Integer}) where {N}
    return IndexedPlotElement(plot, CartesianIndex(idx...), Vec{N, Int64}(size))
end


struct InterpolatedPlotElement{PlotType, D} <: PlotElement{PlotType}
    parent::PlotType
    index0::CartesianIndex{D}
    index1::CartesianIndex{D}
    interpolation::Vec{D, Float32}
    size::Vec{D, Int64}
end

function InterpolatedPlotElement(plot::Plot, i0::Integer, i1::Integer, interpolation::AbstractFloat, size::Integer)
    return InterpolatedPlotElement(plot, CartesianIndex(i0), CartesianIndex(i1), Vec{1, Float32}(interpolation), Vec{1, Int64}(size))
end

function InterpolatedPlotElement(
        plot::Plot, i0::VecTypes{D, <:Integer}, i1::VecTypes{D, <:Integer},
        interpolation::VecTypes{D, <:AbstractFloat}, size::VecTypes{D, <:Integer}
    ) where {D}

    return InterpolatedPlotElement(plot, CartesianIndex(i0...), CartesianIndex(i1...), Vec{D, Float32}(interpolation), Vec{D, Int64}(size))
end

struct MeshPlotElement{PlotType} <: PlotElement{PlotType}
    parent::PlotType
    submesh_index::Int64
    face::GLTriangleFace
    uv::Vec2f

    function MeshPlotElement(plot::PlotType, submesh_index::Integer, face::TriangleFace, uv::VecTypes{2}) where {PlotType}
        return new{PlotType}(plot, submesh_index, GLTriangleFace(face), Vec2f(uv))
    end
end

function element_getindex(x, element::IndexedPlotElement)
    return sv_getindex(x, element.index)
end

function dimensional_element_getindex(x, element::IndexedPlotElement{PlotType, 2}, dim::Integer) where {PlotType}
    if x isa AbstractArray{T, 2} where T
        return element_getindex(x, element)
    elseif x isa Union{EndPoints, EndPointsLike}
        x0, x1 = x
        r = range(x0, x1, element.size[dim])
        return r[element.index[dim]]
    elseif is_array_attribute(x) # or vector, we already filtered 2d arrays
        return sv_getindex(x, element.index[dim])
    else
        return x
    end
end

# TODO: can we extend is_vector_attribute() to consider Matrices vectors?
is_array_attribute(x::AbstractArray) = true
is_array_attribute(x::Base.Generator) = is_array_attribute(x.iter)
is_array_attribute(x::NativeFont) = false
is_array_attribute(x::Quaternion) = false
is_array_attribute(x::VecTypes) = false
is_array_attribute(x::ScalarOrVector) = x.sv isa Vector
is_array_attribute(x) = false

function element_getindex(x, element::InterpolatedPlotElement{PlotType, 1}) where {PlotType}
    if is_array_attribute(x)
        low = sv_getindex(x, element.index0)
        high = sv_getindex(x, element.index1)
        return lerp(low, high, element.interpolation[1])
    else
        return x
    end
end

function element_getindex(x, element::InterpolatedPlotElement{PlotType, 2}) where {PlotType}
    if is_array_attribute(x)
        i0, j0 = Tuple(element.index0)
        i1, j1 = Tuple(element.index1)

        x00 = sv_getindex(x, CartesianIndex(i0, j0))
        x10 = sv_getindex(x, CartesianIndex(i1, j0))
        x01 = sv_getindex(x, CartesianIndex(i0, j1))
        x11 = sv_getindex(x, CartesianIndex(i1, j1))

        x_0 = lerp(x00, x10, element.interpolation[1])
        x_1 = lerp(x01, x11, element.interpolation[1])

        return lerp(x_0, x_1, element.interpolation[2])
    else
        return x
    end
end

function dimensional_element_getindex(x, element::InterpolatedPlotElement{PlotType, 2}, dim::Integer) where {PlotType}
    if x isa AbstractArray{T, 2} where T
        return element_getindex(x, element)
    elseif x isa Union{EndPoints, EndPointsLike}
        x0, x1 = x
        f = (element.index0[dim] + element.interpolation[dim] - 0.5) / element.size[dim]
        return lerp(x0, x1, f)
    elseif is_array_attribute(x)
        x0 = sv_getindex(x, element.index0[dim])
        x1 = sv_getindex(x, element.index1[dim])
        return lerp(x0, x1, element.interpolation[dim])
    else
        return x
    end
end

function element_getindex(x, element::MeshPlotElement)
    if is_array_attribute(x)
        i, j, k = element.face
        a = sv_getindex(x, i)
        b = sv_getindex(x, j)
        c = sv_getindex(x, k)
        u, v = element.uv
        return a + u * (b-a) + v * (c-a)
    else
        return x
    end
end
