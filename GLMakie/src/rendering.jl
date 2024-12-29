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
function render_frame(screen::Screen; resize_buffers=true)
    isempty(screen.framebuffer_factory.children) && return

    # Make sure this context is active (for multi-window rendering)
    nw = to_native(screen)
    ShaderAbstractions.switch_context!(nw)
    GLAbstraction.require_context(nw)

    # Resize framebuffer to window size
    # TODO: Hacky, assumes our first draw is a render (ZSort doesn't draw) and
    #       no earlier stage uses color or objectid
    #       Also assumes specific names
    fb = screen.framebuffer_factory.children[1]
    if resize_buffers && !isnothing(screen.scene)
        ppu = screen.px_per_unit[]
        resize!(screen.framebuffer_factory, round.(Int, ppu .* size(screen.scene))...)
    end

    GLAbstraction.bind(fb)
    glViewport(0, 0, size(fb)...)

    # clear objectid, depth and stencil
    glDrawBuffer(get_attachment(fb, :objectid))
    glClearColor(0, 0, 0, 0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    # TODO: figure out something better for setup!()
    setup!(screen, fb)

    render_frame(screen, nothing, screen.render_pipeline)
    return
end
