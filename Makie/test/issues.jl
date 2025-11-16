@testset "Issues" begin
    @testset "#659 Volume errors if data is not a cube" begin
        fig, ax, vplot = volume(1 .. 8, 1 .. 8, 1 .. 10, rand(8, 8, 10))
        lims = Makie.data_limits(vplot)
        lo, hi = extrema(lims)
        @test all(lo .<= 1)
        @test all(hi .>= (8, 8, 10))
    end

    @testset "#3979 lossy matrix multiplication" begin
        ps = Point{3, Float64}[[436132.5523666298, 7.002123574681671e6, 505.0239189387989], [436132.5523666298, 7.002123574681671e6, 1279.2437345933633], [436132.5523666298, 7.002884453296079e6, 505.0239189387989], [436132.5523666298, 7.002884453296079e6, 1279.2437345933633], [437151.16775504407, 7.002123574681671e6, 505.0239189387989], [437151.16775504407, 7.002123574681671e6, 1279.2437345933633], [437151.16775504407, 7.002884453296079e6, 505.0239189387989], [437151.16775504407, 7.002884453296079e6, 1279.2437345933633]]
        f, a, p = scatter(ps)
        Makie.update_state_before_display!(f)
        # sanity check: old behavior should fail
        M = Makie.Mat4f(Makie.clip_to_space(a.scene.camera, :data)) *
            Makie.Mat4f(Makie.space_to_clip(a.scene.camera, :data))
        @test !(M ≈ I)
        # this should not
        M = Makie.clip_to_space(a.scene.camera, :data) * Makie.space_to_clip(a.scene.camera, :data)
        @test M ≈ I atol = 1.0e-4
    end

    @testset "#4416 Merging attributes" begin
        # See https://github.com/MakieOrg/Makie.jl/pull/4416
        theme1 = Theme(Axis = (; titlesize = 10))
        theme2 = Theme(Axis = (; xgridvisible = false))
        merged_theme = merge(theme1, theme2)
        # Test that merging themes does not modify leftmost argument
        @test !haskey(theme1.Axis, :xgridvisible)
        @test !haskey(theme2.Axis, :titlesize)  # sanity check other argument
    end

    @testset "#4722 Transformation passthrough" begin
        scene = Scene(camera = campixel!)
        p = text!(scene, L"\frac{1}{2}")
        translate!(scene, 0, 0, 10)
        @test isassigned(p.transformation.parent)
        @test isassigned(p.plots[1].transformation.parent)

        @test scene.transformation.model[][3, 4] == 10.0
        @test p.transformation.model[][3, 4] == 10.0
        @test p.plots[1].transformation.model[][3, 4] == 10.0
    end

    @testset "#4883 colorscale that breaks sort" begin
        data = Float32.(Makie.peaks())
        f, a, p = image(data; colorscale = -)
        @test p.scaled_colorrange[][1] == -maximum(data)
        @test p.scaled_colorrange[][2] == -minimum(data)
        @test issorted(p.scaled_colorrange[])
    end

    @testset "#4957 axis cycling for same plot type with different argument types" begin
        @testset "Lines" begin
            f, a, p1 = lines(rand(Float64, 10))
            p2 = lines!(a, rand(Float32, 10))
            p3 = lines!(a, rand(Float64, 10))

            palette_colors = a.scene.theme.palette.color[]

            @test p1.color[] == palette_colors[1]
            @test p2.color[] == palette_colors[2]
            @test p3.color[] == palette_colors[3]

            p4 = lines!(a, rand(Float32, 10))
            @test p4.color[] == palette_colors[4]
        end

        @testset "Poly" begin
            poly1 = Makie.GeometryBasics.Polygon(Point2f[(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)])
            multipoly1 = Makie.GeometryBasics.MultiPolygon([poly1, poly1])

            f, a, p1 = poly(poly1; alpha = 1)
            p2 = poly!(a, [poly1, poly1])
            p3 = poly!(a, multipoly1)

            # convert to RGBf here, because poly decreases alpha by 0.2
            palette_colors = a.scene.theme.palette.patchcolor[]

            @test p1.color[] == palette_colors[1]
            @test p2.color[] == palette_colors[2]
            @test p3.color[] == palette_colors[3]
        end
    end

    @testset "`default_attribute` with Attributes containing Attributes" begin
        foo = Attributes(; bar = 1)
        @test propertynames(foo) == (:bar,)
        @test Dict(Makie.default_attribute(Attributes(; foo), (:foo, Attributes()))) == Dict(foo)

        pl = Scatter((1:4,), Dict{Symbol, Any}())
        @test Set(propertynames(pl)) == keys(pl.attributes.outputs)
    end
end
