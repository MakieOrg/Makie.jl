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

    # Clear stencil, depth, objectid (and color, but that should not be needed)
    fb = screen.framebuffer_manager.accumulation
    wh = size(fb)
    glDisable(GL_SCISSOR_TEST)
    glDisable(GL_STENCIL_TEST)
    set_draw_buffers(fb)
    glViewport(0, 0, wh[1], wh[2])
    glClearColor(0, 0, 0, 0)
    glClearStencil(0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)

    # prepare for stencil being used
    glEnable(GL_STENCIL_TEST)
    glStencilFunc(GL_EQUAL, 0, 0xff)

    return
end

function update_stencil!(screen::Screen, scene_group, fb)
    GLAbstraction.bind(fb)

    # draw 1 to stencil buffer for every cleared scene viewport
    glEnable(GL_SCISSOR_TEST)
    glEnable(GL_STENCIL_TEST)
    glStencilFunc(GL_ALWAYS, 0, 0xff)
    glClearStencil(1)
    ppu = screen.px_per_unit[]
    for scene in scene_group.scenes
        if scene.visible[] && scene.clear[]
            a = viewport(scene)[]
            rt = (round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
            glScissor(rt...)
            glClear(GL_STENCIL_BUFFER_BIT)
        end
    end
    glDisable(GL_SCISSOR_TEST)

    # And reset to a useful stencil function
    glStencilFunc(GL_EQUAL, 0, 0xff)

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

    # Render groups front to back where the stencil is empty (0)
    # then add all cleared areas of the group to the stencil so we don't render
    # under them
    for group in screen.render_context.groups
        render_frame(screen, group, screen.render_pipeline)
        update_stencil!(screen, group, screen.framebuffer_manager.accumulation)
    end

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
