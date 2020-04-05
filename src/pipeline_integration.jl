import Plots
using Plots.RecipePipeline

# Define overrides for RecipesPipeline hooks.

RecipesBase.apply_recipe(plotattributes::Plots.AKW, ::Type{T}, ::AbstractPlotting.Scene) where T = throw(MethodError("Unmatched plot type: $T"))

# Allow a series type to be plotted.
RecipePipeline.is_seriestype_supported(sc::Scene, st) = haskey(makie_seriestype_map, st)

# Forward the argument preprocessing to Plots for now.
RecipePipeline.series_defaults(sc::Scene, args...) = Dict{Symbol, Any}()

# Pre-processing of user recipes
function RecipePipeline.process_userrecipe!(sc::Scene, kw_list, kw)
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
function RecipePipeline.get_axis_limits(sc::Scene, f, letter)
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
slice_arg(wrapper::Plots.InputWrapper, idx) = wrapper.obj
slice_arg(v, idx) = v

# function RecipePipeline.slice_series_attributes!(sc::Scene, kw_list, kw)
#     idx = Int(kw[:series_plotindex]) - Int(kw_list[1][:series_plotindex]) + 1
#
#     for k in keys(Plots._series_defaults)
#         if haskey(kw, k)
#         end
#     end
# end

# Utilities
function from_nansep_vec(v::Vector{T}) where T
    idxs = findall(isnan, v)
    vs = Vector{Vector{T}}(undef, length(idxs))
    prev = 1
    num = 1
    for i in idxs
        vs[num] = v[prev:i-1]

        prev = i + 1
        num += 1
    end

    return vs
end

# Series type conversions

"""
    makie_plottype(st::Symbol)

Returns the Makie plot type which corresponds to the given seriestype.
The plot type is returned as a Type (`Lines`, `Scatter`, ...).
"""
function makie_plottype(st::Symbol)
    return get(makie_seriestype_map, st, AbstractPlotting.Lines)
end

function makie_args(::Union{Type{AbstractPlotting.Scatter}, Type{AbstractPlotting.Lines}}, plotattributes)
    if !isnothing(get(plotattributes, :z, nothing))
        return (plotattributes[:x], plotattributes[:y], plotattributes[:z])
    else
        return (plotattributes[:x], plotattributes[:y])
    end
end

makie_args(::Union{Type{AbstractPlotting.Surface},Type{AbstractPlotting.Heatmap}}, plotattributes) = (plotattributes[:x], plotattributes[:y], plotattributes[:z].surf)

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
    if st == :path || st == :path3d
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
        pa[:markersize] = get(pa, :markersize, 5) / 10
    elseif st == :surface
        haskey(pa, :fill_z) && (pa[:color] = pa[:fill_z])
    else
        # some default transformations
    end

end

########################################
#      The real plotting function      #
########################################

function set_series_color!(scene, st, plotattributes)

    if get(plotattributes, :seriescolor, :match) == :match
        delete!(plotattributes, :seriescolor)
    end

    plts = filter(scene.plots) do plot
        !(plot isa Union{AbstractPlotting.Heatmap, AbstractPlotting.Surface, AbstractPlotting.Image, AbstractPlotting.Spy, AbstractPlotting.Axis2D, AbstractPlotting.Axis3D})
    end

    if length(plts) == 0
        get!(plotattributes, :seriescolor, AbstractPlotting.wong_colors[2])
        return nothing
    elseif length(plts) == 1
        get!(plotattributes, :seriescolor, AbstractPlotting.wong_colors[1])
        return nothing
    end

    get!(plotattributes, :seriescolor, AbstractPlotting.wong_colors[length(plts)])

    return nothing

end

function plot_series_annotations!(plt, args, pt, plotattributes)

    sa = plotattributes[:series_annotations]

    @show sa pt

    positions = Point2f0.(plotattributes[:x], plotattributes[:y])

    strs = sa[1]

    bbox_shape = sa[2]

    fontsize = sa[3]

    annotations!(plt, strs, positions; textsize = fontsize/30, align = (:center, :center))

end

# Add the "series" to the Scene.
function RecipePipeline.add_series!(plt::Scene, plotattributes)

    # kys = filter((x -> x !∈ (:plot_object, :x, :y)), keys(plotattributes))
    # vals = getindex.(Ref(plotattributes), kys)
    # fpa = Dict{Symbol, Any}(kys .=> vals)
    # @show fpa

    # extract the seriestype
    st = plotattributes[:seriestype]

    if st != :scatter
        @debug "I hope you know what you're doing?"
    end

    set_series_color!(plt, st, plotattributes)

    pt = makie_plottype(st)

    theme = AbstractPlotting.default_theme(plt, pt)

    translate_to_makie!(st, plotattributes)

    # plot_fillrange!(plt, st, plotattributes)


    args = makie_args(pt, plotattributes)

    for (k, v) in pairs(plotattributes)
        isnothing(v) && delete!(plotattributes, k)
    end

    # @show plotattributes

    # @infiltrate

    ap_attrs = copy(plotattributes)
    for (k, v) in pairs(ap_attrs)
        haskey(theme, k) || delete!(ap_attrs, k)
    end

    # @infiltrate

    AbstractPlotting.plot!(plt, pt, AbstractPlotting.Attributes(ap_attrs), args...)

    # handle series annotations after, so they can overdraw
    !isnothing(get(plotattributes, :series_annotations, nothing)) && plot_series_annotations!(plt, args, pt, plotattributes)


    return plt
end


# Examples


# sc = Scene()
#
# # AbstractPlotting.scatter!(sc, rand(10))
# sc = Scene()
# RecipePipeline.recipe_pipeline!(sc, Dict{Symbol, Any}(:seriestype => :scatter), (1:10, rand(10, 2)))
#
# RecipePipeline.recipe_pipeline!(sc, Dict(:color => :blue, :seriestype => :path), (1:10, rand(10, 1)))
#
# RecipePipeline.recipe_pipeline!(sc, Dict(:seriestype => :scatter), (1:10, rand(10, 2)))
#
#
# using DifferentialEquations, RecipePipeline, Makie
# import Plots # we need some recipes from here
#
# f(u,p,t) = 1.01.*u
# u0 = [1/2, 1]
# tspan = (0.0,1.0)
# prob = ODEProblem(f,u0,tspan)
# sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(), (sol,))


# A  = [1. 0  0 -5
#       4 -2  4 -3
#      -4  0  0  1
#       5 -2  2  3]
# u0 = rand(4,2)
# tspan = (0.0,1.0)
# f(u,p,t) = A*u
# prob = ODEProblem(f,u0,tspan)
# sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(), (sol,))
#
# f(du,u,p,t) = (du .= u)
# g(du,u,p,t) = (du .= u)
# u0 = rand(4,2)
#
# W = WienerProcess(0.0,0.0,0.0)
# prob = SDEProblem(f,g,u0,(0.0,1.0),noise=W)
# sol = solve(prob,SRIW1())
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(), (sol,))


# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:seriestype => :surface, :cgrad => :inferno), (rand(10, 10),))
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:seriestype => :heatmap), (rand(10, 10),))

# # Phylogenetic tree
# using Phylo
# hummer = open(t -> parsenewick(t, NamedPolytomousTree), "/Users/Anshul/Downloads/hummingbirds.tree")
# evolve(tree) = Phylo.map_depthfirst((val, node) -> val + randn(), 0., tree, Float64)
# trait = evolve(hummer)
#
# scp = RecipePipeline.recipe_pipeline!(Scene(scale_plot = false, show_axis = false), Dict{Symbol, Any}(:treetype=>:fan, :line_z => trait, :linewidth => 5, :showtips => false, :cgrad => :RdYlBu, :seriestype => :path), (hummer,))

# # Timeseries with market data
# using MarketData, TimeSeries
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:seriestype => :path), (MarketData.ohlc,))

# # Julia AST with GraphRecipes
# using GraphRecipes
#
# code = quote
#     function mysum(list)
#         out = 0
#         for value in list
#             out += value
#         end
#         out
#     end
# end
#
# plot(code, fontsize=12, shorten=0.01, axis_buffer=0.15, nodeshape=:rect)
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:fontsize => 12, :shorten => 0.01, :axis_buffer => 0.15, :nodeshape => :rect), (code,))
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:method=>:tree, :fontsize=>10, :nodeshape=>:ellipse), (AbstractFloat,))

# # 
