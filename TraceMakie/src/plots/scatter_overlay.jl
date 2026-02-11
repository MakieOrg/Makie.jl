# =============================================================================
# draw_atomic for Makie.scatter (overlay plot)
# =============================================================================
# Positions stored as GPU arrays, projected + rasterized at render time via KA.

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.scatter})
    attr = plot.attributes
    state = screen.state

    # 1. Positions → GPU array (use final world-space positions with model transforms)
    register_computation!(attr, [:positions_transformed_f32c], [:trace_overlay_positions]) do args, changed, last
        positions = args.positions_transformed_f32c
        return (Adapt.adapt(screen.config.backend, positions),)
    end

    # 2. Color/marker → style
    register_computation!(attr, [:color, :markersize, :marker], [:trace_overlay_style]) do args, changed, last
        color = _to_single_rgba(args.color)
        ms = args.markersize
        marker_size = if ms isa AbstractVector
            isempty(ms) ? 10f0 : Float32(maximum(Makie.to_2d_scale(first(ms))))
        else
            Float32(maximum(Makie.to_2d_scale(ms)))
        end
        shape = marker_to_shape(args.marker)
        return ((color=color, markersize=marker_size, shape=shape),)
    end

    # 3. Combine → trace_renderobject
    register_computation!(attr, [:trace_overlay_positions, :trace_overlay_style], [:trace_renderobject]) do args, changed, last
        positions = args.trace_overlay_positions
        style = args.trace_overlay_style
        n = length(positions)
        backend = screen.config.backend

        # Reuse buffers if size unchanged
        buffers = if !isnothing(last) && !isnothing(last.trace_renderobject) &&
                     hasproperty(last.trace_renderobject, :buffers) &&
                     length(last.trace_renderobject.buffers.screen_pos) == n
            last.trace_renderobject.buffers
        else
            Overlay.allocate_scatter_buffers(backend, n)
        end

        state.needs_film_clear = true
        return ((
            type = :scatter,
            positions = positions,
            style = style,
            buffers = buffers,
        ),)
    end
end
