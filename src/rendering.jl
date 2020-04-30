function renderloop(screen::Screen; framerate = 1/30, prerender = () -> nothing)
    # Somehow errors get sometimes ignored, so we at least print them here
    try
        while isopen(screen)
            t = time()
            GLFW.PollEvents() # GLFW poll
            prerender()
            make_context_current(screen)
            render_frame(screen)
            GLFW.SwapBuffers(to_native(screen))
            diff = framerate - (time() - t)
            if diff > 0
                sleep(diff)
            else # if we don't sleep, we need to yield explicitely
                yield()
            end
        end
    catch e
        ce = CapturedException(e, Base.catch_backtrace())
        @error "Error in renderloop!" exception=ce
        rethrow(e)
    finally
        destroy!(screen)
    end
    return
end

function setup!(screen)
    glEnable(GL_SCISSOR_TEST)
    if isopen(screen)
        glScissor(0, 0, widths(screen)...)
        glClearColor(1, 1, 1, 1)
        glClear(GL_COLOR_BUFFER_BIT)
        for (id, scene) in screen.screens
            if scene.visible[]
                a = pixelarea(scene)[]
                rt = (minimum(a)..., widths(a)...)
                glViewport(rt...)
                bits = GL_STENCIL_BUFFER_BIT
                glClearStencil(id)
                if scene.clear
                    c = to_color(scene.backgroundcolor[])
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
function render_frame(screen::Screen)
    nw = to_native(screen)
    ShaderAbstractions.is_context_active(nw) || return
    fb = screen.framebuffer
    wh = Int.(framebuffer_size(nw))
    resize!(fb, wh)
    w, h = wh

    # primary render
    glEnable(GL_STENCIL_TEST)
    #prepare for geometry in need of anti aliasing
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # color framebuffer
    glDrawBuffers(4, [
        GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1,
        GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3
    ])
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0xff)
    glClearStencil(0)
    glClearColor(0,0,0,0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
    setup!(screen)

    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen, true)
    # glDisable(GL_STENCIL_TEST)


    # SSAO - calculate occlusion
    glDrawBuffer(GL_COLOR_ATTACHMENT4)  # occlusion buffer
    glViewport(0, 0, w, h)
    glClearColor(1, 1, 1, 1)            # 1 means no darkening
    glClear(GL_COLOR_BUFFER_BIT)
    try
        for (screenid, scene) in screen.screens
            if !isempty(scene.plots)
                # use stencil to select one scene,
                # draw with appropriate projection matrix
                projection = scene.camera.projection[]
                fb.postprocess[1].uniforms[:projection][] = projection
                glStencilFunc(GL_EQUAL, screenid, 0xff)
                GLAbstraction.render(fb.postprocess[1])
            end
        end
    catch e
        @error "Error while rendering!" exception=e
        rethrow(e)
    end
    glDisable(GL_STENCIL_TEST)


    # SSAO - blur occlusion and apply to color
    glDrawBuffer(GL_COLOR_ATTACHMENT0)  # color buffer
    GLAbstraction.render(fb.postprocess[2])

    # FXAA - calculate LUMA
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[2])
    glDrawBuffer(GL_COLOR_ATTACHMENT0)  # color_luma buffer
    glViewport(0, 0, w, h)
    # clear shouldn't be necessary. every pixel should be written to
    glClearColor(1, 0, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[3])

    # FXAA - perform anti-aliasing
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glDrawBuffer(GL_COLOR_ATTACHMENT0)  # color buffer
    # glViewport(0, 0, w, h) # not necessary
    GLAbstraction.render(fb.postprocess[4])

    # no FXAA primary render
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen, false)
    glDisable(GL_STENCIL_TEST)

    # transfer everything to the screen
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glViewport(0, 0, w, h)
    # not necessary? color buffer should be full
    glClearColor(0, 1, 0, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[5]) # copy postprocess

    return
end

function id2scene(screen, id1)
    # TODO maybe we should use a different data structure
    for (id2, scene) in screen.screens
        id1 == id2 && return true, scene
    end
    return false, nothing
end

function GLAbstraction.render(screen::Screen, fxaa::Bool)
    # Somehow errors in here get ignored silently!?
    try
        # sort by overdraw, so that overdrawing objects get drawn last!
        # sort!(screen.renderlist, by = ((zi, id, robj),)-> robj.prerenderfunction.overdraw[])
        for (zindex, screenid, elem) in screen.renderlist
            found, scene = id2scene(screen, screenid)
            found || continue
            a = pixelarea(scene)[]
            glViewport(minimum(a)..., widths(a)...)
            if scene.clear
                glStencilFunc(GL_EQUAL, screenid, 0xff)
            else
                # if we don't clear, that means we have a screen that is overlaid
                # on top of another, which means it doesn't have a stencil value
                # so we can't do the stencil test
                glStencilFunc(GL_ALWAYS, screenid, 0xff)
            end
            if fxaa && elem[:fxaa][]
                render(elem)
            end
            if !fxaa && !elem[:fxaa][]
                render(elem)
            end
        end
    catch e
        @error "Error while rendering!" exception=e
        rethrow(e)
    end
    return
end
