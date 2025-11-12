################################################################################
### Generic/Abstract
################################################################################

abstract type AbstractElementAccessor end

"""
    abstract type PlotElement{PlotType, AccessorType}

A PlotElement represents an element of a plot selected through picking. Unlike
with `pick()` and related functions, the plot is not restricted to a primitive
plot. Instead it can be any plot.

This object is typically constructed by `pick_element(...)`

## Related functions:
- `getproperty(element, name)` or `element.name` will return an attribute value
of the encapsulated plot relevant to the picked element
- `get_plot(element)` will return the encapsulated plot
- `child(element)` will construct a new `PlotElement` using the child plot from
which the pick originated. Note that the accessor is not recomputed and may not
be compatible with the child plot.
- `accessor(element)` returns the `<:AbstractElementAccessor` of the element,
which represents the indexing or interpolation information necessary to identify
the picked element.
- `element_getindex(data, element)` will apply the accessor to the given
(plot external) data
- `dimensional_element_getindex(data, element, dim)` will apply a specific
dimension of the accessor to the data
"""
abstract type PlotElement{PlotType, AccessorType} end

PlotElement(@nospecialize(::Any), ::Nothing) = nothing

"""
    dimensional_element_getindex(data, element, dim)
    dimensional_element_getindex(data, accessor, dim)

Applies a specific dimension of a multidimensional accessor to the given data.

For example, a 2D `IndexedAccessor{2}` contains a 2D index `(i, j)`. With
`dim = 1`, the first index `i` would be applied to the given `data`. This is
useful, for example, with `heatmap` where the indexing is 2D to match the plots
z/image values but needs to be accessed per dimensional for x and y data.
"""
function dimensional_element_getindex(x, element::PlotElement, dim::Integer)
    return dimensional_element_getindex(x, accessor(element), dim)
end
element_getindex(x, element::PlotElement) = element_getindex(x, accessor(element))

get_plot(element::PlotElement) = first(element.plot_stack)
get_plot(plot::Plot) = plot
accessor(element::PlotElement) = element.accessor

function Base.getproperty(element::T, name::Symbol) where {T <: PlotElement}
    if hasfield(T, name)
        return getfield(element, name)
    else
        plot = get_plot(element)
        if haskey(plot.attributes, name)
            return element_getindex(getproperty(plot, name)[], accessor(element))
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

"""
    sample_color(element, value)

Resolves colormapping for given element at the given color `value`. If the
`value` is a color, it is returned as is.
"""
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

################################################################################
### PlotElement
################################################################################

"""
    SimplePlotElement{PlotType, AccessorType, PlotStackType}

Basic implementation of a `PlotElement` containing just a `plot_stack` and
`accessor`.
"""
struct SimplePlotElement{
        PlotType,
        AccessorType,
        PlotStack <: Tuple{PlotType, Vararg{Plot}},
    } <: PlotElement{PlotType, AccessorType}

    plot_stack::PlotStack
    accessor::AccessorType
end

PlotElement(plot_stack::Tuple, elem::PlotElement) = SimplePlotElement(plot_stack, elem.accessor)
PlotElement(plot_stack::Tuple, accessor::AbstractElementAccessor) = SimplePlotElement(plot_stack, accessor)
child(element::SimplePlotElement) = PlotElement(Base.tail(element.plot_stack), element.accessor)

"""
    TrackedPlotElement{PlotType, AccessorType, PlotStackType}

Implementation of `PlotElement` which adds tracking of the accessed attributes.
This is used internally to figure out which attributes a persistent tooltip
needs to track.

An attribute can be explicitly tracked by `track!(element, names...)`. This is
safe to call from any `PlotElement`.
"""
struct TrackedPlotElement{
        PlotType,
        AccessorType,
        PlotStack <: Tuple{PlotType, Vararg{Plot}},
    } <: PlotElement{PlotType, AccessorType}
    plot_stack::PlotStack
    accessor::AccessorType
    accessed::Vector{Computed}
end


# Manual
track!(::PlotElement, ::Symbol...) = nothing
function track!(e::TrackedPlotElement, names::Symbol...)
    for name in names
        push!(e.accessed, getproperty(get_plot(e), name))
    end
    return
end

# Automatic
function Base.getproperty(element::TrackedPlotElement, name::Symbol)
    if hasfield(TrackedPlotElement, name)
        return getfield(element, name)
    else
        plot = get_plot(element)
        if haskey(plot.attributes, name)
            track!(element, name)
            return element_getindex(getproperty(plot, name)[], element.accessor)
        else
            return getproperty(plot, name)
        end
    end
end

# Util
TrackedPlotElement(e::SimplePlotElement) = TrackedPlotElement(e.plot_stack, e.accessor, Computed[])
Base.empty!(e::TrackedPlotElement) = empty!(e.accessed)
get_accessed_nodes(e::TrackedPlotElement) = e.accessed
child(e::TrackedPlotElement) = TrackedPlotElement(Base.tail(e.plot_stack), e.accessor, e.accessed)

################################################################################
### Accessors
################################################################################

"""
    IndexedAccessor(index, length)
    IndexedAccessor(index, size)

Constructs an accessor representing an index into data of a given size. The
dimensionality of the index must match the dimensionality of the given size.

## Fields
$(TYPEDFIELDS)
"""
struct IndexedAccessor{D} <: AbstractElementAccessor
    "The index to be accessed."
    index::CartesianIndex{D}
    "The size which the index relates to. This is used to avoid indexing data of different sizes."
    size::Vec{D, Int64}

    function IndexedAccessor(idx::CartesianIndex{N}, size::VecTypes{N, <:Integer}) where {N}
        return new{N}(idx, Vec{N, Int64}(size))
    end
end

function IndexedAccessor(idx::Integer, size::Integer)
    return IndexedAccessor(CartesianIndex(idx), Vec{1, Int64}(size))
end

function IndexedAccessor(idx::VecTypes{N, <:Integer}, size::VecTypes{N, <:Integer}) where {N}
    return IndexedAccessor(CartesianIndex(idx...), Vec{N, Int64}(size))
end

function element_getindex(x, element::IndexedAccessor)
    return sv_getindex(x, element.index)
end

function dimensional_element_getindex(x, element::IndexedAccessor{2}, dim::Integer)
    if x isa AbstractArray{T, 2} where {T}
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
            high = sv_getindex(x, element.index[dim] + 1)
            return 0.5 * (low + high)
        else
            error("Got unexpected length $(length(x)).")
        end
    else
        return x
    end
end

"""
    InterpolatedAccessor(index0, index1, interpolation, length[, edge_based = false])
    InterpolatedAccessor(index0, index1, interpolation, size[, edge_based = false])

Constructs an accessor representing (repeated) linear interpolation. For data of
the appropriate size `Makie.lerp(data[index0], data[index1], interpolation)` is
called to get the relevant element. Note that `interpolation` is not clamped
internally. For `InterpolatedAccessor{2}` this expands to bilinear interpolation.

If `edge_based == true`, the given indices and interpolation factor are assumed
to apply to edge based data. The `size` is still assumed to be cell based. If
the accessed data is detected to be edge based (size + 1), the indices and
interpolation are applied as is. If the data is cell based (size) then the
indices and interpolation are resampled by `interpolated_edge_to_cell_index()`.
This only applies to `InterpolatedAccessor{2}`.

## Fields
$(TYPEDFIELDS)
"""
struct InterpolatedAccessor{D} <: AbstractElementAccessor
    "Lower index used to get data for the interpolation."
    index0::CartesianIndex{D}
    "Higher index used to get data for the interpolation"
    index1::CartesianIndex{D}
    """
    Interpolation factor used to linearly interpolate between data points. This
    should generally be between 0 and 1
    """
    interpolation::Vec{D, Float32}
    """
    Size of the data which the indices refer to. Data with a different size will
    not be interpolated unless `edge_based = true` and the data size is `size + 1`.
    """
    size::Vec{D, Int64}
    """
    Marks that indices are given for edge based data of size `size + 1` and need
    to be downsampled for cell based data.
    """
    edge_based::Bool
end

function InterpolatedAccessor(
        i0::Integer, i1::Integer, interpolation::AbstractFloat, size::Integer, edge_based = false
    )
    return InterpolatedAccessor(
        CartesianIndex(i0), CartesianIndex(i1), Vec{1, Float32}(interpolation),
        Vec{1, Int64}(size), edge_based
    )
end

function InterpolatedAccessor(
        i0::VecTypes{D, <:Integer}, i1::VecTypes{D, <:Integer},
        interpolation::VecTypes{D, <:AbstractFloat}, size::VecTypes{D, <:Integer},
        edge_based = false
    ) where {D}

    return InterpolatedAccessor(
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

function element_getindex(x, element::InterpolatedAccessor{1})
    if is_array_attribute(x)
        low = sv_getindex(x, element.index0)
        high = sv_getindex(x, element.index1)
        return lerp(low, high, element.interpolation[1])
    else
        return x
    end
end

function element_getindex(x, element::InterpolatedAccessor{2})
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

function dimensional_element_getindex(x, element::InterpolatedAccessor{2}, dim::Integer)
    if x isa AbstractArray{T, 2} where {T}
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

"""
    MeshAccessor(N_vertices, N_submeshes, submesh_index, face, uv)
    MeshAccessor(N_vertices, N_submeshes, submesh_index, face, uv)

Constructs an accessor representing indexing and interpolation information on a
mesh.

If the accessed data is vertex like, i.e. `length(data) == N_vertices` the
stored (triangle) `face` is used to 3 relevant vertices. These vertices are then
interpolated using `uv` values:

```
a = sv_getindex(data, face[1])
b = sv_getindex(data, face[2])
c = sv_getindex(data, face[3])
return a + u * (b - a) + v * (c - a)
```

If the accessed data matches the length of submeshes `length(data) == N_submeshes`
it is instead accessed by the `submesh_index`. Submeshes are generated when
merging meshes e.g. by `poly([...])`.

## Fields
$(TYPEDFIELDS)
"""
struct MeshAccessor <: AbstractElementAccessor
    "Number of vertices of the parent mesh."
    N_vertices::Int64
    "Number of submeshes of the parent mesh, i.e. `length(mesh.views)."
    N_submeshes::Int64

    "Index of the submesh the selected face belongs to."
    submesh_index::Int64
    "The selected triangle face of the mesh."
    face::GLTriangleFace
    "The interpolation factors (u, v) which represent the selected point on the face."
    uv::Vec2f

    function MeshAccessor(
            N_vertices::Integer, N_submeshes::Integer,
            submesh_index::Integer, face::TriangleFace, uv::VecTypes{2}
        )
        return new(N_vertices, N_submeshes, submesh_index, GLTriangleFace(face), Vec2f(uv))
    end
end

function element_getindex(x, element::MeshAccessor)
    if is_array_attribute(x)
        if length(x) == element.N_vertices
            i, j, k = element.face
            a = sv_getindex(x, i)
            b = sv_getindex(x, j)
            c = sv_getindex(x, k)
            u, v = element.uv
            return a + u * (b - a) + v * (c - a)
        elseif length(x) == element.N_submeshes
            return x[element.submesh_index]
        else
            return x
        end
    else
        return x
    end
end

"""
    ViolinAccessor(violin_index, num_violins, vertex_index0, vertex_index1, vertex_interpolation, N_vertices)

Specialized accessor for Violin plots.

This deals with categories/x-values creating multiple separate violins and the
different number of elements between `plot.vertices` and
`plot.specs[][violin_index].kde.density`.

## Fields
$(TYPEDFIELDS)
"""
struct ViolinAccessor <: AbstractElementAccessor
    "Index of the selected violin or half-violin/density."
    violin_index::Int64
    "Number of (half-)violins"
    num_violins::Int64

    "Lower index into violin vertices"
    index0::Int64
    "Upper index into violin vertices"
    index1::Int64
    "Interpolation factor used to linearly interpolate the selected vertex."
    interpolation::Float32
    "Number of vertices"
    N_vertices::Int64
end

function element_getindex(x, element::ViolinAccessor)
    if is_array_attribute(x)
        if length(x) == element.num_violins
            return element_getindex(x[element.violin_index], element)
        elseif length(x) == element.N_vertices # e.g. vertices
            low = sv_getindex(x, element.index0)
            high = sv_getindex(x, element.index1)
            return lerp(low, high, element.interpolation)
        elseif length(x) == element.N_vertices - 2
            # e.g. kde.density whose edge values are duplicated in vertices
            low = sv_getindex(x, clamp(element.index0 - 1, 1, length(x)))
            high = sv_getindex(x, clamp(element.index1 - 1, 1, length(x)))
            return lerp(low, high, element.interpolation)
        else
            return x
        end
    else
        return x
    end
end

################################################################################
### Utilities
################################################################################

"""
    get_post_transform(element, names...)

Returns the value of `element.name` after applying the elements `transform_func`.

In practice, this returns `getproperty(element, Symbol(name, :_transformed))`.
If this node does not exist yet, it will be created. The result will then be
interpolated (or indexed) after the transform function is applied, matching the
way interpolation parameters are calculated for plot elements. The result can
then be back-transformed to get the correct pre-transform values.

This is needed for `get_tooltip_position()` as PlotElements calculate their
interpolation parameters after applying transform functions
"""
function get_post_transform(element::PlotElement, name1::Symbol, names::Symbol...)
    return get_post_transform(element, name1), get_post_transform.(Ref(element), names)...
end

function get_post_transform(element::PlotElement, name::Symbol)
    plt = get_plot(element)
    transformed_name = Symbol(name, :_transformed)
    if !haskey(plt, transformed_name)
        map!(plt, [:transform_func, name], transformed_name) do tf, data
            return apply_transform(tf, data)
        end
    end
    return getproperty(element, transformed_name)
end

function get_post_transform(element::PlotElement{<:AbstractPlot, <:IndexedAccessor}, name::Symbol)
    pos = getproperty(element, name)
    return apply_transform(element.transform_func, pos)
end

"""
    get_pre_transform(element, names...)

Returns the value of `element.name` with the interpolation (or index) of the
plot `element` being calculated to transformed data.

In practice, this returns `getproperty(element, Symbol(name, :_transformed))`.
If this node does not exist yet, it will be created. The result will then be
interpolated (or indexed) after the transform function is applied, matching the
way interpolation parameters are calculated for plot elements. The result can
then be back-transformed to get the correct pre-transform values.

This is needed for `get_tooltip_position()` as PlotElements calculate their
interpolation parameters after applying transform functions
"""
function get_pre_transform(element::PlotElement, name1::Symbol, names::Symbol...)
    return get_pre_transform(element, name1), get_pre_transform.(Ref(element), names)...
end

function get_pre_transform(element::PlotElement, name::Symbol)
    plt = get_plot(element)
    data = get_post_transform(element, name)
    itf = inverse_transform(transform_func(parent_scene(plt)))
    return Makie.apply_transform(itf, data)
end
