@block SimonDanisch ["2d"] begin
    @cell "Animated time series" [lines, record] begin
        f0 = 1/2; fs = 100;
        winsec = 4; hopsec = 1/60
        nwin = round(Integer, winsec*fs)
        nhop = round(Integer, hopsec*fs)
        # do the loop
        frame_start = -winsec
        frame_time = collect((0:(nwin-1)) * (1/fs))
        aframe = sin.(2*pi*f0.*(frame_start .+ frame_time))
        scene = lines(frame_start .+ frame_time, aframe)
        center!(scene)
        lineplot = scene[end]
        fix = 0
        record(scene, @replace_with_a_path(mp4), 1:50) do i
            global frame_start
            aframe .= sin.(2*pi*f0.*(frame_start .+ frame_time))
            # append!(aframe, randn(nhop)); deleteat!(aframe, 1:nhop)
            lineplot[1] = frame_start .+ frame_time
            lineplot[2] = aframe
            AbstractPlotting.update_limits!(scene)
            AbstractPlotting.update!(scene)
            sleep(hopsec)
            frame_start += hopsec
        end

    end
    @cell "Test heatmap + image overlap" [image, heatmap, transparency] begin
        heatmap(rand(32, 32))
        image!(map(x->RGBAf0(x,0.5, 0.5, 0.8), rand(32,32)))
    end

    @cell "Animation" [scatter, linesegment, record] begin
        scene = Scene()
        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)
        time_node = Node(0.0)
        p1 = scatter!(scene, lift(t-> f.(t, range(0, stop = 2pi, length = 50), 1), time_node))[end]
        p2 = scatter!(scene, lift(t-> f.(t * 2.0, range(0, stop = 2pi, length = 50), 1.5), time_node))[end]
        points = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, points)
        N = 150
        record(scene, @replace_with_a_path(mp4), range(0, stop = 10, length = N)) do i
            time_node[] = i
        end
    end
    @cell "barplot" [barplot] begin
        # barplot(1:10, rand(10))
        # barplot(rand(10))
        barplot(rand(10), color = rand(10))
        # barplot(rand(3), color = [:red, :blue, :green])
    end
    @cell "poly and colormap" [poly, colormap, colorrang] begin
        # example by @Paulms from JuliaPlots/Makie.jl#310
        points = Point2f0[[0.0, 0.0], [0.1, 0.0], [0.1, 0.1], [0.0, 0.1]]
        colors = [0.0 ,0.0, 0.5, 0.0]
        scene = poly(points, color = colors, colorrange = (0.0,1.0))
        points = Point2f0[[0.1, 0.1], [0.2, 0.1], [0.2, 0.2], [0.1, 0.2]]
        colors = [0.5,0.5,1.0,0.3]
        poly!(scene, points, color = colors, colorrange = (0.0,1.0))
        scene
    end
    @cell "quiver" [quiver, arrows, vectorfield, gradient] begin
        using ImageFiltering
        x = range(-2, stop = 2, length = 21)
        y = x
        z = x .* exp.(-x .^ 2 .- (y') .^ 2)
        scene = contour(x, y, z, levels = 10, linewidth = 3)
        u, v = ImageFiltering.imgradients(z, KernelFactors.ando3)
        arrows!(x, y, u, v, arrowsize = 0.05)
    end
    @cell "Arrows on hemisphere" [arrows, quiver, mesh] begin
        # This example is courtesy of Mark Junge, (Github @Nyrox).
        scene = mesh(Sphere(Point3f0(0), 0.9f0), transparency=true, alpha=0.05)

        function cosine_weighted_sample_hemisphere()
            θ = acos(sqrt(rand()))
            ϕ = 2π * rand()

            Point3f0(sin(θ)cos(ϕ), cos(θ), sin(θ)sin(ϕ))
        end

        N = 100

        dirs = [cosine_weighted_sample_hemisphere() for i in 1:N]

        arrows!(
            scene,
            fill(Point3f0(0), N),
            dirs,
            arrowcolor=:red,
            arrowsize=0.1,
            linecolor=:red
        )
    end
    @cell "image" [image] begin
        vbox(
            image(AbstractPlotting.logo(), scale_plot = false),
            image(rand(100, 500), scale_plot = false),
        )
    end
    @cell "scatter colormap" [scatter, colormap] begin
        scatter(rand(10), rand(10), color = rand(10))
    end
    @cell "Lots of Heatmaps" [heatmap, performance, vbox, record] begin
        # example by @ssfrr
        function makeheatmaps(bufs)
            heatmaps = map(bufs) do buf
                heatmap(
                    buf, padding = (0,0), colorrange = (0,1),
                    axis = (names = (axisnames = ("", ""),),)
                )
            end
            scene = hbox(map(i-> vbox(heatmaps[i, :]), 1:size(bufs, 1))...)
            scene, last.(heatmaps)
        end
        datarows = 500; datacols = 500
        plotrows = 4; plotcols = 4
        bufs = [fill(0.0f0, datarows, datacols) for _ in 1:plotrows, _ in 1:plotcols]
        scene, hms = makeheatmaps(bufs)
        N = 100
        record(scene, @replace_with_a_path(mp4), 1:N) do i
            for (hm, buf) in zip(vec(hms), vec(bufs))
                buf .= rand.(Float32)
                hm[1] = buf
            end
            yield()
        end
    end
    @cell "FEM polygon 2D" [fem, poly] begin
        coordinates = [
            0.0 0.0;
            0.5 0.0;
            1.0 0.0;
            0.0 0.5;
            0.5 0.5;
            1.0 0.5;
            0.0 1.0;
            0.5 1.0;
            1.0 1.0;
        ]
        connectivity = [
            1 2 5;
            1 4 5;
            2 3 6;
            2 5 6;
            4 5 8;
            4 7 8;
            5 6 9;
            5 8 9;
        ]
        color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
        poly(coordinates, connectivity, color = color, strokecolor = (:black, 0.6), strokewidth = 4)
    end
    @cell "FEM mesh 2D" [fem, mesh] begin
        coordinates = [
            0.0 0.0;
            0.5 0.0;
            1.0 0.0;
            0.0 0.5;
            0.5 0.5;
            1.0 0.5;
            0.0 1.0;
            0.5 1.0;
            1.0 1.0;
        ]
        connectivity = [
            1 2 5;
            1 4 5;
            2 3 6;
            2 5 6;
            4 5 8;
            4 7 8;
            5 6 9;
            5 8 9;
        ]
        color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
        scene = mesh(coordinates, connectivity, color = color, shading = false)
        wireframe!(scene[end][1], color = (:black, 0.6), linewidth = 3)
    end
    @cell "colored triangle" [mesh, polygon] begin
        mesh(
            [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
            shading = false
        )
    end
    @cell "heatmap interpolation" [heatmap, interpolate, subscene, theme] begin
        using AbstractPlotting: hbox, vbox
        data = rand(50, 100)
        p1 = heatmap(data, interpolate = true)
        p2 = heatmap(data, interpolate = false)
        s = vbox(
            title(p1, "interpolate = true";  textsize = 15),
            title(p2, "interpolate = false"; textsize = 15),
        )
    end
    @cell "colored triangle" [polygon] begin
        poly(
            [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
            color = [:red, :green, :blue],
            strokecolor = :black, strokewidth = 2
        )
    end
    @cell "Subscenes" [image, scatter, subscene] begin
        img = rand(RGBAf0, 100, 100)
        scene = image(img, show_axis = false)
        subscene = Scene(scene, IRect(100, 100, 300, 300))
        scatter!(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
        scene
    end

    @cell "scale_plot" [scale] begin
        t = range(0, stop=1, length=500) # time steps
        θ = (6π) .* t    # angles
        x = t .* cos.(θ) # x coords of spiral
        y = t .* sin.(θ) # y coords of spiral
        p1 = lines(
             x,
             y,
             color      = t,
             colormap   = :algae,
             linewidth  = 8,
             scale_plot = false
         )
    end

    @cell "Polygons" [poly, polygon, linesegments] begin
        using GeometryBasics
        scene = Scene(resolution = (500, 500))
        points = decompose(Point2f0, Circle(Point2f0(50), 50f0))
        pol = poly!(scene, points, color = :gray, strokewidth = 10, strokecolor = :red)
        # Optimized forms
        poly!(scene, [Circle(Point2f0(50+300), 50f0)], color = :gray, strokewidth = 10, strokecolor = :red)
        poly!(scene, [Circle(Point2f0(50+i, 50+i), 10f0) for i = 1:100:400], color = :red)
        poly!(scene, [FRect2D(50+i, 50+i, 20, 20) for i = 1:100:400], strokewidth = 2, strokecolor = :green)
        linesegments!(scene,
            [Point2f0(50 + i, 50 + i) => Point2f0(i + 70, i + 70) for i = 1:100:400], linewidth = 8, color = :purple
        )
    end

    @cell "Contour Function" [contour] begin
        r = range(-10, stop = 10, length = 512)
        z = ((x, y)-> sin(x) + cos(y)).(r, r')
        contour(r, r, z, levels = 5, colormap = :viridis, linewidth = 3)
    end
    @cell "Hbox" [lines, scatter, hbox] begin
        t = range(-122277.93103448274, stop=-14798.035304081845, length=29542)
        x = -42 .- randn(length(t))
        sc1 = scatter(t, x, color=:black, markersize=sqrt(length(t)/20))
        sc2 = lines(t[1:end-1], diff(x), color = :blue)
        hbox(sc2, sc1)
    end
    @cell "Customize Axes" [lines, axis] begin
        x = LinRange(0,3pi,200); y = sin.(x)
        lin = lines(x, y, padding = (0.0, 0.0), axis = (
            names = (axisnames = ("", ""),),
            grid = (linewidth = (0, 0),),
        ))
    end
    @cell "contour" [contour] begin
        y = range(-0.997669, stop = 0.997669, length = 23)
        contour(range(-0.99, stop = 0.99, length = 23), y, rand(23, 23), levels = 10)
    end

    @cell "Heatmap" [heatmap] begin
        heatmap(rand(32, 32))
    end

    @cell "Animated Scatter" [animated, scatter, updating, record] begin
        N = 10
        r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:N]
        scene = scatter(r[1][:, 1], r[1][:, 2], markersize = 1, limits = FRect(-25/2, -25/2, 25, 25))
        s = scene[end] # last plot in scene
        record(scene, @replace_with_a_path(mp4), r) do m
            s[1] = m[:, 1]
            s[2] = m[:, 2]
        end
    end

    @cell "Text Annotation" [text, align, annotation] begin
        text(
            ". This is an annotation!",
            position = (300, 200),
            align = (:center,  :center),
            textsize = 60,
            font = "Blackchancery"
        )
    end

    @cell "Text rotation" [text, rotation] begin
        scene = Scene()
        pos = (500, 500)
        posis = Point2f0[]
        for r in range(0, stop = 2pi, length = 20)
            global pos, posis
            p = pos .+ (sin(r)*100.0, cos(r) * 100)
            push!(posis, p)
            t = text!(
                scene, "test",
                position = p,
                textsize = 50,
                rotation = 1.5pi - r,
                align = (:center, :center)
            )
        end
        scatter!(scene, posis, markersize = 10)
    end

    @cell "Chess Game" [heatmap, scatter, interactive] begin
        using Base.Iterators: repeated
        r = 1:8
        board = isodd.(r .+ r')
        scene = Scene(resolution = (1000, 1000))
        heatmap!(scene, board, scale_plot = false, show_axis = false)
        white = ['♕', '♔', '♖', '♖', '♗', '♗', '♘', '♘', repeated('♙', 8)...]
        wx_positions = [4, 5, 1, 8, 3, 6, 2, 7, (1:8)...]
        wy_positions = [repeated(1, 8)..., repeated(2, 8)...]
        w_positions = Point2.(wx_positions, wy_positions)
        white_game = scatter!(
            scene, w_positions, marker = white,
            scale_plot = false, show_axis = false,
            markersize = 0.5, marker_offset = Vec2f0(-0.7)
        )[end]
        black = Char.(Int.(white) .+ 6)
        b_positions = Point2f0.(wx_positions, [repeated(8, 8)..., repeated(7, 8)...])
        black_game = scatter!(
            scene, b_positions, marker = black,
            scale_plot = false, show_axis = false,
            markersize = 0.5, marker_offset = Vec2f0(-0.7)
        )[end]

        function move_fig!(color, figure, target)
            game = color == :white ? white_game : black_game
            game[1][][figure] = target
            game[1][] = game[1][]
        end
        st = Stepper(scene, @replace_with_a_path)
        step!(st)
        move_fig!(:white, 9, (1, 4))
        step!(st)
        st
    end

    @cell "linesegments + colors" [linesegments] begin
        using Colors
        linesegments(
            [rand(Point2f0) => rand(Point2f0) for i in 1:5],
            color = rand(RGB{Float64}, 5)
        )
    end

    @cell "Standard deviation band" [band, lines, statistics] begin
        # Sample 100 Brownian motion path and plot the mean trajectory together
        # with a ±1σ band (visualizing uncertainty as marginal standard deviation).
        using Statistics
        n, m = 100, 101
        t = range(0, 1, length=m)
        X = cumsum(randn(n, m), dims = 2)
        X = X .- X[:, 1]
        μ = vec(mean(X, dims=1)) # mean
        lines(t, μ)              # plot mean line
        σ = vec(std(X, dims=1))  # stddev
        band!(t, μ + σ, μ - σ)   # plot stddev band
    end

    @cell "Parallel Prefix Sum" [lines, scatter] begin
        # credits to [jiahao chen](https://github.com/jiahao)
        using GeometryBasics

        function prefix_sum(y, func)
            l = length(y)
            k = ceil(Int, log2(l))
            for j=1:k, i=2^j:2^j:min(l, 2^k)
                y[i] = func(y[i-2^(j-1)], y[i])
            end
            for j=(k-1):-1:1, i=3*2^(j-1):2^j:min(l, 2^k)
                y[i] = func(y[i-2^(j-1)], y[i])
            end
            y
        end
        import Base: getindex, setindex!, length, size

        mutable struct AccessArray <: AbstractArray{Nothing, 1}
            length::Int
            read::Vector
            history::Vector
        end

        function AccessArray(length, read = [], history = [])
            AccessArray(length, read, history)
        end

        length(A::AccessArray) = A.length
        size(A::AccessArray) = (A.length,)

        function getindex(A::AccessArray, i)
            push!(A.read, i)
            return
        end

        function setindex!(A::AccessArray, x, i)
            push!(A.history, (A.read, [i]))
            A.read = []
        end

        import Base.+
        +(a::Nothing, b::Nothing)=a
        A = prefix_sum(AccessArray(8), +)

        function render(A::AccessArray)
            olast = depth = 0
            for y in A.history
                (any(y[1] .≤ olast)) && (depth += 1)
                olast = maximum(y[2])
            end
            maxdepth = depth
            olast = depth = 0
            C = []
            for y in A.history
                (any(y[1] .≤ olast)) && (depth += 1)
                push!(C, ((y...,), A.length, maxdepth, depth))
                olast = maximum(y[2])
            end
            msize = 0.1
            outsize = 0.15
            x1 = Point2f0.(first.(first.(first.(C))), last.(C) .+ outsize .+ 0.05)
            x2 = Point2f0.(last.(first.(first.(C))), last.(C) .+ outsize .+ 0.05)
            x3 = Point2f0.(first.(last.(first.(C))), last.(C) .+ 1)
            connections = Point2f0[]

            yoff = Point2f0(0, msize / 2)
            ooff = Point2f0(0, outsize / 2 + 0.05)
            for i = 1:length(x3)
                push!(connections, x3[i] .- ooff, x1[i] .+ yoff, x3[i] .- ooff, x2[i] .+ yoff)
            end
            node_theme = Theme(
                markersize = msize, strokewidth = 3,
                strokecolor = :black, color = (:white, 0.0),
                axis = (
                    ticks = (ranges = (1:8, 1:5),),
                    names = (axisnames = ("Array Index", "Depth"),),
                    frame = (axis_position = :none,)
                )
            )
            s = scatter(node_theme, x1)
            scatter!(node_theme, x2)
            scatter!(x3, color = :white, markersize = 0.2, strokewidth = 4, strokecolor = :black)
            scatter!(x3, color = :red, marker = '+', markersize = outsize)
            linesegments!(connections, color = :red)
            s
        end
        render(A)
    end

    @cell "Interactive light cone" [record, interaction] begin

        # draw the axis
        scene = linesegments([Point2f0(-5,0) => Point2f0(5,0), Point2f0(0,-1) => Point2f0(0,2)],scale_plot=false, show_axis=false)

        function get_lightcone(pos)
            x,v = pos
            len = sqrt(x^2+2^2)
            return [
                    Point2f0(x,v) => Point2f0(x + x/len, v + 2/len),
                    Point2f0(x + x/len, v + 2/len) => Point2f0(x-1, v),
                    Point2f0(x-1, v) => Point2f0(x,v)
                ]
        end

        visible = Node(false)
        lift(scene.events.mousebuttons) do mb
            visible[] = ispressed(scene, Mouse.left)
        end

        coords = lift(scene.events.mouseposition) do mp
            pos = to_world(scene, Point2f0(mp))
            return get_lightcone(pos)
        end

        linesegments!(scene, coords; visible = visible)

        # Do not execute beyond this point!

        RecordEvents(scene, @replace_with_a_path)

    end

    @cell "Cobweb plot" [lines, interaction] begin
        ## setup functions
        f(x::Real, r::Real) = r * x * (1 - x)
        function cobweb(
              xᵢ::Real,
              curve_f::Function,
              r::Real;
              nstep::Real = 30
          )::Vector{Point2f0} # col 1 is x, col 2 is y

          a = zeros(nstep*2, 2)
          a[1, 1] = xᵢ
          x = xᵢ
          y = curve_f(x, r)
          ret = similar(Vector{Point2f0}, nstep*2)

          for i ∈ 2:2:nstep*2-2
              a[i, 1] = x
              a[i, 2] = y
              x = y
              y = curve_f(x, r)
              a[i+1, 1] = x
              a[i+1, 2] = x
              ret[i] = Point2f0(a[i, 1], a[i, 2])
              ret[i+1] = Point2f0(a[i+1, 1], a[i+1, 2])
          end

          return ret

        end

        xᵢ = 0.1
        rᵢ = 2.8
        xr = 0:0.001:1
        ## setup sliders
        sx, x = textslider(0:0.01:1, "xᵢ", start = xᵢ)
        sr, r = textslider(0:0.01:4, "r", start = rᵢ)
        ## setup lifts
        fs = lift(r -> f.(xr, r), r)
        cw = lift((x, r) -> cobweb(x, f, r), x, r)
        ## setup plots
        sc = lines(               # plot x=y, the bisector line
          xr,                   # xs
          xr,                   # ys
          linestyle = :dash,    # style of line
          linewidth = 3,        # width of line
          color = :blue        # colour of line
        )

        sc[Axis][:names][:axisnames] = ("x(t)", "x(t+1)") # set axis names

        lines!(sc, xr, fs) # plot the curve

        lines!(sc, cw) # plot the cobweb

        xlims!(sc, (0, 1))
        ylims!(sc, (0, 1))

        final = hbox(sc, vbox(sx, sr))

        record(final, @replace_with_a_path(mp4), range(0.01, stop = 5, length = 100)) do i
          r[] = i
        end
    end

    @cell "Streamplot animation" ["streamplot", "animation"] begin

        v(x::Point2{T}, t) where T = Point2{T}(one(T) * x[2] * t, 4 * x[1])

        sf = Node(Base.Fix2(v, 0e0))

        title_str = Node("t = 0.00")

        sp = streamplot(sf, -2..2, -2..2;
                        linewidth = 2, padding = (0, 0),
                        arrow_size = 0.09, colormap =:magma)

        sc = title(sp, title_str)

        record(sc, @replace_with_a_path(mp4), LinRange(0, 20, 5*30)) do i
            sf[] = Base.Fix2(v, i)
            title_str[] = "t = $(round(i; sigdigits = 2))"
        end
    end
end

@block AnshulSinghvi ["colors"] begin

    @cell "Line with varying colors" [lines, colors, colorlegend, camera] begin

        using ColorSchemes      # colormaps galore

        t = range(0, stop=1, length=500) # time steps

        θ = (6π) .* t    # angles

        x = t .* cos.(θ) # x coords of spiral
        y = t .* sin.(θ) # y coords of spiral

        p1 = lines(
            x,
            y,
            color = t,
            colormap = ColorSchemes.magma.colors,
            linewidth=8)

        cm = colorlegend(
            p1[end],             # access the plot of Scene p1
            raw = true,          # without axes or grid
            camera = campixel!,  # gives a concrete bounding box in pixels
                                 # so that the `vbox` gives you the right size
            width = (            # make the colorlegend longer so it looks nicer
                30,              # the width
                540              # the height
            ))

        scene_final = vbox(p1, cm) # put the colorlegend and the plot together in a `vbox`

    end

    @cell "Viridis color scheme" [colorlegend, colors] begin

        c = to_colormap(:viridis) # get colors of colormap

        image(         # to plot colors, an image is best
           0..10,      # x range
           0..1,       # y range
           hcat(c, c), # reshape this to a matrix for the colors
           show_axis  = false, # don't show axes
           scale_plot = false,  # maintain aspect ratio,
           resolution = (1000, 200)
        )

    end

    @cell "timeseries" [timeseries, lines, animation] begin
        signal = Node(0.0)
        scene = timeseries(signal, history = 30)
        record(scene, @replace_with_a_path(mp4), LinRange(0, 10π, 240); framerate = 24) do i
            signal[] = sin(i)
        end
    end

    @cell "Line changing colour" [colors, lines, animation] begin

        scene = lines(rand(10); linewidth=10)

        record(scene, @replace_with_a_path(mp4), 1:255; framerate = 60) do i
               scene.plots[2][:color] = RGBf0(i/255, (255 - i)/255, 0) # animate scene
               # `scene.plots` gives the plots of the Scene.
               # `scene.plots[1]` is always the Axis if it exists,
               # and `scene.plots[2]` onward are the user-defined plots.
        end

    end

    @cell "Line changing colour with Observables" [colors, lines, animation, observables] begin

        "'Time' - an Observable that controls the animation"
        t = Node(0)

        "The colour of the line"
        c = lift(t) do t
                RGBf0(t/255, (255 - t)/255, 0)
            end

        scene = lines(rand(10); linewidth=10, color = c)

        record(scene, @replace_with_a_path(mp4), 1:255; framerate = 60) do i
            t[] = i # update `t`'s value
        end

    end

    @cell "streamplot" [arrows, lines, streamplot] begin
        struct FitzhughNagumo{T}
            ϵ::T
            s::T
            γ::T
            β::T
        end

        P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)
        f(x, P::FitzhughNagumo) = Point2f0(
            (x[1]-x[2]-x[1]^3+P.s)/P.ϵ,
            P.γ*x[1]-x[2] + P.β
        )
        f(x) = f(x, P)
        streamplot(f, -1.5..1.5, -1.5..1.5, colormap = :magma)
    end

    @cell "Categorical heatmap" [heatmap, categorical, string] begin
        x = ["a", "b", "c"]
        y = ["α", "β", "γ"]
        heatmap(x, y, rand(3, 3))
    end

end

@block AnshulSinghvi ["Recipes"] begin

    @cell "Arc" [arc] begin
        s = arc(
            Point2f0(0, 0),   # origin
            1,        # radius
            0,        # start angle
            pi        # end angle
        )
        s
    end

end

@block AnshulSinghvi ["Transformations"] begin
    @cell "Transforming lines" [transformation, lines] begin
        N = 7 # number of colours in default palette
        sc = Scene()
        st = Stepper(sc, @replace_with_a_path)

        xs = 0:9        # data
        ys = zeros(10)

        for i in 1:N    # plot lines
            lines!(sc,
                xs, ys;
                color = AbstractPlotting.default_palettes.color[][i],
                limits = FRect((0, 0), (10, 10)),
                linewidth = 5
            ) # plot lines with colors
        end

        center!(sc)

        step!(st)

        for (i, rot) in enumerate(LinRange(0, π/2, N))
            rotate!(sc.plots[i+1], rot)
            arc!(sc,
                Point2f0(0),
                (8 - i),
                pi/2,
                (pi/2-rot);
                color = sc.plots[i+1].color,
                linewidth = 5,
                linestyle = :dash
            )
        end

        step!(st)
    end
end
