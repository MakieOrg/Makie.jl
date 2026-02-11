# =============================================================================
# draw_atomic for Makie.lines and Makie.linesegments (overlay plots)
# =============================================================================
# Positions stored as GPU arrays, projected + rasterized at render time via KA.

# Extract a single RGBA color from whatever the compute graph provides
_to_single_rgba(c::AbstractVector) = isempty(c) ? RGBA{Float32}(0,0,0,0) : RGBA{Float32}(Makie.to_color(first(c)))
_to_single_rgba(c) = RGBA{Float32}(Makie.to_color(c))

# Extract a single linewidth from scalar or vector
_to_single_linewidth(lw::AbstractVector) = isempty(lw) ? 1f0 : Float32(first(lw))
_to_single_linewidth(lw) = Float32(lw)

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.linesegments})
    attr = plot.attributes
    state = screen.state

    # 1. Positions → GPU array (use final world-space positions with model transforms)
    register_computation!(attr, [:positions_transformed_f32c], [:trace_overlay_positions]) do args, changed, last
        positions = args.positions_transformed_f32c
        return (Adapt.adapt(screen.config.backend, positions),)
    end

    # 2. Color/linewidth → style
    register_computation!(attr, [:color, :linewidth], [:trace_overlay_style]) do args, changed, last
        color = _to_single_rgba(args.color)
        lw = _to_single_linewidth(args.linewidth)
        return ((color=color, linewidth=lw),)
    end

    # 3. Combine → trace_renderobject
    register_computation!(attr, [:trace_overlay_positions, :trace_overlay_style], [:trace_renderobject]) do args, changed, last
        positions = args.trace_overlay_positions
        style = args.trace_overlay_style
        n = length(positions)
        n < 2 && return (nothing,)
        backend = screen.config.backend

        # Reuse buffers if size unchanged
        buffers = if !isnothing(last) && !isnothing(last.trace_renderobject) &&
                     hasproperty(last.trace_renderobject, :buffers) &&
                     length(last.trace_renderobject.buffers.screen_pos) == n
            last.trace_renderobject.buffers
        else
            Overlay.allocate_line_buffers(backend, n, false)
        end

        state.needs_film_clear = true
        return ((
            type = :linesegments,
            positions = positions,
            style = style,
            buffers = buffers,
        ),)
    end
end

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.lines})
    attr = plot.attributes
    state = screen.state

    # 1. Positions → GPU array
    register_computation!(attr, [:positions_transformed_f32c], [:trace_overlay_positions]) do args, changed, last
        positions = args.positions_transformed_f32c
        return (Adapt.adapt(screen.config.backend, positions),)
    end

    # 2. Color/linewidth → style
    register_computation!(attr, [:color, :linewidth], [:trace_overlay_style]) do args, changed, last
        color = _to_single_rgba(args.color)
        lw = _to_single_linewidth(args.linewidth)
        return ((color=color, linewidth=lw),)
    end

    # 3. Combine → trace_renderobject
    register_computation!(attr, [:trace_overlay_positions, :trace_overlay_style], [:trace_renderobject]) do args, changed, last
        positions = args.trace_overlay_positions
        style = args.trace_overlay_style
        n = length(positions)
        n < 2 && return (nothing,)
        backend = screen.config.backend

        # Reuse buffers if size unchanged
        buffers = if !isnothing(last) && !isnothing(last.trace_renderobject) &&
                     hasproperty(last.trace_renderobject, :buffers) &&
                     length(last.trace_renderobject.buffers.screen_pos) == n
            last.trace_renderobject.buffers
        else
            Overlay.allocate_line_buffers(backend, n, true)
        end

        state.needs_film_clear = true
        return ((
            type = :lines,
            positions = positions,
            style = style,
            buffers = buffers,
        ),)
    end
end
