using GLMakie.Makie: getscreen

function project_sp(scene, point)
    point_px = Makie.project(scene, point)
    offset = Point2f(minimum(pixelarea(scene)[]))
    return point_px .+ offset
end

@testset "unit tests" begin
    GLMakie.closeall(GLMakie.GLFW_WINDOWS)
    GLMakie.closeall(GLMakie.SINGLETON_SCREEN)
    GLMakie.closeall(GLMakie.SINGLETON_SCREEN_NO_RENDERLOOP)
    @testset "Window handling" begin
        # Without previous windows/figures everything should be empty/unassigned
        @test isempty(GLMakie.GLFW_WINDOWS)
        @test !isassigned(GLMakie.SINGLETON_SCREEN)
        @test !isassigned(GLMakie.SINGLETON_SCREEN_NO_RENDERLOOP)

        # A raw screen should be tracked in GLFW_WINDOWS
        screen = GLMakie.Screen(resolution = (100, 100), visible = false)
        @test isopen(screen)
        @test length(GLMakie.GLFW_WINDOWS) == 1 && (GLMakie.GLFW_WINDOWS[1] === screen.glscreen)
        @test !isassigned(GLMakie.SINGLETON_SCREEN)
        @test !isassigned(GLMakie.SINGLETON_SCREEN_NO_RENDERLOOP)

        # A displayed figure should create a singleton screen and leave other
        # screens untouched
        fig, ax, splot = scatter(1:4);
        screen2 = display(fig)
        @test screen !== screen2
        @test length(GLMakie.GLFW_WINDOWS) == 2 && (GLMakie.GLFW_WINDOWS == [screen.glscreen, screen2.glscreen])
        @test isassigned(GLMakie.SINGLETON_SCREEN) && (GLMakie.SINGLETON_SCREEN[] === screen2)
        @test !isassigned(GLMakie.SINGLETON_SCREEN_NO_RENDERLOOP)

        # TODO overload getscreen for figure
        @test getscreen(ax.scene) === screen2

        # closing screens should remove just the GLFW windows from GLFW_WINDOWS
        close(screen)
        @test !isopen(screen) && isopen(screen2)
        @test length(GLMakie.GLFW_WINDOWS) == 1 && (GLMakie.GLFW_WINDOWS[1] == screen2.glscreen)
        @test isassigned(GLMakie.SINGLETON_SCREEN) && (GLMakie.SINGLETON_SCREEN[] === screen2)

        close(screen2)
        @test !isopen(screen) && !isopen(screen2)
        @test length(GLMakie.GLFW_WINDOWS) == 0
        @test isassigned(GLMakie.SINGLETON_SCREEN) && (GLMakie.SINGLETON_SCREEN[] === screen2)

        # assure we correctly close screen and remove it from plot
        @test getscreen(ax.scene) === nothing
        @test !events(ax.scene).window_open[]
        @test isempty(events(ax.scene).window_open.listeners)

        # Test singleton screen replacement
        fig, ax, p = scatter(1:4);
        screen = display(fig)
        ptr = deepcopy(screen.glscreen.handle)
        @test length(GLMakie.GLFW_WINDOWS) == 1 && (GLMakie.GLFW_WINDOWS[1] == screen.glscreen)
        @test isopen(screen) && (screen === GLMakie.SINGLETON_SCREEN[])
        fig2, ax2, p2 = scatter(4:-1:1);
        screen2 = display(fig2)
        @test length(GLMakie.GLFW_WINDOWS) == 1 && (GLMakie.GLFW_WINDOWS[1] == screen2.glscreen)
        @test isopen(screen2) && (screen2 === GLMakie.SINGLETON_SCREEN[])
        @test screen === screen2
        @test screen2.glscreen.handle == ptr
        close(screen)
        close(screen2)
    end

    @testset "Pick a plot element or plot elements inside a rectangle" begin
        N = 100000
        fig, ax, splot = scatter(1:N, 1:N)
        limits!(ax, 99990,100000, 99990,100000)
        screen = display(GLMakie.Screen(visible = false), fig)
        # we don't really need the color buffer here, but this should be the best way right now to really
        # force a full render to happen
        GLMakie.Makie.colorbuffer(screen)
        # test for pick a single data point (with idx > 65535)
        point_px = project_sp(ax.scene, Point2f(N-1,N-1))
        plot,idx = pick(ax.scene, point_px)
        @test idx == N-1

        # test for pick a rectangle of data points (also with some indices > 65535)
        rect = Rect2f(99990.5,99990.5,8,8)
        origin_px = project_sp(ax.scene, Point(origin(rect)))
        tip_px = project_sp(ax.scene, Point(origin(rect) .+ widths(rect)))
        rect_px = Rect2i(round.(origin_px), round.(tip_px .- origin_px))
        picks = unique(pick(ax.scene, rect_px))

        # objects returned in plot_idx should be either grid lines (i.e. LineSegments) or Scatter points
        @test all(pi-> pi[1] isa Union{LineSegments,Scatter, Makie.Mesh}, picks)
        # scatter points should have indices equal to those in 99991:99998
        scatter_plot_idx = filter(pi -> pi[1] isa Scatter, picks)
        @test Set(last.(scatter_plot_idx)) == Set(99991:99998)
        close(screen)
    end
end

@testset "emtpy!(fig)" begin
    GLMakie.closeall()
    fig = Figure()
    ax = Axis(fig[1,1])
    heatmap!(ax, rand(4, 4))
    lines!(ax, 1:5, rand(5); linewidth=3)
    text!(ax, [Point2f(2)], text=["hi"])
    screen = display(fig)
    empty!(fig)
    @testset "all got freed" begin
        for (_, _, robj) in screen.renderlist
            for (k, v) in robj.uniforms
                if v isa GLMakie.GPUArray
                    @test v.id == 0
                end
            end
            @test robj.vertexarray.id == 0
        end
    end
    ax = Axis(fig[1,1])
    heatmap!(ax, rand(4, 4))
    lines!(ax, 1:5, rand(5); linewidth=3)
    text!(ax, [Point2f(2)], text=["hi"])
    @testset "no freed object after replotting" begin
        for (_, _, robj) in screen.renderlist
            for (k, v) in robj.uniforms
                if v isa GLMakie.GPUArray
                    @test v.id != 0
                end
            end
            @test robj.vertexarray.id != 0
        end
    end
    close(screen)
    @test isempty(screen.renderlist)
end


@testset "empty!(ax)" begin
    GLMakie.closeall()
    fig = Figure()
    ax = Axis(fig[1,1])
    hmp = heatmap!(ax, rand(4, 4))
    lp = lines!(ax, 1:5, rand(5); linewidth=3)
    tp = text!(ax, [Point2f(2)], text=["hi"])
    screen = display(fig)

    @test ax.scene.plots == [hmp, lp, tp]

    robjs = map(x-> screen.cache[objectid(x)], [hmp, lp, tp.plots...])

    empty!(ax)

    tex_atlas = GLMakie.get_texture!(Makie.get_texture_atlas())
    for robj in robjs
        for (k, v) in robj.uniforms
            if (v isa GLMakie.GPUArray) && (v !== tex_atlas)
                @test v.id == 0
            end
        end
        @test robj.vertexarray.id == 0
    end

    heatmap!(ax, rand(4, 4))
    lines!(ax, 1:5, rand(5); linewidth=3)
    text!(ax, [Point2f(2)], text=["hi"])
    @testset "no freed object after replotting" begin
        for (_, _, robj) in screen.renderlist
            for (k, v) in robj.uniforms
                if v isa GLMakie.GPUArray
                    @test v.id != 0
                end
            end
            @test robj.vertexarray.id != 0
        end
    end
    close(screen)
    @test isempty(screen.renderlist)
end
