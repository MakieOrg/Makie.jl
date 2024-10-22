
function add_cycle_attribute!(plot::Plot, scene::Scene, cycle=get_cycle_for_plottype(plot.cycle[]))
    cycler = scene.cycler
    palette = scene.theme.palette
    add_cycle_attributes!(plot, cycle, cycler, palette)
    return
end

function color_and_colormap!(plot, colorsym = plot.color)
    scene = parent_scene(plot)
    if !isnothing(scene) && haskey(plot, :cycle)
        add_cycle_attribute!(plot, scene)
    end
    on(plot, colorsym, :colormap, :colorrange) do changed
        color = plot[][colorsym]

    colors = assemble_colors(colors[], colors, plot)
    plot.computed[:color] = colors
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
    lines, surface, volume, heatmap, image, voxels
)
const Atomic{Arg} = Union{map(x-> Plot{x, Arg}, atomic_functions)...}

function get_kw_values(func, names, kw)
    return [Pair{Symbol,Any}(k, func(kw[k]))
            for k in names if haskey(kw, k)]
end

function get_kw_obs(names, kw)
    isempty(names) && return Observable(Pair{Symbol, Any}[])
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


"""
    expand_dimensions(plottrait, plotargs...)

Expands the dims for e.g. `scatter(1:4)` becoming `scatter(1:4, 1:4)` for 2D plots.
We're separating this state from convert_arguments, to better apply `dim_converts` before convert_arguments.
"""
expand_dimensions(trait, args...) = nothing

expand_dimensions(::PointBased, y::VecTypes) = nothing # VecTypes are nd points
expand_dimensions(::PointBased, y::RealVector) = (keys(y), y)
expand_dimensions(::PointBased, y::OffsetVector{<:Real}) =
    (OffsetArrays.no_offset_view(keys(y)), OffsetArrays.no_offset_view(y))

function expand_dimensions(::Union{ImageLike, GridBased}, data::AbstractMatrix{<:Union{<:Real, <:Colorant}})
    # Float32, because all ploteable sizes should fit into float32
    x, y = map(x-> (0f0, Float32(x)), size(data))
    return (x, y, data)
end

function expand_dimensions(::Union{CellGrid, VertexGrid}, data::AbstractMatrix{<:Union{<:Real,<:Colorant}})
    x, y = map(x-> (1f0, Float32(x)), size(data))
    return (x, y, data)
end

function expand_dimensions(::VolumeLike, data::RealArray{3})
    x, y, z = map(x-> (0f0, Float32(x)), size(data))
    return (x, y, z, data)
end

function got_converted(P::Type, PTrait::ConversionTrait, result)
    if result isa Union{PlotSpec,BlockSpec,GridLayoutSpec,AbstractVector{PlotSpec}}
        return SpecApi
    end
    types = MakieCore.types_for_plot_arguments(P, PTrait)
    if !isnothing(types)
        return result isa types
    end
    return nothing
end

"""
    conversion_pipeline(P::Type{<:Plot}, used_attrs::Tuple, args::Tuple,
        args_obs::Tuple, user_attributes::Dict{Symbol, Any}, deregister, recursion=1)

The main conversion pipeline for converting arguments for a plot type.
Applies dim_converts, expand_dimensions (in `try_dim_convert`), convert_arguments and checks if the conversion was successful.
"""
function conversion_pipeline(P, user_args::Tuple, user_attributes::Dict, used_attrs,
        PTrait=conversion_trait(P, user_args...),
        recursion=1
    )
    expanded_args = expand_dimensions(PTrait, user_args...)
    args = isnothing(expanded_args) ? user_args : expanded_args
    kw = [k => user_attributes[k] for k in used_attrs if haskey(user_attributes, k)]
    converted = convert_arguments(P, args...; kw...)
    status = got_converted(P, PTrait, converted)
    @show args converted
    if status === true
        # We're done converting!
        return converted
    elseif status === SpecApi
        return converted
    elseif status === false
        if recursion === 1
            # We haven't reached a target type, so we try to apply convert arguments again and try_dim_convert
            # This is the case for e.g. convert_arguments returning types that need dim_convert
            return conversion_pipeline(P, converted, user_attributes, used_attrs, PTrait, recursion + 1)
        else # recursion > 1
            kw_str = isempty(kw) ? "" : " and kw: $(typeof(kw))"
            kw_convert = isempty(kw) ? "" : "; kw..."
            conv_trait = PTrait isa NoConversion ? "" : " (With conversion trait $(PTrait))"
            types = MakieCore.types_for_plot_arguments(P, PTrait)
            throw(ArgumentError("""
                Conversion failed for $(P)$(conv_trait) with args: $(typeof(user_args)) $(kw_str).
                $(P) requires to convert to argument types $(types), which convert_arguments didn't succeed in.
                To fix this overload convert_arguments(P, args...$(kw_convert)) for $(P) or $(PTrait) and return an object of type $(types).`
            """))
        end
    elseif isnothing(status)
        # No types_for_plot_arguments defined, so we don't know what we need to convert to.
        # This is for backwards compatibility for recipes that don't define argument types
        return converted
    else
        error("Unknown status: $(status)")
    end
    return
end


function Plot{Func}(user_args::Tuple, user_attributes::Dict) where {Func}
    # Handle plot!(plot, attributes::Attributes, args...) here
    if !isempty(user_args) && first(user_args) isa Attributes
        attr = attributes(first(user_args))
        merge!(user_attributes, attr)
        return Plot{Func}(Base.tail(user_args), user_attributes)
    end
    P = Plot{Func}
    args = map(to_value, user_args)
    attr = used_attributes(P, args...)
    converted = conversion_pipeline(P, args, user_attributes, attr)
    ArgTyp = MakieCore.argtypes(converted)
    FinalPlotFunc = plotfunc(plottype(P, converted...))

    return Plot{FinalPlotFunc,ArgTyp}(user_attributes, user_args, converted)
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


clip_planes_obs(parent::AbstractPlot) = attributes(parent).clip_planes
clip_planes_obs(parent::Scene) = parent.theme[:clip_planes]

# all the plotting functions that get a plot type
const PlotFunc = Type{<:AbstractPlot}

function plot!(::Plot{F, Args}) where {F, Args}
    if !(F in atomic_functions)
        error("No recipe for $(F) with args: $(Args)")
    end
end

function connect_plot!(parent::SceneLike, plot::Plot{F}) where {F}
    plot.parent = parent
    scene = parent_scene(parent)
    apply_theme!(scene, plot)
    t_user = to_value(get(plot.input, :transformation, automatic))
    if t_user isa Transformation
        plot.transformation = t_user
    else
        if t_user isa Union{Nothing, Automatic}
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

    if to_value(get(plot.input, :clip_planes, automatic)) === automatic
        plot.input[:clip_planes] = map(identity, plot, clip_planes_obs(parent))
    end

    plot!(plot)

    conversions = get_conversions(plot)
    if !isnothing(conversions)
        connect_conversions!(scene.conversions, conversions)
    end
    return plot
end

function plot!(scene::SceneLike, plot::Plot)
    connect_plot!(scene, plot)
    push!(scene, plot)
    return plot
end

function apply_theme!(scene::Scene, plot::P) where {P<: Plot}
    raw_attr = plot.computed
    plot_theme = default_theme(scene, P)
    plot_sym = plotsym(P)
    if haskey(theme(scene), plot_sym)
        merge_without_obs_reverse!(plot_theme, theme(scene, plot_sym))
    end

    for (k, v) in plot.input
        if v isa NamedTuple
            raw_attr[k] = Attributes(v)
        else
            raw_attr[k] = convert(Observable{Any}, v)
        end
    end
    return merge!(plot.computed, plot_theme.attributes)
end
