function LRect(fig_or_scene; bbox = nothing, kwargs...)

    parent = get_scene(fig_or_scene)

    default_attrs = default_attributes(LRect, parent).attributes
    theme_attrs = subtheme(parent, :LRect)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    layoutobservables = LayoutObservables{LRect}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf0(0, 0, 0, 0)
    end

    ibbox = @lift(round_to_IRect2D($(layoutobservables.computedbbox)))

    r = poly!(parent, ibbox, color = color, visible = visible, raw = true,
        strokecolor = strokecolor_with_visibility, strokewidth = strokewidth)[end]

    elements = Dict(:rect => r)

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LRect(fig_or_scene, layoutobservables, attrs, elements)
end


function Base.delete!(lr::LRect)
    GridLayoutBase.disconnect_layoutobservables!(lr.layoutobservables.gridcontent)
    GridLayoutBase.remove_from_gridlayout!(lr.layoutobservables.gridcontent)
    empty!(lr.layoutobservables.suggestedbbox.listeners)
    empty!(lr.layoutobservables.computedbbox.listeners)
    empty!(lr.layoutobservables.reportedsize.listeners)
    empty!(lr.layoutobservables.autosize.listeners)
    empty!(lr.layoutobservables.protrusions.listeners)

    # remove the plot object from the scene
    delete!(lr.parent, lr.rect)
end
