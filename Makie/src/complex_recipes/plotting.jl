# === ComplexRecipe Construction ===

num_decoration_plots_in_axis_scene(::Any) = 0
num_decoration_plots_in_axis_scene(::Axis3) = 12

function flatten_blocklist(blocks::Vector)
    clean_blocks = Block[]
    for thing in blocks
        if thing isa Block
            push!(clean_blocks, thing)
        elseif thing isa GridLayout
            append!(clean_blocks, flatten_blocklist(thing.content))
        elseif thing isa GridLayoutBase.GridContent
            @assert thing.content isa Block
            push!(clean_blocks, thing.content)
        else
            error("What else is there? $(typeof(blocks))")
        end
    end
    return clean_blocks
end

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

    # We need to update from the theme early so we can create e.g. a Legend
    # entry that relies on an inherited attribute
    add_theme!(ComplexRecipe{Func}, user_kw, attr, get_topscene(parent))

    # Create the recipe
    converted = attr[:converted][]
    ArgTyp = typeof(converted)
    cr = ComplexRecipe{Func, ArgTyp}(parent, user_kw, attr)

    # Call the user's plot! implementation
    plot!(cr)

    cr.blocks = convert(Vector{Any}, flatten_blocklist(cr.blocks))

    for block in cr.blocks
        if block isa AbstractAxis
            N = num_decoration_plots_in_axis_scene(block)
            axis_plots = block.scene.plots
            append!(cr.plots, view(axis_plots, N+1 : length(axis_plots)))
        end
    end

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

# Make RecipeSubfig work with plot_args dispatch
@inline function plot_args(rsf::RecipeSubfig, args...)
    return (rsf, args)
end

# Integration with create_axis_like for non-mutating plots (scatter, lines, etc.)
function create_axis_like(plot::AbstractPlot, attributes::Dict, rsf::RecipeSubfig)
    gp = get_grid_position(rsf)
    ax = create_axis_like(plot, attributes, gp)
    push!(rsf.parent.blocks, ax)
    return ax
end

# === Mutating plot support for RecipeSubfig ===

"""
    create_axis_like!(attributes::Dict, rsf::RecipeSubfig)

For mutating plots (plot!), get the axis at the RecipeSubfig position.
The axis must already exist.
"""
function create_axis_like!(attributes::Dict, rsf::RecipeSubfig)
    gp = get_grid_position(rsf)
    ax = create_axis_like!(attributes, gp)
    # Track the axis if not already tracked
    if ax ∉ rsf.parent.blocks
        push!(rsf.parent.blocks, ax)
    end
    # Return wrapped axis so figurelike_return! can track the plot
    return ax
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
    b = _block(T, get_grid_position(rsf), args...; kwargs...)
    push!(rsf.parent.blocks, b)
    return b
end

function GridLayoutBase.GridLayout(rsf::RecipeSubfig, args...; kwargs...)
    gl = GridLayout(get_grid_position(rsf), args...; kwargs...)
    push!(rsf.parent.blocks, gl)
    return gl
end