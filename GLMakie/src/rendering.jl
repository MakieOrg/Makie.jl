function prepare_frame(screen, resize_buffers)
    # Make sure this context is active (for multi-window rendering)
    nw = to_native(screen)
    gl_switch_context!(nw)
    GLAbstraction.require_context(nw)

    # Resize framebuffer to window size
    if resize_buffers
        ppu = screen.px_per_unit[]
        new_size = round.(Int, ppu .* size(screen.scene))
        resize!(screen.framebuffer_manager, new_size...)
        resize!(screen.render_pipeline, new_size...)
    end

    # TODO: temporary, keep track of this in screen owned framebuffer
    stage = last(screen.render_pipeline.stages)::BlitToScreen
    fb = stage.source_framebuffer
    if haskey(fb, :objectid)
        # clear objectid
        wh = size(fb)
        glDisable(GL_SCISSOR_TEST)
        glDisable(GL_STENCIL_TEST)
        set_draw_buffers(fb, :objectid)
        glViewport(0, 0, wh[1], wh[2])
        glClearColor(0, 0, 0, 0)
        glClear(GL_COLOR_BUFFER_BIT)
    end

    return
end

"""
    render_frame(screen[; resize_buffer = true])

Renders a single frame of a `screen`
"""
function render_frame(screen::Screen; resize_buffers = true)
    if isempty(screen.framebuffer_manager) || isnothing(screen.scene) || !isopen(screen)
        return
    end

    prepare_frame(screen, resize_buffers)

    render_frame(screen, nothing, screen.render_pipeline)

    copy_to_screen(screen, screen.framebuffer_manager.accumulation)

    GLAbstraction.require_context(to_native(screen))

    return
end

"""
    copy_to_screen(screen, framebuffer)

Copies the final render to the screen for displaying.

Can be extended for other window types by dispatching on `Screen{WindowType}`
"""
function copy_to_screen(screen::Screen, fb)
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fb.id)
    glReadBuffer(get_attachment(fb, :color))

    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)

    src_w, src_h = framebuffer_size(screen)
    trg_w, trg_h = makie_window_size(screen)

    glBlitFramebuffer(
        0, 0, src_w, src_h,
        0, 0, trg_w, trg_h,
        GL_COLOR_BUFFER_BIT, GL_LINEAR
    )

    return
end

# TODO: extend this to any kind of buffer
# See colorbuffer implementation
function stage_output(
        screen::Screen, stage_index::Int, buffername = :color;
        format::Makie.ImageStorageFormat = Makie.JuliaNative
    )
    if !isopen(screen)
        error("Screen not open!")
    end
    gl_switch_context!(screen.glscreen)
    framebuffer = screen.render_pipeline.stages[stage_index].framebuffer
    ctex = get_buffer(framebuffer, buffername)
    pollevents(screen, Makie.BackendTick)
    poll_updates(screen)

    prepare_frame(screen, false)

    # Render up to target stage
    for idx in 1:stage_index
        stage = screen.render_pipeline.stages[idx]
        require_context(screen.glscreen)
        run_stage(screen, nothing, stage)
    end

    glFinish()

    if size(ctex) != size(screen.framecache)
        screen.framecache = Matrix{RGB{N0f8}}(undef, size(ctex))
    end
    fast_color_data!(screen.framecache, ctex)

    # Render remainign stages
    for idx in (stage_index + 1):length(screen.render_pipeline.stages)
        stage = screen.render_pipeline.stages[idx]
        require_context(screen.glscreen)
        run_stage(screen, nothing, stage)
    end

    if screen.config.visible
        GLFW.SwapBuffers(to_native(screen))
    else
        glFinish()
    end

    if format == Makie.GLNative
        return screen.framecache
    elseif format == Makie.JuliaNative
        img = screen.framecache
        return PermutedDimsArray(view(img, :, size(img, 2):-1:1), (2, 1))
    end
end
