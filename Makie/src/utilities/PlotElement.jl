abstract type AbstractElementAccessor end

abstract type PlotElement{PlotType} end

PlotElement(@nospecialize(::Any), ::Nothing) = nothing

function dimensional_element_getindex(x, element::PlotElement, dim::Integer)
    return dimensional_element_getindex(x, accessor(element), dim)
end
element_getindex(x, element::PlotElement) = element_getindex(x, accessor(element))

# TODO: Should this be called child() instead? Or something else? Because its
# not the PlotElement containing the parent plot...
get_plot(element::PlotElement) = first(element.plot_stack)
get_plot(plot::Plot) = plot
accessor(element::PlotElement) = element.index

function Base.getproperty(element::T, name::Symbol) where {T <: PlotElement}
    if hasfield(T, name)
        return getfield(element, name)
    else
        plot = get_plot(element)
        if haskey(plot.attributes, name)
            return element_getindex(getproperty(plot, name)[], element.index)
        else
            return getproperty(plot, name)
        end
    end
end

function Base.get(element::PlotElement{PT}, name::Symbol, default) where {PT}
    plot = get_plot(element)
    if haskey(plot.attributes, name) || hasfield(PT, name)
        return getproperty(element, name)
    else
        return default
    end
end

sample_color(plotlike::Union{Plot, PlotElement}, color::Colorant) = color

function sample_color(plotlike::Union{Plot, PlotElement}, value::Real)
    plot = get_plot(plotlike)
    color = sample_color(
        plot.alpha_colormap[], value, plot.scaled_colorrange[],
        plot.lowclip_color[], plot.highclip_color[],
        plot.nan_color[]
    )
    return color
end




struct SimplePlotElement{
        PlotType,
        IndexType <: AbstractElementAccessor,
        PlotStack <: Tuple{PlotType, Vararg{Plot}}
    } <: PlotElement{PlotType}

    plot_stack::PlotStack
    index::IndexType
end

PlotElement(plot_stack::Tuple, elem::PlotElement) = SimplePlotElement(plot_stack, elem.index)
PlotElement(plot_stack::Tuple, accessor::AbstractElementAccessor) = SimplePlotElement(plot_stack, accessor)
Base.parent(element::SimplePlotElement) = PlotElement(Base.tail(element.plot_stack), element.index)



struct TrackedPlotElement{
        PlotType,
        IndexType <: AbstractElementAccessor,
        PlotStack <: Tuple{PlotType, Vararg{Plot}}
    } <: PlotElement{PlotType}
    plot_stack::PlotStack
    index::IndexType
    accessed_fields::Vector{Symbol}
end


# Manual
track!(::PlotElement, ::Symbol...) = nothing
track!(e::TrackedPlotElement, names::Symbol...) = push!(e.accessed_fields, names...)

# Automatic
function Base.getproperty(element::TrackedPlotElement, name::Symbol)
    if hasfield(TrackedPlotElement, name)
        return getfield(element, name)
    else
        plot = get_plot(element)
        if haskey(plot.attributes, name)
            track!(element, name)
            return element_getindex(getproperty(plot, name)[], element.index)
        else
            return getproperty(plot, name)
        end
    end
end

# Util
TrackedPlotElement(e::SimplePlotElement) = TrackedPlotElement(e.plot_stack, e.index, Symbol[])
Base.empty!(e::TrackedPlotElement) = empty!(e.accessed_fields)
get_accessed_fields(e::TrackedPlotElement) = e.accessed_fields
Base.parent(e::TrackedPlotElement) = TrackedPlotElement(Base.tail(e.plot_stack), e.index, e.accessed_fields)

################################################################################
### Accessors
################################################################################

struct IndexedElement{D} <: AbstractElementAccessor
    index::CartesianIndex{D}
    size::Vec{D, Int64}

    function IndexedElement(idx::CartesianIndex{N}, size::VecTypes{N, <:Integer}) where {N}
        return new{N}(idx, Vec{N, Int64}(size))
    end
end

function IndexedElement(idx::Integer, size::Integer)
    return IndexedElement(CartesianIndex(idx), Vec{1, Int64}(size))
end

function IndexedElement(idx::VecTypes{N, <:Integer}, size::VecTypes{N, <:Integer}) where {N}
    return IndexedElement(CartesianIndex(idx...), Vec{N, Int64}(size))
end

function element_getindex(x, element::IndexedElement)
    return sv_getindex(x, element.index)
end

function dimensional_element_getindex(x, element::IndexedElement{2}, dim::Integer)
    if x isa AbstractArray{T, 2} where T
        return element_getindex(x, element)
    elseif x isa Union{EndPoints, EndPointsLike}
        x0, x1 = x
        r = range(x0, x1, 2 * element.size[dim] + 1) # N+1 edges and N centers
        return r[2 * element.index[dim]] # indexing centers
    elseif is_array_attribute(x) # or vector, we already filtered 2d arrays
        if length(x) == element.size[dim] # center based
            return sv_getindex(x, element.index[dim])
        elseif length(x) == element.size[dim] + 1 # edge based
            low = sv_getindex(x, element.index[dim])
            high = sv_getindex(x, element.index[dim]+1)
            return 0.5 * (low + high)
        else
            error("Got unexpected length $(length(x)).")
        end
    else
        return x
    end
end


struct InterpolatedElement{D} <: AbstractElementAccessor
    index0::CartesianIndex{D}
    index1::CartesianIndex{D}
    interpolation::Vec{D, Float32}
    size::Vec{D, Int64}
    edge_based::Bool
end

function InterpolatedElement(
        i0::Integer, i1::Integer, interpolation::AbstractFloat, size::Integer, edge_based = false
    )
    return InterpolatedElement(
        CartesianIndex(i0), CartesianIndex(i1), Vec{1, Float32}(interpolation),
        Vec{1, Int64}(size), edge_based
    )
end

function InterpolatedElement(
        i0::VecTypes{D, <:Integer}, i1::VecTypes{D, <:Integer},
        interpolation::VecTypes{D, <:AbstractFloat}, size::VecTypes{D, <:Integer},
        edge_based = false
    ) where {D}

    return InterpolatedElement(
        CartesianIndex(i0...), CartesianIndex(i1...), Vec{D, Float32}(interpolation),
        Vec{D, Int64}(size), edge_based
    )
end

# TODO: can we extend is_vector_attribute() to consider Matrices vectors?
is_array_attribute(x::AbstractArray) = true
is_array_attribute(x::Base.Generator) = is_array_attribute(x.iter)
is_array_attribute(x::NativeFont) = false
is_array_attribute(x::Quaternion) = false
is_array_attribute(x::VecTypes) = false
is_array_attribute(x::ScalarOrVector) = x.sv isa Vector
is_array_attribute(x) = false

function element_getindex(x, element::InterpolatedElement{1})
    if is_array_attribute(x)
        low = sv_getindex(x, element.index0)
        high = sv_getindex(x, element.index1)
        return lerp(low, high, element.interpolation[1])
    else
        return x
    end
end

function element_getindex(x, element::InterpolatedElement{2})
    if is_array_attribute(x)
        i0, j0 = Tuple(element.index0)
        i1, j1 = Tuple(element.index1)
        fi, fj = element.interpolation

        # Heatmap uses edge based indices that sometimes need to be converted to
        # cell based indices
        if element.edge_based
            if size(x, 1) == element.size[1] # center based
                i0, i1, fi = interpolated_edge_to_cell_index(i0 + fi, element.size[1], true)
            end
            if size(x, 2) == element.size[2] # center based
                j0, j1, fj = interpolated_edge_to_cell_index(j0 + fj, element.size[2], true)
            end
        end

        x00 = sv_getindex(x, CartesianIndex(i0, j0))
        x10 = sv_getindex(x, CartesianIndex(i1, j0))
        x01 = sv_getindex(x, CartesianIndex(i0, j1))
        x11 = sv_getindex(x, CartesianIndex(i1, j1))

        x_0 = lerp(x00, x10, fi)
        x_1 = lerp(x01, x11, fi)

        return lerp(x_0, x_1, fj)
    else
        return x
    end
end

function dimensional_element_getindex(x, element::InterpolatedElement{2}, dim::Integer)
    if x isa AbstractArray{T, 2} where T
        return element_getindex(x, element)

    elseif x isa Union{EndPoints, EndPointsLike}

        x0, x1 = x
        if element.edge_based
            f = (element.index0[dim] + element.interpolation[dim] - 1.0) / element.size[dim]
        else
            f = (element.index0[dim] + element.interpolation[dim] - 0.5) / element.size[dim]
        end
        return lerp(x0, x1, f)

    elseif is_array_attribute(x)

        i0 = element.index0[dim]
        i1 = element.index1[dim]
        interp = element.interpolation[dim]

        if element.edge_based && length(x) == element.size[dim] # center based values
            i0, i1, interp = interpolated_edge_to_cell_index(i0 + interp, element.size[dim], true)
        end

        return lerp(x[i0], x[i1], interp)
    else
        return x
    end
end



struct InterpolatedMeshElement <: AbstractElementAccessor
    N_vertices::Int64
    N_submeshes::Int64

    submesh_index::Int64
    face::GLTriangleFace
    uv::Vec2f

    function InterpolatedMeshElement(
            N_vertices::Integer, N_submeshes::Integer,
            submesh_index::Integer, face::TriangleFace, uv::VecTypes{2}
        )
        return new(N_vertices, N_submeshes, submesh_index, GLTriangleFace(face), Vec2f(uv))
    end
end

function element_getindex(x, element::InterpolatedMeshElement)
    if is_array_attribute(x)
        if length(x) == element.N_vertices
            i, j, k = element.face
            a = sv_getindex(x, i)
            b = sv_getindex(x, j)
            c = sv_getindex(x, k)
            u, v = element.uv
            return a + u * (b-a) + v * (c-a)
        elseif length(x) == element.N_submeshes
            return x[element.submesh_index]
        else
            return x
        end
    else
        return x
    end
end
