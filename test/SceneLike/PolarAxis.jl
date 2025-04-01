@testset "PolarAxis" begin
    @testset "rtick rotations" begin
        f = Figure()
        angles = [
            7pi/4+0.01, 0,      pi/4-0.01,
            pi/4+0.01, pi/2,   3pi/4-0.01,
            3pi/4+0.01, pi,    5pi/4-0.01,
            5pi/4+0.01, 3pi/2, 7pi/4-0.01,
        ]
        po = PolarAxis(
            f[1, 1], thetalimits = (0, pi/4), rticklabelrotation = Makie.automatic,
            rticklabelpad = 10f0
        )
        rticklabelplot = po.overlay.plots[8].plots[1]

        # Mostly for verification that we got the right plot
        @test po.overlay.plots[8][1][] == [("0.0", Point2f(0.0, 0.0)), ("2.5", Point2f(0.25, 0.0)), ("5.0", Point2f(0.5, 0.0)), ("7.5", Point2f(0.75, 0.0)), ("10.0", Point2f(1.0, 0.0))]

        # automatic
        for i in 1:4
            align = (Vec2f(0.5, 1.0), Vec2f(0.0, 0.5), Vec2f(0.5, 0.0), Vec2f(1.0, 0.5))[i]
            for j in 1:3
                po.theta_0[] = angles[j + 3(i-1)]
                s, c = sincos(angles[j + 3(i-1)] - pi/2)
                @test rticklabelplot.plots[1].offset[] ≈ 10f0 * Vec2f(c, s)
                @test rticklabelplot.align[] ≈ align
                @test isapprox(mod(rticklabelplot.rotation[], -pi..pi), (-pi/4+0.01, 0, pi/4-0.01)[j], atol = 1e-3)
            end
        end

        # value
        v = 2pi * rand()
        po.rticklabelrotation[] = v
        s, c = sincos(po.theta_0[] - pi/2)
        @test rticklabelplot.plots[1].offset[] ≈ 10f0 * Vec2f(c, s)
        scale = 1 / max(abs(s), abs(c))
        @test rticklabelplot.align[] ≈ Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        @test rticklabelplot.rotation[] ≈ v

        # horizontal
        po.rticklabelrotation[] = :horizontal
        @test rticklabelplot.plots[1].offset[] ≈ 10f0 * Vec2f(c, s)
        @test rticklabelplot.align[] ≈ Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        @test rticklabelplot.rotation[] ≈ 0f0

        # radial
        po.rticklabelrotation[] = :radial
        @test rticklabelplot.plots[1].offset[] ≈ 10f0 * Vec2f(c, s)
        @test rticklabelplot.align[] ≈ Vec2f(0, 0.5)
        @test rticklabelplot.rotation[] ≈ po.theta_0[] - pi/2

        # aligned
        po.rticklabelrotation[] = :aligned
        @test rticklabelplot.plots[1].offset[] ≈ 10f0 * Vec2f(c, s)
        @test rticklabelplot.align[] ≈ Vec2f(1, 0.5)
        @test rticklabelplot.rotation[] ≈ po.theta_0[] - 3pi/2
    end


    @testset "Limits" begin
        # Should not error (0 width limits)
        fig = Figure()
        ax = PolarAxis(fig[1, 1])
        p = scatter!(ax, Point2f(0))

        # verify defaults
        @test ax.rautolimitmargin[] == (0.05, 0.05)
        @test ax.thetaautolimitmargin[] == (0.05, 0.05)

        # default should have mostly set default limits
        @test ax.rlimits[] == (:origin, nothing)
        @test ax.thetalimits[] == (0.0, 2pi)
        @test ax.target_rlims[] == (0.0, 10.0)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # but we want to test automatic limits here
        autolimits!(ax)
        reset_limits!(ax) # needed because window isn't open
        @test ax.rlimits[] == (nothing, nothing)
        @test ax.thetalimits[] == (nothing, nothing)
        @test ax.target_rlims[] == (0.0, 10.0)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # derived r, default theta
        scatter!(ax, Point2f(0, 1))
        reset_limits!(ax)
        @test ax.target_rlims[] == (0.0, 1.05)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # back to full default
        delete!(ax, p)
        reset_limits!(ax)
        @test ax.target_rlims[] == (0.0, 10.0)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # default r, derived theta
        scatter!(ax, Point2f(0.5pi, 1))
        reset_limits!(ax)
        @test ax.target_rlims[] == (0.0, 10.0)
        @test all(isapprox.(ax.target_thetalims[], (-0.025pi, 0.525pi), rtol=1e-6))

        # derive both
        scatter!(ax, Point2f(pi, 2))
        reset_limits!(ax)
        @test all(isapprox.(ax.target_rlims[], (0.95, 2.05), rtol=1e-6))
        @test all(isapprox.(ax.target_thetalims[], (-0.05pi, 1.05pi), rtol=1e-6))

        # set limits
        rlims!(ax, 0.0, 3.0)
        reset_limits!(ax)
        @test ax.rlimits[] == (0.0, 3.0)
        @test ax.target_rlims[] == (0.0, 3.0)
        @test all(isapprox.(ax.target_thetalims[], (-0.05pi, 1.05pi), rtol=1e-6))

        thetalims!(ax, 0.0, 2pi)
        reset_limits!(ax)
        @test ax.rlimits[] == (0.0, 3.0)
        @test ax.target_rlims[] == (0.0, 3.0)
        @test ax.thetalimits[] == (0.0, 2pi)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # test tightlimits
        fig = Figure()
        ax = PolarAxis(fig[1, 1])
        surface!(ax, 0.5pi..pi, 2..5, rand(10, 10))
        tightlimits!(ax)

        @test ax.rautolimitmargin[] == (0.0, 0.0)
        @test ax.thetaautolimitmargin[] == (0.0, 0.0)

        # with default limits
        reset_limits!(ax)
        @test ax.rlimits[] == (:origin, nothing)
        @test ax.thetalimits[] == (0.0, 2pi)
        @test ax.target_rlims[] == (0.0, 5.0)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # with fully automatic limits
        autolimits!(ax)
        reset_limits!(ax)
        @test ax.rlimits[] == (nothing, nothing)
        @test ax.thetalimits[] == (nothing, nothing)
        @test ax.target_rlims[] == (2.0, 5.0)
        @test all(isapprox.(ax.target_thetalims[], (0.5pi, 1.0pi), rtol=1e-6))
    end

    @testset "Radial Offset" begin
        fig = Figure()
        ax = PolarAxis(fig[1, 1], radius_at_origin = -1.0, rlimits = (0, 10))
        @test ax.scene.transformation.transform_func[].r0 == -1.0
    end

    @testset "PolarAxis fontsize from Figure()" begin
        fig = Figure(fontsize = 50)
        ax = PolarAxis(fig[1, 1])
        @test ax.rticklabelsize[] == 50
        @test ax.thetaticklabelsize[] == 50
    end

    @testset "PolarAxis fontsize from :Axis" begin
        fig = Figure(; Axis = (; xticklabelsize = 35, yticklabelsize = 65))
        ax = PolarAxis(fig[1, 1])
        @test ax.thetaticklabelsize[] == 35
        @test ax.rticklabelsize[] == 65
    end

    @testset "PolarAxis fontsize from Theme()" begin
        fontsize_theme = Theme(fontsize = 10)
        with_theme(fontsize_theme) do
            fig = Figure()
            ax = PolarAxis(fig[1, 1])
            @test ax.rticklabelsize[] == 10
            @test ax.thetaticklabelsize[] == 10
        end
    end
end