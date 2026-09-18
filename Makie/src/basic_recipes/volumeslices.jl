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

    "Sets the index of the shown xy slice `volume[:, :, idx]`."
    xy_index = 1
    "Sets the index of the shown xz slice `volume[:, idx, :]`."
    xz_index = 1
    "Sets the index of the shown yz slice `volume[idx, :, :]`."
    yz_index = 1
end

function plot!(plot::VolumeSlices)
    @extract plot (x, y, z, volume)

    map!(plot.attributes, [:colorrange, :volume], :computed_colorrange) do colorrange, volume
        eltype(volume) <: Colorant && return automatic
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

    for (ax, plane_sym, offsets, (X, Y)) in zip(axes, (:yz, :xz, :xy), (x, y, z), ((y, z), (x, z), (x, y)))
        map!(
            plot,
            [Symbol(plane_sym, :_index), offsets],
            [Symbol(plane_sym, :_transform), Symbol(plane_sym, :_slice)]
        ) do idx, offsets
            indices = ntuple(Val(3)) do j
                axes[j] == ax ? idx : (:)
            end
            return (plane_sym, offsets[idx]), view(volume[], indices...)
        end

        hmap = heatmap!(
            plot, Attributes(plot), X, Y, plot[Symbol(plane_sym, :_slice)],
            colorrange = plot.computed_colorrange, visible = parent_vis,
        )

        on(plot[Symbol(plane_sym, :_transform)], update = true) do plane_transform
            transform!(hmap, plane_transform)
        end

        update = i -> begin
            @warn "Updating volumeslices with `plot.update_$plane_sym(index) is deprecated in favor of setting `plot.$(plane_sym)_index = index`." maxlog = 1
            plot[Symbol(plane_sym, :_index)] = i
        end
        add_input!(plot.attributes, Symbol(:update_, plane_sym), update)
        add_constant!(plot.attributes, Symbol(:heatmap_, plane_sym), hmap)
    end

    linesegments!(
        plot, plot.data_limits, color = plot.bbox_color,
        visible = plot.bbox_visible, inspectable = false
    )

    return plot
end
