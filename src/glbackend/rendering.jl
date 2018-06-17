import .GLAbstraction: bind, draw, textures, unbind

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

function was_destroyed(nw)
    if isdefined(GLFW, :_window_callbacks)
        !haskey(GLFW._window_callbacks, nw)
    elseif !isimmutable(nw)
        nw.handle == C_NULL
    else
        error("Unknown GLFW.jl version. Can't verify if window is destroyed")
    end
end
function destroy!(nw::GLFW.Window)
    if nw.handle != C_NULL
        was_destroyed(nw) || GLFW.DestroyWindow(nw)
        # GLFW.jl compat - newer versions are immutable and don't need to be set to C_NULL
        if !isimmutable(nw)
            nw.handle = C_NULL
        end
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

const selection_queries = Function[]


import .GLAbstraction: defaultframebuffer, RenderPass, Pipeline, setup

default_pipeline(fbo)=Pipeline(:default, [default_renderpass(fbo), postprocess_renderpass(fbo), fxaa_renderpass(fbo), final_renderpass(fbo)])

default_renderpass(fbo) =
    RenderPass(:default, [loadshader("fullscreen.vert"), loadshader("default.frag")], fbo)
postprocess_renderpass(fbo) =
    RenderPass(:postprocess, [loadshader("fullscreen.vert"), loadshader("postprocess.frag")], fbo)
fxaa_renderpass(fbo) =
    Renderpass(:fxaa, [loadshader("fullscreen.vert"), loadshader("fxaa.frag")], fbo)

final_renderpass(fbo) =
    Renderpass(:final, [loadshader("fullscreen.vert"), loadshader("copy.frag")], fbo)
#Defaults for pipeline and renderpasses. This could probably be put somewhere else.
#This could probably also be a bit cleaner with some thought

#Implementation of the setup interface for the default pipeline.
function setup(pipe::Pipeline{:default})

    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0xff)
    glClearStencil(0)
    glViewport(0, 0, w, h) #This used to be in between default render pass and
                           #postprocess1

end

function setup(rp::RenderPass{:default})
    bind(rp.target)
    draw(rp.target, 1:2)
    clear!(rp.target) #this clears everything,
                      #so if textures get reused then we need to clear more
                      #specifically, lets try this first
end

#Implementation of the rendering interfaces
function (rp::RenderPass{:default})(screen::Screen)
    if isempty(screen.renderlist)
        return
    end
    glEnable(GL_SCISSOR_TEST)
    setup!(screen)
    glDisable(GL_SCISSOR_TEST)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)

    for (zindex, screenid, elem) in screen.renderlist
        found, rect = id2rect(screen, screenid)
        found || continue
        a = rect[]
        glViewport(minimum(a)..., widths(a)...)
        glStencilFunc(GL_EQUAL, screenid, 0xff)
        render(elem)
    end

    glDisable(GL_STENCIL_TEST)
end

function setup(rp::RenderPass{:postprocess})
    glDepthMask(GL_TRUE)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_BLEND)
    glDisable(GL_STENCIL_TEST)
    glStencilMask(0xff)
    glDisable(GL_CULL_FACE)
#target doesn't need to be bound since it's still bound from before I think
    draw(rp.target, 3) #only the color part of the fbo
end

#this has the luma FBO
function (rp::RenderPass{:postprocess})(screen::Screen)
    program = rp.program
    location, target = program.uniformloc[:color_texture]
    gluniform(location, target, textures(rp.target)[1])
    draw_fullscreen(screen.fullscreenvao)
end

#maybe glviewport needs to be here
function setup(rp::RenderPass{:fxaa})
    draw(rp.target, 1) #copy back to original color
end

function (rp::RenderPass{:fxaa})(screen::Screen)
    location, target = program.uniformloc[:color_texture]
    rcploc = program.uniformloc[:RCPFrame]
    gluniform(location, target, textures(rp.target)[3])
    gluniform(rcploc, size(rp.target))
    draw_fullscreen(screen.fullscreenvao)
end

function setup(rp::RenderPass{:final})
    unbind(rp.target)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
end

function (rp::RenderPass{:final})(screen::Screen)
    program = rp.program
    location, target = program.uniformloc[:color_texture]
    gluniform(location, target, textures(rp.target)[1])
    draw_fullscreen(screen.fullscreenvao)
end

"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen)
    !isopen(screen) && return
    nw = to_native(screen)
    wh = Int.(GLFW.GetFramebufferSize(nw))

    resize_targets!(screen.pipeline, wh)
    render(screen.pipeline, screen)
    return
end

function id2rect(screen, id1)
    # TODO maybe we should use a different data structure
    for (id2, rect, clear, color) in screen.screens
        id1 == id2 && return true, rect
    end
    false, IRect(0,0,0,0)
end
