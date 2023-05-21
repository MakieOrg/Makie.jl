function plotting_funcs(folder)
    MAKIERED = "#CB4266"
    MAKIEYELLOW = "#E2CC4D"
    MAKIEBLUE = "#477FB5"

    th = Theme(
        resolution = (300, 300),
        Axis = (
            spinewidth = 3,
            bottomspinecolor = :gray90,
            leftspinecolor = :gray90,
            titlesize = 30,
            aspect = 1,
            topspinevisible = false,
            rightspinevisible = false,
            xticklabelsvisible = false,
            yticklabelsvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            xautolimitmargin = (0.15, 0.15),
            yautolimitmargin = (0.15, 0.15),
            xgridvisible = false,
            ygridvisible = false,
        ),
        Axis3 = (
            aspect = :equal,
            xspinecolor_1 = :transparent,
            xspinecolor_2 = :gray90,
            xspinecolor_3 = :transparent,
            xspinewidth = 3,
            yspinecolor_1 = :transparent,
            yspinecolor_2 = :gray90,
            yspinecolor_3 = :transparent,
            yspinewidth = 3,
            zspinecolor_1 = :transparent,
            zspinecolor_2 = :gray90,
            zspinecolor_3 = :transparent,
            zspinewidth = 3,
            xgridvisible = false,
            ygridvisible = false,
            zgridvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            zticksvisible = false,
            xticklabelsvisible = false,
            yticklabelsvisible = false,
            zticklabelsvisible = false,
            titlesize = 30,
            protrusions = 0,
        )
    )

    function makefig(func, name; backend = CairoMakie, format = backend == CairoMakie ? "svg" : "png")
        fig = with_theme(func, th)
        Label(fig[0, :], name, tellwidth = false, font = :bold, fontsize = 25)
        filename = joinpath(folder, "$name.$format")
        backend.activate!()
        backend.save(filename, fig)
        return name => "$name.$format"
    end

    thumbpairs = [
        makefig("ablines") do
            f = Figure()
            ax = Axis(f[1, 1])
            ablines!(ax, 1, 0.8, color = MAKIERED, linewidth = 6)
            ablines!(ax, 8, -0.6, color = MAKIEBLUE, linewidth = 6, linestyle = :dash)
            ablines!(ax, 3.5, 0, color = MAKIEYELLOW, linewidth = 6, linestyle = :dot)
            f
        end,
        makefig("arc") do
            f = Figure()
            ax = Axis(f[1, 1])
            arc!(ax, Point(0, 0), 1, 0, 1.5pi, color = MAKIEBLUE, linewidth = 6)
            arc!(ax, Point(0, 0), 0.75, pi, 2.5pi, color = MAKIERED, linewidth = 6)
            f
        end,
        makefig("arrows") do
            f = Figure()
            ax = Axis(f[1, 1])
            arrows!(ax,
                [Point2f(cos(a * pi), sin(a * pi)) for a in range(0.1, 0.3, length = 3)],
                [2 .* Point2f(cos(a * pi), sin(a * pi)) for a in range(0.1, 0.3, length = 3)],
                color = [MAKIEBLUE, MAKIERED, MAKIEYELLOW],
                linewidth = 6,
                arrowsize = 25,
            )
            f
        end,
        makefig("band") do
            f = Figure()
            ax = Axis(f[1, 1])
            x = 0:0.1:1.3pi
            ylower = sin.(x) .+ 1.5 .* x
            yupper = sin.(x) .+ 1.5 .* x .+ 3
            band!(ax, x, ylower, yupper, color = (MAKIERED, 0.8))
            ylower = reverse(cos.(x) .+ 1.5 .* x)
            yupper = reverse(cos.(x) .+ 1.5 .* x .+ 3)
            band!(ax, x, ylower, yupper, color = (MAKIEBLUE, 0.8))
            f
        end,
        makefig("barplot") do
            f = Figure()
            ax = Axis(f[1, 1])
            barplot!(ax, [2, 4, 3], color = [MAKIEBLUE, MAKIERED, MAKIEYELLOW])
            f
        end,
        makefig("boxplot") do
            f = Figure()
            ax = Axis(f[1, 1])
            boxplot!(ax, fill(1, 100), 1:100, color = MAKIEBLUE, medianlinewidth = 6, whiskerlinewidth = 6, mediancolor = :gray30, whiskercolor = :gray30)
            boxplot!(ax, fill(2, 100), 1.5 .* (1:100) .- 60, color = MAKIERED, medianlinewidth = 6, whiskerlinewidth = 6, mediancolor = :gray30, whiskercolor = :gray30)
            boxplot!(ax, fill(3, 100), (1:100) .+ 20, color = MAKIEYELLOW, medianlinewidth = 6, whiskerlinewidth = 6, mediancolor = :gray30, whiskercolor = :gray30)
            f
        end,
        makefig("bracket") do
            f = Figure()
            ax = Axis(f[1, 1])
            bracket!(ax, 0, 0, 1, 0, linewidth = 6, color = MAKIERED, width = 40, offset = 5, text = "A", fontsize = 25, font = :bold, textcolor = MAKIERED)
            bracket!(ax, 0, 0, 1, 0, linewidth = 6, color = MAKIEYELLOW, width = 30, style = :square, orientation = :down, offset = 5, text = "B", fontsize = 25, font = :bold, textcolor = MAKIEYELLOW)
            f
        end,
        makefig("contour") do
            f = Figure()
            ax = Axis(f[1, 1])
            function func(x, y)
                r = sqrt(x^2 + y^2)
                angwobble = (2 + 0.3 * sin(3 * atan(y, x) + 0.3 * r))
                r * angwobble * 0.36
            end
            contour!(ax, -5:0.1:5, -5:0.1:5, func, levels = [1, 2, 3], linewidth = 6, color = [MAKIEBLUE, MAKIEYELLOW, MAKIERED],
                labels = true, labelsize = 25)
            f
        end,
        makefig("heatmap") do
            f = Figure()
            ax = Axis(f[1, 1])
            heatmap!(ax, randn(6, 6), colormap = [MAKIEBLUE, MAKIERED, MAKIEYELLOW])
            f
        end,
        makefig("lines") do
            f = Figure()
            ax = Axis(f[1, 1])
            lines!(ax, 0..2pi, x -> sin(x) + 0.5x, color = MAKIERED, linewidth = 6)
            f
        end,
        makefig("meshscatter") do
            f = Figure()
            ax = Axis3(f[1, 1])
            meshscatter!(ax, randn(15, 3), color = MAKIERED, markersize = 0.3)
            limits!(ax, -2.5, 2.5, -2.5, 2.5, -2.5, 2.5)
            f
        end,
        makefig("scatterlines") do
            f = Figure()
            ax = Axis(f[1, 1])
            scatterlines!(ax, 0:0.5:2pi, x -> sin(x) + 0.5x,
                color = MAKIERED,
                linewidth = 6,
                markersize = 15,
                markercolor = :white,
                strokecolor = MAKIERED,
                strokewidth = 4)
            f
        end,
        makefig("scatter") do
            function rand_in_unit_circle()
                theta = 2π * rand()
                r = sqrt(rand())
            
                x = r * cos(theta)
                y = r * sin(theta)
            
                return Point2f(x, y)
            end
            
            f = Figure()
            ax = Axis(f[1, 1])
            scatter!(ax, [rand_in_unit_circle() for _ in 1:20], color = MAKIERED)
            scatter!(ax, [rand_in_unit_circle() + Point2f(cos(0), sin(0)) .* 3 for _ in 1:20], color = MAKIEBLUE)
            scatter!(ax, [rand_in_unit_circle() + Point2f(cosd(60), sind(60)) .* 3 for _ in 1:20], color = MAKIEYELLOW)
            f
        end,
    ]
    sort(thumbpairs, by = first)
end