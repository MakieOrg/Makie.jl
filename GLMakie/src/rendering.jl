
function setup!(screen)
    glEnable(GL_SCISSOR_TEST)
    if isopen(screen)
        glScissor(0, 0, size(screen)...)
        glClearColor(1, 1, 1, 1)
        glClear(GL_COLOR_BUFFER_BIT)
        for (id, scene) in screen.screens
            if scene.visible[]
                a = pixelarea(scene)[]
                rt = (minimum(a)..., widths(a)...)
                glViewport(rt...)

                # Each scene gets a stencil index/value during scene insertion
                # based on its depth in the scene tree (root = 0x00). When a 
                # scene has `clear = true` we mark its area with its stencil 
                # value here. When rendering we then discard any plot whose
                # parent scene has a lower stencil value, i.e. we only allow the
                # marked `clear = true` scene and its children to render plots.

                bits = GL_STENCIL_BUFFER_BIT
                glClearStencil(screen.stencil_index[id])
                if scene.clear
                    c = scene.backgroundcolor[]
                    glScissor(rt...)
                    glClearColor(red(c), green(c), blue(c), alpha(c))
                    bits |= GL_COLOR_BUFFER_BIT
                    glClear(bits)
                end
            end
        end
    end
    glDisable(GL_SCISSOR_TEST)
    return
end

const selection_queries = Function[]

"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen; resize_buffers=true)
    nw = to_native(screen)
    ShaderAbstractions.switch_context!(nw)
    function sortby(x)
        robj = x[3]
        plot = screen.cache2plot[robj.id]
        # TODO, use actual boundingbox
        return Makie.zvalue2d(plot)
    end
    zvals = sortby.(screen.renderlist)
    permute!(screen.renderlist, sortperm(zvals))

    # NOTE
    # The transparent color buffer is reused by SSAO and FXAA. Changing the
    # render order here may introduce artifacts because of that.

    fb = screen.framebuffer
    if resize_buffers
        wh = Int.(framebuffer_size(nw))
        resize!(fb, wh)
    end
    w, h = size(fb)

    # prepare stencil (for sub-scenes)
    glEnable(GL_STENCIL_TEST)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    glDrawBuffers(length(fb.render_buffer_ids), fb.render_buffer_ids)
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0xff)
    glClearStencil(0)
    glClearColor(0, 0, 0, 0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    glDrawBuffer(fb.render_buffer_ids[1])
    setup!(screen)
    glDrawBuffers(length(fb.render_buffer_ids), fb.render_buffer_ids)

    # render with SSAO
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen) do robj
        return !Bool(robj[:transparency][]) && Bool(robj[:ssao][])
    end
    # SSAO
    screen.postprocessors[1].render(screen)

    # render no SSAO
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    # render all non ssao
    GLAbstraction.render(screen) do robj
        return !Bool(robj[:transparency][]) && !Bool(robj[:ssao][])
    end
    glDisable(GL_STENCIL_TEST)

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
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    # Render only transparent objects
    GLAbstraction.render(screen) do robj
        return Bool(robj[:transparency][])
    end
    glDisable(GL_STENCIL_TEST)

    # TRANSPARENT BLEND
    screen.postprocessors[2].render(screen)

    # FXAA
    screen.postprocessors[3].render(screen)

    # transfer everything to the screen
    screen.postprocessors[4].render(screen)

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
            a = pixelarea(scene)[]
            glViewport(minimum(a)..., widths(a)...)
            glStencilFunc(GL_GEQUAL, screen.stencil_index[screenid], 0xff)
            render(elem)
        end
    catch e
        @error "Error while rendering!" exception = e
        rethrow(e)
    end
    return
end
