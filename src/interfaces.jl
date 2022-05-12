function default_theme(scene)
    Attributes(
        # color = theme(scene, :color),
        linewidth = 1,
        transformation = automatic,
        model = automatic,
        visible = true,
        transparency = false,
        overdraw = false,
        diffuse = Vec3f(0.4),
        specular = Vec3f(0.2),
        shininess = 32f0,
        nan_color = RGBAf(0,0,0,0),
        ssao = false,
        inspectable = theme(scene, :inspectable),
        depth_shift = 0f0,
        space = :data
    )
end

function color_and_colormap!(plot, intensity = plot[:color])
    if isa(intensity[], AbstractArray{<: Number})
        haskey(plot, :colormap) || error("Plot $(typeof(plot)) needs to have a colormap to allow the attribute color to be an array of numbers")

        replace_automatic!(plot, :colorrange) do
            lift(distinct_extrema_nan, intensity)
        end
        return true
    else
        delete!(plot, :colorrange)
        return false
    end
end

function calculated_attributes!(::Type{<: Mesh}, plot)
    need_cmap = color_and_colormap!(plot)
    need_cmap || delete!(plot, :colormap)
    return
end

function calculated_attributes!(::Type{<: Union{Heatmap, Image}}, plot)
    plot[:color] = plot[3]
    color_and_colormap!(plot)
end

function calculated_attributes!(::Type{<: Surface}, plot)
    colors = plot[3]
    if haskey(plot, :color)
        color = plot[:color][]
        if isa(color, AbstractMatrix{<: Number}) && !(color === to_value(colors))
            colors = plot[:color]
        end
    end
    color_and_colormap!(plot, colors)
end

function calculated_attributes!(::Type{<: MeshScatter}, plot)
    color_and_colormap!(plot)
end


function calculated_attributes!(::Type{<: Scatter}, plot)
    # calculate base case
    color_and_colormap!(plot)

    replace_automatic!(plot, :marker_offset) do
        # default to middle
        lift(x-> to_2d_scale(x .* (-0.5f0)), plot[:markersize])
    end

    replace_automatic!(plot, :markerspace) do
        lift(plot.markersize) do ms
            if ms isa Pixel || (ms isa AbstractVector && all(x-> ms isa Pixel, ms))
                return :pixel
            else
                return :data
            end
        end
    end
end

function calculated_attributes!(::Type{T}, plot) where {T<:Union{Lines, LineSegments}}
    color_and_colormap!(plot)
    pos = plot[1][]
    # extend one color/linewidth per linesegment to be one (the same) color/linewidth per vertex
    if T <: LineSegments
        for attr in [:color, :linewidth]
            # taken from @edljk  in PR #77
            if haskey(plot, attr) && isa(plot[attr][], AbstractVector) && (length(pos) ÷ 2) == length(plot[attr][])
                plot[attr] = lift(plot[attr]) do cols
                    map(i -> cols[(i + 1) ÷ 2], 1:(length(cols) * 2))
                end
            end
        end
    end
end

const atomic_function_symbols = (
    :text, :meshscatter, :scatter, :mesh, :linesegments,
    :lines, :surface, :volume, :heatmap, :image
)

const atomic_functions = getfield.(Ref(Makie), atomic_function_symbols)
const Atomic{Arg} = Union{map(x-> Combined{x, Arg}, atomic_functions)...}

function (PT::Type{<: Combined})(parent, transformation, attributes, input_args, converted)
    PT(parent, transformation, attributes, input_args, converted, AbstractPlot[])
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
    pt = plottype(P, x...)
    return (pt, values(convert_arguments_typed(pt, x...)))
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
    pt = plottype(S, P)
    return (pt, values(convert_arguments_typed(pt, args...)))
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

function (PlotType::Type{<: AbstractPlot{Typ}})(scene::SceneLike, attributes::Attributes, args) where Typ
    input = convert.(Observable, args)
    argnodes = lift(input...) do args...
        convert_arguments(PlotType, args...)
    end
    return PlotType(scene, attributes, input, argnodes)
end

function plot(scene::Scene, plot::AbstractPlot)
    # plot object contains local theme (default values), and user given values (from constructor)
    # fill_theme now goes through all values that are missing from the user, and looks if the scene
    # contains any theming values for them (via e.g. css rules). If nothing founds, the values will
    # be taken from local theme! This will connect any values in the scene's theme
    # with the plot values and track those connection, so that we can separate them
    # when doing delete!(scene, plot)!
    complete_theme!(scene, plot)
    # we just return the plot... whoever calls plot (our pipeline usually)
    # will need to push!(scene, plot) etc!
    return plot
end

function (PlotType::Type{<: AbstractPlot{Typ}})(scene::SceneLike, attributes::Attributes, input, args) where Typ
    # The argument type of the final plot object is the assumened to stay constant after
    # argument conversion. This might not always hold, but it simplifies
    # things quite a bit
    ArgTyp = typeof(to_value(args))
    # construct the fully qualified plot type, from the possible incomplete (abstract)
    # PlotType
    FinalType = Combined{Typ, ArgTyp}
    plot_attributes = merged_get!(
        ()-> default_theme(scene, FinalType),
        plotsym(FinalType), scene, attributes
    )

    # Transformation is a field of the plot type, but can be given as an attribute
    trans = get(plot_attributes, :transformation, automatic)
    transval = to_value(trans)
    transformation = if transval === automatic
        Transformation(scene)
    elseif isa(transval, Transformation)
        transval
    else
        t = Transformation(scene)
        transform!(t, transval)
        t
    end
    replace_automatic!(plot_attributes, :model) do
        transformation.model
    end
    # create the plot, with the full attributes, the input signals, and the final signals.
    plot_obj = FinalType(scene, transformation, plot_attributes, input, seperate_tuple(args))

    calculated_attributes!(plot_obj)
    plot_obj
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
const PlotFunc = Union{Type{Any}, Type{<: AbstractPlot}}


######################################################################

# plots to scene

"""
Main plotting signatures that plot/plot! route to if no Plot Type is given
"""
function plot!(P::PlotFunc, attributes::Attributes, scene::Union{Combined, SceneLike}, args...)
    argvalues = to_value.(args)
    PreType = plottype(P, argvalues...)
    # plottype will lose the argument types, so we just extract the plot func
    # type and recreate the type with the argument type
    PreType = Combined{plotfunc(PreType), typeof(argvalues)}
    convert_keys = intersect(used_attributes(PreType, argvalues...), keys(attributes))
    kw_signal = if isempty(convert_keys) # lift(f) isn't supported so we need to catch the empty case
        Observable(())
    else
        # Remove used attributes from `attributes` and collect them in a `Tuple` to pass them more easily
        lift((args...)-> Pair.(convert_keys, args), pop!.(attributes, convert_keys)...)
    end
    # call convert_arguments for a first time to get things started
    converted = convert_arguments(PreType, argvalues...; kw_signal[]...)
    # convert_arguments can return different things depending on the recipe type
    # apply_conversion deals with that!

    FinalType, argsconverted = apply_convert!(PreType, attributes, converted)
    converted_node = Observable(argsconverted)
    input_nodes =  convert.(Observable, args)
    onany(kw_signal, lift(tuple, input_nodes...)) do kwargs, args
        # do the argument conversion inside a lift
        result = convert_arguments(FinalType, args...; kwargs...)
        finaltype, argsconverted_ = apply_convert!(FinalType, attributes, result) # avoid a Core.Box (https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured)
        if finaltype != FinalType
            error("Plot type changed from $FinalType to $finaltype after conversion.
                Changing the plot type based on values in convert_arguments is not allowed"
            )
        end
        converted_node[] = argsconverted_
    end
    plot!(FinalType, attributes, scene, input_nodes, converted_node)
end

plot!(p::Combined) = _plot!(p)

_plot!(p::Atomic{T}) where T = p

function _plot!(p::Combined{fn, T}) where {fn, T}
    throw(PlotMethodError(fn, T))
end

struct PlotMethodError <: Exception
    fn
    T
end

function Base.showerror(io::IO, err::PlotMethodError)
    fn = err.fn
    T = err.T
    args = (T.parameters...,)
    typed_args = join(string.("::", args), ", ")

    print(io, "PlotMethodError: no ")
    printstyled(io, fn == Any ? "plot" : fn; color=:cyan)
    print(io, " method for arguments ")
    printstyled(io, "($typed_args)"; color=:cyan)
    print(io, ". To support these arguments, define\n  ")
    printstyled(io, "plot!(::$(Combined{fn,S} where {S<:T}))"; color=:cyan)
    print(io, "\nAvailable methods are:\n")
    for m in methods(plot!)
        if m.sig <: Tuple{typeof(plot!), Combined{fn}}
            println(io, "  ", m)
        end
    end
end

function show_attributes(attributes)
    for (k, v) in attributes
        println("    ", k, ": ", v[] == nothing ? "nothing" : v[])
    end
end

function plot!(P::PlotFunc, attributes::Attributes, scene::SceneLike, input::NTuple{N, Observable}, args::Observable) where {N}
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object = P(scene, copy(attributes), input, args)
    # transfer the merged attributes from theme and user defined to the scene
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene, plot_object)
    return plot_object
end

function plot!(P::PlotFunc, attributes::Attributes, scene::Combined, input::NTuple{N,Observable}, args::Observable) where {N}
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object = P(scene, attributes, input, args)
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)
    plot_object
end
