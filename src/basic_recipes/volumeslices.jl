
"""
    volumeslices(x, y, z, v)

Draws heatmap slices of the volume v
"""
@recipe VolumeSlices (x, y, z, volume) begin
    MakieCore.documented_attributes(Heatmap)...
    bbox_visible = true
    bbox_color = RGBAf(0.5, 0.5, 0.5, 0.5)
end

function Makie.plot!(plot::VolumeSlices)
    @extract plot (x, y, z, volume)

    map!(plot.attributes, [:colorrange, :volume], :computed_colorrange) do colorrange, volume
        return colorrange === automatic ? extrema(volume) : colorrange
    end

    bbox = lift(plot, x, y, z) do x, y, z
        mx, Mx = extrema(x)
        my, My = extrema(y)
        mz, Mz = extrema(z)
        Rect3(mx, my, mz, Mx-mx, My-my, Mz-mz)
    end

    axes = :x, :y, :z
    for (ax, p, r, (X, Y)) ∈ zip(axes, (:yz, :xz, :xy), (x, y, z), ((y, z), (x, z), (x, y)))
        hmap = heatmap!(
            plot, Attributes(plot), X, Y, zeros(length(X[]), length(Y[])),
            colorrange = plot.computed_colorrange
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
    end

    linesegments!(plot, bbox, color = plot.bbox_color, visible = plot.bbox_visible, inspectable = false)

    plot
end
