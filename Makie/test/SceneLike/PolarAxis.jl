@testset "PolarAxis" begin
    @testset "rtick rotations" begin
        f = Figure()
        po = PolarAxis(
            f[1, 1], thetalimits = (0, pi / 4), rlimits = (1, 2.0),
            rticklabelrotation = Makie.automatic,
            rticklabelpad = 10.0f0
        )
        rticklabelplot = po.overlay.plots[1]

        # Mostly for verification that we got the right plot
        @test po.overlay.plots[1].arg1[] == [
            ("1.00", Point2f(0.5, 0.0)),
            ("1.25", Point2f(0.625, 0.0)),
            ("1.50", Point2f(0.75, 0.0)),
            ("1.75", Point2f(0.875, 0.0)),
            ("2.00", Point2f(1.0, 0.0)),
        ]
        f

        angles = [
            7pi / 4 + 1.0e-5, 0, pi / 4 - 1.0e-5,
            pi / 4 + 1.0e-5, pi / 2, 3pi / 4 - 1.0e-5,
            3pi / 4 + 1.0e-5, pi, 5pi / 4 - 1.0e-5,
            5pi / 4 + 1.0e-5, 3pi / 2, 7pi / 4 - 1.0e-5,
        ]

        # automatic
        for dir in [1, -1], mirror in [false, true]
            @testset "direction = $dir and rticksmirrored = $mirror" begin
                po.direction[] = dir
                po.rticksmirrored[] = mirror
                # are ticks shifted to the thetamax side?
                tick_side_shift = ifelse(xor(dir == -1, mirror), pi / 4, 0.0)

                for labelrotation in (Makie.automatic, :aligned)
                    @testset "rticklabelrotation = $labelrotation" begin
                        po.rticklabelrotation[] = labelrotation

                        # theta_0 is picked such that ticks are drawn at the selected angle, i.e.
                        # relative to the (cos(angle), sin(angle)) direction

                        for i in 1:4, j in 1:3
                            angle = angles[j + 3(i - 1)]
                            # set theta_0 so that rticks are relative to picked angle
                            po.theta_0[] = dir * angle - tick_side_shift

                            # tick offset
                            # mirror = false: axis on counterclockwise side, ticks on clockwise side
                            # mirror = true: axis on cw side, ticks on ccw
                            s, c = sincos(angle + ifelse(mirror, pi / 2, -pi / 2))
                            @test rticklabelplot.offset[] ≈ 10.0f0 * Vec3f(c, s, 0)

                            # tick rotation:
                            # synched with picked angle
                            tick_rotations = (-pi / 4 + 1.0e-5, 0.0, pi / 4 - 1.0e-5)
                            @test mod(rticklabelplot.attributes.inputs[:rotation].value, -pi .. pi) ≈ tick_rotations[j] atol = 1.0e-6

                            # tick align:
                            # if ticks are mirrored we draw them on the other side of the angle-direction,
                            # which mirrors/180° rotates alignment. Equivalent by shifting index 2 along
                            align = (Vec2f(0.5, 1.0), Vec2f(0.0, 0.5), Vec2f(0.5, 0.0), Vec2f(1.0, 0.5))[mod1(i + 2 * mirror, 4)]
                            @test rticklabelplot.align[] ≈ align
                        end
                    end
                end

                @testset "rticklabelrotation = value" begin
                    po.theta_0[] = 2pi * rand()

                    v = 2pi * rand()
                    po.rticklabelrotation[] = v
                    @test rticklabelplot.attributes.inputs[:rotation].value ≈ v

                    # Where are the tick labels actually drawn
                    label_angle = po.direction[] * (po.theta_0[] + tick_side_shift)
                    # clockwise or counterclockwise side of r line?
                    offset_dir_angle = label_angle + ifelse(mirror, pi / 2, -pi / 2)
                    s, c = sincos(offset_dir_angle)
                    @test rticklabelplot.offset[] ≈ 10.0f0 * Vec3f(c, s, 0)

                    s, c = sincos(offset_dir_angle - v)
                    scale = 1 / max(abs(s), abs(c))
                    @test rticklabelplot.align[] ≈ Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
                end

                @testset "rticklabelrotation = :horizontal" begin
                    po.theta_0[] = 2pi * rand()
                    po.rticklabelrotation[] = :horizontal
                    @test rticklabelplot.attributes.inputs[:rotation].value ≈ 0.0f0

                    # Same offset and alignment except rotation is strictly 0
                    label_angle = po.direction[] * (po.theta_0[] + tick_side_shift)
                    offset_dir_angle = label_angle + ifelse(mirror, pi / 2, -pi / 2)
                    s, c = sincos(offset_dir_angle)
                    @test rticklabelplot.offset[] ≈ 10.0f0 * Vec3f(c, s, 0)
                    scale = 1 / max(abs(s), abs(c))
                    @test rticklabelplot.align[] ≈ Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
                end

                @testset "rticklabelrotation = :radial" begin
                    po.theta_0[] = 2pi * rand()
                    po.rticklabelrotation[] = :radial

                    # always (:left, :center) aligned, which is (0, 0.5)
                    @test rticklabelplot.align[] ≈ Point2f(0, 0.5)

                    # Same offset
                    label_angle = po.direction[] * (po.theta_0[] + tick_side_shift)
                    offset_dir_angle = label_angle + ifelse(mirror, pi / 2, -pi / 2)
                    s, c = sincos(offset_dir_angle)
                    @test rticklabelplot.offset[] ≈ 10.0f0 * Vec3f(c, s, 0)

                    @test mod(rticklabelplot.attributes.inputs[:rotation].value, -pi .. pi) ≈ mod(offset_dir_angle, -pi .. pi) atol = 1.0e-6
                end
            end
        end
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
        @test all(isapprox.(ax.target_thetalims[], (-0.025pi, 0.525pi), rtol = 1.0e-6))

        # derive both
        scatter!(ax, Point2f(pi, 2))
        reset_limits!(ax)
        @test all(isapprox.(ax.target_rlims[], (0.95, 2.05), rtol = 1.0e-6))
        @test all(isapprox.(ax.target_thetalims[], (-0.05pi, 1.05pi), rtol = 1.0e-6))

        # set limits
        rlims!(ax, 0.0, 3.0)
        reset_limits!(ax)
        @test ax.rlimits[] == (0.0, 3.0)
        @test ax.target_rlims[] == (0.0, 3.0)
        @test all(isapprox.(ax.target_thetalims[], (-0.05pi, 1.05pi), rtol = 1.0e-6))

        thetalims!(ax, 0.0, 2pi)
        reset_limits!(ax)
        @test ax.rlimits[] == (0.0, 3.0)
        @test ax.target_rlims[] == (0.0, 3.0)
        @test ax.thetalimits[] == (0.0, 2pi)
        @test ax.target_thetalims[] == (0.0, 2pi)

        # test tightlimits
        fig = Figure()
        ax = PolarAxis(fig[1, 1])
        surface!(ax, 0.5pi .. pi, 2 .. 5, rand(10, 10))
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
        @test all(isapprox.(ax.target_thetalims[], (0.5pi, 1.0pi), rtol = 1.0e-6))
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
