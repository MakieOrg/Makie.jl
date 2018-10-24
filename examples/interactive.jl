@block SimonDanisch [interaction] begin

    @cell "Interaction with Mouse" [interactive, scatter, lines, marker, record] begin
        using LinearAlgebra
        scene = Scene()
        r = range(0, stop = 3, length = 4)
        cam2d!(scene)
        time = Node(0.0)
        pos = lift(scene.events.mouseposition, time) do mpos, t
            map(range(0, stop = 2pi, length = 60)) do i
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
        p2[:marker] = 'π' #TODO fix this
        p2[:markersize] = 0.2

        # push a reasonable mouse position in case this is executed as part
        # of the documentation
        push!(scene.events.mouseposition, (250.0, 250.0))
        N = 50
        record(scene, @outputfile(mp4), range(0.01, stop = 0.4, length = N)) do i
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
        on(scene.events.mousebuttons) do buttons
           if ispressed(scene, Mouse.left)
               pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
               push!(clicks, push!(clicks[], pos))
           end
           return
        end
        scatter!(scene, clicks, color = :red, marker = '+', markersize = 10)
    end

    @cell "sliders" [scatter, slider] begin
        s1 = slider(LinRange(0.01, 1, 100), raw = true, camera = campixel!)
        s2 = slider(LinRange(-2pi, 2pi, 100), raw = true, camera = campixel!)
        data = lift(s2[end][:value]) do v
            map(LinRange(0, 2pi, 100)) do x
                4f0 .* Point2f0(sin(x) + (sin(x * v) .* 0.1), cos(x) + (cos(x * v) .* 0.1))
            end
        end
        p = scatter(data, markersize = s1[end][:value])
        hbox(p, vbox(s1, s2))
    end
end
