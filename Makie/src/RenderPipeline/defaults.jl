# This defines the RenderStages available in base GLMakie as well as the default
# render pipeline

"""
    SortStage()

Sorts plots based on the z translation of their model matrix.
"""
SortStage() = RenderStage(:ZSort)

"""
    PlotRenderStage([; fxaa, ssao, oit])

Renders plots with depth, color and objectid outputs.

Optionally `fxaa`, `ssao` and `oit` can be set to true or false to filter plots
with the respective `fxaa`, `ssao` and `transparency` attribute values. By
default any value passes.
"""
function PlotRenderStage(; kwargs...)
    outputs = [
        :depth => BufferFormat(1, BFT.depth24),
        :color => BufferFormat(4, N0f8),
        :objectid => BufferFormat(2, UInt32),
    ]
    return RenderStage(:Render; outputs, kwargs...)
end

"""
    SSAOPlotRenderStage([; fxaa, ssao, oit])

Renders plots with depth, color, objectid, position and normal outputs.

Optionally `fxaa`, `ssao` and `oit` can be set to true or false to filter plots
with the respective `fxaa`, `ssao` and `transparency` attribute values. By
default any value passes.
"""
function SSAOPlotRenderStage(; ssao = true, kwargs...)
    outputs = [
        :depth => BufferFormat(1, BFT.depth24),
        :color => BufferFormat(4, N0f8),
        :objectid => BufferFormat(2, UInt32),
        :position => BufferFormat(3, Float16),
        :normal => BufferFormat(3, Float16),
    ]
    return RenderStage(Symbol("SSAO Render"); outputs, ssao, kwargs...)
end

"""
    TransparentPlotRenderStage([; fxaa, ssao, oit])

Renders plots with depth, color_sum, objectid, transmittance outputs.

Optionally `fxaa`, `ssao` and `oit` can be set to true or false to filter plots
with the respective `fxaa`, `ssao` and `transparency` attribute values. By
default any value passes.
"""
function TransparentPlotRenderStage(; oit = true)
    outputs = [
        :depth => BufferFormat(1, BFT.depth24),
        :color_sum => BufferFormat(4, Float16),
        :objectid => BufferFormat(2, UInt32),
        :transmittance => BufferFormat(1, N0f8),
    ]
    return RenderStage(Symbol("OIT Render"); oit, outputs)
end

"""
    SSAOStage()

Applies Screen Space Ambient Occlusion to the color buffer using a position and
normal inputs.
"""
function SSAOStage(; kwargs...)
    inputs = [
        :position => BufferFormat(3, Float32),
        :normal => BufferFormat(3, Float16),
    ]
    stage1 = RenderStage(:SSAO1, inputs, [:occlusion => BufferFormat(1, N0f8)]; kwargs...)

    inputs = [
        :occlusion => BufferFormat(1, N0f8),
        :color => BufferFormat(4, N0f8),
        :objectid => BufferFormat(2, UInt32),
    ]
    stage2 = RenderStage(:SSAO2, inputs, [:color => BufferFormat()]; kwargs...)

    pipeline = RenderPipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

"""
    OITStage()

Resolves Order Independent Transparency by blending the color_sum and
transmittance inputs of OIT into the color buffer.
"""
function OITStage(; kwargs...)
    inputs = [:color_sum => BufferFormat(4, Float16), :transmittance => BufferFormat(1, N0f8)]
    outputs = [:color => BufferFormat(4, N0f8)]
    return RenderStage(:OIT, inputs, outputs; kwargs...)
end

"""
    FXAAStage()

Applies Fast approximate Anti Aliasing to the color buffer.
"""
function FXAAStage(; kwargs...)
    stage1 = RenderStage(
        :FXAA1,
        [:color => BufferFormat(4, N0f8), :objectid => BufferFormat(2, UInt32)],
        [:color_luma => BufferFormat(4, N0f8)];
        kwargs...
    )

    stage2 = RenderStage(
        :FXAA2,
        [:color_luma => BufferFormat(4, N0f8, minfilter = :linear)],
        [:color => BufferFormat(4, N0f8)];
        kwargs...
    )

    pipeline = RenderPipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

"""
    DisplayStage()

Displays the color buffer by blitting it to the screen. Also includes the depth
and objectid buffers as inputs for `depthbuffer()` and picking functions.
"""
function DisplayStage()
    return RenderStage(
        :Display,
        inputs = [
            :depth => BufferFormat(1, BFT.depth24),
            :color => BufferFormat(4, N0f8),
            :objectid => BufferFormat(2, UInt32),
        ],
    )
end

"""
    MSAAResolveStage(source_stage)

Resolves multi sampling of all buffers in `source_stage` by blitting them into
single sample buffers. This is required for Multi Sample Anti Aliasing.
"""
function MSAAResolveStage(source_stage::RenderStage)
    # TODO: Should this generate multiple independent stages?
    inputs = Vector{Pair{Symbol, BufferFormat}}(undef, length(source_stage.outputs))
    outputs = Vector{Pair{Symbol, BufferFormat}}(undef, length(source_stage.outputs))
    for (name, idx) in source_stage.outputs
        format = source_stage.output_formats[idx]
        inputs[idx] = name => format
        outputs[idx] = name => BufferFormat(format, samples = 1)
    end

    return RenderStage(:MSAAResolve; inputs, outputs)
end

"""
    default_pipeline([ssao = false, fxaa = true, oit = true])

Sets up the default render pipeline. Keyword arguments can be used to turn
on different postprocessing effects.
"""
function default_pipeline(; ssao = false, fxaa = true, oit = true)
    pipeline = RenderPipeline()
    push!(pipeline, SortStage())

    # Note - order important!
    # TODO: maybe add insert!()?
    if ssao
        render1 = push!(pipeline, SSAOPlotRenderStage(ssao = true, transparency = false))
        _ssao = push!(pipeline, SSAOStage())
        render2 = push!(pipeline, PlotRenderStage(ssao = false, transparency = false))
    else
        render2 = push!(pipeline, PlotRenderStage(transparency = false))
    end
    if oit
        render3 = push!(pipeline, TransparentPlotRenderStage())
        _oit = push!(pipeline, OITStage())
    else
        render3 = push!(pipeline, PlotRenderStage(transparency = true))
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

"""
    minimal_render_pipeline()

Constructs the minimal pipeline needed for rendering.
"""
function minimal_render_pipeline()
    pipeline = RenderPipeline()
    render = push!(pipeline, PlotRenderStage())
    display = push!(pipeline, DisplayStage())
    connect!(pipeline, render, display)
    return pipeline
end
