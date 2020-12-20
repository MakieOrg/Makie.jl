@block Contributors ["GLMakie backend tests"] begin

    # A test case for wide lines and mitering at joints
    @cell "Miter Joints for line rendering" [lines] begin
        scene = Scene()

        r = 4
        sep = 4*r
        scatter!(scene, (sep+2*r)*[-1,-1,1,1], (sep+2*r)*[-1,1,-1,1])

        for i=-1:1
            for j=-1:1
                angle = pi/2 + pi/4*i
                x = r*[-cos(angle/2),0,-cos(angle/2)]
                y = r*[-sin(angle/2),0,sin(angle/2)]

                linewidth = 40 * 2.0^j
                lines!(scene, x .+ sep*i, y .+ sep*j, color=RGBAf0(0,0,0,0.5), linewidth=linewidth)
                lines!(scene, x .+ sep*i, y .+ sep*j, color=:red)
            end
        end
        scene
    end
    @cell "Sampler type" [Sampler] begin
        using GLMakie.ShaderAbstractions
        using GLMakie.ShaderAbstractions: Sampler
        # Directly access texture parameters:
        x = Sampler(fill(to_color(:yellow), 100, 100), minfilter=:nearest)
        scene = image(x, show_axis=false)
        # indexing will go straight to the GPU, while only transfering the changes
        st = Stepper(scene, @replace_with_a_path)
        x[1:10, 1:50] .= to_color(:red)
        step!(st)
        x[1:10, end] .= to_color(:green)
        step!(st)
        x[end, end] = to_color(:blue)
        step!(st)
    end
    # Test for resizing of TextureBuffer
    @cell "Dynamically adjusting number of particles in a meshscatter" [meshscatter] begin

        pos = Node(rand(Point3f0, 2))
        rot = Node(rand(Vec3f0, 2))
        color = Node(rand(RGBf0, 2))
        size = Node(0.1*rand(2))

        makenew = Node(1)
        on(makenew) do i
            pos[] = rand(Point3f0, i)
            rot[] = rand(Vec3f0, i)
            color[] = rand(RGBf0, i)
            size[] = 0.1*rand(i)
        end

        scene = meshscatter(pos,
            rotations=rot,
            color=color,
            markersize=size,
            limits=FRect3D(Point3(0), Point3(1))
        )

        record(scene, @replace_with_a_path(mp4), [10, 5, 100, 60, 177]) do i
            makenew[] = i
        end
    end

    @cell "Explicit frame rendering" [opengl, render_frame, meshscatter] begin
        using ModernGL, GLMakie
        using GLFW
        set_window_config!(renderloop=(screen) -> nothing)
        function update_loop(m, buff, screen)
            for i = 1:20
                GLFW.PollEvents()
                buff .= rand.(Point3f0) .* 20f0
                m[1] = buff
                GLMakie.render_frame(screen)
                GLFW.SwapBuffers(GLMakie.to_native(screen))
                glFinish()
            end
        end
        scene = meshscatter(rand(Point3f0, 10^4) .* 20f0)
        screen = AbstractPlotting.backend_display(GLMakie.GLBackend(), scene)
        meshplot = scene[end]
        buff = rand(Point3f0, 10^4) .* 20f0;
        update_loop(meshplot, buff, screen)
        set_window_config!(renderloop=GLMakie.renderloop)
        scene
    end

    @cell "Pick a plot element or plot elements inside a rectangle" [pick] begin
        using Makie,GLMakie
        using AbstractPlotting:project,transformationmatrix
        using StaticArrays
        using GeometryBasics

        # this function should probably be included in AbstractPlotting
        function AbstractPlotting.project(scene::Scene,point::T) where T<:StaticVector
            cam = scene.camera
            project(cam.projection[]*cam.view[]*transformationmatrix(scene)[] , Vec2(scene.resolution[]), point)
        end
        
        N = 100000
        scene = scatter(1:N,1:N)
        xlims!((99990,100000))
        ylims!((99990,100000))
        display(scene)
        
        # test for pick a single data point (with idx > 65535)
        idx = 0
        while idx == 0
            plot,idx = pick(scene,project(scene,Point((100000.,100000.))))
        end
        @assert idx == 100000
        
        # test for pick a rectangle of data points (also with some indices > 65535)
        rect = FRect2D(99990.5,99990.5,8,8)
        origin_px = project(scene,Point(origin(rect)))
        tip_px    = project(scene,Point(origin(rect) .+ widths(rect)))
        rect_px = IRect2D(round.(origin_px), round.(tip_px .- origin_px))
        plot_idx = pick(AbstractPlotting.getscreen(scene),rect_px) #! there is no pick(::Scene,::IRect2D)
        
        # objects returned in plot_idx should be either grid lines (i.e. LineSegments) or Scatter points
        @assert all([typeof(pi[1]) <: Union{LineSegments,Scatter} for pi in plot_idx])
        # scatter points should have indices equal to those in 99991:99998
        scatter_plot_idx = filter(pi -> typeof(pi[1]) <: Scatter, plot_idx)
        @assert Set([pi[2] for pi in scatter_plot_idx]) == Set(99991:99998)
    end


end
