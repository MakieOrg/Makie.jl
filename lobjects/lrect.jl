function LRect(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LRect))

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    computedsize = computedsizenode!(sizeattrs)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs)

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf0(0, 0, 0, 0)
    end

    r = poly!(parent, finalbbox, color = color, visible = visible, raw = true,
        strokecolor = strokecolor_with_visibility, strokewidth = strokewidth)[end]

    # no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    # trigger bbox
    suggestedbbox[] = suggestedbbox[]

    LRect(parent, layoutnodes, r, attrs)
end

defaultlayout(lr::LRect) = ProtrusionLayout(lr)

computedsizenode(lr::LRect) = lr.layoutnodes.computedsize
protrusionnode(lr::LRect) = lr.layoutnodes.protrusions

function align_to_bbox!(lt::LRect, bbox)
    lt.layoutnodes.suggestedbbox[] = bbox
end
