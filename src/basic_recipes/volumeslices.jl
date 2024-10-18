
"""
VolumeSlices

    volumeslices(x, y, z, v)

Draws heatmap slices of the volume v
"""
@recipe VolumeSlices (x, y, z, volume) begin
    # MakieCore.documented_attributes(LineSegments)... # TODO: How is that meant to work?
    MakieCore.documented_attributes(Heatmap)...
    bbox_visible = true
    bbox_color = RGBAf(0.5, 0.5, 0.5, 0.5)
end

function Makie.plot!(plot::VolumeSlices)
    @extract plot (x, y, z, volume)
    replace_automatic!(plot, :colorrange) do
        lift(extrema, plot, volume)
    end

    heatmap_attr = shared_attributes(plot, Heatmap)
    # pop!(heatmap_attr, :model) # stops `transform!()` from working

    axes = :x, :y, :z
    for (ax, p, r, (X, Y)) ∈ zip(axes, (:yz, :xz, :xy), (x, y, z), ((y, z), (x, z), (x, y)))
        plot[Symbol(:heatmap_, p)] = hmap = heatmap!(
            plot, heatmap_attr, X, Y, zeros(length(X[]), length(Y[]))
        )
        plot[Symbol(:update_, p)] = update = i -> begin
            transform!(hmap, (p, r[][i]))
            indices = ntuple(Val(3)) do j
                axes[j] == ax ? i : (:)
            end
            hmap[3][] = view(volume[], indices...)
        end
        update(1) # trigger once to place heatmaps correctly
    end

    
    bbox = lift(plot, x, y, z) do x, y, z
        mx, Mx = extrema(x)
        my, My = extrema(y)
        mz, Mz = extrema(z)
        Rect3(mx, my, mz, Mx-mx, My-my, Mz-mz)
    end
    bbox_attr = shared_attributes(
        plot, LineSegments, 
        color = plot.bbox_color, visible = plot.bbox_visible, inspectable = false
    )
    linesegments!(plot, bbox_attr, bbox)

    return plot
end
