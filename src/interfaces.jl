function color_and_colormap!(plot, colors = plot.color)
    scene = parent_scene(plot)
    if !isnothing(scene) && haskey(plot, :cycle)
        cycler = scene.cycler
        palette = scene.theme.palette
        cycle = get_cycle_for_plottype(to_value(plot.cycle))
        add_cycle_attributes!(plot, cycle, cycler, palette)
    end
    colors = assemble_colors(colors[], colors, plot)
    attributes(plot.attributes)[:calculated_colors] = colors
end

function calculated_attributes!(T::Type{<: AbstractPlot}, plot)
    scene = parent_scene(plot)
    if !isnothing(scene) && haskey(plot, :cycle)
        cycler = scene.cycler
        palette = scene.theme.palette
        cycle = get_cycle_for_plottype(to_value(plot.cycle))
        add_cycle_attributes!(plot, cycle, cycler, palette)
    end
end

function calculated_attributes!(T::Type{<: Mesh}, plot)
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
const Atomic{Arg} = Union{map(x-> Combined{x, Arg}, atomic_functions)...}

function convert_arguments!(plot::Combined{F}) where {F}
    P = Combined{F,Any}
    function on_update(kw, args...)
        nt = convert_arguments(P, args...; kw...)
        pnew, converted = apply_convert!(P, plot.attributes, nt)
        @assert plotfunc(pnew) === F "Changed the plot type in convert_arguments. This isn't allowed!"
        for (obs, new_val) in zip(plot.converted, converted)
            obs[] = new_val
        end
    end
    used_attrs = used_attributes(P, to_value.(plot.args)...)
    convert_keys = intersect(used_attrs, keys(plot.attributes))
    kw_signal = if isempty(convert_keys)
        # lift(f) isn't supported so we need to catch the empty case
        Observable(())
    else
        # Remove used attributes from `attributes` and collect them in a `Tuple` to pass them more easily
        lift((args...) -> Pair.(convert_keys, args), plot, pop!.(plot.attributes, convert_keys)...)
    end
    onany(on_update, plot, kw_signal, plot.args...)
    return
end

function Combined{Func}(args::Tuple, plot_attributes::Dict) where {Func}
    if first(args) isa Attributes
        merge!(plot_attributes, attributes(first(args)))
        return Combined{Func}(Base.tail(args), plot_attributes)
    end
    P = Combined{Func}
    used_attrs = used_attributes(P, to_value.(args)...)
    if used_attrs === ()
        args_converted = convert_arguments(P, map(to_value, args)...)
    else
        kw = [Pair(k, to_value(v)) for (k, v) in plot_attributes if k in used_attrs]
        args_converted = convert_arguments(P, map(to_value, args)...; kw...)
    end
    PNew, converted = apply_convert!(P, Attributes(), args_converted)

    obs_args = Any[convert(Observable, x) for x in args]

    ArgTyp = MakieCore.argtypes(converted)
    converted_obs = map(Observable, converted)
    plot = Combined{plotfunc(PNew),ArgTyp}(plot_attributes, obs_args, converted_obs)
    return plot
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
used_attributes(PlotType, args...) = ()


## generic definitions
# If the Combined has no plot func, calculate them
plottype(::Type{<: Combined{Any}}, argvalues...) = plottype(argvalues...)
plottype(::Type{Any}, argvalues...) = plottype(argvalues...)
# If it has something more concrete than Any, use it directly
plottype(P::Type{<: Combined{T}}, argvalues...) where T = P

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

"""
    plottype(P1::Type{<: Combined{T1}}, P2::Type{<: Combined{T2}})

Chooses the more concrete plot type
```julia
function convert_arguments(P::PlotFunc, args...)
    ptype = plottype(P, Lines)
    ...
end
```
"""
plottype(::Type{<: Combined{Any}}, P::Type{<: Combined{T}}) where T = P
plottype(P::Type{<: Combined{T}}, ::Type{<: Combined}) where T = P

# all the plotting functions that get a plot type
const PlotFunc = Union{Type{Any},Type{<:AbstractPlot}}

function plot!(::Combined{F}) where {F}
    if !(F in atomic_functions)
        error("No recipe for $(F)")
    end
end

function connect_plot!(scene::SceneLike, plot::Combined{F}) where {F}
    plot.parent = scene

    apply_theme!(parent_scene(scene), plot)
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
        obsfunc = connect!(transformation(scene), transformation(plot))
        append!(plot.deregister_callbacks, obsfunc)
    end
    plot.model = transformationmatrix(plot)
    convert_arguments!(plot)
    calculated_attributes!(Combined{F}, plot)
    plot!(plot)
    return plot
end

function plot!(scene::SceneLike, plot::Combined)
    connect_plot!(scene, plot)
    push!(scene, plot)
    return plot
end

function apply_theme!(scene::Scene, plot::P) where {P<: Combined}
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
