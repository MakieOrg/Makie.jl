using GLMakie, ModernGL
using GLMakie.ShaderAbstractions
GLMakie.closeall()

function accum_render(screen)
    nw = to_native(screen)
    ShaderAbstractions.switch_context!(nw)
    fb = screen.framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    glDrawBuffer(GL_COLOR_ATTACHMENT1)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_SCISSOR_TEST)
    glDepthMask(GL_FALSE)
    glEnablei(GL_BLEND, accum_id)
    glBlendEquationSeparate(GLenum modeRGB​, GLenum modeAlpha​);
    GLAbstraction.render(screen) do robj
        return true
    end
    glFinish()

end

function accum_render(framebuffer, shader_cache)
    # Add missing buffers
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id[1])
    accum_buffer = Texture(Float32, size(framebuffer); minfilter=:linear, x_repeat=:clamp_to_edge)
    accum_id = attach_colorbuffer!(framebuffer, :accumulation, color_luma_buffer)

    color_id = framebuffer[:accumulation][1]
    function render_accum(screen)
        fb = screen.framebuffer
        w, h = size(fb)
        glDrawBuffer(accum_id)

        glViewport(0, 0, w, h)
        glClearColor(0,0,0,0)
        glClear(GL_COLOR_BUFFER_BIT)
        GLAbstraction.render(pass1)
    end

    return PostProcessor(RenderObject[], (screen)-> nothing, accum_render)
end



second_screen = GLMakie.Screen(resolution=(800, 800), title="Display")
render_screen = GLMakie.Screen(resolution=(800, 800), title="Render", visible=false, start_renderloop=false)
for i in 2:3
    GLMakie.replace_processor!(render_screen, GLMakie.empty_postprocessor(), i)
end

scene1 = Scene();
image!(scene1, rand(800, 800); colorrange=(0, 1));
scatter!(scene1, [rand(Point2f) .* Point2f(800, 800) for i in 1:10^3]; colorrange=(0, 1), marker=GLMakie.FastPixel(), color=RGBAf(0.00001, 0, 0, 1));
campixel!(scene1)
display(render_screen, scene1)
GLMakie.render_frame(render_screen)
texture = render_screen.framebuffer.buffers[:color]

scene = Scene();
GLMakie.ShaderAbstractions.switch_context!(second_screen.glscreen)
image!(scene, texture; colorrange=(0, 1));
campixel!(scene)
display(second_screen, scene)
