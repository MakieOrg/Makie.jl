
@block AnthonyWang [documentation] begin
    @cell "pong" [animated, scatter, updating] begin
        # init speed and velocity vector
        xyvec = rand(Point2f0, (2)) .* 5 .+ 1
        velvec = rand(Point2f0, (2)) .* 10
        # define some other parameters
        t = 0
        ts = 0.03
        balldiameter = 1
        origin = Point2f0(0, 0)
        xybounds = Point2f0(10, 10)
        N = 200
        scene = scatter(
            xyvec,
            markersize = balldiameter,
            color = rand(RGBf0, 2),
            limits = FRect(0, 0, xybounds)
        )
        s = scene[end] # last plot in scene

        record(scene, @outputfile(mp4), 1:N) do i
            # calculate new ball position
            global t = t + ts
            global xyvec = xyvec .+ velvec .* ts
            global velvec = map(xyvec, xybounds, origin, velvec) do p, b, o, vel
                boolvec = ((p .+ balldiameter/2) .> b) .| ((p .- balldiameter/2) .< o)
                velvec = map(boolvec, vel) do b, v
                    b ? -v : v
                end
            end
            # plot
            s[1] = xyvec
        end
    end

    @cell "pulsing marker" [animated, scatter, markersize, updating] begin
        N = 100
        scene = scatter([0], [0], marker = '❤', markersize = 0.5, color = :red, raw = true)
        s = scene[end] # last plot in scene
        record(scene, @outputfile(mp4), linspace(0, 10pi, N)) do i
            s[:markersize] = (cos(i) + 1) / (5 + 1)
        end
    end

    @cell "Travelling wave" [animated, lines, updating, interaction] begin
        scene = Scene()
        time = Node(0.0)
        f(v, t) = sin(v + t)
        scene = lines!(
            scene,
            lift(t -> f.(linspace(0, 2pi, 50), t), time),
            color = :blue
        )
        p1 = scene[end];
        N = 100
        record(scene, @outputfile(mp4), linspace(0, 4pi, N)) do i
            time[] = i
        end
    end

    @cell "Viridis scatter" ["2d", scatter, color, viridis, colormap] begin
        N = 30
        scatter(1:N, 1:N, markersize = 2, color = to_colormap(:viridis, N))
    end

    @cell "Viridis meshscatter" ["3d", scatter, color, viridis, colormap] begin
        N = 30
        R = 2
        theta = 4pi
        h = 5
        x = [R .* (t/3) .* cos(t) for t = linspace(0, theta, N)]
        y = [R .* (t/3) .* sin(t) for t = linspace(0, theta, N)]
        z = linspace(0, h, N)
        meshscatter(x, y, z, markersize = 0.5, color = to_colormap(:viridis, N))
    end

    @cell "Marker sizes + Marker colors" ["2d", scatter, markersize, color] begin
        scatter(
            rand(20), rand(20),
            markersize = rand(20) ./20 + 0.02,
            color = rand(RGBf0, 20)
        )
    end

    @cell "Marker offset" [scatter, marker_offset] begin
        scene = Scene(@resolution)
        points = Point2f0[(0,0), (1,1), (2,2)]
        offset = rand(Point2f0, 3)./5
        scatter!(scene, points)
        scatter!(scene, points, marker_offset = offset, color = :red)
    end

    @cell "colormaps" [image, translate, colormap, colorbrewer, meta] begin
        h = 0.0
        offset = 0.1
        scene = Scene()
        cam2d!(scene)
        plot = map(AbstractPlotting.colorbrewer_names) do cmap
            global h
            c = to_colormap(cmap)
            cbar = image!(
                scene,
                linspace(0, 10, length(c)),
                linspace(0, 1, length(c)),
                reshape(c, (1, length(c))),
                show_axis = false
            )[end]
            text!(
                scene,
                string(cmap, ":"),
                position = Point2f0(-0.1, 0.5 + h),
                align = (:right, :center),
                show_axis = false,
                textsize = 0.4
            )
            translate!(cbar, 0, h, 0)
            h -= (1 + offset)
        end
        scene
    end

    @cell "Available markers" [annotations, markers, meta] begin
        using GeometryTypes
        scene = Scene()
        marker = collect(AbstractPlotting._marker_map)
        positions = Point2f0.(0, 1:length(marker))
        scatter!(
            scene,
            positions,
            marker = last.(marker),
            markersize = 0.8,
            raw = true,
            marker_offset = Vec2f0(0.5, -0.4)
        )
        cam2d!(scene)
        annotations!(
            scene,
            string.(":", first.(marker)),
            positions,
            align = (:right, :center),
            textsize = 0.4,
            raw = true
        )
    end

    @cell "Theming" [theme, scatter, surface, set_theme] begin
        new_theme = Theme(
            resolution = (500, 500),
            linewidth = 3,
            colormap = :RdYlGn,
            color = :red,
            scatter = Theme(
                marker = '⊝',
                markersize = 0.03,
                strokecolor = :black,
                strokewidth = 0.1,
            ),
        )
        AbstractPlotting.set_theme!(new_theme)
        scene2 = scatter(rand(100), rand(100))
        new_theme[:color] = :blue
        new_theme[:scatter, :marker] = '◍'
        new_theme[:scatter, :markersize] = 0.05
        new_theme[:scatter, :strokewidth] = 0.1
        new_theme[:scatter, :strokecolor] = :green
        scene2 = scatter(rand(100), rand(100))
        scene2[end][:marker] = 'π'

        r = linspace(-0.5pi, pi + pi/4, 100)

        AbstractPlotting.set_theme!(new_theme)
        scene = surface(r, r, (x, y)-> sin(2x) + cos(2y))
        scene[end][:colormap] = :PuOr
        scene
        surface!(r + 2pi - pi/4, r, (x, y)-> sin(2x) + cos(2y))
        AbstractPlotting.set_theme!(resolution = (500, 500))
        surface(r + 2pi - pi/4, r, (x, y)-> sin(2x) + cos(2y))
    end
end
