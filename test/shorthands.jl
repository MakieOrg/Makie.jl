@testset "shorthands" begin

    scene2d = scatter(1:10, 1:10);
    scene = scatter(1:10, 1:10, 1:10);
    axis = scene[Axis]

    @testset "tick labels" begin

        @test xticklabels(scene) == ["0.0", "2.5", "5.0", "7.5", "10.0"]
        @test yticklabels(scene) == ["2", "4", "6", "8", "10"]
        @test zticklabels(scene) == ["2", "4", "6", "8", "10"]
        @test_throws AssertionError("The Scene does not have a z-axis!") zticklabels(scene2d)

        @test xtickrange(scene) == [0.0, 2.5, 5.0, 7.5, 10.0]
        @test ytickrange(scene) == [2.0, 4.0, 6.0, 8.0, 10.0]
        @test ztickrange(scene) == [2.0, 4.0, 6.0, 8.0, 10.0]
        @test_throws AssertionError("The Scene does not have a z-axis!") ztickrange(scene2d)

        xticks!(scene, xticklabels=["a", "b", "c", "d", "e"])
        @test xticklabels(scene) == ["a", "b", "c", "d", "e"]

        yticks!(scene, yticklabels=["a", "b", "c", "d", "e", "f"], ytickrange=collect(range(2.0, stop=10.0, length=6)))
        @test yticklabels(scene) == ["a", "b", "c", "d", "e", "f"]

        yticks!(scene2d, yticklabels=["a", "b", "c", "d", "e", "f"], ytickrange=collect(range(2.0, stop=10.0, length=6)))
        @test yticklabels(scene2d) == ["a", "b", "c", "d", "e", "f"]

        zticks!(scene, zticklabels=["2", "10"], ztickrange=[2.0, 10.0])
        @test zticklabels(scene) == ["2", "10"]

        @test_throws AssertionError("The Scene does not have a z-axis!") zticks!(scene2d, zticklabels=["2", "10"], ztickrange=[2.0, 10.0])
    end

    @testset "tick rotation" begin
        @test xtickrotation(scene) == axis.ticks.rotation[][1]
        @test ytickrotation(scene) == axis.ticks.rotation[][2]
        @test ztickrotation(scene) == axis.ticks.rotation[][3]

        xtickrotation!(0.0)
        @test xtickrotation(scene) == 0.0

        ytickrotation!(0.0)
        @test ytickrotation(scene) == 0.0

        ztickrotation!(0.0)
        @test ztickrotation(scene) == 0.0

        @test_throws AssertionError("The Scene does not have a z-axis!") ztickrotation(scene2d)
        @test_throws AssertionError("The Scene does not have a z-axis!") ztickrotation!(scene2d, 0.0)
    end

end
