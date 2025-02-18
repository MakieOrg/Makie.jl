@testset "core attributes" begin
    # also tests that plot!(scene, ...) always works
    core_attributes = [
        :visible, :transparency, :space, :overdraw, :inspectable, :inspector_label,
        :inspector_clear, :inspector_hover, :clip_planes, :depth_shift, #:fxaa
    ]

    # `exclude` to exclude an attribute from being checked
    # `skip_inheritance` to exclude it after the top level plot is checked (e.g. if child plots do not inherit it)
    # `expected` attributes to compare to (default values)
    function validate_attributes(p; exclude = Set(), expected = Dict{Symbol, Any}(), skip_inheritance = Set())
        attr = attributes(p)

        for name in core_attributes
            name in exclude && continue
            name in skip_inheritance && push!(exclude, name)
            @test haskey(attr, name) && (to_value(attr[name]) == to_value(expected[name]))
        end

        foreach(p -> validate_attributes(p, exclude = exclude, expected = expected), p.plots)
    end

    scene = Scene()
    expected = Makie.MakieCore.generic_plot_attributes!(Attributes())
    expected[:clip_planes] = scene.theme.clip_planes

    for PlotType in ALL_PLOT_TYPES
        @testset "$PlotType" begin
            p = testplot!(scene, PlotType)
            # validate_attributes(p, expected = expected)
        end
    end
end