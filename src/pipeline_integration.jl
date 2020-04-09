# # RecipesPipeline API implementation

# ## Types and aliases

const PlotContext = Union{
                    AbstractPlotting.AbstractScene,
                    AbstractPlotting.AbstractPlot,
                    MakieLayout.LAxis
                }

# ## Utilities

expand_palette(palette; kwargs...) = RGBA.(distinguishable_colors(20, palette; kwargs...))


const wong = copy(AbstractPlotting.wong_colors)
begin
    global wong
    tmp = wong[1]
    wong[1] = wong[2]
    wong[2] = wong[1]
end
const rwong = expand_palette(wong; lchoices = [57], cchoices = [100])


# ## API implementation

# Define overrides for RecipesPipeline hooks.

RecipesBase.apply_recipe(plotattributes, ::Type{T}, ::PlotContext) where T = throw(MethodError("Unmatched plot type: $T"))

# Allow a series type to be plotted.
RecipesPipeline.is_seriestype_supported(sc::PlotContext, st) = haskey(makie_seriestype_map, st)

# Forward the argument preprocessing to Plots for now.
RecipesPipeline.series_defaults(sc::PlotContext, args...) = Dict{Symbol, Any}()

# Pre-processing of user recipes
function RecipesPipeline.process_userrecipe!(sc::PlotContext, kw_list, kw)
    if isa(get(kw, :marker_z, nothing), Function)
        # TODO: should this take y and/or z as arguments?
        kw[:marker_z] = isa(kw[:z], Nothing) ? map(kw[:marker_z], kw[:x], kw[:y]) :
            map(kw[:marker_z], kw[:x], kw[:y], kw[:z])
    end

    # map line_z if it's a Function
    if isa(get(kw, :line_z, nothing), Function)
        kw[:line_z] = isa(kw[:z], Nothing) ? map(kw[:line_z], kw[:x], kw[:y]) :
            map(kw[:line_z], kw[:x], kw[:y], kw[:z])
    end

    push!(kw_list, kw)
end

# Determine axis limits
function RecipesPipeline.get_axis_limits(sc::PlotContext, f, letter)
    lims = to_value(AbstractPlotting.data_limits(sc))
    i = if letter === :x
            1
        elseif letter === :y
            2
        elseif letter === :z
            3
        else
            throw(ArgumentError("Letter $letter does not correspond to an axis."))
        end

    o = origin(lims)
    return (o[i], o[i] + widths(lims)[i])
end

########################################
#       Series argument slicing        #
########################################

function slice_arg(v::AbstractMatrix, idx::Int)
    c = mod1(idx, size(v,2))
    m,n = axes(v)
    size(v,1) == 1 ? v[first(m),n[c]] : v[:,n[c]]
end
# slice_arg(wrapper::Plots.InputWrapper, idx) = wrapper.obj
slice_arg(v, idx) = v

# function RecipesPipeline.slice_series_attributes!(sc::PlotContext, kw_list, kw)
#     idx = Int(kw[:series_plotindex]) - Int(kw_list[1][:series_plotindex]) + 1
#
#     for k in keys(Plots._series_defaults)
#         if haskey(kw, k)
#         end
#     end
# end

# Series type conversions

"""
    makie_plottype(st::Symbol)

Returns the Makie plot type which corresponds to the given seriestype.
The plot type is returned as a Type (`Lines`, `Scatter`, ...).
"""
function makie_plottype(st::Symbol)
    return get(makie_seriestype_map, st, AbstractPlotting.Lines)
end

makie_args(::Type{T}, plotattributes) where T <: AbstractPlotting.AbstractPlot = makie_args(AbstractPlotting.conversion_trait(T), plotattributes)

function makie_args(::AbstractPlotting.PointBased, plotattributes)

    x, y = (plotattributes[:x], plotattributes[:y])
    c = plotattributes[:color]

    if isempty(x) && isempty(y)
        return
    end

    if !isnothing(get(plotattributes, :z, nothing))
        return (plotattributes[:x], plotattributes[:y], plotattributes[:z])
    else
        return (plotattributes[:x], plotattributes[:y])
    end
end

# TODO use Makie.plottype
makie_args(::AbstractPlotting.SurfaceLike, plotattributes) = (plotattributes[:x], plotattributes[:y], plotattributes[:z].surf)

makie_args(::Type{<: Contour}, plotattributes) = (plotattributes[:x], plotattributes[:y], plotattributes[:z].surf)

function makie_args(::Type{<: AbstractPlotting.Poly}, plotattributes)
    return (from_nansep_vec(Point2f0.(plotattributes[:x], plotattributes[:y])),)
end

function translate_to_makie!(st, pa)

    # general translations first

    # handle colormap
    haskey(pa, :cgrad) && (pa[:colormap] = pa[:cgrad])

    # series color population
    haskey(pa, :seriescolor) && (pa[:color] = pa[:seriescolor])

    # series color
    if st ∈ (:path, :path3d, :curves)
        if !isnothing(get!(pa, :line_z, nothing))
            pa[:color] = pa[:line_z]
        elseif !isnothing(get!(pa, :linecolor, nothing))
            pa[:color] = pa[:linecolor]
        elseif !isnothing(get!(pa, :seriescolor, nothing))
            pa[:color] = pa[:seriescolor]
        end
        pa[:linewidth] = get(pa, :linewidth, 1)

    elseif st == :scatter
        if !isnothing(get!(pa, :marker_z, nothing))
            pa[:color] = pa[:marker_z]
        elseif !isnothing(get!(pa, :markercolor, nothing))
            pa[:color] = pa[:markercolor]
        elseif !isnothing(get!(pa, :seriescolor, nothing))
            pa[:color] = pa[:seriescolor]
        end
        pa[:markersize] = get(pa, :markersize, 5) * 5 * AbstractPlotting.px

    elseif st ∈ (:surface, :heatmap, :image)
        haskey(pa, :fill_z) && (pa[:color] = pa[:fill_z])
        pa[:shading] = false # set shading to false, default in Plots
    elseif st === :contour
        # pa[:levels] = pa[:levels]
    elseif st === :bar
        haskey(pa, :widths) && (pa[:width] = pa[:widths])
    else
        # some default transformations
    end

end

########################################
#      The real plotting function      #
########################################

function set_series_color!(scene, st, plotattributes)

    if haskey(plotattributes, :seriescolor)
        if plotattributes[:seriescolor] ∈ (:match, :auto)
            delete!(plotattributes, :seriescolor)
        else
            return nothing
        end
    end

    plts = filter(scene.plots) do plot
        !(plot isa Union{AbstractPlotting.Heatmap, AbstractPlotting.Surface, AbstractPlotting.Image, AbstractPlotting.Spy, AbstractPlotting.Axis2D, AbstractPlotting.Axis3D})
    end

    get!(plotattributes, :seriescolor, get(plotattributes, :palette, rwong)[length(plts) + 1])

    return nothing

end

function plot_series_annotations!(plt, args, pt, plotattributes)

    sa = plotattributes[:series_annotations]

    positions = Point2f0.(plotattributes[:x], plotattributes[:y])

    strs = sa[1]

    bbox_shape = sa[2]

    fontsize = sa[3]

    annotations!(plt, strs, positions; textsize = fontsize/30, align = (:center, :center))

end

function plot_fill!(plt, args, pt, plotattributes)
    lowerval, opacity, color = plotattributes[:fill]
    upper = plotattributes[:y]
    x = plotattributes[:x]

    lower = fill(lowerval, size(x))

    c = AbstractPlotting.to_color(color)
    bandcolor = RGBA(red(c), green(c), blue(c), alpha(c) * opacity)

    band!(plt, x, upper, lower; color = bandcolor)
end

# Add the "series" to the Scene.
function RecipesPipeline.add_series!(plt::PlotContext, plotattributes)

    # kys = filter((x -> x !∈ (:plot_object, :x, :y)), keys(plotattributes))
    # vals = getindex.(Ref(plotattributes), kys)
    # fpa = Dict{Symbol, Any}(kys .=> vals)

    # extract the seriestype
    st = plotattributes[:seriestype]

    set_series_color!(plt, st, plotattributes)

    pt = makie_plottype(st)

    theme = AbstractPlotting.default_theme(plt, pt)

    translate_to_makie!(st, plotattributes)

    args = makie_args(pt, plotattributes)

    for (k, v) in pairs(plotattributes)
        isnothing(v) && delete!(plotattributes, k)
    end

    ap_attrs = copy(plotattributes)
    for (k, v) in pairs(ap_attrs)
        haskey(theme, k) || delete!(ap_attrs, k)
    end

    # @infiltrate

    if args === nothing
        @debug "Found an empty series with type $(plotattributes[:seriestype])."
        return plt
    end

    AbstractPlotting.plot!(plt, pt, AbstractPlotting.Attributes(ap_attrs), args...)

    # handle fill and series annotations after, so they can overdraw

    !isnothing(get(plotattributes, :fill, nothing)) && plot_fill!(plt, args, pt, plotattributes)

    !isnothing(get(plotattributes, :series_annotations, nothing)) && plot_series_annotations!(plt, args, pt, plotattributes)

    return plt
end
