
@block AnthonyWang [tutorials] begin

    # @cell "Tutorial scene" [tutorial, scene] begin
    #     scene = Scene()
    # end

    @cell "Tutorial simple scatter" [tutorial, scatter] begin
        x = rand(10)
        y = rand(10)
        colors = rand(10)

        scene = scatter(x, y, color = colors)
    end

    @cell "Tutorial markersize" [tutorial, scatter, markersize] begin
        x = 1:10
        y = 1:10
        sizevec = [s for s = 1:length(x)] ./ 10

        scene = scatter(x, y, markersize = sizevec)
    end

    @cell "Tutorial simple line" [tutorial, line] begin
        x = linspace(0, 2pi, 40)
        f(x) = sin.(x)
        y = f(x)

        scene = lines(x, y, color = :blue)
    end

    @cell "Tutorial adding to a scene" [tutorial, line, scene, markers] begin
        x = linspace(0, 2pi, 80)
        f1(x) = sin.(x)
        f2(x) = exp.(-x) .* cos.(2pi*x)
        y1 = f1(x)
        y2 = f2(x)

        scene = lines(x, y1, color = :blue)
        scatter!(scene, x, y1, color = :red, markersize = 0.1)

        lines!(scene, x, y2, color = :black)
        scatter!(scene, x, y2, color = :green, marker = :utriangle, markersize = 0.1)
    end

    @cell "Tutorial adjusting scene limits" [tutorial, scene, limits] begin
        x = linspace(0, 10, 40)
        y = x
        #= specify the scene limits, note that the arguments for FRect are
            x_min, y_min, x_dist, y_dist,
            therefore, the maximum x and y limits are then x_min + x_dist and y_min + y_dist
        =#
        limits = FRect(-5, -10, 20, 30)

        scene = lines(x, y, color = :blue, limits = limits)
    end

    @cell "Tutorial basic theming" [tutorial, scene, limits] begin
        x = linspace(0, 2pi, 40)
        f(x) = cos.(x)
        y = f(x)
        scene = lines(x, y, color = :blue)

        axis = scene[Axis] # get the axis object from the scene
        axis[:grid][:linecolor] = ((:red, 0.5), (:blue, 0.5))
        axis[:names][:textcolor] = ((:red, 1.0), (:blue, 1.0))
        axis[:names][:axisnames] = ("x", "y = cos(x)")
        scene
    end

    @cell "Tutorial heatmap" [tutorial, heatmap] begin
        x = rand(10)
        y = rand(10)
        scene = heatmap(x, y)
    end

    @cell "Tutorial linesegments" [tutorial, linesegments] begin
        points = [
            Point2f0(0, 0) => Point2f0(5, 5);
            Point2f0(15, 15) => Point2f0(25, 25);
            Point2f0(0, 15) => Point2f0(35, 5);
            ]
        scene = linesegments(points, color = :red, linewidth = 2)
    end

    @cell "Tutorial barplot" [tutorial, barplot] begin
        data = sort(randn(100))
        barplot(1:10, rand(10))
        barplot(data)
        barplot(rand(10), color = rand(10))
    end

end
