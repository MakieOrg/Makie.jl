function layoutable(::Type{Box}, fig_or_scene; bbox = nothing, kwargs...)

    topscene = get_topscene(fig_or_scene)
    attrs = merge_theme(Box, topscene, kwargs)

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    layoutobservables = LayoutObservables(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    ibbox = @lift(round_to_IRect2D($(layoutobservables.computedbbox)))

    r = poly!(topscene, ibbox, color = color, visible = visible,
        strokecolor = strokecolor_with_visibility, strokewidth = strokewidth,
        inspectable = false)

    elements = Dict(:rect => r)

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    Box(fig_or_scene, layoutobservables, attrs, elements)
end
