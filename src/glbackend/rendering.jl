function renderloop(screen::Screen; framerate = 1/60, prerender = () -> nothing)
    try
        while isopen(screen)
            t = time()
            GLWindow.poll_glfw() # GLFW poll
            prerender()
            if Base.n_avail(Reactive._messages) > 0
                GLWindow.reactive_run_till_now()
                GLFW.MakeContextCurrent(to_native(screen))
                render_frame(screen)
                GLWindow.swapbuffers(to_native(screen))
            end
            t = time() - t
            GLWindow.sleep_pessimistic(framerate - t)
        end
    catch e
        rethrow(e)
    finally
        nw = to_native(screen)
        destroy!(nw)
    end
    return
end
function destroy!(nw::GLFW.Window)
    if nw.handle != C_NULL
        GLFW.DestroyWindow(nw)
        nw.handle = C_NULL
    end
end

function setup!(screen)
    if isopen(screen)
        for (id, rect, clear, color) in screen.screens
            a = rect[]
            glScissor(minimum(a)..., widths(a)...)
            glClearStencil(id)
            bits = GL_STENCIL_BUFFER_BIT
            if clear[]
                c = color[]
                glClearColor(red(c), green(c), blue(c), alpha(c))
                bits |= GL_COLOR_BUFFER_BIT
            end
            glClear(bits)
        end
    end
    return
end


"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen)
    !isopen(screen) && return
    nw = to_native(screen)
    fb = (screen.framebuffer)
    wh = Int.(GLFW.GetFramebufferSize(nw))
    resize!(fb, wh)
    w, h = wh
    #prepare for geometry in need of anti aliasing
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # color framebuffer
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    # setup stencil and backgrounds
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0xff)
    glClearStencil(0)
    glClearColor(0,0,0,0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
    glEnable(GL_SCISSOR_TEST)
    setup!(screen)
    glDisable(GL_SCISSOR_TEST)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    # deactivate stencil write
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen, true)
    glDisable(GL_STENCIL_TEST)

    # transfer color to luma buffer and apply fxaa
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[2]) # luma framebuffer
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
    glClearColor(0,0,0,0)
    glClear(GL_COLOR_BUFFER_BIT)
    glViewport(0, 0, w, h)
    GLAbstraction.render(fb.postprocess[1]) # add luma and preprocess

    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # transfer to non fxaa framebuffer
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
    GLAbstraction.render(fb.postprocess[2]) # copy with fxaa postprocess

    #prepare for non anti aliased pass
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])

    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen, false)
    glDisable(GL_STENCIL_TEST)
    glViewport(0, 0, w, h)
    #Read all the selection queries
    # GLWindow.push_selectionqueries!(window)
    glBindFramebuffer(GL_FRAMEBUFFER, 0) # transfer back to window
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[3]) # copy postprocess
    return
end

function id2rect(screen, id1)
    # TODO maybe we should use a different data structure
    for (id2, rect, clear, color) in screen.screens
        id1 == id2 && return true, rect
    end
    false, IRect(0,0,0,0)
end

function GLAbstraction.render(screen::Screen, fxaa::Bool)
    if isopen(screen)
        for (zindex, screenid, elem) in screen.renderlist
            found, rect = id2rect(screen, screenid)
            found || continue
            a = rect[]
            glViewport(minimum(a)..., widths(a)...)
            glStencilFunc(GL_EQUAL, screenid, 0xff)
            if fxaa && elem[:fxaa][]
                render(elem)
            end
            if !fxaa && !elem[:fxaa][]
                render(elem)
            end
        end
    end
    return
end
