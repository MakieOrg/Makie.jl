function color_and_colormap!(plot, colors = plot.color)
    colors = assemble_colors(colors[], colors, plot)
    attributes(plot.attributes)[:calculated_colors] = colors
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
                plot[attr] = lift(plot, plot[attr]) do cols
                    map(i -> cols[(i + 1) ÷ 2], 1:(length(cols) * 2))
                end
            end
        end
    end
    color_and_colormap!(plot)
    return
end

const atomic_function_symbols = (
    :text, :meshscatter, :scatter, :mesh, :linesegments,
    :lines, :surface, :volume, :heatmap, :image
)

const atomic_functions = getfield.(Ref(Makie), atomic_function_symbols)
const Atomic{Arg} = Union{map(x-> Combined{x, Arg}, atomic_functions)...}

function Combined{Func, ArgTypes}(plot_attributes, args) where {Func, ArgTypes}
    trans = get!(plot_attributes, :transformation, automatic)
    transval = to_value(trans)
    transformation = if transval isa Automatic
        Transformation()
    elseif transval isa Transformation
        transval
    else
        t = Transformation()
        transform!(t, transval)
        t
    end
    plot = Combined{Func,ArgTypes}(transformation, plot_attributes, convert.(Observable, args))
    plot.model = transformationmatrix(transformation)
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

"""
apply for return type
    (args...,)
"""
function apply_convert!(P, attributes::Attributes, x::Tuple)
    return (plottype(P, x...), x)
end

"""
apply for return type PlotSpec
"""
function apply_convert!(P, attributes::Attributes, x::PlotSpec{S}) where S
    args, kwargs = x.args, x.kwargs
    # Note that kw_args in the plot spec that are not part of the target plot type
    # will end in the "global plot" kw_args (rest)
    for (k, v) in pairs(kwargs)
        attributes[k] = v
    end
    return (plottype(S, P), args)
end

function seperate_tuple(args::Observable{<: NTuple{N, Any}}) where N
    ntuple(N) do i
        lift(args) do x
            if i <= length(x)
                x[i]
            else
                error("You changed the number of arguments. This isn't allowed!")
            end
        end
    end
end

function plot(scene::Scene, plot::AbstractPlot)
    # plot object contains local theme (default values), and user given values (from constructor)
    # fill_theme now goes through all values that are missing from the user, and looks if the scene
    # contains any theming values for them (via e.gg. css rules). If nothing founds, the values will
    # be taken from local theme! This will connect any values in the scene's theme
    # with the plot values and track those connection, so that we can separate them
    # when doing delete!(scene, plot)!
    complete_theme!(scene, plot)
    # we just return the plot... whoever calls plot (our pipeline usually)
    # will need to push!(scene, plot) etc!
    return plot
end

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
plottype(P1::Type{<: Combined{Any}}, P2::Type{<: Combined{T}}) where T = P2
plottype(P1::Type{<: Combined{T}}, P2::Type{<: Combined}) where T = P1

# all the plotting functions that get a plot type
const PlotFunc = Union{Type{Any},Type{<:AbstractPlot}}


function plot!(plot::Combined{F}) where {F}
    if !(F in atomic_functions)
        error("No recipe for $(F)")
    end
end

function plot!(scene::SceneLike, plot::Combined)
    prepare_plot!(scene, plot)
    push!(scene, plot)
    return plot
end

function apply_theme!(scene::Scene, plot::Combined{F}) where {F}
    theme = default_theme(scene, Combined{F, Any})
    raw_attr = getfield(plot.attributes, :attributes)
    for (k, v) in plot.kw
        if v isa NamedTuple
            raw_attr[k] = Attributes(v)
        else
            raw_attr[k] = convert(Observable{Any}, v)
        end
    end
    return merge!(plot.attributes, theme)
end

function prepare_plot!(scene::SceneLike, plot::Combined{F}) where {F}
    plot.parent = scene
    # TODO, move transformation into attributes?
    # This hacks around transformation being already constructed in the constructor
    # So here we don't want to connect to the scene if an explicit Transformation was passed to the plot
    t = to_value(getfield(plot, :kw)[:transformation])
    if t isa Automatic
        connect!(transformation(scene), transformation(plot))
    end
    apply_theme!(parent_scene(scene), plot)
    convert_arguments!(plot)
    calculated_attributes!(Combined{F}, plot)
    plot!(plot)
    return plot
end

function MakieCore.argtypes(F, plot::PlotSpec{P}) where {P}
    args_converted = convert_arguments(P, plot.args...)
    return MakieCore.argtypes(plotfunc(P), args_converted)
end


function convert_arguments!(plot::Combined{F}) where F
    P = Combined{F, Any}
    function on_update(args...)
        nt = convert_arguments(P, args...)
        P, converted = apply_convert!(P, plot.attributes, nt)
        if isempty(plot.converted)
            # initialize the tuple first for when it was `()`
            plot.converted = Observable.(converted)
        end
        for (obs, new_val) in zip(plot.converted, converted)
            obs[] = new_val
        end
    end
    on_update(map(to_value, plot.args)...)
    onany(on_update, plot, plot.args...)
    return
end
