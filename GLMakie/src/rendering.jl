function setup!(screen::Screen)
    glEnable(GL_SCISSOR_TEST)
    if isopen(screen) && !isnothing(screen.scene)
        ppu = screen.px_per_unit[]
        glScissor(0, 0, round.(Int, size(screen.scene) .* ppu)...)
        glClearColor(1, 1, 1, 1)
        glClear(GL_COLOR_BUFFER_BIT)
        for (id, scene) in screen.screens
            if scene.visible[]
                a = viewport(scene)[]
                rt = (round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
                glViewport(rt...)
                if scene.clear[]
                    c = scene.backgroundcolor[]
                    glScissor(rt...)
                    glClearColor(red(c), green(c), blue(c), alpha(c))
                    glClear(GL_COLOR_BUFFER_BIT)
                end
            end
        end
    end
    glDisable(GL_SCISSOR_TEST)
    return
end

"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen; resize_buffers=true)
    nw = to_native(screen)
    ShaderAbstractions.switch_context!(nw)
    GLAbstraction.require_context(nw)

    function sortby(x)
        robj = x[3]
        plot = screen.cache2plot[robj.id]
        # TODO, use actual boundingbox
        # ~7% faster than calling zvalue2d doing the same thing?
        return Makie.transformationmatrix(plot)[][3, 4]
        # return Makie.zvalue2d(plot)
    end

    sort!(screen.renderlist; by=sortby)

    # NOTE
    # The transparent color buffer is reused by SSAO and FXAA. Changing the
    # render order here may introduce artifacts because of that.

    fb = screen.framebuffer
    if resize_buffers && !isnothing(screen.scene)
        ppu = screen.px_per_unit[]
        resize!(fb, round.(Int, ppu .* size(screen.scene))...)
    end

    # clear global buffers
    GLAbstraction.bind(fb)
    glDrawBuffers(2, get_attachment.(Ref(fb), [:color, :objectid]))
    glClearColor(0, 0, 0, 0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    # draw backgrounds
    glDrawBuffer(get_attachment(fb, :color))
    setup!(screen)

    # render with SSAO
    run_step(screen, nothing, screen.render_pipeline[1])
    # run SSAO
    run_step(screen, nothing, screen.render_pipeline[2])

    # render all plots without SSAO and transparency
    run_step(screen, nothing, screen.render_pipeline[3])

    # Render only transparent objects
    run_step(screen, nothing, screen.render_pipeline[4])

    # TRANSPARENT BLEND
    run_step(screen, nothing, screen.render_pipeline[5])

    # FXAA
    run_step(screen, nothing, screen.render_pipeline[6])

    # transfer everything to the screen
    run_step(screen, nothing, screen.render_pipeline[7])

    GLAbstraction.require_context(nw)

    return
end
