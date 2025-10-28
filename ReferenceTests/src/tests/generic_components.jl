# For things that aren't as plot related

@reference_test "picking" begin
    scene = Scene(size = (230, 370))
    campixel!(scene)

    sc1 = scatter!(scene, [20, NaN, 20], [20, NaN, 50], marker = Rect, markersize = 20)
    sc2 = scatter!(scene, [50, 50, 20, 50], [20, 50, 80, 80], marker = Circle, markersize = 20, color = [:red, :red, :transparent, :red])
    ms = meshscatter!(scene, [20, NaN, 50], [110, NaN, 110], markersize = 10)
    l1 = lines!(scene, [20, 50, 50, 20, 20], [140, 140, 170, 170, 140], linewidth = 10)
    l2 = lines!(scene, [20, 50, NaN, 20, 50], [200, 200, NaN, 230, 230], linewidth = 20, linecap = :round)
    ls = linesegments!(scene, [20, 50, NaN, NaN, 20, 50], [260, 260, NaN, NaN, 290, 290], linewidth = 20, linecap = :square)
    tp = text!(scene, Point2f[(15, 320), (NaN, NaN), (15, 350)], text = ["█ ●", "hi", "●"], fontsize = 20, align = (:left, :center))

    i = image!(scene, 80 .. 140, 20 .. 50, to_color.([:red :blue; :green :orange; :black :lightblue]), interpolate = false)
    s = surface!(scene, 80 .. 140, 80 .. 110, [1 2; 3 4; 5 6], interpolate = false)
    hm = heatmap!(scene, [80, 110, 140], [140, 170], [1 4; 2 5; 3 6])
    # mesh coloring should match triangle placements
    m = mesh!(scene, Point2f.([80, 80, 110, 110], [200, 230, 200, 230]), [1 2 3; 2 3 4], color = [1, 1, 1, 2])
    vx = voxels!(scene, (65, 155), (245, 305), (-1, 1), reshape([1, 2, 3, 4, 5, 6], (3, 2, 1)), shading = NoShading)
    vol = volume!(scene, 80 .. 110, 320 .. 350, -1 .. 1, reshape(1:8, 2, 2, 2))

    # reversed axis
    i2 = image!(scene, 210 .. 180, 20 .. 50, to_color.([:red :green; :blue :orange]))
    s2 = surface!(scene, 210 .. 180, 80 .. 110, [1 2; 3 4], interpolate = false)
    hm2 = heatmap!(scene, [210, 180], [140, 170], [1 2; 3 4])

    # for ranged picks
    m2 = mesh!(
        scene,
        Point2f[(190, 330), (200, 330), (190, 340), (200, 340)],
        [1 2 4; 1 4 3]
    )

    scene # for easy reviewing of the plot

    # render one frame to generate picking texture
    colorbuffer(scene, px_per_unit = 2)

    # verify that heatmap path is used for heatmaps
    if Symbol(Makie.current_backend()) == :WGLMakie
        # / 3 since its already flattened
        @test (length(WGLMakie.create_shader(scene, hm)[:faces]) / 3) > 2
        @test (length(WGLMakie.create_shader(scene, hm2)[:faces]) / 3) > 2
    elseif Symbol(Makie.current_backend()) == :GLMakie
        screen = scene.current_screens[1]
        for plt in (hm, hm2)
            robj = screen.cache[objectid(plt)]
            shaders = robj.vertexarray.program.shader
            names = [string(shader.name) for shader in shaders]
            @test any(name -> endswith(name, "heatmap.vert"), names) && any(name -> endswith(name, "heatmap.frag"), names)
        end
    else
        error("picking tests are only meant to run on GLMakie & WGLMakie")
    end

    # raw picking tests
    @testset "pick(scene, point)" begin
        @testset "scatter" begin
            @test pick(scene, Point2f(20, 20)) == (sc1, 1)
            @test pick(scene, Point2f(29, 59)) == (sc1, 3)
            @test pick(scene, Point2f(57, 58)) == (nothing, 0) # maybe fragile
            @test pick(scene, Point2f(57, 13)) == (sc2, 1) # maybe fragile
            @test pick(scene, Point2f(20, 80)) == (nothing, 0)
            @test pick(scene, Point2f(50, 80)) == (sc2, 4)
        end

        @testset "meshscatter" begin
            @test pick(scene, (20, 110)) == (ms, 1)
            @test pick(scene, (44, 117)) == (ms, 3)
            @test pick(scene, (57, 117)) == (nothing, 0)
        end

        @testset "lines" begin
            # Bit less precise since joints aren't strictly one segment or the other
            @test pick(scene, 22, 140) == (l1, 2)
            @test pick(scene, 48, 140) == (l1, 2)
            @test pick(scene, 50, 142) == (l1, 3)
            @test pick(scene, 50, 168) == (l1, 3)
            @test pick(scene, 48, 170) == (l1, 4)
            @test pick(scene, 22, 170) == (l1, 4)
            @test pick(scene, 20, 168) == (l1, 5)
            @test pick(scene, 20, 142) == (l1, 5)

            # more precise checks around borders (these maybe off by a pixel due to AA)
            @test pick(scene, 20, 200) == (l2, 2)
            @test pick(scene, 30, 209) == (l2, 2)
            @test pick(scene, 30, 211) == (nothing, 0)
            @test pick(scene, 59, 200) == (l2, 2)
            @test pick(scene, 61, 200) == (nothing, 0)
            @test pick(scene, 57, 206) == (l2, 2)
            @test pick(scene, 57, 208) == (nothing, 0)
            @test pick(scene, 40, 230) == (l2, 5) # nan handling
        end

        @testset "linesegments" begin
            @test pick(scene, 8, 260) == (nothing, 0) # off by a pixel due to AA
            @test pick(scene, 10, 260) == (ls, 2)
            @test pick(scene, 30, 269) == (ls, 2)
            @test pick(scene, 30, 271) == (nothing, 0)
            @test pick(scene, 59, 260) == (ls, 2)
            @test pick(scene, 61, 260) == (nothing, 0)

            @test pick(scene, 8, 290) == (nothing, 0) # off by a pixel due to AA
            @test pick(scene, 10, 290) == (ls, 6)
            @test pick(scene, 30, 280) == (ls, 6)
            @test pick(scene, 30, 278) == (nothing, 0) # off by a pixel due to AA
            @test pick(scene, 59, 290) == (ls, 6)
            @test pick(scene, 61, 290) == (nothing, 0)
        end

        @testset "text" begin
            @test pick(scene, 15, 320) == (tp, 1)
            @test pick(scene, 13, 320) == (nothing, 0)
            # edge checks, further outside due to AA
            @test pick(scene, 20, 306) == (nothing, 0)
            @test pick(scene, 20, 320) == (tp, 1)
            @test pick(scene, 20, 333) == (nothing, 0)
            # space is counted
            @test pick(scene, 43, 320) == (tp, 3)
            @test pick(scene, 48, 324) == (tp, 3)
            @test pick(scene, 49, 326) == (nothing, 0)
            # characters at nan position are counted
            @test pick(scene, 20, 350) == (tp, 6)
        end

        @testset "image" begin
            # outside border
            for p in vcat(
                    [(x, y) for x in (79, 141) for y in (21, 49)],
                    [(x, y) for x in (81, 139) for y in (19, 51)]
                )
                @test pick(scene, p) == (nothing, 0)
            end

            # cell centered checks
            @test pick(scene, 90, 30) == (i, 1)
            @test pick(scene, 110, 30) == (i, 2)
            @test pick(scene, 130, 30) == (i, 3)
            @test pick(scene, 90, 40) == (i, 4)
            @test pick(scene, 110, 40) == (i, 5)
            @test pick(scene, 130, 40) == (i, 6)

            # precise check (around cell intersection)
            @test pick(scene, 100 - 1, 35 - 1) == (i, 1)
            @test pick(scene, 100 + 1, 35 - 1) == (i, 2)
            @test pick(scene, 100 - 1, 35 + 1) == (i, 4)
            @test pick(scene, 100 + 1, 35 + 1) == (i, 5)

            @test pick(scene, 120 - 1, 35 - 1) == (i, 2)
            @test pick(scene, 120 + 1, 35 - 1) == (i, 3)
            @test pick(scene, 120 - 1, 35 + 1) == (i, 5)
            @test pick(scene, 120 + 1, 35 + 1) == (i, 6)

            # reversed axis check
            @test pick(scene, 200, 30) == (i2, 1)
            @test pick(scene, 190, 30) == (i2, 2)
            @test pick(scene, 200, 40) == (i2, 3)
            @test pick(scene, 190, 40) == (i2, 4)
        end

        @testset "surface" begin
            # outside border
            for p in vcat(
                    [(x, y) for x in (79, 141) for y in (81, 109)],
                    [(x, y) for x in (81, 139) for y in (79, 111)]
                )
                @test pick(scene, p) == (nothing, 0)
            end

            # cell centered checks
            @test pick(scene, 90, 90) == (s, 1)
            @test pick(scene, 110, 90) == (s, 2)
            @test pick(scene, 130, 90) == (s, 3)
            @test pick(scene, 90, 100) == (s, 4)
            @test pick(scene, 110, 100) == (s, 5)
            @test pick(scene, 130, 100) == (s, 6)

            # precise check (around cell intersection)
            @test pick(scene, 95 - 1, 95 - 1) == (s, 1)
            @test pick(scene, 95 + 1, 95 - 1) == (s, 2)
            @test pick(scene, 95 - 1, 95 + 1) == (s, 4)
            @test pick(scene, 95 + 1, 95 + 1) == (s, 5)

            @test pick(scene, 125 - 1, 95 - 1) == (s, 2)
            @test pick(scene, 125 + 1, 95 - 1) == (s, 3)
            @test pick(scene, 125 - 1, 95 + 1) == (s, 5)
            @test pick(scene, 125 + 1, 95 + 1) == (s, 6)

            # reversed axis check
            @test pick(scene, 200, 90) == (s2, 1)
            @test pick(scene, 190, 90) == (s2, 2)
            @test pick(scene, 200, 100) == (s2, 3)
            @test pick(scene, 190, 100) == (s2, 4)
        end

        @testset "heatmap" begin
            # outside border
            for p in vcat(
                    [(x, y) for x in (64, 156) for y in (126, 184)],
                    [(x, y) for x in (66, 154) for y in (124, 186)]
                )
                @test pick(scene, p) == (nothing, 0)
            end

            # cell centered checks
            @test pick(scene, 80, 140) == (hm, 1)
            @test pick(scene, 110, 140) == (hm, 2)
            @test pick(scene, 140, 140) == (hm, 3)
            @test pick(scene, 80, 170) == (hm, 4)
            @test pick(scene, 110, 170) == (hm, 5)
            @test pick(scene, 140, 170) == (hm, 6)

            # precise check (around cell intersection)
            @test pick(scene, 94, 154) == (hm, 1)
            @test pick(scene, 96, 154) == (hm, 2)
            @test pick(scene, 94, 156) == (hm, 4)
            @test pick(scene, 96, 156) == (hm, 5)

            @test pick(scene, 124, 154) == (hm, 2)
            @test pick(scene, 126, 154) == (hm, 3)
            @test pick(scene, 124, 156) == (hm, 5)
            @test pick(scene, 126, 156) == (hm, 6)

            # reversed axis check
            @test pick(scene, 210, 140) == (hm2, 1)
            @test pick(scene, 180, 140) == (hm2, 2)
            @test pick(scene, 210, 170) == (hm2, 3)
            @test pick(scene, 180, 170) == (hm2, 4)
        end

        @testset "mesh" begin
            @test pick(scene, 80, 200)[1] == m
            @test pick(scene, 79, 200) == (nothing, 0)
            @test pick(scene, 80, 199) == (nothing, 0)
            @test pick(scene, 81, 201) == (m, 3)
            @test pick(scene, 81, 225) == (m, 3)
            @test pick(scene, 105, 201) == (m, 3)
            @test pick(scene, 85, 229) == (m, 4)
            @test pick(scene, 109, 205) == (m, 4)
            @test pick(scene, 109, 229) == (m, 4)
            @test pick(scene, 109, 229)[1] == m
            @test pick(scene, 111, 230) == (nothing, 0)
            @test pick(scene, 110, 231) == (nothing, 0)
        end

        @testset "voxel" begin
            # outside border
            for p in vcat(
                    [(x, y) for x in (64, 156) for y in (246, 304)],
                    [(x, y) for x in (66, 154) for y in (244, 306)]
                )
                @test pick(scene, p) == (nothing, 0)
            end

            # cell centered checks
            @test pick(scene, 80, 260) == (vx, 1)
            @test pick(scene, 110, 260) == (vx, 2)
            @test pick(scene, 140, 260) == (vx, 3)
            @test pick(scene, 80, 290) == (vx, 4)
            @test pick(scene, 110, 290) == (vx, 5)
            @test pick(scene, 140, 290) == (vx, 6)

            # precise check (around cell intersection)
            @test pick(scene, 94, 274) == (vx, 1)
            @test pick(scene, 96, 274) == (vx, 2)
            @test pick(scene, 94, 276) == (vx, 4)
            @test pick(scene, 96, 276) == (vx, 5)

            @test pick(scene, 124, 274) == (vx, 2)
            @test pick(scene, 126, 274) == (vx, 3)
            @test pick(scene, 124, 276) == (vx, 5)
            @test pick(scene, 126, 276) == (vx, 6)
        end

        @testset "volume" begin
            # volume doesn't produce indices because we can't resolve the depth of
            # the pick
            @test pick(scene, 80, 320)[1] == vol
            @test pick(scene, 79, 320) == (nothing, 0)
            @test pick(scene, 80, 319) == (nothing, 0)
            @test pick(scene, 81, 321) == (vol, 0)
            @test pick(scene, 81, 349) == (vol, 0)
            @test pick(scene, 109, 321) == (vol, 0)
            @test pick(scene, 109, 349) == (vol, 0)
            @test pick(scene, 109, 349)[1] == vol
            @test pick(scene, 111, 350) == (nothing, 0)
            @test pick(scene, 110, 351) == (nothing, 0)
        end
    end


    @testset "ranged pick/pick_sorted" begin
        @testset "scatter" begin
            @test pick(scene, Point2f(40, 60), 10) == (sc2, 2)
        end
        @testset "meshscatter" begin
            @test pick(scene, (35, 117), 10) == (ms, 3)
        end
        @testset "lines" begin
            @test pick(scene, 10, 160, 10) == (l1, 5)
            @test pick(scene, 40, 218, 10) == (l2, 5)
        end
        @testset "linesegments" begin
            @test pick(scene, 5, 280, 10) == (ls, 6)
        end
        @testset "text" begin
            @test pick(scene, 32, 320, 10) == (tp, 1)
            @test pick(scene, 35, 320, 10) == (tp, 3)
        end
        @testset "image" begin
            @test pick(scene, 98, 15, 10) == (i, 1)
            @test pick(scene, 102, 15, 10) == (i, 2)
            @test pick(scene, 200, 15, 10) == (i2, 1)
            @test pick(scene, 190, 15, 10) == (i2, 2)
        end
        @testset "surface" begin
            @test pick(scene, 93, 75, 10) == (s, 1)
            @test pick(scene, 97, 75, 10) == (s, 2)
            @test pick(scene, 200, 75, 10) == (s2, 1)
            @test pick(scene, 190, 75, 10) == (s2, 2)
        end
        @testset "heatmap" begin
            @test pick(scene, 93, 120, 10) == (hm, 1)
            @test pick(scene, 97, 120, 10) == (hm, 2)
            @test pick(scene, 200, 120, 10) == (hm2, 1)
            @test pick(scene, 190, 120, 10) == (hm2, 2)
        end
        @testset "mesh" begin
            @test pick(scene, 115, 230, 10) == (m, 4)
        end
        @testset "voxel" begin
            @test pick(scene, 93, 240, 10) == (vx, 1)
            @test pick(scene, 97, 240, 10) == (vx, 2)
        end
        @testset "volume" begin
            @test pick(scene, 75, 320, 10) == (vol, 0)
        end
        @testset "range" begin
            # mesh!(scene, Rect2f(200, 330, 10, 10))
            # verify borders
            @test pick(scene, 189, 331) == (nothing, 0)
            @test pick(scene, 191, 329) == (nothing, 0)
            @test pick(scene, 191, 331) == (m2, 4)
            @test pick(scene, 199, 339) == (m2, 4)
            @test pick(scene, 201, 339) == (nothing, 0)
            @test pick(scene, 199, 341) == (nothing, 0)

            @testset "horizontal" begin
                @test pick(scene, 170, 335, 19) == (nothing, 0)
                @test pick(scene, 170, 335, 21) == (m2, 3)
                @test pick(scene, 220, 335, 19) == (nothing, 0)
                @test pick(scene, 220, 335, 21) == (m2, 4)
            end

            @testset "vertical" begin
                @test pick(scene, 205, 310, 19) == (nothing, 0)
                @test pick(scene, 205, 310, 21) == (m2, 4)
                @test pick(scene, 205, 360, 19) == (nothing, 0)
                @test pick(scene, 205, 360, 22) == (m2, 4) # off by one?
            end
            @testset "diagonals" begin
                # 190, 330
                @test pick(scene, 180, 320, 14) == (nothing, 0)
                @test pick(scene, 180, 320, 15) == (m2, 4)
                @test pick(scene, 180, 350, 14) == (nothing, 0)
                @test pick(scene, 180, 350, 15) == (m2, 3)
                @test pick(scene, 210, 320, 14) == (nothing, 0)
                @test pick(scene, 210, 320, 15) == (m2, 4)
                @test pick(scene, 210, 350, 14) == (nothing, 0)
                @test pick(scene, 210, 350, 16) == (m2, 4) # off by one?
            end
        end
    end

    # pick_sorted
    @testset "pick_sorted" begin
        list = Makie.pick_sorted(scene, Vec2(100, 100), 50)
        @test length(list) == 14
        @test list[1] == (s, 5)
        @test list[2] == (s, 2)
        @test list[3] == (s, 4)
        @test list[4] == (s, 1)
        @test list[5] == (s, 6)
        @test list[6] == (hm, 2)
        @test list[7] == (s, 3)
        @test list[8] == (hm, 1)
        @test list[9] == (hm, 3)
        @test list[10] == (ms, 3)
        @test list[11] == (sc2, 4)
        @test list[12] == (l1, 3)
        @test list[13] == (l1, 2)
        @test list[14] == (sc2, 2)
    end

    #=
    For Verification
    Note that the text only marks the index in the picking list. The position
    that is closest (that pick_sorted used) is somewhere else in the marked
    element. Check scene2 to see the pickable regions if unsure

    list = Makie.pick_sorted(scene, Vec2(100, 100), 50)
    ps = Point2f[]
    for (p, idx) in list
        if p isa Union{Surface, Heatmap}
            data = Point2f.(p.converted[1][], collect(p.converted[2][])')
            push!(ps, data[idx])
        else
            push!(ps, p.converted[1][][idx])
        end
    end
    scatter!(scene, Vec2f(100, 100), color = :white, strokecolor = :black, strokewidth = 2, overdraw = true)
    text!(
        scene, ps, text = ["$i" for i in 1:14],
        strokecolor = :white, strokewidth = 2,
        align = (:center, :center), overdraw = true)
    =#

    # pick(scene, Rect)
    # grab all indices and generate a plot for them (w/ fixed px_per_unit)
    full_screen = last.(pick(scene, scene.viewport[]))

    scene2 = Scene(size = 2.0 .* widths(scene.viewport[]))
    campixel!(scene2)
    image!(scene2, full_screen, colormap = :viridis)
    scene2
end

@reference_test "Transformations and space" begin
    transforms = [:automatic, :inherit, :inherit_transform_func, :inherit_model, :nothing]
    spaces = [:data, :pixel, :relative, :clip]

    t = Transformation(
        x -> 2 * x,
        scale = Vec3f(0.75, 2, 1),
        rotation = qrotation(Vec3f(0, 0, 1), 0.3)
    )

    grid = vcat(
        [Point2f(x, y) for x in -1:6 for y in (-1, 6)],
        [Point2f(x, y) for y in -1:6 for x in (-1, 6)]
    )

    f = Figure(size = (450, 550))
    for (i, transform) in enumerate(transforms)
        Label(f[i, 0], [":automatic", ":inherit", "transform_func", "model", ":nothing"][i], rotation = pi / 2, tellheight = false)
        for (j, space, scale) in zip(eachindex(spaces), spaces, [1, 20, 0.2, 0.2])
            a = LScene(f[i, j], show_axis = false, scenekw = (camera = cam2d!, transformation = t))
            linesegments!(a, grid, transformation = :nothing, color = :lightgray)
            # text!(a, Point2f(6,6), text = "$space", align = (:right, :top), transformation = :nothing)
            scatter!(
                a,
                [scale * Point2f(cos(x), sin(x)) for x in range(0.2, 1.3, length = 11)],
                transformation = transform, space = space
            )
        end
    end
    for (j, space) in enumerate(spaces)
        Label(f[0, j], ":space", tellwidth = false)
    end

    f
end

@reference_test "DataInspector" begin
    scene = Scene(camera = campixel!, size = (290, 230))

    # bottom rect (roughly 0..290 x 0..140)

    # primitives
    scatter!(scene, Point2f(20), markersize = 30)
    meshscatter!(scene, Point2f[(90, 20), (90, 60)], marker = Rect2f(-1, -1, 2, 2), markersize = 15)
    lines!(scene, [10, 30, 50, 70], [40, 40, 10, 10], linewidth = 10)
    linesegments!(scene, [10, 50, 60, 60], [60, 60, 70, 30], linewidth = 10)
    mesh!(scene, Rect2f(10, 80, 40, 40))
    surface!(scene, 60 .. 100, 80 .. 120, [1 2; 3 4])
    heatmap!(scene, [120, 140, 160], [10, 30, 50], [1 2; 3 4])
    image!(scene, 120 .. 160, 60 .. 100, [1 2; 3 4])

    # barplot, arrows, contourf, volumeslices, band, spy,
    barplot!(scene, [180, 200, 220], [40, 20, 60])
    arrows2d!(scene, Point2f[(200, 30)], Vec2f[(0, 30)], shaftwidth = 4, tiplength = 15, tipwidth = 12)
    arrows3d!(
        scene, Point3f[(220, 80, 0)], Vec3f[(-48, -16, 0)],
        shaftradius = 2.5, tiplength = 15, tipradius = 7, markerscale = 1.0
    )
    contourf!(scene, 240 .. 280, 10 .. 50, [1 2 1; 2 0 2; 1 2 1], levels = 3)
    spy!(scene, 240 .. 280, 60 .. 100, [1 2 1; 2 0 2; 1 2 1])
    band!(scene, [150, 180, 210, 240], [110, 80, 90, 110], [120, 110, 130, 120])

    # lines!(scene, [0, 285, 285], [135, 135, 0])

    # below top row
    arc!(scene, Point2f(25, 140), 15, pi / 3, pi, linewidth = 10)
    contour!(scene, 40:5:80, 140:5:180, [sqrt(x^2 + y^2) for x in -4:4, y in -4:4], levels = 3, linewidth = 5)
    crossbar!(scene, [90, 105], [160, 160], [140, 145], [170, 165], width = 15)
    p = density!(scene, 10 .* sin.(1:100))
    translate!(p, 135, 140, 0)
    scale!(p, 1, 700, 1)
    errorbars!(scene, [160], [155], [10], linewidth = 5, whiskerwidth = 10)
    rangebars!(scene, [175], [140], [170], linewidth = 5, whiskerwidth = 10)
    hexbin!(scene, 200 .+ 10 .* sin.(1:100), 160 .+ 10 .* cos.(1:100), bins = 4)
    p = hist!(scene, 230 .+ 10 .* sin.(1:100), bins = 4)
    translate!(p, 0, 140, 0)
    pie!(scene, 260, 160, [3, 5, 7, 11, 13], radius = 15, color = 1:5)

    poly!(scene, [10, 30, 20], [170, 165, 180])

    # top row
    p = rainclouds!(scene, ones(100), 200 .+ 10 .* sin.(1:100))
    translate!(p, -40, 0, 0)
    scale!(p, 70, 1, 1)
    scatterlines!(scene, [60, 50, 60], [190, 200, 210], linewidth = 3, markersize = 10)
    series!(scene, [Point2f.([80, 70, 80], [190, 200, 210])], linewidth = 4)
    stairs!(scene, [90, 100, 110], [190, 210, 200], linewidth = 4)
    stem!(scene, [120, 130], [200, 210], offset = 190, stemwidth = 3, trunkwidth = 3, markersize = 10)
    p = stephist!(scene, 150 .+ 10 .* sin.(1:70), bins = 4, linewidth = 4)
    translate!(p, 0, 190, 0)
    tricontourf!(scene, 180 .+ 15 .* sin.(1:100), 200 .+ 15 .* cos.(1:100), 1:100, levels = 3)
    p = violin!(scene, ones(100), 200 .+ 10 .* sin.(range(0, 10, length = 100) .^ 2), side = ifelse.(1:100 .> 50, :left, :right))
    translate!(p, 190, 0, 0)
    scale!(p, 20, 1, 1)
    v = p
    p = waterfall!(scene, [230, 240], [25, -15])
    translate!(p, 0, 190, 0)

    # mouse positions for targetting each plot
    mps = [
        # 0..285 x 0..135 block
        (20, 20), (90, 20), (20, 40), (40, 30), (30, 60), (55, 50), (30, 100),
        (90, 110), (130, 20), (150, 90), (200, 10), (200, 35),
        (217, 79), (200, 45), (181, 67), (260, 30), (260, 90), (205, 110),
        # top-1 row
        (17, 153), (67, 163), (90, 152), (139, 153), (160, 163), (175, 150), (210, 156),
        (235, 145), (265, 154), (20, 175),
        # top row
        (17, 209), (32, 194), (39, 193), (61, 211), (56, 195), (76, 207), (101, 199),
        (130, 195), (155, 214), (185, 193), (205, 193), (214, 208), (242, 208),
    ]

    e = events(scene)
    # Prevent the hover event Channel getting closed
    e.window_open[] = true
    # blocking = true forces immediately resolution of DataInspector updates
    di = Makie.DataInspector2(
        scene, offset = 5.0, fontsize = 12, outline_linewidth = 1,
        textpadding = (2, 2, 2, 2),
        blocking = true, no_tick_discard = true
    )
    # force indicator plots to be created for WGLMakie
    Makie.get_indicator_plot(di, Lines)
    Makie.get_indicator_plot(di, LineSegments)
    Makie.get_indicator_plot(di, Scatter)
    scene

    st = Makie.Stepper(scene)

    # record
    is_wglmakie = Symbol(Makie.current_backend()) === :WGLMakie

    for mp in mps
        # remove tooltip so we don't select it
        e.mouseposition[] = (1.0, 1.0)
        notify(e.tick) # trigger DataInspector update
        colorbuffer(scene) # force update of picking buffer
        is_wglmakie && sleep(0.15) # wait for WGLMakie
        @test !di.dynamic_tooltip.visible[] # verify cleanup

        e.mouseposition[] = mp
        notify(e.tick)
        is_wglmakie && sleep(0.15) # wait for WGLMakie
        Makie.step!(st)
    end

    st
end

@reference_test "DataInspector continued" begin
    f = Figure(size = (450, 750))
    col3d = f[1, 1]
    data3d = reshape(sin.(1:1000), (10, 10, 10))
    volumeslices(col3d[1, 1], 1:10, 1:10, 1:10, data3d)
    voxels(col3d[2, 1], data3d)
    contour3d(col3d[3, 1], 1:10, 1:10, reshape(10 .* sin.(1:100), (10, 10)), linewidth = 3)
    wireframe(col3d[4, 1], Rect3d(0, 0, 0, 1, 1, 1))

    col2d = f[1, 2]
    x = sin.(1:10_000) .* sin.(0.1:0.1:1000)
    y = sin.(2:2:20000) .* sin.(5:5:50000)
    datashader(col2d[1, 1], Point2f.(x, y), async = false)
    heatmap(col2d[2, 1], Resampler(reshape(sin.(1:1_000_000), (1000, 1000))))
    ablines(col2d[3, 1], 0, 1.0)
    hlines!(1)
    vlines!(1)
    hspan!(9, 10)
    vspan!(9, 10)

    colsize!(f.layout, 1, 125)

    e = events(f)
    e.window_open[] = true # Prevent the hover event Channel from getting closed

    dis = []
    for a in f.content
        di = Makie.DataInspector2(a, blocking = true, no_tick_discard = true)
        # force indicator plots to be created for WGLMakie
        Makie.get_indicator_plot(di, LineSegments)
        Makie.get_indicator_plot(di, Lines)
        Makie.get_indicator_plot(di, Scatter)
        push!(dis, di)
    end

    mps = [
        # 3D
        (97.0, 658.0), (65.0, 634.0), (98.0, 471.0), (75.0, 314.0), (102.0, 140.0),
        # 2D
        (315.0, 632.0), (312.0, 387.0), (362.0, 226.0), (410.0, 146.0), (311.0, 134.0),
        (210.0, 151.0), (305.0, 41.0),
    ]

    st = Makie.Stepper(f)

    # record
    is_wglmakie = Symbol(Makie.current_backend()) === :WGLMakie

    for mp in mps
        # remove tooltip so we don't select it
        e.mouseposition[] = (1.0, 1.0)
        notify(e.tick) # trigger DataInspector update
        colorbuffer(f) # force update of picking buffer
        is_wglmakie && sleep(0.15) # wait for WGLMakie

        # verify cleanup
        @test !any(di -> di.dynamic_tooltip.visible[], dis)

        e.mouseposition[] = mp
        notify(e.tick)
        is_wglmakie && sleep(0.15) # wait for WGLMakie
        Makie.step!(st)
    end

    st
end

@reference_test "DataInspector persistent tooltips" begin
    xy = [Point2f(x, y) for x in -2:2 for y in -2:2]
    f = Figure(size = (400, 400))
    a,p = scatter(f[1, 1], xy, markersize = 20)
    Makie.DataInspector2(a)
    st = Makie.Stepper(f)

    e = events(f)

    # Make 3 persistent tooltips
    mps = [(135, 290), (213, 209), (291, 130)]
    e.keyboardbutton[] = Makie.KeyEvent(Keyboard.left_shift, Keyboard.press)
    for mp in mps
        e.mouseposition[] = mp
        colorbuffer(f)
        e.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        e.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    end
    e.keyboardbutton[] = Makie.KeyEvent(Keyboard.left_shift, Keyboard.release)

    Makie.step!(st)

    # check that tooltips move with axis changes
    Makie.xlims!(a, -4, 4)
    Makie.ylims!(a, -3, 4)

    Makie.step!(st)

    # remove center tooltip
    e.keyboardbutton[] = Makie.KeyEvent(Keyboard.left_shift, Keyboard.press)
    e.mouseposition[] = (210, 220)
    colorbuffer(f)
    e.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    e.keyboardbutton[] = Makie.KeyEvent(Keyboard.left_shift, Keyboard.release)

    Makie.step!(st)

    # check that model is included
    translate!(p, 0, 1, 0)

    Makie.step!(st)

    st
end

function create_test_plot()
    # Grid scatter
    x, y = repeat(1:10, 8), repeat(1:8, inner = 10)
    f, ax, pl = scatter(x, y, color = x .* y, markersize = 25)
    # Text with uncommon chars (no custom fonts)
    text!(ax, 5, 6, text = "∫∂∇αβγ←→€¥", fontsize = 40, align = (:center, :center))
    text!(ax, 5, 4, text = "◆●▲½⅓∞≈", fontsize = 40, color = :darkred, strokewidth = 2, strokecolor = :white, align = (:center, :center))
    text!(ax, 5, 2, text = "abcdefg", color = 1:8, colormap = :turbo, fontsize = 60, align = (:center, :center), font = assetpath("fonts", "blkchcry.ttf"))
    return f
end

@reference_test "Threading Test" begin
    ref = copy(colorbuffer(create_test_plot()))
    chan = Channel{Matrix{RGBAf}}(Inf)
    runs = Channel{Int}(100)
    Threads.@threads for i in 1:100
        f = create_test_plot()
        fetch(
            Makie.spawnat(1) do
                thread_ref = copy(colorbuffer(f))
                if !(ref ≈ thread_ref)
                    put!(chan, thread_ref)
                end
                put!(runs, i)
            end
        )
    end
    close(chan)
    close(runs)
    vals = collect(chan)
    runs_vals = collect(runs)
    @test Set(runs_vals) == Set(1:100)
    s = Scene(size = reverse(size(ref)))
    if isempty(vals)
        image!(s, -1 .. 1, -1 .. 1, rotr90(ref))
    else
        val, idx = findmax(x -> ReferenceTests.compare_images(x, ref), vals)
        println("Failing with comparison value: ", val)
        image!(s, -1 .. 1, -1 .. 1, rotr90(vals[idx]))
    end
    s
end
