function LayoutedRect(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedRect))

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = Node(BBox(0, 100, 0, 100))

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

    LayoutedRect(parent, layoutnodes, r, attrs)
end

defaultlayout(lr::LayoutedRect) = ProtrusionLayout(lr)

computedsizenode(lr::LayoutedRect) = lr.layoutnodes.computedsize
protrusionnode(lr::LayoutedRect) = lr.layoutnodes.protrusions

function align_to_bbox!(lt::LayoutedRect, bbox)
    lt.layoutnodes.suggestedbbox[] = bbox
end
