"""
Plots `scatter` markers with `lines` between them.
"""
@recipe ScatterLines (positions,) begin
    documented_attributes(Lines)...
    filtered_attributes(
        Scatter, exclude = (
            :color, :colormap, :colorrange, :colorscale, :lowclip, :highclip, :alpha,
            :nan_color,
            :fxaa, :visible, :transparency, :space, :clip_planes, :ssao, :overdraw,
            :cycle, :transformation, :model, :depth_shift,
            :inspector_label, :inspectable,
        )
    )...
    "The color of the line, and by default also of the scatter markers."
    color = @inherit linecolor
    "Sets the color of scatter markers. These default to `color`"
    markercolor = automatic
    "Sets the colormap for scatter markers. This defaults to `colormap`"
    markercolormap = automatic
    "Sets the colorrange for scatter markers. This defaults to `colorrange`"
    markercolorrange = automatic
end

conversion_trait(::Type{<:ScatterLines}) = PointBased()

function attribute_groups(::Type{<:ScatterLines})
    groups = default_attribute_groups()
    attr = uncategorized_attributes(Scatter)
    filter!(!=(:color), attr) # is linecolor first
    push!(attr, :markercolor, :markercolormap, :markercolorrange)
    push!(groups, "Scatter Attributes" => attr)
    push!(groups, "Line Attributes" => uncategorized_attributes(Lines))
    return groups
end

function plot!(p::ScatterLines)
    # markercolor is the same as linecolor if left automatic
    map!(default_automatic, p, [:markercolor, :color], :real_markercolor)
    ComputePipeline.set_type!(p.real_markercolor, Any)

    map!(default_automatic, p, [:markercolormap, :colormap], :real_markercolormap)
    map!(default_automatic, p, [:markercolorrange, :colorrange], :real_markercolorrange)

    lines!(p, p.attributes, p.positions)
    scatter!(
        p, p.attributes, p.positions;
        color = p.real_markercolor,
        colormap = p.real_markercolormap,
        colorrange = p.real_markercolorrange,
    )

    return p
end
