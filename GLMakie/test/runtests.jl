ENV["ENABLE_COMPUTE_CHECKS"] = "true"

using Makie
using GLMakie, Test
using FileIO
using GeometryBasics
using GeometryBasics: origin
using Random
using ReferenceTests

# verify OpenGL object cleanup
GLMakie.DEBUG[] = true

deref(x) = x
deref(x::Base.RefValue) = x[]

if !deref(GLMakie.ModernGL.enable_opengl_debugging)
    # can't error, since we can't enable debugging for users
    @warn("TESTING WITHOUT OPENGL DEBUGGING")
end

GLMakie.activate!(framerate = 1.0, scalefactor = 1.0)
@testset "GLMakie" begin
    @testset "mimes" begin
        Makie.inline!(true)
        f, ax, pl = scatter(1:4)
        @test showable("image/png", f)
        @test showable("image/jpeg", f)
        # see https://github.com/MakieOrg/Makie.jl/pull/2167
        @test !showable("blaaa", f)
        Makie.inline!(false)
    end

    # run the unit test suite
    include("isolated_tests.jl")
    include("unit_tests.jl")

    @testset "ComputeGraph Sanity Checks" begin
        # This is supposed to catch changes in ComputePipeline causing nodes to
        # be skipped or become duplicated. This will also trigger if plot attributes
        # are modified in which case the numbers should just be updated
        f, a, p = scatter(rand(10))
        colorbuffer(f)
        @test length(p.attributes.inputs) == 44
        @test length(p.attributes.outputs) == 88
    end

    @testset "Reference Tests" begin
        @testset "refimages" begin
            ReferenceTests.mark_broken_tests()
            recorded_files, recording_dir = @include_reference_tests GLMakie "refimages.jl" joinpath(@__DIR__, "glmakie_refimages.jl")
            missing_images, scores = ReferenceTests.record_comparison(recording_dir, "GLMakie")
            ReferenceTests.test_comparison(scores; threshold = 0.05)
        end

        GLMakie.closeall()
        GC.gc(true) # make sure no finalizers act up!
    end

    @testset "Tick Events" begin
        function check_tick(tick, state, count)
            @test tick.state == state
            @test tick.count == count
            @test tick.time > 1.0e-9
            @test tick.delta_time > 1.0e-9
        end

        f, a, p = scatter(rand(10))
        @test events(f).tick[] == Makie.Tick()

        filename = "$(tempname()).png"
        try
            save(filename, f)
            tick = events(f).tick[]
            @test tick.state == Makie.OneTimeRenderTick
            @test tick.count == 0
            @test tick.time == 0.0
            @test tick.delta_time == 0.0
        finally
            rm(filename)
        end

        f, a, p = scatter(rand(10))
        filename = "$(tempname()).mp4"
        try
            tick_record = Makie.Tick[]
            on(tick -> push!(tick_record, tick), events(f).tick)
            record(_ -> nothing, f, filename, 1:10, framerate = 30)

            start = findfirst(tick -> tick.state == Makie.OneTimeRenderTick, tick_record)
            dt = 1.0 / 30.0

            for (i, tick) in enumerate(tick_record[start:end])
                @test tick.state == Makie.OneTimeRenderTick
                @test tick.count == i - 1
                @test tick.time ≈ dt * (i - 1)
                @test tick.delta_time ≈ dt
            end
        finally
            rm(filename)
        end

        # test destruction of tick overwrite
        f, a, p = scatter(rand(10))
        let
            io = VideoStream(f)
            @test events(f).tick[] == Makie.Tick(Makie.OneTimeRenderTick, 0, 0.0, 1.0 / io.options.framerate)
            nothing
        end
        tick = Makie.Tick(Makie.UnknownTickState, 1, 1.0, 1.0)
        events(f).tick[] = tick
        @test events(f).tick[] == tick


        f, a, p = scatter(rand(10))
        tick_record = Makie.Tick[]
        on(t -> push!(tick_record, t), events(f).tick)
        screen = GLMakie.Screen(render_on_demand = true, framerate = 30.0, pause_rendering = false, visible = false)
        display(screen, f.scene)
        sleep(0.15)
        GLMakie.pause_renderloop!(screen)
        sleep(0.1)
        GLMakie.closeall()

        # Why does it start with a skipped tick?
        i = 1
        while tick_record[i].state == Makie.SkippedRenderTick
            check_tick(tick_record[1], Makie.SkippedRenderTick, i)
            i += 1
        end

        check_tick(tick_record[i], Makie.RegularRenderTick, i)
        i += 1

        while tick_record[i].state == Makie.SkippedRenderTick
            check_tick(tick_record[i], Makie.SkippedRenderTick, i)
            i += 1
        end

        while (i <= length(tick_record)) && (tick_record[i].state == Makie.PausedRenderTick)
            check_tick(tick_record[i], Makie.PausedRenderTick, i)
            i += 1
        end

        @test i == length(tick_record) + 1
    end


    # NOTE: Keep this at the end! It also verifies that all cleanup is complete after
    #       all other tests have finished

    @testset "gl object deletion" begin
        GLMakie.closeall()

        # image so we have a user generated texture in the mix
        # texture atlas is triggered by text
        # include SSAO to make sure its cleanup works too
        f, a, p = image(rand(4, 4))
        screen = display(f, ssao = true, visible = false)
        colorbuffer(screen)

        # verify that SSAO is active
        @test screen.postprocessors[1] != GLMakie.empty_postprocessor()

        framebuffer = screen.framebuffer
        framebuffer_textures = copy(screen.framebuffer.buffers)
        atlas_textures = first.(values(GLMakie.atlas_texture_cache))
        shaders = vcat([[shader for shader in values(shaders)] for shaders in values(screen.shader_cache.shader_cache)]...)
        programs = [program for program in values(screen.shader_cache.program_cache)]
        postprocessors = copy(screen.postprocessors)
        robjs = last.(screen.renderlist)

        GLMakie.destroy!(screen)

        @testset "Texture Atlas" begin
            @test !isempty(atlas_textures)
            for tex in atlas_textures
                @test tex.id == 0
            end
        end

        @testset "Framebuffer" begin
            @test framebuffer.id == 0
            @test !isempty(framebuffer_textures)
            for (k, tex) in framebuffer_textures
                @test tex.id == 0
            end
        end

        @testset "ShaderCache" begin
            @test !isempty(shaders)
            for shader in shaders
                @test shader.id == 0
            end
            @test !isempty(programs)
            for program in programs
                @test program.id == 0
            end
        end

        function validate_robj(robj)
            for uniform in robj.uniforms
                if to_value(uniform) isa GLMakie.GLAbstraction.GPUArray
                    @test to_value(uniform).id == 0
                end
            end
            @test robj.vertexarray.id == 0
            if robj.vertexarray.indices isa GLMakie.GLAbstraction.GPUArray
                @test robj.vertexarray.indices.id == 0
            end
            for buffer in values(robj.vertexarray.buffers)
                @test buffer.id == 0
            end
            @test robj.vertexarray.program.id == 0
            for shader in robj.vertexarray.program.shader
                @test shader.id == 0
            end
        end

        @testset "PostProcessors" begin
            @test map(pp -> length(pp.robjs), postprocessors) == [2, 1, 2, 1]
            for pp in postprocessors
                for robj in pp.robjs
                    validate_robj(robj)
                end
            end
        end

        @testset "RenderObjects" begin
            @test !isempty(robjs)
            for robj in robjs
                validate_robj(robj)
            end
        end

        # Check that no finalizers triggered on un-freed objects throughout all tests
        @test GLMakie.GLAbstraction.FAILED_FREE_COUNTER[] == 0
    end
end
