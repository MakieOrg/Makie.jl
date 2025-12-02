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
function render_frame(screen::Screen; resize_buffers = true)
    isnothing(screen.scene) && return

    nw = to_native(screen)
    gl_switch_context!(nw)
    GLAbstraction.require_context(nw)

    function sortby(x)
        robj = x[3]
        plot = screen.cache2plot[robj.id]
        # TODO, use actual boundingbox
        # ~7% faster than calling zvalue2d doing the same thing?
        return Makie.transformationmatrix(plot)[][3, 4]
        # return Makie.zvalue2d(plot)
    end

    sort!(screen.renderlist; by = sortby)

    # NOTE
    # The transparent color buffer is reused by SSAO and FXAA. Changing the
    # render order here may introduce artifacts because of that.

    fb = screen.framebuffer
    if resize_buffers
        ppu = screen.px_per_unit[]
        resize!(fb, round.(Int, ppu .* size(screen.scene::Scene))...)
    end

    # prepare stencil (for sub-scenes)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    glDrawBuffers(length(fb.render_buffer_ids), fb.render_buffer_ids)
    glClearColor(0, 0, 0, 0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    glDrawBuffer(fb.render_buffer_ids[1])
    setup!(screen)
    glDrawBuffers(length(fb.render_buffer_ids), fb.render_buffer_ids)

    # render with SSAO
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    GLAbstraction.render(screen) do robj
        return !Bool(robj[:transparency][]) && Bool(robj[:ssao][])
    end
    # SSAO
    screen.postprocessors[1].render(screen)

    # render no SSAO
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    # render all non ssao
    GLAbstraction.render(screen) do robj
        return !Bool(robj[:transparency][]) && !Bool(robj[:ssao][])
    end

    # TRANSPARENT RENDER
    # clear sums to 0
    glDrawBuffer(GL_COLOR_ATTACHMENT2)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    # clear alpha product to 1
    glDrawBuffer(GL_COLOR_ATTACHMENT3)
    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    # draw
    glDrawBuffers(3, [GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT3])
    # Render only transparent objects
    GLAbstraction.render(screen) do robj
        return Bool(robj[:transparency][])
    end

    # TRANSPARENT BLEND
    screen.postprocessors[2].render(screen)

    # FXAA
    screen.postprocessors[3].render(screen)

    # transfer everything to the screen
    screen.postprocessors[4].render(screen)

    GLAbstraction.require_context(nw)

    return
end

function id2scene(screen, id1)
    # TODO maybe we should use a different data structure
    for (id2, scene) in screen.screens
        id1 == id2 && return true, scene
    end
    return false, nothing
end

function GLAbstraction.render(filter_elem_func, screen::Screen)
    # Somehow errors in here get ignored silently!?
    try
        for (zindex, screenid, elem) in screen.renderlist
            filter_elem_func(elem)::Bool || continue

            found, scene = id2scene(screen, screenid)
            found || continue
            scene.visible[] || continue
            ppu = screen.px_per_unit[]
            a = viewport(scene)[]
            glViewport(round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
            elem[:px_per_unit] = ppu
            render(elem)
        end
    catch e
        @error "Error while rendering!" exception = e
        rethrow(e)
    end
    return
end
