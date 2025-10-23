# This defines the Stages available in base GLMakie as well as the default
# render pipeline

SortStage() = Stage(:ZSort)

function RenderStage(; kwargs...)
    outputs = [
        :depth => BufferFormat(1, BFT.depth24_stencil),
        :color => BufferFormat(4, N0f8),
        :objectid => BufferFormat(2, UInt32),
    ]
    return Stage(:Render; outputs, kwargs...)
end

function SSAORenderStage(; kwargs...)
    outputs = [
        :depth => BufferFormat(1, BFT.depth24_stencil),
        :color => BufferFormat(4, N0f8),
        :objectid => BufferFormat(2, UInt32),
        :position => BufferFormat(3, Float16),
        :normal => BufferFormat(3, Float16),
    ]
    return Stage(Symbol("SSAO Render"); outputs, kwargs...)
end

function TransparentRenderStage()
    outputs = [
        :depth => BufferFormat(1, BFT.depth24_stencil),
        :color_sum => BufferFormat(4, Float16),
        :objectid => BufferFormat(2, UInt32),
        :transmittance => BufferFormat(1, N0f8),
    ]
    return Stage(Symbol("OIT Render"); outputs)
end

function SSAOStage(; kwargs...)
    inputs = [
        :position => BufferFormat(3, Float32),
        :normal => BufferFormat(3, Float16),
    ]
    stage1 = Stage(:SSAO1, inputs, [:occlusion => BufferFormat(1, N0f8)]; kwargs...)

    inputs = [
        :occlusion => BufferFormat(1, N0f8),
        :color => BufferFormat(4, N0f8),
        :objectid => BufferFormat(2, UInt32),
    ]
    stage2 = Stage(:SSAO2, inputs, [:color => BufferFormat()]; kwargs...)

    pipeline = RenderPipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

function OITStage(; kwargs...)
    inputs = [:color_sum => BufferFormat(4, Float16), :transmittance => BufferFormat(1, N0f8)]
    outputs = [:color => BufferFormat(4, N0f8)]
    return Stage(:OIT, inputs, outputs; kwargs...)
end

function FXAAStage(; kwargs...)
    stage1 = Stage(
        :FXAA1,
        [:color => BufferFormat(4, N0f8), :objectid => BufferFormat(2, UInt32)],
        [:color_luma => BufferFormat(4, N0f8)];
        kwargs...
    )

    stage2 = Stage(
        :FXAA2,
        [:color_luma => BufferFormat(4, N0f8, minfilter = :linear)],
        [:color => BufferFormat(4, N0f8)];
        kwargs...
    )

    pipeline = RenderPipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

function DisplayStage()
    return Stage(
        :Display,
        inputs = [
            :depth => BufferFormat(1, BFT.depth24_stencil),
            :color => BufferFormat(4, N0f8),
            :objectid => BufferFormat(2, UInt32),
        ],
    )
end

function MSAAResolveStage(source_stage::Stage)
    # TODO: Should this generate multiple independent stages?
    inputs = Vector{Pair{Symbol, BufferFormat}}(undef, length(source_stage.outputs))
    outputs = Vector{Pair{Symbol, BufferFormat}}(undef, length(source_stage.outputs))
    for (name, idx) in source_stage.outputs
        format = source_stage.output_formats[idx]
        inputs[idx] = name => format
        outputs[idx] = name => BufferFormat(format, samples = 1)
    end

    return Stage(:MSAAResolve; inputs, outputs)
end


function default_pipeline(; ssao = false, fxaa = true, oit = true)
    pipeline = RenderPipeline()
    push!(pipeline, SortStage())

    # Note - order important!
    # TODO: maybe add insert!()?
    if ssao
        render1 = push!(pipeline, SSAORenderStage(ssao = true, transparency = false))
        _ssao = push!(pipeline, SSAOStage())
        render2 = push!(pipeline, RenderStage(ssao = false, transparency = false))
    else
        render2 = push!(pipeline, RenderStage(transparency = false))
    end
    if oit
        render3 = push!(pipeline, TransparentRenderStage())
        _oit = push!(pipeline, OITStage())
    else
        render3 = push!(pipeline, RenderStage(transparency = true))
    end
    if fxaa
        _fxaa = push!(pipeline, FXAAStage(filter_in_shader = true))
    end
    display = push!(pipeline, DisplayStage())


    if ssao
        connect!(pipeline, render1, _ssao)
        connect!(pipeline, _ssao, fxaa ? _fxaa : display, :color)
    end
    connect!(pipeline, render2, fxaa ? _fxaa : display)
    if oit
        connect!(pipeline, render3, _oit)
        connect!(pipeline, _oit, fxaa ? _fxaa : display, :color)
    else
        connect!(pipeline, render3, fxaa ? _fxaa : display, :color)
    end
    if fxaa
        connect!(pipeline, _fxaa, display, :color)
    end
    connect!(pipeline, :objectid)
    connect!(pipeline, :depth)

    return pipeline
end
