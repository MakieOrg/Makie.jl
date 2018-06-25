import .GLAbstraction: bind, draw, textures, unbind, resize_targets!, draw_fullscreen
import FileIO: load


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
import .GLVisualize: GLVisualizeShader

default_pipeline(fbo, program)=
    # Pipeline(:default, [default_renderpass(fbo, program)])
    # Pipeline(:default, [default_renderpass(fbo, program), postprocess_renderpass(fbo), final_renderpass(fbo)])
    Pipeline(:default, [default_renderpass(fbo, program), postprocess_renderpass(fbo), fxaa_renderpass(fbo), final_renderpass(fbo)])

#TODO shadercleanup: cleanup gl_convert GLVisualizeShader etc
default_renderpass(fbo, program) = RenderPass(:default, program, fbo)

postprocess_renderpass(fbo) =
    RenderPass(:postprocess, gl_convert(LazyShader(loadshader("fullscreen.vert"),loadshader("postprocess.frag")),Dict{Symbol, Any}()), fbo)
fxaa_renderpass(fbo) =
    RenderPass(:fxaa, gl_convert(LazyShader(loadshader("fullscreen.vert"),loadshader("fxaa.frag")),Dict{Symbol, Any}()), fbo)

final_renderpass(fbo) =
    RenderPass(:final,gl_convert(LazyShader(loadshader("fullscreen.vert"),loadshader("copy.frag")),Dict{Symbol, Any}()), fbo)

#TODO run through all the visualize things and add the pipelines!
function makiepipeline(pipesym::Symbol, args...)
    pipesym == :default && return default_pipeline(args...)
end
#Defaults for pipeline and renderpasses. This could probably be put somewhere else.
#This could probably also be a bit cleaner with some thought

#Implementation of the setup interface for the default pipeline.
function setup(pipe::Pipeline{:default})
    glDisable(GL_STENCIL_TEST)
    # glEnable(GL_STENCIL_TEST)
    # glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    # glStencilMask(0xff)
    # glClearStencil(0)
    #
end

###WIP shadercleanup
function setup(rp::RenderPass{:default})
    bind(rp.target)
    draw(rp.target, 1:2)
    glClearColor(0,0,0,0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
    # clear!(rp.target) #this clears everything,
                      #so if textures get reused then we need to clear more
                      #specifically, lets try this first
    glEnable(GL_DEPTH_TEST)
    glDepthMask(GL_TRUE)
    glDepthFunc(GL_LEQUAL)
    # Disable cullface for now, untill all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)
    enabletransparency()

end

#Implementation of the rendering interfaces
function (rp::RenderPass{:default})(screen::Screen, renderlist)
    if isempty(screen.renderlist)
        return
    end
    glEnable(GL_SCISSOR_TEST)
    setup!(screen)
    glDisable(GL_SCISSOR_TEST)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    for (zindex, screenid, elem) in renderlist
        bind(elem.uniforms[:shader])
        Reactive.value(elem[:visible]) || continue
        found, rect = id2rect(screen, screenid)
        Reactive.value(found) || continue
        a = rect[]
        glViewport(minimum(a)..., widths(a)...)
        # glStencilFunc(GL_EQUAL, screenid, 0xff) #TODO rendercleanup: Can this be somewhere else?
        for (key,value) in elem.uniforms[:shader].uniformloc #TODO uniformbuffer: This should be inside a buffer I think
            if haskey(elem.uniforms, key) && elem.uniforms[key] != nothing
                if length(value) == 1
                    gluniform(value[1], elem.uniforms[key])
                elseif length(value) == 2
                    gluniform(value[1], value[2], elem.uniforms[key])
                else
                    error("Uniform tuple too long: $(length(value))")
                end
            end
        end
        draw(elem)
    end
    unbind(renderlist[end][3].vao)
    # glDisable(GL_STENCIL_TEST)
end

function setup(rp::RenderPass{:postprocess})
    draw(rp.target, 3) #only the color part of the fbo
    glDepthMask(GL_TRUE)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_BLEND)
    glDisable(GL_STENCIL_TEST)
    glStencilMask(0xff)
    glDisable(GL_CULL_FACE)
    glClearColor(0,0,0,0)
    glClear(GL_COLOR_BUFFER_BIT)
end

#this has the luma FBO
function (rp::RenderPass{:postprocess})(screen::Screen, args...)
    program = rp.program
    location, target = program.uniformloc[:color_texture]
    gluniform(location, target, textures(rp.target)[1])
    draw_fullscreen(screen.fullscreenvao)
end

#maybe glviewport needs to be here
function setup(rp::RenderPass{:fxaa})
    bind(rp.target)
    draw(rp.target, 1) #copy back to original color
end

function (rp::RenderPass{:fxaa})(screen::Screen, args...)
    program = rp.program
    location, target = program.uniformloc[:color_texture]
    rcploc = program.uniformloc[:RCPFrame]
    gluniform(location, target, textures(rp.target)[3])
    gluniform(rcploc[1], GLuint.([size(rp.target)...]))
    draw_fullscreen(screen.fullscreenvao)
end

function setup(rp::RenderPass{:final})
    unbind(rp.target)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
end

function (rp::RenderPass{:final})(screen::Screen, args...)
    program = rp.program
    location, target = program.uniformloc[:color_texture]
    gluniform(location, target, textures(rp.target)[1])
    draw_fullscreen(screen.fullscreenvao)
end

"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen)
    (!isopen(screen) || isempty(screen.pipelines)) && return
                           #postprocess1
    nw = to_native(screen)
    wh = Int.(GLFW.GetFramebufferSize(nw))
    #TODO framebuffercleanup: resizing framebuffers == GLViewport... ?
    glViewport(0, 0, wh[1], wh[2])

    #run through all the pipes in the queue and push the robjs linked to them through them.
    for pipe in screen.pipelines
        !haskey(screen.renderlist, pipe.name) && return #TODO what is going on here??

        resize_targets!(pipe, wh)
        render(pipe, screen, screen.renderlist[pipe.name])
    end
    return
end

function id2rect(screen, id1)
    # TODO maybe we should use a different data structure
    for (id2, rect, clear, color) in screen.screens
        id1 == id2 && return true, rect
    end
    false, IRect(0,0,0,0)
end
