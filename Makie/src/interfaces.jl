const atomic_functions = (
    text, meshscatter, scatter, mesh, linesegments,
    lines, surface, volume, heatmap, image, voxels,
)
const Atomic{Arg} = Union{map(x -> Plot{x, Arg}, atomic_functions)...}


"""
    expand_dimensions(plottrait, plotargs...)

Expands the dims for e.g. `scatter(1:4)` becoming `scatter(1:4, 1:4)` for 2D plots.
We're separating this state from convert_arguments, to better apply `dim_converts` before convert_arguments.
"""
expand_dimensions(trait, args...) = nothing

expand_dimensions(::PointBased, y::VecTypes) = nothing # VecTypes are n dimensional points
expand_dimensions(::PointBased, y::RealVector) = (keys(y), y)
expand_dimensions(::PointBased, y::OffsetVector{<:Real}) =
    (collect(OffsetArrays.no_offset_view(keys(y))), collect(OffsetArrays.no_offset_view(y)))

function expand_dimensions(::Union{ImageLike, GridBased}, data::AbstractMatrix{<:Union{<:Real, <:Colorant}})
    # Float32, because all ploteable sizes should fit into float32
    x, y = map(x -> (0.0f0, Float32(x)), size(data))
    return (x, y, data)
end

function expand_dimensions(::Union{CellGrid, VertexGrid}, data::AbstractMatrix{<:Union{<:Real, <:Colorant}})
    x, y = map(x -> (1.0f0, Float32(x)), size(data))
    return (x, y, data)
end

function expand_dimensions(::VolumeLike, data::Array{<:Any, 3})
    x, y, z = map(x -> EndPoints(0.0f0, Float32(x)), size(data))
    return (x, y, z, data)
end

# Mainly for Voxels, which breaks conversion_trait(Voxels)::ConversionTrait
got_converted(P, PTrait, result) = nothing
function got_converted(P::Type, PTrait::ConversionTrait, result)
    SpecLike = Union{PlotSpec, BlockSpec, GridLayoutSpec, AbstractVector{PlotSpec}}
    if result isa Tuple && length(result) == 1
        if result[1] isa SpecLike
            return SpecApi
        end
    end
    if result isa SpecLike
        return SpecApi
    end
    types = types_for_plot_arguments(P, PTrait)
    if !isnothing(types)
        return result isa types
    end
    return nothing
end


"""
    used_attributes(args...) = ()

Function used to indicate what keyword args one wants to get passed in `convert_arguments`.
Those attributes will not be forwarded to the backend, but only used during the
conversion pipeline.
Usage:
```julia
struct MyType end
used_attributes(::MyType) = (:attribute,)
function convert_arguments(x::MyType; attribute = 1)
    ...
end
# attribute will get passed to convert_arguments
# without keyword_verload, this wouldn't happen
plot(MyType, attribute = 2)
#You can also use the convenience macro, to overload convert_arguments in one step:
@keywords convert_arguments(x::MyType; attribute = 1)
    ...
end
```
"""
used_attributes(::Type{<:Plot}, args...) = used_attributes(args...)
used_attributes(args...) = ()

## generic definitions
# Chose the more specific plot type from arguments or input type
# Note the plottype(Scatter, Plot{plot}) will return Scatter
# And plottype(args...) falls back to Plot{plot}
plottype(P::Type{<:Plot{T}}, argvalues...) where {T} = plottype(P, plottype(argvalues...))
plottype(P::Type{<:Plot{T}}) where {T} = P
plottype(P1::Type{<:Plot{T1}}, ::Type{<:Plot{T2}}) where {T1, T2} = P1
plottype(::Type{Plot{plot}}, ::Type{Plot{plot}}) = Plot{plot}

"""
    plottype(P1::Type{<: Plot{T1}}, P2::Type{<: Plot{T2}})

Chooses the more concrete plot type
```julia
function convert_arguments(P::PlotFunc, args...)
    ptype = plottype(P, Lines)
    ...
end
```
"""
plottype(::Type{Plot{plot}}, P::Type{<:Plot{T}}) where {T} = P
plottype(P::Type{<:Plot{T}}, ::Type{Plot{plot}}) where {T} = P


## specialized definitions for types
plottype(::AbstractVector, ::AbstractVector, ::AbstractVector) = Scatter
plottype(::AbstractVector, ::AbstractVector) = Scatter
plottype(::AbstractVector) = Scatter
plottype(::AbstractMatrix{<:Real}) = Heatmap
plottype(::Array{<:AbstractFloat, 3}) = Volume
plottype(::AbstractString) = Text

plottype(::LineString) = Lines
plottype(::AbstractVector{<:LineString}) = Lines
plottype(::MultiLineString) = Lines

plottype(::Polygon) = Poly
plottype(::GeometryBasics.AbstractPolygon) = Poly
plottype(::AbstractVector{<:GeometryBasics.AbstractPolygon}) = Poly
plottype(::MultiPolygon) = Lines
plottype(::AbstractVector{<:MultiPoint}) = Scatter
plottype(::MultiPoint) = Scatter


clip_planes_obs(parent::AbstractPlot) = attributes(parent).clip_planes
clip_planes_obs(parent::Scene) = parent.theme[:clip_planes]

# all the plotting functions that get a plot type
const PlotFunc = Type{<:AbstractPlot}

function plot!(::Plot{F, Args}) where {F, Args}
    return if !(F in atomic_functions)
        error("No recipe for $(F) with args: $(Args)")
    end
end

function handle_transformation!(plot, parent)
    t_user = to_value(pop!(plot.kw, :transformation, :automatic))

    # Handle passing transform!() inputs through transformation
    if t_user isa Tuple{Symbol, <:Real} || t_user isa Union{Attributes, AbstractDict, NamedTuple}
        transform_op = t_user
        t_user = :automatic
    elseif t_user isa Tuple # Allow (t_user, transform_op)
        t_user, transform_op = t_user
    else
        transform_op = nothing
    end

    # Use given transformation
    if t_user isa Transformation
        plot.transformation = t_user
    else
        plot.transformation = Transformation()

        # Derive transformation based on space compatibility / use parent transform
        if t_user in (:automatic, :inherit)

            if is_space_compatible(plot, parent) || (t_user === :inherit)
                obsfunc = connect!(transformation(parent), transformation(plot))
                append!(plot.deregister_callbacks, obsfunc)
            end

            # Connect only transform_func
        elseif t_user === :inherit_transform_func
            obsfunc = connect!(transformation(parent), transformation(plot), connect_model = false)
            append!(plot.deregister_callbacks, obsfunc)

            # Connect only model
        elseif t_user === :inherit_model
            obsfunc = connect!(transformation(parent), transformation(plot), connect_func = false)
            append!(plot.deregister_callbacks, obsfunc)

            # Keep child transform disconnected
        elseif t_user === :nothing

        else
            @error("$t_user is not a valid input for `transformation`. Defaulting to `:automatic`.")
            if is_space_compatible(plot, parent)
                obsfunc = connect!(transformation(parent), transformation(plot))
                append!(plot.deregister_callbacks, obsfunc)
            end
        end
    end

    if !isnothing(transform_op)
        transform!(plot.transformation, transform_op)
    end


    # TODO: Consider removing Transformation() and handling this in compute graph
    # connect updates
    # TODO: These should not be added as inputs. But how do we update them otherwise?
    if haskey(plot, :model) && haskey(plot.attributes.inputs, :model)
        on(model -> update!(plot, model = model), plot, transformationmatrix(plot), update = true)
    else
        add_input!(plot.attributes, :model, transformationmatrix(plot))
    end

    if haskey(plot, :transform_func)
        on(tf -> update!(plot; transform_func = tf), plot, transform_func_obs(plot); update = true)
    else
        add_input!(plot.attributes, :transform_func, transform_func_obs(plot))
    end

    return
end

function plot!(scene::SceneLike, plot::Plot)
    connect_plot!(scene, plot)
    push!(scene, plot)
    return plot
end

function apply_theme!(scene::Scene, plot::P) where {P <: Plot}
    raw_attr = attributes(plot.attributes)
    plot_theme = default_theme(scene, P)
    plot_sym = plotsym(P)
    if haskey(theme(scene), plot_sym)
        merge_without_obs_reverse!(plot_theme, theme(scene, plot_sym))
    end
    for (k, v) in plot.kw
        if v isa NamedTuple
            raw_attr[k] = Attributes(v)
        else
            raw_attr[k] = convert(Observable{Any}, v)
        end
    end
    return merge!(plot.attributes, plot_theme)
end
