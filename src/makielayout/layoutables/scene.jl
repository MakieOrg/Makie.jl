function Makie.plot!(
        lscene::LScene, P::Makie.PlotFunc,
        attributes::Makie.Attributes, args...;
        kw_attributes...)

    # We store the show_axis attribute in the LScene
    if haskey(attributes, :show_axis)
        lscene.attributes[:show_axis] = pop!(attributes, :show_axis)
    end

    show_axis = get!(lscene.attributes, :show_axis, true)
    plot = Makie.plot!(lscene.scene, P, attributes, args...; kw_attributes...)

    if isnothing(lscene.scene[OldAxis])
        # Add axis on first plot!, if requested
        to_value(show_axis) && Makie.axis3d!(lscene.scene)
    else
        # Update limits when plotting new objects
        axis_plot = lscene.scene[OldAxis]
        lims = data_limits(lscene.scene, Makie.isaxis)
        axis_plot[1] = lims
    end
    # Make sure axis is always in pos 1
    sort!(lscene.scene.plots, by=!Makie.isaxis)
    center!(lscene.scene)
    plot
end

function Makie.plot!(P::Makie.PlotFunc, ls::LScene, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    Makie.plot!(ls, P, attributes, args...)
end


function layoutable(::Type{LScene}, fig_or_scene; bbox = nothing, scenekw = NamedTuple(), kwargs...)

    topscene = get_topscene(fig_or_scene)

    default_attrs = default_attributes(LScene, topscene).attributes
    theme_attrs = subtheme(topscene, :LScene)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    layoutobservables = LayoutObservables{LScene}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        attrs.halign, attrs.valign, attrs.alignmode; suggestedbbox = bbox)
    # pick a camera and draw axis.
    scenekw = merge((clear = false,), scenekw)
    scene = Scene(topscene, lift(round_to_IRect2D, layoutobservables.computedbbox); scenekw...)
    return LScene(fig_or_scene, layoutobservables, attrs, Dict{Symbol, Any}(), scene)
end

function Base.delete!(ax::LScene, plot::AbstractPlot)
    delete!(ax.scene, plot)
    ax
end

can_be_current_axis(ls::LScene) = true
