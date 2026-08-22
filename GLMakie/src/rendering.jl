# Needs to run before first draw to opaque color buffers.
# SSAO needs to run this between stages as it switches to a different color buffer
function setup!(screen::Screen, fb)
    GLAbstraction.bind(fb)

    # clear color buffer
    glDrawBuffer(get_attachment(fb, :color))
    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)

    # draw scene backgrounds
    glEnable(GL_SCISSOR_TEST)
    ppu = screen.px_per_unit[]
    for (id, scene) in screen.screens
        if scene.visible[] && scene.clear[]
            a = viewport(scene)[]
            rt = (round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
            glViewport(rt...)
            glScissor(rt...)
            c = scene.backgroundcolor[]
            glClearColor(red(c), green(c), blue(c), alpha(c))
            glClear(GL_COLOR_BUFFER_BIT)
        end
    end
    glDisable(GL_SCISSOR_TEST)

    return
end

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

    # TODO: Hacky, assumes our first draw is a `RenderPlots` (ZSort doesn't draw) and
    #       no earlier stage uses color or objectid
    #       Also assumes specific names
    # TODO: Clearing should be a stage itself
    fb = screen.framebuffer_manager.children[1]
    GLAbstraction.bind(fb)
    glViewport(0, 0, size(fb)...)

    # clear objectid, depth and stencil
    glClearColor(0, 0, 0, 0)
    if haskey(fb, :objectid)
        glDrawBuffer(get_attachment(fb, :objectid))
        glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
    else
        glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
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

    # TODO: Is this a reasonable solution?
    # Maybe we should have a setup stage instead? (Kinda annoying for SSAO though)
    idx = findfirst(stage -> stage isa RenderPlots, screen.render_pipeline.stages)
    if !isnothing(idx)
        setup!(screen, screen.render_pipeline.stages[idx].framebuffer)
    end

    render_frame(screen, nothing, screen.render_pipeline)

    GLAbstraction.require_context(to_native(screen))

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
