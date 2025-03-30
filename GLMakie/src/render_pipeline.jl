function Makie.reset!(factory::FramebufferFactory, formats::Vector{Makie.BufferFormat})
    @assert factory.fb.id != 0 "Cannot reset a destroyed FramebufferFactory"
    GLAbstraction.free.(factory.children)
    empty!(factory.children)

    # function barrier for types?
    function get_buffer!(context, buffers, T, format)
        # reuse
        internalformat = GLAbstraction.default_internalcolorformat(T)
        is_float_format = eltype(T) == N0f8 || eltype(T) <: AbstractFloat
        default_filter = ifelse(is_float_format, :linear, :nearest)
        minfilter = ifelse(format.minfilter === :any, ifelse(format.mipmap, :linear_mipmap_linear, default_filter), format.minfilter)
        magfilter = ifelse(format.magfilter === :any, default_filter, format.magfilter)

        for (i, buffer) in enumerate(buffers)
            if (buffer.id != 0) && (internalformat == buffer.internalformat) &&
                (minfilter == buffer.parameters.minfilter) &&
                (magfilter == buffer.parameters.magfilter) &&
                (format.repeat == buffer.parameters.repeat) &&
                (format.mipmap == buffer.parameters.mipmap)

                return popat!(buffers, i)
            end
        end

        # create new
        if !is_float_format && (format.mipmap || minfilter != :nearest || magfilter != :nearest)
            error("Cannot use :linear interpolation or mipmaps with non float buffers.")
        end
        format.mipmap && error("Mipmaps not yet implemented for Pipeline buffers")
        # TODO: Figure out what we need to do for mipmaps. Do we need to call
        #       glGenerateMipmap before every stage using the buffer? Should
        #       Stages do that? Do we need anything extra for setup?
        return Texture(context, T, size(factory),
            minfilter = minfilter, magfilter = magfilter,
            x_repeat = format.repeat[1], y_repeat = format.repeat[2])
    end

    # reuse buffers that match formats (and make sure that factory.buffers
    # follows the order of formats)
    buffers = copy(factory.buffers)
    empty!(factory.buffers)
    for format in formats
        T = Makie.format_to_type(format)
        tex = get_buffer!(factory.fb.context, buffers, T, format)
        push!(factory.buffers, tex)
    end

    # clean up leftovers
    foreach(GLAbstraction.free, buffers)

    # Always rebuild this though, since we don't know which buffers are the
    # final output buffers
    fb = GLFramebuffer(factory.fb.context, size(factory))
    attach_depthstencilbuffer(fb, :depth_stencil, get_buffer(factory.fb, :depth_stencil))
    GLAbstraction.free(factory.fb)
    factory.fb = fb

    return factory
end


function gl_render_pipeline!(screen::Screen, pipeline::Makie.RenderPipeline)
    pipeline.stages[end].name === :Display || error("RenderPipeline must end with a Display stage")
    previous_pipeline = screen.render_pipeline

    # Exit early if the pipeline is already up to date
    previous_pipeline.parent == pipeline && return

    # TODO: check if pipeline is different from the last one before replacing it
    factory = screen.framebuffer_factory

    ShaderAbstractions.switch_context!(screen.glscreen)

    screen.render_pipeline = GLRenderPipeline()

    # Resolve pipeline
    buffers, remap = Makie.generate_buffers(pipeline)

    # Add required buffers
    reset!(factory, buffers)

    # Add back output color and objectid attachments
    N = length(pipeline.stages)
    buffer_idx = remap[pipeline.stageio2idx[(N, -1)]]
    attach_colorbuffer(factory.fb, :color, get_buffer(factory, buffer_idx))
    buffer_idx = remap[pipeline.stageio2idx[(N, -2)]]
    attach_colorbuffer(factory.fb, :objectid, get_buffer(factory, buffer_idx))

    # Careful - framebuffer attachments are used as inputs so they need to be
    #           filtered when destroying the stage! (Which may include other
    #           other textures that do need cleanup)
    keep_alive = [tex.id for tex in screen.framebuffer_factory.buffers]
    push!(keep_alive, get_buffer(factory.fb, :depth_stencil).id)

    needs_cleanup = collect(eachindex(previous_pipeline.steps))
    render_pipeline = AbstractRenderStep[]

    for (stage_idx, stage) in enumerate(pipeline.stages)
        inputs = Dict{Symbol, Any}()
        for (key, input_idx) in stage.inputs
            idx = remap[pipeline.stageio2idx[(stage_idx, -input_idx)]]
            inputs[Symbol(key, :_buffer)] = get_buffer(factory, idx)
        end

        connection_indices = map(eachindex(stage.output_formats)) do output_idx
            return get(pipeline.stageio2idx, (stage_idx, output_idx), -1)
        end

        N = length(connection_indices) + 1
        while (N > 1) && (connection_indices[N-1] == -1)
            N = N-1
        end

        if isempty(connection_indices)
            framebuffer = nothing
        else
            try
                idx2name = Dict([idx => k for (k, idx) in stage.outputs])
                outputs = ntuple(N-1) do n
                    remap[connection_indices[n]] => idx2name[n]
                end
                framebuffer = generate_framebuffer(factory, outputs...)
            catch e
                rethrow(e)
            end
        end

        # can we reconstruct? (reconstruct should update framebuffer, and replace
        # inputs if necessary, i.e. handle differences in connections and attributes)
        idx = findfirst(==(stage), previous_pipeline.parent.stages)

        if idx === nothing
            pass = construct(Val(stage.name), screen, framebuffer, inputs, stage)
        else
            pass = reconstruct(previous_pipeline.steps[idx], screen, framebuffer, inputs, stage, keep_alive)
            filter!(!=(idx), needs_cleanup)
        end

        # I guess stage should also have extra information for settings? Or should
        # that be in scene.theme?
        # Maybe just leave it there for now
        push!(render_pipeline, pass)
    end

    # Cleanup orphaned stages
    foreach(i -> destroy!(previous_pipeline.steps[i], keep_alive), needs_cleanup)

    screen.render_pipeline = GLRenderPipeline(pipeline, render_pipeline)

    return
end