function to_pixel2(point, dims)
    lon, lat = point[1], point[2]
    x = ((dims[2]/180.0) * (90 + (lon / 10^7)))
    y = ((dims[1]/360.0) * (180 - (lat / 10^7)))
    Point2f0(y, x)
end


using MakiE, Images
scene = Scene()
scat = scatter(rand(Point2f0, 10^6) .* 1000f0, markersize = 0.2, color = (:blue, 0.4))
gpu_buff = scene[:screen].renderlist[1][1][:position]
scene[:screen].clear = false
scat[:markersize] = 0.1
w = Point2f0(widths(screen))
scat[:positions] = rand(Point2f0, 10^6)
scat[:color] = (:white, 0.1)
center!(scene)
using ModernGL

function render_no_clear(window)
    !isopen(window) && return
    fb = GLWindow.framebuffer(window)
    wh = widths(window)
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
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
    glEnable(GL_SCISSOR_TEST)
    GLWindow.setup_window(window, false)
    glDisable(GL_SCISSOR_TEST)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    # deactivate stencil write
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(window, true)
    glDisable(GL_STENCIL_TEST)

    # transfer color to luma buffer and apply fxaa
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[2]) # luma framebuffer
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
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
    GLAbstraction.render(window, false)
    glDisable(GL_STENCIL_TEST)
    # draw strokes
    glEnable(GL_SCISSOR_TEST)
    GLWindow.setup_window(window, true)
    glDisable(GL_SCISSOR_TEST)
    glViewport(0,0, wh...)
    #Read all the selection queries
    GLWindow.push_selectionqueries!(window)
    glBindFramebuffer(GL_FRAMEBUFFER, 0) # transfer back to window
    glClearColor(0,0,0,0)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[3]) # copy postprocess
    return
end

function render_points(points, scene, gpu_buff, n = typemax(Int))
    screen = scene[:screen]
    dims = (widths(screen)...,)
    N = min(n, length(points))
    NBuff = length(gpu_buff)
    slices = floor(Int, N / NBuff)
    for i = 1:NBuff:N
        GLWindow.poll_glfw()
        ptr, _ = start(gpu_buff)
        for j = 1:NBuff
            @inbounds p = to_pixel2(points[i + (j - 1)], dims)
            unsafe_store!(ptr, p, j)
        end
        done(gpu_buff, (ptr, length(gpu_buff) + 1)) # unmap buffer
        render_no_clear(screen)
        GLWindow.swapbuffers(screen)
        glFinish()
    end
end
path = render_points(points, scene, gpu_buff)
screen = scene[:screen]
dims = reverse(widths(screen))