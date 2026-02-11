# =============================================================================
# draw_atomic for Makie.text (overlay plot)
# =============================================================================
# Text rendering uses Makie's SDF atlas and glyph layout system.
# The draw_atomic stores the plot reference; actual glyph computation and
# rasterization happen at render time in render_overlays!.

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.text})
    attr = plot.attributes
    state = screen.state

    # Text plots from Axis3D etc. may not have standard compute graph inputs.
    # Use a safe dependency — :sdf_uv is computed for all rendered text.
    dep = if haskey(attr, :sdf_uv)
        :sdf_uv
    elseif haskey(attr, :converted_1)
        :converted_1
    else
        return nothing  # skip this text plot
    end

    register_computation!(attr, [dep], [:trace_renderobject]) do args, changed, last
        state.needs_film_clear = true
        return ((type = :text, plot = plot),)
    end
end
