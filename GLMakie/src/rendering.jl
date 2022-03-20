# TODO process!(scene, RenderTickEvent())
function vsynced_renderloop(screen)
    while isopen(screen) && !WINDOW_CONFIG.exit_renderloop[]
        pollevents(screen) # GLFW poll
        screen.render_tick[] = nothing
        if WINDOW_CONFIG.pause_rendering[]
            sleep(0.1)
        else
            @sync begin
                ShaderAbstractions.switch_context!(screen.glscreen)
                render_frame(screen)
                GLFW.SwapBuffers(to_native(screen))
            end
            yield()
        end
    end
end

function fps_renderloop(screen::Screen, framerate=WINDOW_CONFIG.framerate[])
    time_per_frame = 1.0 / framerate
    while isopen(screen) && !WINDOW_CONFIG.exit_renderloop[]
        t = time_ns()
        pollevents(screen) # GLFW poll
        screen.render_tick[] = nothing
        if WINDOW_CONFIG.pause_rendering[]
            sleep(0.1)
        else
            @sync begin
                ShaderAbstractions.switch_context!(screen.glscreen)
                render_frame(screen)
                GLFW.SwapBuffers(to_native(screen))
            end
            t_elapsed = (time_ns() - t) / 1e9
            diff = time_per_frame - t_elapsed
            if diff > 0.001 # can't sleep less than 0.001
                sleep(diff)
            else # if we don't sleep, we still need to yield explicitely to other tasks
                yield()
            end
        end
    end
end

function renderloop(screen; framerate=WINDOW_CONFIG.framerate[])
    isopen(screen) || error("Screen most be open to run renderloop!")
    try
        if WINDOW_CONFIG.vsync[]
            GLFW.SwapInterval(1)
            vsynced_renderloop(screen)
        else
            GLFW.SwapInterval(0)
            fps_renderloop(screen, framerate)
        end
    catch e
        showerror(stderr, e, catch_backtrace())
        println(stderr)
        rethrow(e)
    finally
        destroy!(screen)
    end
end

const WINDOW_CONFIG = (renderloop = Ref{Function}(renderloop),
    vsync = Ref(false),
    framerate = Ref(30.0),
    float = Ref(false),
    pause_rendering = Ref(false),
    focus_on_show = Ref(false),
    decorated = Ref(true),
    title = Ref("Makie"),
    exit_renderloop = Ref(false),)

"""
    set_window_config!(;
        renderloop = renderloop,
        vsync = false,
        framerate = 30.0,
        float = false,
        pause_rendering = false,
        focus_on_show = false,
        decorated = true,
        title = "Makie"
    )
Updates the screen configuration, will only go into effect after closing the current
window and opening a new one!
"""
function set_window_config!(; kw...)
    for (key, value) in kw
        getfield(WINDOW_CONFIG, key)[] = value
    end
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
    nw = to_native(screen)
    ShaderAbstractions.is_context_active(nw) || return
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

function GLAbstraction.render(filter_elem_func, screen::GLScreen)
    # Somehow errors in here get ignored silently!?
    try
        for (zindex, screenid, elem) in screen.renderlist
            filter_elem_func(elem)::Bool || continue

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

            render(elem)
        end
    catch e
        @error "Error while rendering!" exception = e
        rethrow(e)
    end
    return
end
