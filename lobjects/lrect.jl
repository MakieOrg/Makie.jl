function LRect(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LRect))

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    layoutobservables = LayoutObservables(LRect, attrs.width, attrs.height,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf0(0, 0, 0, 0)
    end

    r = poly!(parent, layoutobservables.computedbbox, color = color, visible = visible, raw = true,
        strokecolor = strokecolor_with_visibility, strokewidth = strokewidth)[end]

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LRect(parent, layoutobservables, r, attrs)
end


function Base.delete!(lr::LRect)
    disconnect_layoutnodes!(lr.layoutobservables.gridcontent)
    GridLayoutBase.remove_from_gridlayout!(lr.layoutobservables.gridcontent)
    empty!(lr.layoutobservables.suggestedbbox.listeners)
    empty!(lr.layoutobservables.computedbbox.listeners)
    empty!(lr.layoutobservables.computedsize.listeners)
    empty!(lr.layoutobservables.autosize.listeners)
    empty!(lr.layoutobservables.protrusions.listeners)

    # remove the plot object from the scene
    delete!(lr.parent, lr.rect)
end
