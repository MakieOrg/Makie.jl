"""
Renders a single frame of a `window`
"""
function render_frame(screen::Screen; resize_buffers=true)
    render_frame(screen, screen.scene_tree.scenes, resize_buffers)
end

function render_frame(screen::Screen, glscenes::Vector{GLScene}, resize_buffers=true)
    nw = to_native(screen)
    ShaderAbstractions.switch_context!(nw)

    # Resize buffers
    fb = screen.framebuffer
    if resize_buffers && !isnothing(screen.root_scene)
        ppu = screen.px_per_unit[]
        resize!(fb, round.(Int, ppu .* size(screen.root_scene))...)
    end
    
    # Clear final output
    # TODO: Could be skipped if glscenes[1] clears
    OUTPUT_FRAMEBUFFER_ID = 0
    glBindFramebuffer(GL_FRAMEBUFFER, OUTPUT_FRAMEBUFFER_ID)
    wh = framebuffer_size(nw)
    glViewport(0, 0, wh[1], wh[2])

    glClearColor(1,0,0,1)
    glClear(GL_COLOR_BUFFER_BIT)
    
    # Reset all intermediate buffers
    # TODO: really just need color, objectid here? (additionals clear per scene)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    glDrawBuffers(length(fb.render_buffer_ids), fb.render_buffer_ids)
    glClearColor(0, 0, 0, 0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    # Draw scene by scene
    glEnable(GL_SCISSOR_TEST)
    for (i, glscene) in enumerate(glscenes)
        @info "Rendering scene $i"
        render_frame(screen, glscene)
    end
    glDisable(GL_SCISSOR_TEST)

    # TODO: copy accumulation buffer to screen buffer
    # screen.postprocessors[4].render(screen)
end


function render_frame(screen::Screen, glscene::GLScene)
    # TODO: Not like this
    if glscene.scene === nothing
        @warn "Parent scene unavailable"
        return
    end

    clear = glscene.clear[]::Bool
    renderlist = glscene.renderobjects::Vector{RenderObject}

    # if the scene doesn't have a visual impact we skip
    if !glscene.visible[] || (isempty(renderlist) && !clear)
        @info "Skipped due to visible = $(glscene.visible[]) or empty renderlist $(isempty(renderlist)) && clear = $clear"
        return
    end

    nw = to_native(screen)
    fb = screen.framebuffer # required

    # z-sorting
    function sortby(robj)
        plot = glscene.robj2plot[robj.id]
        # TODO, use actual boundingbox
        return Makie.zvalue2d(plot)
    end
    zvals = sortby.(glscene.renderobjects)
    permute!(glscene.renderobjects, sortperm(zvals))

    # Redundant?
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)

    # Set/Restrict draw area
    # TODO: move to glscreen?
    mini = round.(Int, screen.px_per_unit[] .* minimum(glscene.viewport[]))
    wh   = round.(Int, screen.px_per_unit[] .* widths(glscene.viewport[]))
    @inbounds glViewport(mini[1], mini[2], wh[1], wh[2])
    @inbounds glScissor(mini[1], mini[2], wh[1], wh[2])
    @info mini, wh

    # TODO: better solution
    # render buffers are (color, objectid, maybe position, maybe normals)
    # color, objectid should only be cleared if glscene.clear == true
    # position, normals are only relevant for SSAO but should be cleared
    # TODO: make DEPTH clear optional?
    # TODO: unpadded clears may create edge-artifacts with SSAO, FXAA
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    glDrawBuffers(length(fb.render_buffer_ids)-2, fb.render_buffer_ids[2:end])
    glClearColor(0, 0, 0, 0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    if glscene.clear[]
        @info "clearing"
        # Draw background color
        glDrawBuffer(fb.render_buffer_ids[1]) # accumulation color buffer
        c = glscene.backgroundcolor[]::RGBAf
        a = alpha(c)
        # @info a * red(c), a * green(c), a * blue(c), 1f0 - a
        glClearColor(a * red(c), a * green(c), a * blue(c), 1f0 - a)
        glClear(GL_COLOR_BUFFER_BIT)

        # If previous picked plots are no longer visible they should not be pickable
        if alpha(c) == 1f0
            glDrawBuffer(fb.render_buffer_ids[2]) # objectid, i.e. picking
            glClearColor(0, 0, 0, 0)
            glClear(GL_COLOR_BUFFER_BIT)
        end
    else
        @info "no clear"
        # TODO: maybe SSAO needs this cleared if we run it per scene...?
        glDrawBuffer(fb.render_buffer_ids[1]) # accumulation color buffer
        glClearColor(0, 0, 0, 1)
        glClear(GL_COLOR_BUFFER_BIT)
    end

    # NOTE
    # The transparent color buffer is reused by SSAO and FXAA. Changing the
    # render order here may introduce artifacts because of that.

    # TODO: clear SSAO buffers here?
    # render with SSAO
    glDrawBuffers(length(fb.render_buffer_ids), fb.render_buffer_ids) # activate all render outputs
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    GLAbstraction.render(glscene) do robj
        return !Bool(robj[:transparency][]) && Bool(robj[:ssao][])
    end
    # SSAO postprocessor
    # TODO: when moving postprocessors to Scene the postprocessor should not need any extra inputs
    screen.postprocessors[1].render(screen, glscene.ssao, glscene.scene.value.camera.projection[])

    # render no SSAO
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1]) # color, objectid
    # render all non ssao
    GLAbstraction.render(glscene) do robj
        return !Bool(robj[:transparency][]) && !Bool(robj[:ssao][])
    end

    # TRANSPARENT RENDER
    # clear sums to 0
    glDrawBuffer(GL_COLOR_ATTACHMENT2) # HDR color (i.e. 16 Bit precision)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    # clear alpha product to 1
    glDrawBuffer(GL_COLOR_ATTACHMENT3) # OIT weight buffer
    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    # draw
    glDrawBuffers(3, [GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT3]) # HDR color, objectid, OIT weight
    # Render only transparent objects
    GLAbstraction.render(glscene) do robj
        return Bool(robj[:transparency][])
    end

    # TRANSPARENT BLEND
    screen.postprocessors[2].render(screen)

    # FXAA
    # screen.postprocessors[3].render(screen)

    # transfer everything to the screen
    # TODO: accumulation buffer would avoid viewport/scissor reset
    screen.postprocessors[4].render(screen, mini[1], mini[2], wh[1], wh[2])

    return
end

function GLAbstraction.render(filter_elem_func, glscene::GLScene)
    # Somehow errors in here get ignored silently!?
    try
        for robj in glscene.renderobjects
            filter_elem_func(robj)::Bool || continue
            robj.visible || continue
            @info "Rendering robj $(robj.id)"
            render(robj)
        end
    catch e
        @error "Error while rendering!" exception = e
        rethrow(e)
    end
    return
end
