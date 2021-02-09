function AbstractPlotting.plot!(
        lscene::LScene, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(lscene.scene, P, attributes, args...; kw_attributes...)

    plot
end

function AbstractPlotting.plot!(P::AbstractPlotting.PlotFunc, ls::LScene, args...; kw_attributes...)
    attributes = AbstractPlotting.Attributes(kw_attributes)
    AbstractPlotting.plot!(ls, P, attributes, args...)
end


function layoutable(::Type{LScene}, fig_or_scene; bbox = nothing, scenekw = NamedTuple(), kwargs...)

    topscene = get_topscene(fig_or_scene)

    default_attrs = default_attributes(LScene, topscene).attributes
    theme_attrs = subtheme(topscene, :LScene)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    layoutobservables = LayoutObservables{LScene}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        attrs.halign, attrs.valign, attrs.alignmode; suggestedbbox = bbox)

    # Using `clear = false` (default for scenes constructed from other scenes)
    # breaks SSAO, so we're using clear = true as a default here. This means
    # that this LScene might draw over plot objects from other scenes.
    # We also set `raw = false` because otherwise the scene will not automatically
    # pick a camera and draw axis.
    scenekw = merge((raw = false, clear = true), scenekw)
    scene = Scene(topscene, lift(round_to_IRect2D, layoutobservables.computedbbox); scenekw...)

    ls = LScene(fig_or_scene, layoutobservables, attrs, Dict{Symbol, Any}(), scene)

    # register as current axis
    # TODO: is this a good place for that? probably not
    if fig_or_scene isa Figure
        AbstractPlotting.current_axis!(fig_or_scene, ls)
    end

    ls
end
