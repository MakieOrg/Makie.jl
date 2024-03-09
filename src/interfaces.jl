
function add_cycle_attribute!(plot::Plot, scene::Scene, cycle=get_cycle_for_plottype(plot.cycle[]))
    cycler = scene.cycler
    palette = scene.theme.palette
    add_cycle_attributes!(plot, cycle, cycler, palette)
    return
end

function color_and_colormap!(plot, colors = plot.color)
    scene = parent_scene(plot)
    if !isnothing(scene) && haskey(plot, :cycle)
        add_cycle_attribute!(plot, scene)
    end
    colors = assemble_colors(colors[], colors, plot)
    attributes(plot.attributes)[:calculated_colors] = colors
end

function calculated_attributes!(::Type{<: AbstractPlot}, plot)
    scene = parent_scene(plot)
    if !isnothing(scene) && haskey(plot, :cycle)
        add_cycle_attribute!(plot, scene)
    end
end

function calculated_attributes!(::Type{<: Mesh}, plot)
    mesha = lift(GeometryBasics.attributes, plot, plot.mesh)
    color = haskey(mesha[], :color) ? lift(x-> x[:color], plot, mesha) : plot.color
    color_and_colormap!(plot, color)
    return
end

function calculated_attributes!(::Type{<: Union{Heatmap, Image}}, plot)
    color_and_colormap!(plot, plot[3])
end

function calculated_attributes!(::Type{<: Surface}, plot)
    colors = plot[3]
    if haskey(plot, :color)
        color = plot[:color][]
        if isa(color, AbstractMatrix) && !(color === to_value(colors))
            colors = plot[:color]
        end
    end
    color_and_colormap!(plot, colors)
end

function calculated_attributes!(::Type{<: MeshScatter}, plot)
    color_and_colormap!(plot)
    return
end

function calculated_attributes!(::Type{<:Volume}, plot)
    color_and_colormap!(plot, plot[4])
    return
end

function calculated_attributes!(::Type{<:Text}, plot)
    color_and_colormap!(plot)
    return
end

function calculated_attributes!(::Type{<: Scatter}, plot)
    # calculate base case
    color_and_colormap!(plot)

    replace_automatic!(plot, :marker_offset) do
        # default to middle
        return lift(plot, plot[:markersize]) do msize
            return to_2d_scale(map(x -> x .* -0.5f0, msize))
        end
    end

    replace_automatic!(plot, :markerspace) do
        lift(plot, plot.markersize) do ms
            if ms isa Pixel || (ms isa AbstractVector && all(x-> ms isa Pixel, ms))
                return :pixel
            else
                return :data
            end
        end
    end
end

function calculated_attributes!(::Type{T}, plot) where {T<:Union{Lines, LineSegments}}
    pos = plot[1][]
    # extend one color/linewidth per linesegment to be one (the same) color/linewidth per vertex
    if T <: LineSegments
        for attr in [:color, :linewidth]
            # taken from @edljk  in PR #77
            if haskey(plot, attr) && isa(plot[attr][], AbstractVector) && (length(pos) ÷ 2) == length(plot[attr][])
                # TODO, this is actually buggy for `plot.color = new_colors`, since we're overwriting the origin color input
                attributes(plot.attributes)[attr] = lift(plot, plot[attr]) do cols
                    map(i -> cols[(i + 1) ÷ 2], 1:(length(cols) * 2))
                end
            end
        end
    end
    color_and_colormap!(plot)
    return
end

const atomic_functions = (
    text, meshscatter, scatter, mesh, linesegments,
    lines, surface, volume, heatmap, image
)
const Atomic{Arg} = Union{map(x-> Plot{x, Arg}, atomic_functions)...}





convert_from_args(conversion, values) = conversion

function convert_from_args(::Automatic, values)
    return axis_conversion_type(MakieCore.get_element_type(values))
end

# single arguments gets ignored for now
# TODO: add similar overloads as convert_arguments for the most common ones that work with units
axis_convert(P, ::Dict, args::Observable...) = args
# we leave Z + n alone for now!
function axis_convert(P, attr::Dict, x::Observable, y::Observable, z::Observable, args...)
    return (axis_convert(P, attr, x, y)..., z, args...)
end

convert_axis_dim(convert, value) = value

function axis_convert(P, attributes::Dict, x::Observable, y::Observable)
    if MakieCore.can_axis_convert(P, x[]) || haskey(attributes, :x_dim_convert)
        xconvert = to_value(get(attributes, :x_dim_convert, automatic))
        xconvert_new = convert_from_args(xconvert, x[])
        attributes[:x_dim_convert] = xconvert_new
        x = convert_axis_dim(xconvert_new, x)
    end
    if MakieCore.can_axis_convert(P, y[]) || haskey(attributes, :y_dim_convert)
        yconvert = to_value(get(attributes, :y_dim_convert, automatic))
        yconvert_new = convert_from_args(yconvert, y[])
        attributes[:y_dim_convert] = yconvert_new
        y = convert_axis_dim(yconvert_new, y)
    end

    return (x, y)
end

function no_obs_conversion(P, args, kw)
    converted = convert_arguments(P, args...; kw...)
    if !(converted isa Tuple)
        # SpecPlot/Vector{SpecPlot}/GridLayoutSpec
        return converted, :half_converted
    else
        typed = convert_arguments_typed(P, converted...)
        if typed isa NamedTuple
            return values(typed), :converted
        elseif typed isa MakieCore.ConversionError
            return converted, :needs_conversion
        elseif typed isa NoConversion
            return converted, :no_typed_conversion
        else
            error("convert_arguments_typed returned an invalid type: $(typed)")
        end
    end
end

apply_axis_conversion(P, args...) = false

function get_kw_values(func, names, kw)
    return NamedTuple([Pair{Symbol,Any}(k, func(kw[k]))
            for k in names if haskey(kw, k)])
end

function get_kw_obs(names, kw)
    isempty(names) && return Observable((;))
    kw_copy = copy(kw)
    init = get_kw_values(to_value, names, kw_copy)
    obs = Observable(init; ignore_equal_values=true)
    in_obs = [kw_copy[k] for k in names if haskey(kw_copy, k)]
    onany(in_obs...) do args...
        obs[] = get_kw_values(to_value, names, kw_copy)
        return
    end
    return obs
end

function conversion_pipeline(P, used_attrs, args_obs, args, user_attributes, plot_attributes, deregister, recursion=1)
    if recursion == 3
        return P, args_obs
    end
    kw_obs = get_kw_obs(used_attrs, user_attributes)
    kw = to_value(kw_obs)
    args_obs = axis_convert(P, user_attributes, args_obs...)
    args = map(to_value, args_obs)

    converted, status = no_obs_conversion(P, args, kw)

    if status === :converted
        new_args_obs = map(Observable, converted)
        fs = onany(kw_obs, args_obs...) do kw, args...
            conv, status = no_obs_conversion(P, args, kw)
            for (obs, arg) in zip(new_args_obs, conv)
                obs[] = arg
            end
            return
        end
        append!(deregister, fs)
        return P, new_args_obs
    elseif status === :needs_conversion
        new_args_obs = map(Observable, converted)
        fs = onany(kw_obs, args_obs...) do kw, args...
            conv, status = no_obs_conversion(P, args, kw)
            for (obs, arg) in zip(new_args_obs, conv)
                obs[] = arg
            end
            return
        end
        append!(deregister, fs)
        # return P, axis_convert(P, user_attributes, new_args_obs...)
        return conversion_pipeline(P, used_attrs, new_args_obs, args, user_attributes, plot_attributes, deregister,
                                   recursion + 1)
    else
        P, converted2 = apply_convert!(P, plot_attributes, converted)
        new_args_obs = map(Observable, converted2)
        fs = onany(kw_obs, args_obs...) do kw, args...
            conv, status = no_obs_conversion(P, args, kw)
            P, converted3 = apply_convert!(P, plot_attributes, conv)
            for (obs, arg) in zip(new_args_obs, converted3)
                obs[] = arg
            end
            return
        end
        append!(deregister, fs)
        return P, new_args_obs
    end
end


function Plot{Func}(user_args::Tuple, user_attributes::Dict) where {Func}
    # Handle plot!(plot, attributes::Attributes, args...) here
    if !isempty(user_args) && first(user_args) isa Attributes
        merge!(user_attributes, attributes(first(user_args)))
        return Plot{Func}(Base.tail(user_args), user_attributes)
    end
    P = Plot{Func}
    args = map(to_value, user_args)
    attr = used_attributes(P, args...)
    args_obs = map(x -> x isa Observable ? x : Observable{Any}(x), user_args)
    plot_attributes = Attributes()
    deregister = Observables.ObserverFunction[]
    PNew, converted_obs = conversion_pipeline(P, attr, args_obs, args, user_attributes, plot_attributes, deregister)
    args = map(to_value, converted_obs)
    ArgTyp = MakieCore.argtypes((args...,))
    FinalPlotFunc = plotfunc(plottype(PNew, args...))
    foreach(x -> delete!(user_attributes, x), attr)
    foreach(x -> delete!(plot_attributes, x), attr)
    return Plot{FinalPlotFunc,ArgTyp}(user_attributes, Any[args_obs...], converted_obs, plot_attributes,
                                      deregister)
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
plottype(P::Type{<: Plot{T}}, argvalues...) where T = plottype(P, plottype(argvalues...))
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
plottype(::AbstractMatrix{<: Real}) = Heatmap
plottype(::Array{<: AbstractFloat, 3}) = Volume
plottype(::AbstractString) = Text

plottype(::LineString) = Lines
plottype(::AbstractVector{<:LineString}) = Lines
plottype(::MultiLineString) = Lines

plottype(::Polygon) = Poly
plottype(::GeometryBasics.AbstractPolygon) = Poly
plottype(::AbstractVector{<:GeometryBasics.AbstractPolygon}) = Poly
plottype(::MultiPolygon) = Lines



# all the plotting functions that get a plot type
const PlotFunc = Type{<:AbstractPlot}

function plot!(::Plot{F}) where {F}
    if !(F in atomic_functions)
        error("No recipe for $(F)")
    end
end

function connect_plot!(parent::SceneLike, plot::Plot{F}) where {F}
    plot.parent = parent

    apply_theme!(parent_scene(parent), plot)
    t_user = to_value(get(attributes(plot), :transformation, automatic))
    if t_user isa Transformation
        plot.transformation = t_user
    else
        if t_user isa Automatic
            plot.transformation = Transformation()
        else
            t = Transformation()
            transform!(t, t_user)
            plot.transformation = t
        end
        if is_space_compatible(plot, parent)
            obsfunc = connect!(transformation(parent), transformation(plot))
            append!(plot.deregister_callbacks, obsfunc)
        end
    end
    plot.model = transformationmatrix(plot)
    calculated_attributes!(Plot{F}, plot)
    default_shading!(plot, parent_scene(parent))
    plot!(plot)
    return plot
end

function plot!(scene::SceneLike, plot::Plot)
    connect_plot!(scene, plot)
    push!(scene, plot)
    return plot
end

function apply_theme!(scene::Scene, plot::P) where {P<: Plot}
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
