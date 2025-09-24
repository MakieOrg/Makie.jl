"""
    initialize_attachments!(manager::FramebufferManager, formats)

Populates a `FramebufferManager` with buffers corresponding to the given formats.
These are then used to create Framebuffers.
"""
function initialize_attachments!(manager::FramebufferManager, formats::Vector{Makie.BufferFormat})
    # Implies `empty!(manager)` has not been called
    @assert isempty(manager.buffers) "Cannot initialize FramebufferManager that has already been initialized."

    # function barrier for types?
    function get_buffer!(context, T, format)
        is_float_format = eltype(T) == N0f8 || eltype(T) <: AbstractFloat
        default_filter = ifelse(is_float_format, :linear, :nearest)
        minfilter = ifelse(format.minfilter === :any, ifelse(format.mipmap, :linear_mipmap_linear, default_filter), format.minfilter)
        magfilter = ifelse(format.magfilter === :any, default_filter, format.magfilter)

        if !is_float_format && (format.mipmap || minfilter != :nearest || magfilter != :nearest)
            error("Cannot use :linear interpolation or mipmaps with non float buffers.")
        end

        # TODO: Figure out what we need to do for mipmaps. Do we need to call
        #       glGenerateMipmap before every stage using the buffer? Should
        #       Stages do that? Do we need anything extra for setup?
        format.mipmap && error("Mipmaps not yet implemented for Pipeline buffers")

        return Texture(
            context, T, size(manager), minfilter = minfilter, magfilter = magfilter,
            x_repeat = format.repeat[1], y_repeat = format.repeat[2]
        )
    end

    # Add buffers in the order of `formats`
    for format in formats
        tex = get_buffer!(manager.fb.context, Makie.format_to_type(format), format)
        push!(manager.buffers, tex)
    end

    return manager
end

"""
    gl_render_pipeline!(screen, pipeline::Makie.RenderPipeline)

Constructs a new `GLRenderPipeline` from a `Makie.RenderPipeline` and adds it
to the given `screen`. If a `GLRenderPipeline` already exists, it is destroyed
and replaced. This will also reset the `FramebufferManager`.
"""
function gl_render_pipeline!(screen::Screen, pipeline::Makie.RenderPipeline)
    pipeline.stages[end].name === :Display || error("RenderPipeline must end with a Display stage")
    previous_pipeline = screen.render_pipeline

    # Exit early if the pipeline is already up to date
    previous_pipeline.parent == pipeline && return

    # Reset GL renderpipeline
    manager = screen.framebuffer_manager
    ShaderAbstractions.switch_context!(screen.glscreen)
    screen.render_pipeline = GLRenderPipeline()

    # Resolve pipeline into a set of buffers (merging and reusing buffers when possible)
    buffers, remap = Makie.generate_buffers(pipeline)

    # Generate all the necessary attachments in the order given above so the
    # correct GLFramebuffers can be generated
    destroy!(manager)
    reset_main_framebuffer!(manager)
    initialize_attachments!(manager, buffers)

    # Add back output color and objectid attachments
    # This assumes the last stage to be the Display stage with inputs (color, objectid)
    @assert pipeline.stages[end].name === :Display "Last Stage must be Display"
    @assert get(pipeline.stages[end].inputs, :color, 0) == 1 "Display stage must have input :color at index 1"
    @assert get(pipeline.stages[end].inputs, :objectid, 0) == 2 "Display stage must have input :objectid at index 2"

    N = length(pipeline.stages)
    buffer_idx = remap[pipeline.stageio2idx[(N, -1)]]
    attach_colorbuffer(manager.fb, :color, get_buffer(manager, buffer_idx))
    buffer_idx = remap[pipeline.stageio2idx[(N, -2)]]
    attach_colorbuffer(manager.fb, :objectid, get_buffer(manager, buffer_idx))

    # Constructing a RenderStep can be somewhat costly, so we want to reuse them
    # if possible. Steps that aren't reused and thus need to be deleted are
    # tracked here:
    needs_cleanup = collect(eachindex(previous_pipeline.steps))
    render_pipeline = AbstractRenderStep[]

    for (stage_idx, stage) in enumerate(pipeline.stages)
        # Get input buffers of the current stage
        inputs = Dict{Symbol, Any}()
        for (key, input_idx) in stage.inputs
            idx = remap[pipeline.stageio2idx[(stage_idx, -input_idx)]]
            inputs[Symbol(key, :_buffer)] = get_buffer(manager, idx)
        end

        # Get buffer indices for stage outputs.
        # Note that outputs aren't always connected and thus do not always have
        # associated buffers. Disconnected outputs must be trailing though, i.e.
        # if output i is connected and i+1 is disconnected, outputs 1..i must
        # be connected and i+1..end must be disconnected. This is verified by
        # `generate_buffers`. Here we just need to filter the disconnected tail.
        connection_indices = map(eachindex(stage.output_formats)) do output_idx
            return get(pipeline.stageio2idx, (stage_idx, output_idx), -1)
        end
        N = length(connection_indices)
        while (N > 0) && (connection_indices[N] == -1)
            N = N - 1
        end

        if isempty(connection_indices)
            framebuffer = nothing
        else
            try
                idx2name = Dict([idx => k for (k, idx) in stage.outputs])
                outputs = ntuple(N) do n
                    remap[connection_indices[n]] => idx2name[n]
                end
                framebuffer = generate_framebuffer(manager, outputs...)
            catch e
                rethrow(e)
            end
        end

        # If the RenderStep already exists, update and reuse it, otherwise create it
        idx = findfirst(==(stage), previous_pipeline.parent.stages)
        if idx === nothing
            pass = construct(Val(stage.name), screen, framebuffer, inputs, stage)
        else
            pass = reconstruct(previous_pipeline.steps[idx], screen, framebuffer, inputs, stage)
            filter!(!=(idx), needs_cleanup)
        end

        # I guess stage should also have extra information for settings? Or should
        # that be in scene.theme?
        # Maybe just leave it there for now
        push!(render_pipeline, pass)
    end

    # Cleanup any old RenderStep that has not been reused, passing along which
    # buffers must be preserved.
    foreach(i -> destroy!(previous_pipeline.steps[i]), needs_cleanup)

    screen.render_pipeline = GLRenderPipeline(pipeline, render_pipeline)

    return
end
