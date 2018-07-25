@block SimonDanisch [interaction] begin

    @cell "Interaction with Mouse" [interactive, scatter, lines, marker, record] begin
        scene = Scene()
        r = linspace(0, 3, 4)
        cam2d!(scene)
        time = Node(0.0)
        pos = lift(scene.events.mouseposition, time) do mpos, t
            map(linspace(0, 2pi, 60)) do i
                circle = Point2f0(sin(i), cos(i))
                mouse = to_world(scene, Point2f0(mpos))
                secondary = (sin((i * 10f0) + t) * 0.09) * normalize(circle)
                (secondary .+ circle) .+ mouse
            end
        end
        scene = lines!(scene, pos, raw = true)
        p1 = scene[end]
        p2 = scatter!(
            scene,
            pos, markersize = 0.1f0,
            marker = :star5,
            color = p1[:color],
            raw = true
        )[end]
        scene
        display(Makie.global_gl_screen(), scene)

        p1[:color] = RGBAf0(1, 0, 0, 0.1)
        p2[:marker] = 'π'
        p2[:markersize] = 0.2

        # push a reasonable mouse position in case this is executed as part
        # of the documentation
        push!(scene.events.mouseposition, (250.0, 250.0))
        N = 50
        record(scene, @outputfile(mp4), linspace(0.01, 0.4, N)) do i
            push!(scene.events.mouseposition, (250.0, 250.0))
            p2[:markersize] = i
            push!(time, time[] + 0.1)
        end
    end

    @cell "Mouse Picking" [scatter, heatmap, interactive] begin
        img = rand(100, 100)
        scene = Scene()
        heatmap!(scene, img, scale_plot = false)
        clicks = Node(Point2f0[(0,0)])
        foreach(scene.events.mousebuttons) do buttons
           if ispressed(scene, Mouse.left)
               pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
               push!(clicks, push!(clicks[], pos))
           end
           return
        end
        scatter!(scene, clicks, color = :red, marker = '+', markersize = 10, raw = true)
    end
end
