function AbstractPlotting.plot!(
        lscene::LScene, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(lscene.scene, P, attributes, args...; kw_attributes...)[end]

    plot
end

function AbstractPlotting.plot!(P::AbstractPlotting.PlotFunc, ls::LScene, args...; kw_attributes...)
    attributes = AbstractPlotting.Attributes(kw_attributes)
    AbstractPlotting.plot!(ls, P, attributes, args...)
end


function LScene(fig_or_scene; bbox = nothing, scenekw = NamedTuple(), kwargs...)

    topscene = get_topscene(fig_or_scene)

    default_attrs = default_attributes(LScene, topscene).attributes
    theme_attrs = subtheme(topscene, :LScene)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    layoutobservables = LayoutObservables{LScene}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        attrs.halign, attrs.valign, attrs.alignmode; suggestedbbox = bbox)

    scene = Scene(topscene, lift(round_to_IRect2D, layoutobservables.computedbbox); scenekw...)

    LScene(fig_or_scene, layoutobservables, attrs, Dict{Symbol, Any}(), scene)
end
