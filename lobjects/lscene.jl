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

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, attrs.halign, attrs.valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    autosizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs, autosizenode)

    protrusions = Node(RectSides{Float32}(0, 0, 0, 0))

    scene = Scene(parent, lift(IRect2D, finalbbox); scenekw...)

    layoutobservables = LayoutObservables{LScene, GridLayout}(suggestedbbox, protrusions, computedsize, autosizenode, finalbbox, nothing)

    LScene(scene, attrs, layoutobservables)
end
