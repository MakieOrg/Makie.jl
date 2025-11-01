# TODO: needs to run before first draw to color buffers.
# With SSAO that ends up being at first render and in SSAO, as SSAO2 draws
# color to a buffer previously used for normals
function setup!(screen::Screen, fb)
    GLAbstraction.bind(fb)

    # clear color buffer
    glDrawBuffer(get_attachment(fb, :color))
    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)

    # draw scene backgrounds
    glEnable(GL_SCISSOR_TEST)
    if isopen(screen) && !isnothing(screen.scene)
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
    end
    glDisable(GL_SCISSOR_TEST)

    return
end

"""
    render_frame(screen[; resize_buffer = true])

Renders a single frame of a `screen`
"""
function render_frame(screen::Screen; resize_buffers = true)
    if isempty(screen.framebuffer_manager.children) || isnothing(screen.scene)
        return
    end

    # Make sure this context is active (for multi-window rendering)
    nw = to_native(screen)
    gl_switch_context!(nw)
    GLAbstraction.require_context(nw)

    # Resize framebuffer to window size
    if resize_buffers
        ppu = screen.px_per_unit[]
        resize!(screen.framebuffer_manager, round.(Int, ppu .* size(screen.scene))...)
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

    # TODO: figure out something better for setup!()
    setup!(screen, fb)

    render_frame(screen, nothing, screen.render_pipeline)

    GLAbstraction.require_context(nw)

    return
end
