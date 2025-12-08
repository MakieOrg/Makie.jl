# === ComplexRecipe Construction ===

"""
    _create_complex_recipe(Func, parent, args, kw)

Internal function to create a ComplexRecipe. Similar to Plot construction.
"""
function _create_complex_recipe(Func, parent::ComplexRecipeFigureLike, user_args::Tuple, user_kw::Dict{Symbol, Any})
    isempty(user_args) && throw(ArgumentError("ComplexRecipe requires at least one argument"))

    CR = ComplexRecipe{Func}
    attr = ComputeGraph()

    # Register input arguments
    arg_names = argument_names(CR)
    for (i, (name, arg)) in enumerate(zip(arg_names, user_args))
        add_input!(attr, name, arg)
        attr[name].value = RefValue{Any}(arg)
    end

    # Store converted tuple for compatibility
    map!(attr, collect(arg_names), :converted) do args...
        return args
    end

    # Add attributes from documented defaults
    add_complex_attributes!(CR, attr, user_kw)

    # Create the recipe
    converted = attr[:converted][]
    ArgTyp = typeof(converted)
    cr = ComplexRecipe{Func, ArgTyp}(parent, user_kw, attr)

    # Call the user's plot! implementation
    plot!(cr)

    return cr
end

"""
    add_complex_attributes!(::Type{CR}, attr, kwargs)

Add documented attributes to the ComputeGraph, similar to add_attributes! for Plot.
"""
function add_complex_attributes!(::Type{CR}, attr::ComputeGraph, kwargs::Dict) where {CR <: ComplexRecipe}
    documented_attr = complexrecipe_attributes(nothing, CR)

    for (k, v) in documented_attr
        if haskey(kwargs, k)
            val = kwargs[k]
        elseif v isa AttributeMetadata
            val = v.default_value
            if val isa Inherit
                val = val.fallback
            end
        else
            val = to_value(v)
        end

        if !haskey(attr.outputs, k)
            add_input!(to_recipe_attribute, attr, k, val)
        end
    end

    return
end

# === Plotting into RecipeSubfig ===

# RecipeSubfig acts as a GridPosition for plotting purposes.
# When you call scatter(cr[1,1], args...), it goes through _create_plot which
# calls plot_args, and we need RecipeSubfig to be recognized as a figure-like argument.

"""
    RecipeSubfigAxis <: AbstractAxis

Wrapper that carries both the axis and the RecipeSubfig context through the
plotting dispatch chain. This allows figurelike_return to track the created
axis and plot in the parent ComplexRecipe.

Inherits from AbstractAxis so it works with the standard plot!(ax, plot) interface.
"""
struct RecipeSubfigAxis <: AbstractAxis
    axis::AbstractAxis
    rsf::RecipeSubfig
end

# Constructor that unwraps FigureAxis
RecipeSubfigAxis(fa::FigureAxis, rsf::RecipeSubfig) = RecipeSubfigAxis(fa.axis, rsf)

# Forward AbstractAxis interface to the wrapped axis
get_scene(rsa::RecipeSubfigAxis) = get_scene(rsa.axis)
get_conversions(rsa::RecipeSubfigAxis) = get_conversions(rsa.axis)

# Make RecipeSubfig work with plot_args dispatch
@inline function plot_args(rsf::RecipeSubfig, args...)
    return (rsf, args)
end

# Integration with create_axis_like for non-mutating plots (scatter, lines, etc.)
function create_axis_like(plot::AbstractPlot, attributes::Dict, rsf::RecipeSubfig)
    gp = get_grid_position(rsf)
    ax = create_axis_like(plot, attributes, gp)
    return RecipeSubfigAxis(ax, rsf)
end

# Track plots created via RecipeSubfig - dispatch on the wrapper type
function figurelike_return(rsa::RecipeSubfigAxis, plot::AbstractPlot)
    # Track the axis and plot in the parent ComplexRecipe
    push!(rsa.rsf.parent.axes, rsa.axis)
    push!(rsa.rsf.parent.plots, plot)
    # Return (axis, plot) tuple for destructuring convenience
    return rsa.axis, plot
end

# Forward plot! to the wrapped axis
function plot!(rsa::RecipeSubfigAxis, plot::AbstractPlot)
    plot!(rsa.axis, plot)
    return plot
end

# === Mutating plot support for RecipeSubfig ===

"""
    create_axis_like!(attributes::Dict, rsf::RecipeSubfig)

For mutating plots (plot!), get the axis at the RecipeSubfig position.
The axis must already exist. Returns a RecipeSubfigAxis to enable plot tracking.
"""
function create_axis_like!(attributes::Dict, rsf::RecipeSubfig)
    gp = get_grid_position(rsf)
    ax = create_axis_like!(attributes, gp)
    # Track the axis if not already tracked
    if ax ∉ rsf.parent.axes
        push!(rsf.parent.axes, ax)
    end
    # Return wrapped axis so figurelike_return! can track the plot
    return RecipeSubfigAxis(ax, rsf)
end

# Track plots from mutating calls
function figurelike_return!(rsa::RecipeSubfigAxis, plot::AbstractPlot)
    push!(rsa.rsf.parent.plots, plot)
    return plot
end

# === Default plot! fallback ===

"""
    plot!(cr::ComplexRecipe)

Default implementation that does nothing. Users should specialize this for their recipe.
"""
function plot!(cr::ComplexRecipe)
    @warn "No plot! method defined for $(typeof(cr)). Define `Makie.plot!(cr::$(typeof(cr).name.name))` to implement your recipe."
    return cr
end

########################################
# Block Extension
########################################

get_topscene(rsf::RecipeSubfig) = get_topscene(get_grid_position(rsf))

function _block(T::Type{<:Block}, rsf::RecipeSubfig, args...; kwargs...)
    return _block(T, get_grid_position(rsf), args...; kwargs...)
end

function GridLayoutBase.GridLayout(rsf::RecipeSubfig, args...; kwargs...)
    return GridLayout(get_grid_position(rsf), args...; kwargs...)
end