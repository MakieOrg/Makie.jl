function LRect(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LRect))

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    autosizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs, autosizenode)

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf0(0, 0, 0, 0)
    end

    r = poly!(parent, finalbbox, color = color, visible = visible, raw = true,
        strokecolor = strokecolor_with_visibility, strokewidth = strokewidth)[end]

    # no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes{LRect, GridLayout}(suggestedbbox, protrusions, computedsize, autosizenode, finalbbox, nothing)

    # trigger bbox
    suggestedbbox[] = suggestedbbox[]

    LRect(parent, layoutnodes, r, attrs)
end


function Base.delete!(lr::LRect)
    disconnect_layoutnodes!(lr.layoutnodes.gridcontent)
    remove_from_gridlayout!(lr.layoutnodes.gridcontent)
    empty!(lr.layoutnodes.suggestedbbox.listeners)
    empty!(lr.layoutnodes.computedbbox.listeners)
    empty!(lr.layoutnodes.computedsize.listeners)
    empty!(lr.layoutnodes.autosize.listeners)
    empty!(lr.layoutnodes.protrusions.listeners)

    # remove the plot object from the scene
    delete!(lr.parent, lr.rect)
end
