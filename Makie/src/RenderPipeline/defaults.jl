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

# for testing with a consistent kernel we want to be able to generate it from
# a StableRNG
function generate_ssao_kernel(N_samples = 64, lerp_min = 0.1f0, lerp_max = 1.0f0, RNG = Random.default_rng())
    return map(1:N_samples) do i
        n = normalize(Vec3f(2.0f0, 2.0f0, 1.0f0) .* rand(RNG, Vec3f) .- Vec3f(1.0f0, 1.0f0, 0.0f0))
        scale = lerp_min + (lerp_max - lerp_min) * Float32(i / N_samples)^2
        return Vec3f(scale * rand() * n)
    end
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

    N_samples = get(kwargs, :N_samples, 64)
    lerp_min = get(kwargs, :lerp_min, 0.1f0)
    lerp_max = get(kwargs, :lerp_min, 1.0f0)
    kernel = get(kwargs, :kernel) do
        generate_ssao_kernel(N_samples, lerp_min, lerp_max)
    end
    noise = map([(x, y) for x in 1:4, y in 1:4]) do (x, y)
        s, c = sincos(2pi * rand())
        return Vec2f(c, s)
    end

    stage1 = RenderStage(
        :SSAO1, inputs, [:occlusion => BufferFormat(1, N0f8)];
        N_samples, lerp_min, lerp_max, kernel = kernel, noise = noise,
    )

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
