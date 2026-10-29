using Test, GLMakie, FileIO
const GLFW = GLMakie.GLFW

@testset "headless GLMakie" begin
    @test !GLFW.is_initialized()
    @test isempty(GLMakie.ALL_SCREENS)
    @test GLFW.GetPlatform() == GLFW.PLATFORM_NULL
    before = length(GLFW._window_callbacks)
    @test_throws "without a display server" GLMakie.Screen(visible = true)
    @test length(GLFW._window_callbacks) == before
    @test isempty(GLMakie.ALL_SCREENS)

    if get(ENV, "GLMAKIE_TEST_NO_DRIVER", "false") == "true"
        # Import and Vulkan-style windows work even with every EGL vendor
        # disabled and OSMesa absent; OpenGL reports what must be installed.
        err = try
            GLMakie.Screen(visible = false, start_renderloop = false)
        catch err
            err
        end
        @test err isa GLFW.GLFWError
        @test occursin("EGL and OSMesa", err.description)
        @test occursin("Install", err.description)
        @test isempty(GLMakie.ALL_SCREENS)
        GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)
        window = GLFW.CreateWindow(16, 16, "Vulkan needs no OpenGL")
        GLFW.DestroyWindow(window)
        GLFW.DefaultWindowHints()
    else
        GLMakie.activate!()
        try
            # Saving must work as the first rendering operation, with the
            # normal visible=true theme and without setting window hints.
            fig = Figure(size = (160, 120))
            lines!(Axis(fig[1, 1]), 1:3, [1, 3, 2])
            mktempdir() do dir
                path = joinpath(dir, "headless.png")
                save(path, fig)
                @test read(path)[1:8] == UInt8[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
                @test filesize(path) > 1000
            end
            image = colorbuffer(fig)
            @test size(image) == (120, 160)
            @test length(unique(image)) > 10
            @test all(c -> isfinite(c.r) && isfinite(c.g) && isfinite(c.b), image)
            @test events(fig).window_dpi[] == 96
            resize!(fig.scene, 240, 180)
            @test size(colorbuffer(fig)) == (180, 240)

            # Explicit screens, pool reuse and independent contexts must all
            # release their resources without touching a display server.
            for i in 1:3
                screen = GLMakie.Screen(visible = false, start_renderloop = false)
                try
                    scene = Scene(size = (80 + i, 60 + i))
                    scatter!(scene, Point2f[(0, 0), (1, 1)])
                    display(screen, scene)
                    @test size(colorbuffer(screen)) == (60 + i, 80 + i)
                    @test_throws "without a display server" GLMakie.set_screen_visibility!(screen, true)
                    @test isopen(screen)
                finally
                    GLMakie.destroy!(screen)
                end
            end
            window = GLMakie.SINGLETON_SCREEN[1].glscreen
            GLFW.MakeContextCurrent(window)
            getstring = GLFW.GetProcAddress("glGetString")
            println("Headless OpenGL renderer: ", unsafe_string(ccall(getstring, Cstring, (Cuint,), 0x1f01)))
        finally
            GLMakie.closeall()
        end
    end
    @test isempty(GLMakie.ALL_SCREENS)
    @test isempty(GLMakie.SCREEN_REUSE_POOL)
    @test isempty(GLMakie.SINGLETON_SCREEN)
    @test isempty(GLFW._window_callbacks)
    GLFW.Terminate()
end
