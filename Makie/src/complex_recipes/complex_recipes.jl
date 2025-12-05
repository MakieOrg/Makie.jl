"""
    ComplexRecipe

ComplexRecipe is a hybrid between Block and Plot recipes that allows creating
multi-axis, multi-layout visualizations through a simple recipe-like interface.

A ComplexRecipe:
- Acts like a Plot (uses ComputeGraph, supports convert_arguments, plottype dispatch)
- Can create multiple sub-axes and plots within a layout
- The parent is a FigureLike (GridPosition, GridSubposition, Figure)

## Usage

```julia
@recipe complex DualView (x, y) begin
    "Color for scatter plot"
    scatter_color = :blue
    "Color for line plot"
    line_color = :red
end

function Makie.plot!(cr::DualView)
    # cr[row, col] returns a RecipeSubfig that tracks created axes
    # cr.x, cr.y give access to converted arguments
    # cr.scatter_color gives access to attributes
    scatter(cr[1, 1], cr.x, cr.y; color=cr.scatter_color)
    lines(cr[1, 2], cr.x, cr.y; color=cr.line_color)
    return cr
end
```

Then use like any plot:
```julia
fig, ax, cr = dualview(1:10, rand(10))  # Creates Figure + ComplexRecipe
dualview(fig[2, 1], 1:10, rand(10))     # Places in existing figure position
```
"""

const ComplexRecipeFigureLike = Union{GridPosition, GridSubposition, Figure}

"""
    ComplexRecipe{Func, T}

The concrete type for complex recipes. Mirrors `Plot{Func, T}` structure
and is a subtype of `AbstractPlot{Func}`.

- `Func`: The recipe function (e.g., `mycomplex`)
- `T`: Type tuple of converted arguments
"""
mutable struct ComplexRecipe{Func, T} <: AbstractPlot{Func}
    # Where this recipe lives (GridPosition, Figure, etc)
    parent::ComplexRecipeFigureLike
    # Unprocessed arguments directly from the user command
    kw::Dict{Symbol, Any}
    # Converted and processed arguments + attributes
    attributes::ComputeGraph
    # Track created axes and plots
    axes::Vector{Any}  # Vector of created axes
    plots::Vector{AbstractPlot}  # Vector of created plots
    function ComplexRecipe{Func, T}(
            parent::ComplexRecipeFigureLike,
            kw::Dict{Symbol, Any},
            attr::ComputeGraph
        ) where {Func, T}
        return new{Func, T}(parent, kw, attr, Any[], AbstractPlot[])
    end
end

# Type aliases
const ComplexRecipeType{Func} = ComplexRecipe{Func, <:Any}

"""
    RecipeSubfig

A wrapper that represents a grid position within a ComplexRecipe.
This allows us to dispatch on `scatter(::RecipeSubfig, ...)` and track
created axes/plots in the parent ComplexRecipe.
"""
struct RecipeSubfig
    parent::ComplexRecipe
    rows::Union{Int, UnitRange{Int}}
    cols::Union{Int, UnitRange{Int}}
end

# Get the function associated with a ComplexRecipe
complexrecipefunc(::ComplexRecipe{F}) where {F} = F
complexrecipefunc(::Type{<:ComplexRecipe{F}}) where {F} = F

# === RecipeSubfig - Grid Position Access ===

"""
    cr[row, col] -> RecipeSubfig

Returns a RecipeSubfig that can be used with plotting functions.
The created axes/plots will be tracked in the ComplexRecipe.
"""
function Base.getindex(cr::ComplexRecipe, row::Union{Int, UnitRange{Int}}, col::Union{Int, UnitRange{Int}})
    return RecipeSubfig(cr, row, col)
end

"""
Get the actual GridPosition from a RecipeSubfig for placing content.
"""
function get_grid_position(rsf::RecipeSubfig)
    return rsf.parent.parent[rsf.rows, rsf.cols]
end

# === Indexing and Property Access ===
# Note: haskey, get, getindex, setindex!, getproperty, setproperty! are inherited
# from AbstractPlot via shared methods in compute-plots.jl

# === Recipe Infrastructure ===

# argument_names - will be specialized by macro (required, not optional)
argument_names(::Type{<:ComplexRecipe}) = ()
argument_names(::Type{<:ComplexRecipe}, ::Integer) = ()

# DocumentedAttributes support
documented_attributes(::Type{<:ComplexRecipe}) = nothing

function attribute_names(T::Type{<:ComplexRecipe})
    attr = documented_attributes(T)
    isnothing(attr) && return nothing
    return keys(attr.d)
end

function is_attribute(T::Type{<:ComplexRecipe}, sym::Symbol)
    names = attribute_names(T)
    isnothing(names) && return false
    return sym in names
end

function attribute_default_expressions(T::Type{<:ComplexRecipe})
    da = documented_attributes(T)
    isnothing(da) && return Dict{Symbol, String}()
    return Dict(k => v.default_expr for (k, v) in da.d)
end

function _attribute_docs(T::Type{<:ComplexRecipe})
    da = documented_attributes(T)
    isnothing(da) && return nothing
    return Dict(k => v.docstring for (k, v) in da.d)
end

"""
    complexrecipe_attributes(scene, T)

Get the documented attributes for a ComplexRecipe type.
"""
function complexrecipe_attributes(scene, T::Type{<:ComplexRecipe})
    cr_attr = documented_attributes(T)
    if isnothing(cr_attr)
        return Dict{Symbol, Any}()
    else
        return cr_attr.d
    end
end

"""
    default_theme(scene, ::Type{<:ComplexRecipe{Func}})

Get the default theme for a complex recipe.
"""
function default_theme(scene, T::Type{<:ComplexRecipe})
    metas = documented_attributes(T)
    attr = Attributes()
    isnothing(metas) && return attr
    thm = isnothing(scene) ? Attributes() : theme(scene)
    _attr = attr.attributes
    for (k, meta) in metas.d
        _attr[k] = lookup_default(meta, thm)
    end
    return attr
end

"""
    complexrecipetype(args...)

Can be specialized to make `plot(mytype)` dispatch to a ComplexRecipe.
Returns `nothing` by default - specific types can override.
"""
complexrecipetype(args...) = nothing


# === Show ===

function Base.show(io::IO, cr::ComplexRecipe)
    return print(io, typeof(cr))
end

function Base.show(io::IO, ::MIME"text/plain", cr::ComplexRecipe{F}) where {F}
    println(io, "ComplexRecipe{$F}")
    println(io, "  parent: $(typeof(cr.parent))")
    println(io, "  axes: $(length(cr.axes))")
    println(io, "  plots: $(length(cr.plots))")
    return
end

function Base.show(io::IO, rsf::RecipeSubfig)
    return print(io, "RecipeSubfig($(rsf.rows), $(rsf.cols))")
end
