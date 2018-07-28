function renderloop(screen::Screen; framerate = 1/60, prerender = () -> nothing)
    try
        while isopen(screen)
            t = time()
            GLFW.PollEvents() # GLFW poll
            prerender()
            if (Base.n_avail(Reactive._messages) > 0) || must_update()
                reactive_run_till_now()
                #make_context_current(screen)
                render_frame(screen)
                GLFW.SwapBuffers(to_native(screen))
            end
            diff = framerate - (time() - t)
            diff > 0 && sleep(diff)
        end
    catch e
        rethrow(e)
    finally
        nw = to_native(screen)
        destroy!(nw)
    end
    return
end



function setup!(screen)
    if isopen(screen)
        for (id, rect, clear, color) in screen.screens
            a = rect[]
            glViewport(minimum(a)..., widths(a)...)
            if clear[]
                c = color[]
                glClearColor(red(c), green(c), blue(c), alpha(c))
                glClear(GL_COLOR_BUFFER_BIT)
            end
        end
    end
    return
end

const selection_queries = Function[]

"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen)
    nw = to_native(screen)
    GLAbstraction.is_context_active(nw) || return
    fb = screen.framebuffer
    wh = Int.(GLFW.GetFramebufferSize(nw))
    resize!(fb, wh)
    w, h = wh
    glDisable(GL_STENCIL_TEST)
    #prepare for geometry in need of anti aliasing
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # color framebuffer
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glClearColor(0,0,0,0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
    setup!(screen)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    GLAbstraction.render(screen, true)

    # transfer color to luma buffer and apply fxaa
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[2]) # luma framebuffer
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
    glViewport(0, 0, w, h)
    glClearColor(0,0,0,0)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[1]) # add luma and preprocess

    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # transfer to non fxaa framebuffer
    glViewport(0, 0, w, h)
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
    GLAbstraction.render(fb.postprocess[2]) # copy with fxaa postprocess

    #prepare for non anti aliased pass
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])

    GLAbstraction.render(screen, false)
    #Read all the selection queries
    for query_func in selection_queries
        query_func()
    end
    glBindFramebuffer(GL_FRAMEBUFFER, 0) # transfer back to window
    glViewport(0, 0, w, h)
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
    for (zindex, screenid, elem) in screen.renderlist
        found, rect = id2rect(screen, screenid)
        found || continue
        a = rect[]
        glViewport(minimum(a)..., widths(a)...)
        if fxaa && elem[:fxaa][]
            render(elem)
        end
        if !fxaa && !elem[:fxaa][]
            render(elem)
        end
    end
    return
end
