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
        replace_automatic!(plot, :highclip) do
            lift(plot.colormap) do cmap
                return to_colormap(cmap)[end]
            end
        end
        replace_automatic!(plot, :lowclip) do
            lift(plot.colormap) do cmap
                return to_colormap(cmap)[1]
            end
        end
        return true
    else
        delete!(plot, :highclip)
        delete!(plot, :lowclip)
        delete!(plot, :colorrange)
        return false
    end
end

function calculated_attributes!(::Type{<: Mesh}, plot)
    need_cmap = color_and_colormap!(plot)
    need_cmap || delete!(plot, :colormap)
    attributes = plot.attributes
    color = lift(to_color, attributes.color)
    interp = to_value(pop!(attributes, :interpolation, true))
    interp = interp ? :linear : :nearest
    needs_uv = false
    if to_value(color) isa Colorant
        attributes[:vertex_color] = color
        delete!(attributes, :color_map)
        delete!(attributes, :color_norm)
    elseif to_value(color) isa Makie.AbstractPattern
        img = lift(to_image, color)
        attributes[:image] = ShaderAbstractions.Sampler(img, x_repeat=:repeat, minfilter=:nearest)
        get!(attributes, :fetch_pixel, true)
        needs_uv = true
    elseif to_value(color) isa AbstractMatrix{<:Colorant}
        attributes[:image] = ShaderAbstractions.Sampler(lift(to_color, color), minfilter = interp)
        delete!(attributes, :color_map)
        delete!(attributes, :color_norm)
        needs_uv = true
    elseif to_value(color) isa AbstractMatrix{<: Number}
        attributes[:image] = ShaderAbstractions.Sampler(lift(el32convert, color), minfilter = interp)
        needs_uv = true
    elseif to_value(color) isa AbstractVector{<: Union{Number, Colorant}}
        attributes[:vertex_color] = color
    end
    replace_automatic!(plot, :normals) do
        return plot.shading[] ? lift(decompose_normals, plot.mesh) : nothing
    end
    replace_automatic!(plot, :texturecoordinates) do
        return needs_uv ? lift(decompose_uv, plot.mesh) : Vec2f(0)
    end

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
        lift(x-> to_2d_scale(map(x-> x .* -0.5f0, x)), plot[:markersize])
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
    return (P, values(convert_arguments_typed(P, x...)))
end

"""
apply for return type PlotSpec
"""
function apply_convert!(P, attributes::Attributes, x::PlotSpec{S}) where S
    args, kwargs = x.args, x.kwargs
    # Note that kw_args in the plot spec that are not part of the target plot type
    # will end in the "global plot" kw_args (rest)
    for (k, v) in pairs(kwargs)
        # Don't set value when automatic, to leave it up to the theme etc
        if !(v isa Automatic)
            attributes[k] = v
        end
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

## generic definitions
# If the PlotObject has no plot func, calculate them
plottype(::Type{<: PlotObject}, argvalues...) = plottype(argvalues...)
## specialized definitions for types
plottype(::AbstractVector, ::AbstractVector, ::AbstractVector) = Scatter
plottype(::AbstractVector, ::AbstractVector) = Scatter
plottype(::AbstractVector) = Scatter
plottype(::AbstractMatrix{<: Real}) = Heatmap
plottype(::Array{<: AbstractFloat, 3}) = Volume
plottype(::AbstractString) = Text

# plottype(::LineString) = Lines
# plottype(::AbstractVector{<:LineString}) = Lines
# plottype(::MultiLineString) = Lines

plottype(::Polygon) = Poly
plottype(::GeometryBasics.AbstractPolygon) = Poly
plottype(::AbstractVector{<:GeometryBasics.AbstractPolygon}) = Poly
# plottype(::MultiPolygon) = Lines

# all the plotting functions that get a plot type
const PlotFunc = Union{Type{Any}, Type{<: AbstractPlot}}

function PlotObject(::Type{PlotType}, args::Vector{Any}, kw::Dict{Symbol, Any}) where {PlotType <: AbstractPlot}
    t = Transformation()
    plot = PlotObject(
        PlotType,
        t,
        # Unprocessed arguments directly from the user command e.g. `plot(args...; kw...)``
        kw,
        args,
    )
    plot[:model] = transformationmatrix(t)
    return plot
end
