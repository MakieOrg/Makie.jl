function AbstractPlotting.plot!(
        lscene::LScene, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(lscene.scene, P, attributes, args...; kw_attributes...)[end]

    plot
end

protrusionnode(ls::LScene) = ls.layoutobservables.protrusions
computedsizenode(ls::LScene) = ls.layoutobservables.computedsize

function LScene(parent::Scene; bbox = nothing, scenekw = NamedTuple(), kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LScene, parent))

    layoutobservables = LayoutObservables(LScene, attrs.width, attrs.height,
        attrs.halign, attrs.valign; suggestedbbox = bbox)

    scene = Scene(parent, lift(IRect2D_rounded, layoutobservables.computedbbox); scenekw...)

    LScene(scene, attrs, layoutobservables)
end
