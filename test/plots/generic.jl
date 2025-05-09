@testset "core attributes" begin
    # also tests that plot!(scene, ...) always works
    core_attributes = [
        :visible, :transparency, :space, :overdraw, :inspectable, :inspector_label,
        :inspector_clear, :inspector_hover, :clip_planes, :depth_shift#, :fxaa
    ]

    # TODO:
    # After compute plots #4630 consider reworking attribute passthrough to be
    # more automatic and add tests verifying attribute passthrough & completeness
    # This could be a start:

    # `exclude` to exclude an attribute from being checked
    # `skip_inheritance` to exclude it after the top level plot is checked (e.g. if child plots do not inherit it)
    # `expected` attributes to compare to (default values)
    function validate_attributes(p; exclude = Set(), expected = Dict{Symbol, Any}(), skip_inheritance = Set())
        attr = attributes(p)

        # failed = Symbol[]
        for name in core_attributes
            name in exclude && continue
            name in skip_inheritance && push!(exclude, name)
            @test haskey(attr, name) && (to_value(attr[name]) == to_value(expected[name]))
            # if !(haskey(attr, name) && (to_value(attr[name]) == to_value(expected[name])))
                # push!(failed, name)
            # end
        end

        # This shows the failed names in the test failure and also takes less
        # time since it doesn't go through the test pipeline for every failure
        # @test failed == Symbol[]

        foreach(p -> validate_attributes(p, exclude = exclude, expected = expected), p.plots)
    end

    # TODO:
    # Other plots have errors, some due to missing attributes, some due to bad
    # assumptions by the check (e.g. parent visible may not always imply all
    # children are visible, e.g. for labels)
    WORKING_PLOT_TYPES = [
        Scatter, Lines, LineSegments, Makie.Mesh, MeshScatter, Image, Heatmap,
        Surface, Volume, Voxels,
        ABLines, Arc, Arrows, Band, DataShader, HLines, VLines, ScatterLines,
        Stairs, Stem, StreamPlot, TimeSeries, QQPlot, QQNorm,
    ]
    # Probably missing passthrough?
    FAILS_UPDATE = [Arrows, ScatterLines, Stem, TimeSeries, QQPlot, QQNorm]

    scene = Scene()
    expected = Makie.MakieCore.generic_plot_attributes!(Attributes())
    expected[:clip_planes] = scene.theme.clip_planes
    # expected[:fxaa] = nothing
    pop!(expected, :transformation)

    updated = deepcopy(expected)
    updated[:visible][]      = !updated[:visible][]
    updated[:transparency][] = !updated[:transparency][]
    updated[:overdraw][]     = !updated[:overdraw][]
    updated[:inspectable][]  = !updated[:inspectable][]
    updated[:space][]        = :pixel
    updated[:clip_planes][]  = [Plane3f(Point3f(1), Vec3f(-1))]
    updated[:depth_shift][]  = -1f-4

    for PlotType in ALL_PLOT_TYPES
        @testset "$PlotType" begin
            p = testplot!(scene, PlotType)

            if PlotType in WORKING_PLOT_TYPES
                # expected[:fxaa] = to_value(get(p, :fxaa, nothing)) # plot dependent
                validate_attributes(p, expected = expected)
                if !(PlotType in FAILS_UPDATE)
                    for (k, v) in updated
                        p[k][] = v[]
                    end
                    validate_attributes(p, expected = updated)
                else
                    @test_broken false # fails update
                end
            else
                @test_broken false # broken construction/init
                @test_broken false # broken update
            end
        end
    end
end

# TODO: Test these for all attributes
@testset "Generic Attributes" begin
    scene = Scene()
    p = scatter!(scene, rand(10))
    @test scene.theme.inspectable[]
    @test p.inspectable[]

    scene = Scene(inspectable = false)
    p = scatter!(scene, rand(10))
    @test !scene.theme.inspectable[]
    @test !p.inspectable[]
end