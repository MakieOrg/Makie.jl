@block SimonDanisch [interaction, record_events] begin
    @cell "Interaction with Mouse" [interactive, scatter, lines, marker, record] begin
        using LinearAlgebra
        scene = Scene(raw = true, camera = cam2d!, resolution = (500, 500))
        r = range(0, stop = 3, length = 4)
        the_time = Node(time())
        last_open = false
        @async while true
            global last_open
            the_time[] = time()
            # this is a bit awkward, since the isopen(scene) is false
            # as long as the scene isn't displayed
            last_open && !isopen(scene) && break
            last_open = isopen(scene)
            sleep(1/25)
        end
        pos = lift(scene.events.mouseposition, the_time) do mpos, t
            map(LinRange(0, 2pi, 60)) do i
                circle = Point2f0(sin(i), cos(i))
                mouse = to_world(scene, Point2f0(mpos))
                secondary = (sin((i * 10f0) + t) * 0.09) * normalize(circle)
                (secondary .+ circle) .+ mouse
            end
        end
        lines!(scene, pos)
        p1 = scene[end]
        p2 = scatter!(
            scene,
            pos, markersize = 0.1f0,
            marker = :star5,
            color = p1[:color],
        )[end]
        center!(scene)
        t = Theme(raw = true, camera = campixel!)
        b1 = button(t, "color")
        b2 = button(t, "marker")
        msize = slider(t, 0.1:0.01:0.5)
        on(b1[end][:clicks]) do c
            p1[:color] = rand(RGBAf0)
        end
        markers = ('π', '😹', '⚃', '◑', '▼')
        on(b2[end][:clicks]) do c
            p2[:marker] = markers[rand(1:5)]
        end
        on(msize[end][:value]) do val
            p2[:markersize] = val
        end
        RecordEvents(hbox(
            vbox(b1, b2, msize),
            scene
        ), @replace_with_a_path)
    end

    @cell "Mouse Picking" [scatter, heatmap, interactive] begin
        img = rand(100, 100)
        scene = Scene(resolution = (500, 500))
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
        RecordEvents(scene, @replace_with_a_path)
    end

    @cell "sliders" [scatter, slider, vbox] begin
        s1 = slider(LinRange(0.01, 1, 100), raw = true, camera = campixel!, start = 0.3)
        s2 = slider(LinRange(-2pi, 2pi, 100), raw = true, camera = campixel!)
        data = lift(s2[end][:value]) do v
            map(LinRange(0, 2pi, 100)) do x
                4f0 .* Point2f0(sin(x) + (sin(x * v) .* 0.1), cos(x) + (cos(x * v) .* 0.1))
            end
        end
        p = scatter(data, markersize = s1[end][:value])

        RecordEvents(
            hbox(p, vbox(s1, s2), parent = Scene(resolution = (500, 500))),
            @replace_with_a_path
        )
    end

    @cell "Mouse Hover" [lines, hover, lift, poly, translate, text, popup, on] begin
        using Colors, Observables
        r = range(0, stop=5pi, length=100)
        scene = Scene(resolution = (500, 500))
        lines!(scene, r, sin.(r), linewidth = 3)
        lineplot = scene[end]
        visible = node(:visible, false)
        poprect = lift(scene.events.mouseposition) do mp
            FRect((mp .+ 5), 250, 40)
        end
        textpos = lift(scene.events.mouseposition) do mp
            Vec3f0((mp .+ 5 .+ (250/2, 40 / 2))..., 120)
        end
        popup = poly!(campixel(scene), poprect, raw = true, color = :white, strokewidth = 2, strokecolor = :black, visible = visible)
        rect = popup[end]
        translate!(rect, Vec3f0(0, 0, 100))
        text!(popup, "( 0.000,  0.000)", textsize = 30, position = textpos, color = :darkred, align = (:center, :center), raw = true, visible = visible)
        text_field = popup[end]
        scene
        x = Node(false)
        on(scene.events.mouseposition) do event
            plot, idx = Makie.mouse_selection(scene)
            if plot == lineplot && idx > 0
                visible[] = true
                text_field[1] = sprint(io-> print(io, round.(Float64.(Tuple(lineplot[1][][idx])), digits = 3)))
            else
                visible[] = false
            end
            return
        end
        RecordEvents(scene, @replace_with_a_path)
    end

    @cell "GUI for exploring Lorenz equation" [vbox, hbox, meshscatter, slider, textslider, colorswatch] begin
        using Colors, Makie
        using AbstractPlotting: textslider, colorswatch
        s1, a = textslider(0f0:50f0, "a", start = 13)
        s2, b = textslider(-20f0:20f0, "b", start = 10)
        s3, c = textslider(0f0:20f0, "c", start = 2)
        s4, d = textslider(range(0.0, stop = 0.02, length = 100), "d", start = 0.01)
        s5, scales = textslider(range(0.01, stop = 0.5, length = 100), "scale", start = 0.1)
        s6, colorsw, pop = colorswatch()

        function lorenz(t0, a, b, c, h)
            Point3f0(
                t0[1] + h * a * (t0[2] - t0[1]),
                t0[2] + h * (t0[1] * (b - t0[3]) - t0[2]),
                t0[3] + h * (t0[1] * t0[2] - c * t0[3]),
            )
        end
        # step through the `time`
        function lorenz(array::Vector, a = 5.0 ,b = 2.0, c = 6.0, d = 0.01)
            t0 = Point3f0(0.1, 0, 0)
            for i = eachindex(array)
                t0 = lorenz(t0, a,b,c,d)
                array[i] = t0
            end
            array
        end
        n1, n2 = 18, 30
        N = n1*n2
        args_n = (a, b, c, d)
        v0 = lorenz(zeros(Point3f0, N), to_value.(args_n)...)
        positions = lift(lorenz, Node(v0), args_n...)
        rotations = lift(diff, positions)
        rotations = lift(x-> push!(x, x[end]), rotations)

        mesh_scene = meshscatter(
            positions,
            markersize = scales, rotation = rotations,
            intensity = collect(range(0f0, stop = 1f0, length = length(positions[]))),
            color = colorsw
        )
        parent = Scene(resolution = (1000, 800))
        vbox(
            hbox(s1, s2, s3, s4, s5, s6),
            mesh_scene, parent = parent
        )
        RecordEvents(parent, @replace_with_a_path)
    end

    @cell "Edit Polygon" [poly, node, on, events] begin
        points = node(:poly, Point2f0[(0, 0), (0.5, 0.5), (1.0, 0.0)])
        scene = Scene(resolution = (500, 500))
        poly!(scene, points, strokewidth = 2, strokecolor = :black, color = :skyblue2, show_axis = false, scale_plot = false)
        scatter!(points, color = :white, strokewidth = 10, markersize = 0.05, strokecolor = :black, raw = true)
        pplot = scene[end]
        push!(points[], Point2f0(0.6, -0.3))
        points[] = points[]
        function add_move!(scene, points, pplot)
            idx = Ref(0); dragstart = Ref(false); startpos = Base.RefValue(Point2f0(0))
            on(events(scene).mousedrag) do drag
                if ispressed(scene, Mouse.left)
                    if drag == Mouse.down
                        plot, _idx = Makie.mouse_selection(scene)
                        if plot == pplot
                            idx[] = _idx; dragstart[] = true
                            startpos[] = to_world(scene, Point2f0(scene.events.mouseposition[]))
                        end
                    elseif drag == Mouse.pressed && dragstart[] && checkbounds(Bool, points[], idx[])
                        pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
                        points[][idx[]] = pos
                        points[] = points[]
                    end
                else
                    dragstart[] = false
                end
                return
            end
        end

        function add_remove_add!(scene, points, pplot)
            on(events(scene).mousebuttons) do but
                if ispressed(but, Mouse.left) && ispressed(scene, Keyboard.left_control)
                    pos = to_world(scene, Point2f0(events(scene).mouseposition[]))
                    push!(points[], pos)
                    points[] = points[]
                elseif ispressed(but, Mouse.right)
                    plot, idx = Makie.mouse_selection(scene)
                    if plot == pplot && checkbounds(Bool, points[], idx)
                        deleteat!(points[], idx)
                        points[] = points[]
                    end
                end
                return
            end
        end
        add_move!(scene, points, pplot)
        add_remove_add!(scene, points, pplot)
        center!(scene)
        RecordEvents(scene, @replace_with_a_path)
    end

    @cell "Add and change points" [heatmap, on, ispressed, to_world, scatter, center] begin
        using LinearAlgebra
        img = rand(100, 100)
        scene = Scene(scale_plot = false, resolution = (500, 500))
        heatmap!(scene, img)
        clicks = Node(Point2f0[(0, 0)])
        blues = Node(Point2f0[])
        on(scene.events.mousebuttons) do buttons
            if ispressed(scene, Mouse.left)
                pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
                found = -1
                c = clicks[]
                for i in 1:length(c)
                   if norm(pos - c[i]) < 1
                       found = i
                   end
                end
                if found >= 1
                    blues[] = push!(blues[], pos)
                    deleteat!(clicks[], found)
                else
                    push!(clicks[], pos)
                end
                clicks[] = clicks[]
           end
           return
        end
        t = Theme(markersize = 10, raw = true)
        scatter!(scene, t, clicks, color = :red, marker = '+')
        red_clicks = scene[end]
        scatter!(scene, t, blues, color = :blue, marker = 'o')
        center!(scene)
        RecordEvents(scene, @replace_with_a_path)
    end
    @cell "Orbit Diagram" [scatter, slider] begin
        # example by @datseris
        using Observables
        growth(🐇, 🥕) = 🐇 * 🥕 * (1.0 - 🐇)
        function orbitdiagram(growth, r1, r2, n = 500, a = zeros(1000, n); T = 1000)
            rs = range(r1, stop = r2, length = 1000)
            for (j, r) in enumerate(rs)
                x = 0.5
                for _ in 1:T; x = growth(x, r); end
                for i in 1:n
                    x = growth(x, r)
                    @inbounds a[j, i] = x
                end
            end
            rs, a
        end
        r1 = slider(0:0.001:4, raw = true, camera=campixel!, start = 0.0)
        r2 = slider(0:0.001:4, raw = true, camera=campixel!, start = 4)
        n1 = 500; n2 = 1000; a = zeros(n2, n1)
        positions = Vector{Point2f0}(undef, n1 * n2)
        r1node, r2node = r1[end][:value], r2[end][:value]
        r1r2 = async_latest(lift(tuple, r1node, r2node))
        pos = lift(r1r2) do (r1, r2,)
            global a
            rs, a = orbitdiagram(growth, r1, r2, size(a, 2), a)
            dim = size(a, 2)
            for (i, r) in enumerate(rs)
                positions[((i-1)*dim) + 1 : (i*dim)] .= Point2f0.(r, view(a, i, :))
            end
            positions
        end
        p = scatter(
            pos, markersize = 0.006, color = (:black, 0.2),
            show_axis = false
        )
        onany(pos) do pos
            # faster to give the boundingbox ourselves, since otherwise we'll need to
            # loop over pos!
            #AbstractPlotting.update_limits!(p) # <- would calculate bb
            AbstractPlotting.update_limits!(p, FRect(r1node[], 0, r2node[] - r1node[], 1))
            AbstractPlotting.update!(p)
        end
        scene = hbox(
            p,
            vbox(r1, r2)
        )
        RecordEvents(scene, @replace_with_a_path)
    end
end

event_path(entry, ending) = joinpath(dirname(pathof(Makie)), "..", "examples", "recorded_events", string(entry.unique_name, ".jls"))

function record_example_events()
    eval_examples(:record_events, :scatter, :slider, :interactive, outputfile = event_path) do example, value
        record_events(value.scene, value.path) do
            wait(value.scene)
        end
    end
end
function record_example(title = "Orbit Diagram")
    set_theme!(resolution = (500, 500))
    idx = findfirst(x-> x.title == title, database)
    entry = database[idx]
    value = eval_example(entry, outputfile = event_path)
    record_events(value.scene, value.path) do
        wait(value.scene)
    end
end
# record_example()
