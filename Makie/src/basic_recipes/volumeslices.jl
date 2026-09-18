"""
    volumeslices(x, y, z, v)

Draws heatmap slices of the volume `v`.
"""
@recipe VolumeSlices (x, y, z, volume) begin
    documented_attributes(Heatmap)...
    "Controls whether the bounding box outline is visible"
    bbox_visible = true
    "Sets the color of the bounding box outline"
    bbox_color = RGBAf(0.5, 0.5, 0.5, 0.5)
end

function plot!(plot::VolumeSlices)
    @extract plot (x, y, z, volume)

    map!(plot.attributes, [:colorrange, :volume], :computed_colorrange) do colorrange, volume
        return colorrange === automatic ? extrema(volume) : colorrange
    end

    map!(plot, [:x, :y, :z], :data_limits) do x, y, z
        mx, Mx = extrema(x)
        my, My = extrema(y)
        mz, Mz = extrema(z)
        return Rect3(mx, my, mz, Mx - mx, My - my, Mz - mz)
    end

    # Swap to Observable to force visible to be an input in the heatmaps.
    # This allows `h.visible = active` to continue working in the example
    parent_vis = ComputePipeline.get_observable!(plot.visible)
    axes = :x, :y, :z

    for (ax, p, r, (X, Y)) in zip(axes, (:yz, :xz, :xy), (x, y, z), ((y, z), (x, z), (x, y)))
        hmap = heatmap!(
            plot, Attributes(plot), X, Y, zeros(length(X[]), length(Y[])),
            colorrange = plot.computed_colorrange, visible = parent_vis
        )
        update = i -> begin
            transform!(hmap, (p, r[][i]))
            indices = ntuple(Val(3)) do j
                axes[j] == ax ? i : (:)
            end
            update!(hmap, arg3 = view(volume[], indices...))
        end
        update(1) # trigger once to place heatmaps correctly
        add_input!(plot.attributes, Symbol(:update_, p), update)
        add_input!(plot.attributes, Symbol(:heatmap_, p), hmap)
    end

    linesegments!(
        plot, plot.data_limits, color = plot.bbox_color,
        visible = plot.bbox_visible, inspectable = false
    )

    return plot
end
