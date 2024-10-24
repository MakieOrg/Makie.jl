# For things that aren't as plot related

# @reference_test "picking" 
begin
    scene = Scene(size = (230, 370))
    campixel!(scene)
    
    sc1 = scatter!(scene, [20, NaN, 20], [20, NaN, 50], marker = Rect, markersize = 20)
    sc2 = scatter!(scene, [50, 50, 20, 50], [20, 50, 80, 80], marker = Circle, markersize = 20, color = [:red, :red, :transparent, :red])
    ms = meshscatter!(scene, [20, NaN, 50], [110, NaN, 110], markersize = 10)
    l1 = lines!(scene, [20, 50, 50, 20, 20], [140, 140, 170, 170, 140], linewidth = 10)
    l2 = lines!(scene, [20, 50, NaN, 20, 50], [200, 200, NaN, 230, 230], linewidth = 20, linecap = :round)
    ls = linesegments!(scene, [20, 50, NaN, NaN, 20, 50], [260, 260, NaN, NaN, 290, 290], linewidth = 20, linecap = :square)
    tp = text!(scene, Point2f[(15, 320), (NaN, NaN), (15, 350)], text = ["█ ●", "hi", "●"], fontsize = 20, align = (:left, :center))
    t = tp.plots[1]

    i = image!(scene, 80..140, 20..50, rand(RGBf, 3, 2), interpolate = false)
    s = surface!(scene, 80..140, 80..110, rand(3, 2), interpolate = false)
    hm = heatmap!(scene, [80, 110, 140], [140, 170], [1 4; 2 5; 3 6])
    # mesh coloring should match triangle placements
    m = mesh!(scene, Point2f.([80, 80, 110, 110], [200, 230, 200, 230]), [1 2 3; 2 3 4], color = [1,1,1,2])
    vx = voxels!(scene, [65, 155], [245, 305], [-1, 1], reshape([1,2,3,4,5,6], (3,2,1)), shading = NoShading)
    vol = volume!(scene, 80..110, 320..350, -1..1, rand(2,2,2))
    
    # reversed axis
    i2 = image!(scene, 210..180, 20..50, rand(RGBf, 2, 2))
    s2 = surface!(scene, 210..180, 80..110, [1 2; 3 4], interpolate = false)
    hm2 = heatmap!(scene, [210, 180], [140, 170], [1 2; 3 4])

    scene # for easy reviewing of the plot

    # render one frame to generate picking texture
    colorbuffer(scene, px_per_unit = 2);

    # verify that heatmap path is used for heatmaps
    if Symbol(Makie.current_backend()) == :WGLMakie
        @test length(WGLMakie.create_shader(scene, hm).vertexarray.buffers[:faces]) > 2
        @test length(WGLMakie.create_shader(scene, hm2).vertexarray.buffers[:faces]) > 2
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
        @test pick(scene,  8, 260) == (nothing, 0) # off by a pixel due to AA
        @test pick(scene, 10, 260) == (ls, 2)
        @test pick(scene, 30, 269) == (ls, 2)
        @test pick(scene, 30, 271) == (nothing, 0)
        @test pick(scene, 59, 260) == (ls, 2)
        @test pick(scene, 61, 260) == (nothing, 0)

        @test pick(scene,  8, 290) == (nothing, 0) # off by a pixel due to AA
        @test pick(scene, 10, 290) == (ls, 6)
        @test pick(scene, 30, 280) == (ls, 6)
        @test pick(scene, 30, 278) == (nothing, 0) # off by a pixel due to AA
        @test pick(scene, 59, 290) == (ls, 6)
        @test pick(scene, 61, 290) == (nothing, 0)
    end

    @testset "text" begin        
        @test pick(scene, 15, 320) == (t, 1)
        @test pick(scene, 13, 320) == (nothing, 0)
        # edge checks, further outside due to AA
        @test pick(scene, 20, 306) == (nothing, 0)
        @test pick(scene, 20, 320) == (t, 1)
        @test pick(scene, 20, 333) == (nothing, 0)
        # space is counted
        @test pick(scene, 43, 320) == (t, 3)
        @test pick(scene, 48, 324) == (t, 3)
        @test pick(scene, 49, 326) == (nothing, 0)
        # characters at nan position are counted
        @test pick(scene, 20, 350) == (t, 6)
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
        @test pick(scene,  90, 30) == (i, 1)
        @test pick(scene, 110, 30) == (i, 2)
        @test pick(scene, 130, 30) == (i, 3)
        @test pick(scene,  90, 40) == (i, 4)
        @test pick(scene, 110, 40) == (i, 5)
        @test pick(scene, 130, 40) == (i, 6)

        # precise check (around cell intersection)
        @test pick(scene, 100-1, 35-1) == (i, 1)
        @test pick(scene, 100+1, 35-1) == (i, 2)
        @test pick(scene, 100-1, 35+1) == (i, 4)
        @test pick(scene, 100+1, 35+1) == (i, 5)
        
        @test pick(scene, 120-1, 35-1) == (i, 2)
        @test pick(scene, 120+1, 35-1) == (i, 3)
        @test pick(scene, 120-1, 35+1) == (i, 5)
        @test pick(scene, 120+1, 35+1) == (i, 6)

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
        @test pick(scene,  90,  90) == (s, 1)
        @test pick(scene, 110,  90) == (s, 2)
        @test pick(scene, 130,  90) == (s, 3)
        @test pick(scene,  90, 100) == (s, 4)
        @test pick(scene, 110, 100) == (s, 5)
        @test pick(scene, 130, 100) == (s, 6)

        # precise check (around cell intersection)
        @test pick(scene,  95-1, 95-1) == (s, 1)
        @test pick(scene,  95+1, 95-1) == (s, 2)
        @test pick(scene,  95-1, 95+1) == (s, 4)
        @test pick(scene,  95+1, 95+1) == (s, 5)
        
        @test pick(scene, 125-1, 95-1) == (s, 2)
        @test pick(scene, 125+1, 95-1) == (s, 3)
        @test pick(scene, 125-1, 95+1) == (s, 5)
        @test pick(scene, 125+1, 95+1) == (s, 6)

        # reversed axis check
        @test pick(scene, 200,  90) == (s2, 1)
        @test pick(scene, 190,  90) == (s2, 2)
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
        @test pick(scene,  80, 140) == (hm, 1)
        @test pick(scene, 110, 140) == (hm, 2)
        @test pick(scene, 140, 140) == (hm, 3)
        @test pick(scene,  80, 170) == (hm, 4)
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
        @test pick(scene,  81, 201) == (m, 3)
        @test pick(scene,  81, 225) == (m, 3)
        @test pick(scene, 105, 201) == (m, 3)
        @test pick(scene,  85, 229) == (m, 4)
        @test pick(scene, 109, 205) == (m, 4)
        @test pick(scene, 109, 229) == (m, 4)
        @test pick(scene, 109, 229)[1] == m
        @test pick(scene, 111, 230) == (nothing, 0)
        @test pick(scene, 110, 231) == (nothing, 0)
    end

    @testset "voxel" begin
        # outside border
        for p in vcat(
                [(x, y) for x in (64, 246) for y in (126, 184)],
                [(x, y) for x in (66, 244) for y in (124, 186)]
            )
            @test pick(scene, p) == (nothing, 0)
        end
        
        # cell centered checks
        @test pick(scene,  80, 260) == (vx, 1)
        @test pick(scene, 110, 260) == (vx, 2)
        @test pick(scene, 140, 260) == (vx, 3)
        @test pick(scene,  80, 290) == (vx, 4)
        @test pick(scene, 110, 290) == (vx, 5)
        @test pick(scene, 140, 290) == (vx, 6)

        # precise check (around cell intersection)
        @test pick(scene,  94, 274) == (vx, 1)
        @test pick(scene,  96, 274) == (vx, 2)
        @test pick(scene,  94, 276) == (vx, 4)
        @test pick(scene,  96, 276) == (vx, 5)
        
        @test pick(scene, 124, 274) == (vx, 2)
        @test pick(scene, 126, 274) == (vx, 3)
        @test pick(scene, 124, 276) == (vx, 5)
        @test pick(scene, 126, 276) == (vx, 6)
    end
    
    @testset "volume" begin
        # volume doesn't produce indices because we can't resolve the depth of 
        # the pick
        @test pick(scene,  80, 320)[1] == vol
        @test pick(scene,  79, 320) == (nothing, 0)
        @test pick(scene,  80, 319) == (nothing, 0)
        @test pick(scene,  81, 321) == (vol, 0)
        @test pick(scene,  81, 349) == (vol, 0)
        @test pick(scene, 109, 321) == (vol, 0)
        @test pick(scene, 109, 349) == (vol, 0)
        @test pick(scene, 109, 349)[1] == vol
        @test pick(scene, 111, 350) == (nothing, 0)
        @test pick(scene, 110, 351) == (nothing, 0)
    end

    # grab all indices and generate a plot for them (w/ fixed px_per_unit)
    full_screen = last.(pick(scene, scene.viewport[]))
    
    scene2 = Scene(size = 2.0 .* widths(scene.viewport[]))
    campixel!(scene2)
    image!(scene2, full_screen, colormap = :viridis)
    scene2
end