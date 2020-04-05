using RecipePipeline
import Plots
# Define overrides for RecipesPipeline hooks.

function RecipePipeline._recipe_init!(sc::Scene, plotattributes, args)
    @info "Init"
end

function RecipePipeline._recipe_after_user!(sc::Scene, plotattributes, args)
    @info "User complete"
end

function RecipePipeline._recipe_after_plot!(sc::Scene, plotattributes, args)
    @info "Plot complete"
end

function RecipePipeline._recipe_before_series!(sc::Scene, plotattributes, args)
    @info "Series initializing"
    return plotattributes
end

function RecipePipeline._recipe_finish!(sc::Scene, plotattributes, args)
    @info "Finished!"
    return sc
end

RecipePipeline._process_userrecipe(plt::Scene, kw_list, recipedata) = RecipePipeline._process_userrecipe(Plots.Plot(), kw_list, recipedata)

RecipePipeline.RecipesBase.apply_recipe(plotattributes::Plots.AKW, ::Type{T}, ::AbstractPlotting.Scene) where T = throw(MethodError("Unmatched plot type: $T")) # TODO: loosen this restriction and move to RecipesBase


# Allow a series type to be plotted.

RecipePipeline.is_st_supported(sc::Scene, st) = haskey(makie_seriestype_map, st)

RecipePipeline._preprocess_args(sc::Scene, args...) = RecipePipeline._preprocess_args(Plots.Plot(), args...)

########################################
#       Series argument slicing        #
########################################

function slice_arg(v::AbstractMatrix, idx::Int)
    c = mod1(idx, size(v,2))
    m, n = axes(v)
    size(v, 1) == 1 ? v[first(m), n[c]] : v[:, n[c]]
end

# slice_arg(wrapper::InputWrapper, idx) = wrapper.obj

slice_arg(v, idx) = v


function makie_plottype(st::Symbol)
    return get(makie_seriestype_map, st, AbstractPlotting.Lines)
end

function makie_args(::Union{Type{AbstractPlotting.Scatter}, Type{AbstractPlotting.Lines}}, plotattributes)
    if haskey(plotattributes, :z)
        return (plotattributes[:x], plotattributes[:y], plotattributes[:z])
    else
        return (plotattributes[:x], plotattributes[:y])
    end
end

makie_args(::Union{Type{AbstractPlotting.Surface},Type{AbstractPlotting.Heatmap}}, plotattributes) = (plotattributes[:x], plotattributes[:y], plotattributes[:z].surf)


function translate_to_makie!(st, pa)
    if st == :path || st == :path3d
        if !isnothing(get!(pa, :line_z, nothing))
            pa[:color] = pa[:line_z]
        elseif !isnothing(get!(pa, :linecolor, nothing))
            pa[:color] = pa[:linecolor]
        elseif !isnothing(get!(pa, :seriescolor, nothing))
            pa[:color] = pa[:seriescolor]
        end
        pa[:linewidth] = get(pa, :linesize, 5)
    elseif st == :scatter
        if !isnothing(get!(pa, :marker_z, nothing))
            pa[:color] = pa[:marker_z]
        elseif !isnothing(get!(pa, :markercolor, nothing))
            pa[:color] = pa[:markercolor]
        elseif !isnothing(get!(pa, :seriescolor, nothing))
            pa[:color] = pa[:seriescolor]
        end
        pa[:markersize] = get(pa, :markersize, 5)
    else
        # some default transformations
    end
end

########################################
#      The real plotting function      #
########################################

function set_series_color!(scene, st, plotattributes)

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

# TODO this only works for scatter
function RecipePipeline.add_series!(plt::Scene, plotattributes)

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

    for (k, v) in pairs(plotattributes)
        isnothing(v) && delete!(plotattributes, k)
    end

    args = makie_args(pt, plotattributes)

    # @show plotattributes

    # @infiltrate

    for (k, v) in pairs(plotattributes)
        haskey(theme, k) || delete!(plotattributes, k)
    end

    # @infiltrate

    AbstractPlotting.plot!(plt, pt, AbstractPlotting.Attributes(plotattributes), args...)

    return plt
end


# Examples


# sc = Scene()
#
# # AbstractPlotting.scatter!(sc, rand(10))
# RecipePipeline.recipe_pipeline!(sc, Dict(:seriestype => :scatter), (1:10, rand(10, 2)))
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


# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:seriestype => :surface), (rand(10, 10),))
#
# RecipePipeline.recipe_pipeline!(Scene(), Dict{Symbol, Any}(:seriestype => :heatmap), (rand(10, 10),))
