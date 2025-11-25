using GLMakie.Makie: Record
using GLMakie.GLFW
using GLMakie.ModernGL
using GLMakie.ShaderAbstractions
using GLMakie.ShaderAbstractions: Sampler
using GLMakie.GeometryBasics
using ReferenceTests.RNG

@reference_test "Sampler type" begin
    # Directly access texture parameters:
    x = Sampler(fill(to_color(:yellow), 100, 100), minfilter = :nearest)
    scene = image(x)
    # indexing will go straight to the GPU, while only transferring the changes
    st = Stepper(scene)
    x[1:10, 1:50] .= to_color(:red)
    Makie.step!(st)
    x[1:10, end] .= to_color(:green)
    Makie.step!(st)
    x[end, end] = to_color(:blue)
    Makie.step!(st)
    st
end

# Test for resizing of TextureBuffer
@reference_test "Dynamically adjusting number of particles in a meshscatter" begin
    pos = Observable(RNG.rand(Point3f, 2))
    rot = Observable(RNG.rand(Vec3f, 2))
    color = Observable(RNG.rand(RGBf, 2))
    size = Observable(0.1 * RNG.rand(2))

    makenew = Observable(1)
    on(makenew) do i
        pos[] = RNG.rand(Point3f, i)
        rot[] = RNG.rand(Vec3f, i)
        color[] = RNG.rand(RGBf, i)
        size[] = 0.1 * RNG.rand(i)
    end

    fig, ax, p = meshscatter(
        pos,
        rotation = rot,
        color = color,
        markersize = size,
        axis = (; scenekw = (; limits = Rect3f(Point3(0), Point3(1))))
    )
    Record(fig, [10, 5, 100, 60, 177]) do i
        makenew[] = i
    end
end

@reference_test "Explicit frame rendering" begin
    function update_loop(m, buff, screen)
        for i in 1:20
            GLFW.PollEvents()
            buff .= RNG.rand.(Point3f) .* 20.0f0
            m[1] = buff
            GLMakie.render_frame(screen)
            GLFW.SwapBuffers(GLMakie.to_native(screen))
            glFinish()
        end
    end
    fig, ax, meshplot = meshscatter(RNG.rand(Point3f, 10^4) .* 20.0f0; color = :black)
    screen = display(GLMakie.Screen(; renderloop = (screen) -> nothing, start_renderloop = false, visible = false), fig.scene)
    buff = RNG.rand(Point3f, 10^4) .* 20.0f0
    update_loop(meshplot, buff, screen)
    @test isnothing(screen.rendertask)
    GLMakie.destroy!(screen)
    fig
end

@reference_test "Contour and isosurface with correct depth" begin
    # Make sure shaders can recompile
    GLMakie.closeall()

    fig = Figure()
    left = LScene(fig[1, 1])
    contour!(left, [sin(i + j) * sin(j + k) * sin(i + k) for i in 1:10, j in 1:10, k in 1:10], enable_depth = true)
    mesh!(left, Sphere(Point3f(5), 6.0f0), color = :black)
    right = LScene(fig[1, 2])
    volume!(right, [sin(2i) * sin(2j) * sin(2k) for i in 1:10, j in 1:10, k in 1:10], algorithm = :iso, enable_depth = true)
    mesh!(right, Sphere(Point3f(5), 6.0f0); color = :black)
    fig
end

@reference_test "Complex Lighting - Ambient + SpotLights + PointLights" begin
    angle2pos(phi) = Point3f(cosd(phi), sind(phi), 0)
    lights = [
        AmbientLight(RGBf(0.1, 0.1, 0.1)),
        SpotLight(RGBf(2, 0, 0), angle2pos(0), Vec3f(0, 0, -1), Vec2f(pi / 5, pi / 4)),
        SpotLight(RGBf(0, 2, 0), angle2pos(120), Vec3f(0, 0, -1), Vec2f(pi / 5, pi / 4)),
        SpotLight(RGBf(0, 0, 2), angle2pos(240), Vec3f(0, 0, -1), Vec2f(pi / 5, pi / 4)),
        PointLight(RGBf(1, 1, 1), Point3f(-4, -4, -2.5), 10.0),
        PointLight(RGBf(1, 1, 0), Point3f(-4, 4, -2.5), 10.0),
        PointLight(RGBf(1, 0, 1), Point3f(4, 4, -2.5), 10.0),
        PointLight(RGBf(0, 1, 1), Point3f(4, -4, -2.5), 10.0),
    ]

    scene = Scene(size = (400, 400), camera = cam3d!, lights = lights)
    @test Makie.get_shading_mode(scene) == MultiLightShading
    p = mesh!(
        scene,
        Rect3f(Point3f(-10, -10, -2.99), Vec3f(20, 20, 0.02)),
        color = :white, specular = Vec3f(0)
    )
    center!(scene)
    update_cam!(scene, Vec3f(0, 0, 10), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    scene
end

@reference_test "Complex Lighting - DirectionalLight + specular reflection" begin
    angle2dir(phi) = Vec3f(cosd(phi), sind(phi), -2)
    lights = [
        AmbientLight(RGBf(0.1, 0.1, 0.1)),
        DirectionalLight(RGBf(1, 0, 0), angle2dir(0)),
        DirectionalLight(RGBf(0, 1, 0), angle2dir(120)),
        DirectionalLight(RGBf(0, 0, 1), angle2dir(240)),
    ]

    scene = Scene(size = (400, 400), camera = cam3d!, center = false, lights = lights, backgroundcolor = :black)
    @test Makie.get_shading_mode(scene) == MultiLightShading
    mesh!(
        scene, Sphere(Point3f(0), 1.0f0), color = :white,
        specular = Vec3f(1), shininess = 16.0f0
    )
    update_cam!(scene, Vec3f(0, 0, 3), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    scene
end


@reference_test "RectLight" begin
    lights = Makie.AbstractLight[
        RectLight(RGBf(0.5, 0, 0), Point3f(-0.5, -1, 2), Vec3f(3, 0, 0), Vec3f(0, 3, 0)),
        RectLight(RGBf(0, 0.5, 0), Rect2f(-1, 1, 1, 3)),
        RectLight(RGBf(0, 0, 0.5), Point3f(1, 0.5, 2), Vec3f(3, 0, 0), Vec3f(0, 3, 0)),
        RectLight(RGBf(0.5, 0.5, 0.5), Point3f(1, -1, 2), Vec3f(3, 0, 0), Vec3f(0, 3, 0), Vec3f(-0.3, 0.3, -1)),
    ]
    # Test transformations
    lights[2] = Makie.translate(lights[2], Vec3f(-1, 1, 2)) # translate to by default
    lights[2] = Makie.scale(lights[2], 3, 1)

    scene = Scene(lights = lights, camera = cam3d!, size = (400, 400))
    @test Makie.get_shading_mode(scene) == MultiLightShading
    p = mesh!(scene, Rect3f(Point3f(-10, -10, 0.01), Vec3f(20, 20, 0.02)), color = :white)
    update_cam!(scene, Vec3f(0, 0, 7), Vec3f(0, 0, 0), Vec3f(0, 1, 0))

    scene
end

@reference_test "Signed Distance Field - FXAA interaction" begin
    scene = Scene(size = (300, 280), camera = campixel!)

    # scatter/text shader
    xs = 20:20:280
    ys = fill(250, length(xs))
    zs = range(3, 1, length = length(xs))
    scatter!(scene, xs, ys, zs, color = :blue, markersize = 40, fxaa = false)
    ys = fill(210, length(xs))
    scatter!(scene, xs, ys, zs, color = :blue, markersize = 40, fxaa = true)
    ys = fill(170, length(xs))
    scatter!(scene, xs, ys, zs, color = :blue, markersize = 40, depthsorting = true)
    subscene = Scene(scene, viewport = Rect2i(0, 70, 300, 80))
    ys = fill(0.45, length(xs))
    scatter!(
        subscene, range(-0.85, 0.85, length(xs)), ys, -zs ./ 3,
        color = :blue, markersize = 40
    )
    ys = fill(-0.45, length(xs))
    scatter!(
        subscene, range(-0.85, 0.85, length(xs)), ys, -zs ./ 3,
        color = :blue, markersize = 40, depthsorting = true
    )

    # lines/linesegments shader
    xs = 20:10:270
    ys = [50 + shift for _ in 1:13 for shift in (-10, 10)]
    zs = range(3, 1, length = length(xs))
    lines!(scene, xs, ys, zs, color = :blue, linewidth = 4, fxaa = false)
    ys = [20 + shift for _ in 1:13 for shift in (-10, 10)]
    lines!(scene, xs, ys, zs, color = :blue, linewidth = 4, fxaa = true)

    # generate a screen/renderlist before mesh so mesh ends up as the last
    # renderobject. (This is should probably be considered a bug)
    colorbuffer(scene)

    # create some harder contrasts
    mesh!(scene, Rect2f(0, 0, 300, 280), color = :red)

    scene
end

@reference_test "render stage parameters with SSAO postprocessor" begin
    GLMakie.closeall() # (mostly?) for recompilation of plot shaders
    GLMakie.activate!(ssao = true)
    f = Figure()
    ps = [Point3f(x, y, sin(x * y + y - x)) for x in range(-2, 2, length = 21) for y in range(-2, 2, length = 21)]
    for (i, ssao) in zip(1:2, (false, true))
        for (j, fxaa) in zip(1:2, (false, true))
            for (k, transparency) in zip(1:2, (false, true))
                Label(f[2i - 1, k + 2(j - 1)], "$ssao, $fxaa, $transparency", tellwidth = false)
                a, p = meshscatter(
                    f[2i, k + 2(j - 1)], ps, marker = Rect3f(Point3f(-0.5), Vec3f(1)),
                    markersize = 1, color = :white; ssao, fxaa, transparency
                )
            end
        end
    end
    f
end

@reference_test "render stage parameters without SSAO postprocessor" begin
    GLMakie.closeall()
    GLMakie.activate!(ssao = false)
    f = Figure()
    ps = [Point3f(x, y, sin(x * y + y - x)) for x in range(-2, 2, length = 21) for y in range(-2, 2, length = 21)]
    for (i, ssao) in zip(1:2, (false, true))
        for (j, fxaa) in zip(1:2, (false, true))
            for (k, transparency) in zip(1:2, (false, true))
                Label(f[2i - 1, k + 2(j - 1)], "$ssao, $fxaa, $transparency", tellwidth = false)
                a, p = meshscatter(
                    f[2i, k + 2(j - 1)], ps, marker = Rect3f(Point3f(-0.5), Vec3f(1)),
                    markersize = 1, color = :white; ssao, fxaa, transparency
                )
            end
        end
    end
    f
end

@reference_test "Custom stage in render pipeline" begin
    GLMakie.closeall()

    function GLMakie.construct(::Val{:Tint}, screen, framebuffer, inputs, parent)
        frag_shader = """
        {{GLSL_VERSION}}

        in vec2 frag_uv;
        out vec4 fragment_color;

        uniform sampler2D color_buffer; // \$(name of input)_buffer
        uniform mat3 color_transform;   // from Stage attributes

        void main(void) {
            vec4 c = texture(color_buffer, frag_uv).rgba;
            fragment_color = vec4(color_transform * c.rgb, c.a);
            // fragment_color = vec4(1,0,0, c.a);
        }
        """

        shader = GLMakie.LazyShader(
            screen.shader_cache,
            GLMakie.loadshader("postprocessing/fullscreen.vert"),
            GLMakie.ShaderSource(frag_shader, :frag)
        )

        inputs[:color_transform] = parent.attributes[:color_transform]
        inputs[:indices] = 3

        robj = GLMakie.RenderObject(screen.glscreen, inputs)
        GLMakie.add_instructions!(robj, :main, shader, pre = GLMakie.PostprocessPrerender())

        return GLMakie.RenderPass{:Tint}(framebuffer, robj)
    end

    function GLMakie.run_stage(screen, glscene, stage::GLMakie.RenderPass{:Tint})
        resize!(stage.framebuffer, screen.framebuffer_manager.size)
        # Blend transparent onto opaque
        wh = size(stage.framebuffer)
        GLMakie.set_draw_buffers(stage.framebuffer)
        GLMakie.glViewport(0, 0, wh[1], wh[2])
        GLMakie.GLAbstraction.render(stage.robj)
        return
    end


    begin
        # Pipeline matches test_pipeline_2D up to color_tint
        pipeline = Makie.RenderPipeline()

        render1 = push!(pipeline, Makie.PlotRenderStage(transparency = false, fxaa = true))
        render2 = push!(pipeline, Makie.TransparentPlotRenderStage())
        oit = push!(pipeline, Makie.OITStage())
        fxaa = push!(pipeline, Makie.FXAAStage(filter_in_shader = false))
        render3 = push!(pipeline, Makie.PlotRenderStage(transparency = false, fxaa = false))
        color_tint = push!(
            pipeline, Makie.RenderStage(
                :Tint,
                inputs = [:color => Makie.BufferFormat()], # defaults to 4x N0f8, i.e. 32Bit color
                outputs = [:color => Makie.BufferFormat()],
                color_transform = Observable(
                    Makie.Mat3f(
                        # sepia filter
                        0.393, 0.349, 0.272,
                        0.769, 0.686, 0.534,
                        0.189, 0.168, 0.131
                    )
                )
            )
        )
        display_stage = push!(pipeline, Makie.DisplayStage())

        connect!(pipeline, render1, fxaa)
        connect!(pipeline, render1, display_stage, :objectid)
        connect!(pipeline, render1, display_stage, :depth)
        connect!(pipeline, render2, oit)
        connect!(pipeline, render2, display_stage, :objectid)
        connect!(pipeline, render2, display_stage, :depth)
        connect!(pipeline, oit, fxaa, :color)
        connect!(pipeline, fxaa, color_tint, :color)
        connect!(pipeline, render3, color_tint, :color)
        connect!(pipeline, render3, display_stage, :objectid)
        connect!(pipeline, render3, display_stage, :depth)
        connect!(pipeline, color_tint, display_stage, :color)
    end


    GLMakie.activate!(render_pipeline = pipeline)
    cow = load(Makie.assetpath("cow.png"))
    f, a, p = image(rotr90(cow))
end
