msaa_pipeline = let
    function MinimalPlotRenderStage(; kwargs...)
        outputs = [
            :depth => Makie.BufferFormat(1, Makie.BFT.depth24),
            :color => Makie.BufferFormat(4, Makie.N0f8),
        ]
        return Makie.RenderStage(:Render; outputs, kwargs...)
    end

    function MinimalDisplayStage()
        return Makie.RenderStage(
            :Display,
            inputs = [
                :depth => Makie.BufferFormat(1, Makie.BFT.depth24),
                :color => Makie.BufferFormat(4, Makie.N0f8),
            ],
        )
    end

    pipeline = Makie.RenderPipeline()
    render = push!(pipeline, MinimalPlotRenderStage(samples = 4)) # 4x MSAA
    resolve = push!(pipeline, Makie.MSAAResolveStage(render))
    display = push!(pipeline, MinimalDisplayStage())
    connect!(pipeline, render, resolve)
    connect!(pipeline, resolve, display)
    pipeline
end

begin
    GLMakie.closeall()
    f, a, p = scatter(rand(Point2f, 10))
    mesh!(Circle(Point2f(0.5), 0.1))
    screen = Base.display(f, render_pipeline = msaa)
end

#=
Notes:
- objectid/int buffers can not be multisampled
- the setup above requires disabling the `final_stage` check in GLMakie/render_pipeline
- should add clamp msaa samples to:
    `msaa = Ref{GLint}(); glGetIntegerv(GL_MAX_COLOR_TEXTURE_SAMPLES, msaa); msaa[]`
- Makie.RenderPipeline should probably merge depth + stencil when both are there
=#
