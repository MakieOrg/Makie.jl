# @test_deprecated seems broken on 1.9 + 1.10
macro depwarn_message(expr)
    return quote
        logger = Test.TestLogger()
        Base.with_logger(logger) do
            $(esc(expr))
        end
        if length(logger.logs) == 1
            logger.logs[1].message
        else
            nothing
        end
    end
end

@testset "deprecations" begin
    @testset "Scene" begin
        # test that deprecated `resolution keyword still works but throws warning`
        logger = Test.TestLogger()
        Base.with_logger(logger) do
            scene = Scene(; resolution = (999, 999), size = (123, 123))
            @test scene.viewport[] == Rect2i((0, 0), (999, 999))
        end
        @test occursin(
            "The `resolution` keyword for `Scene`s and `Figure`s has been deprecated",
            logger.logs[1].message
        )
        scene = Scene(; size = (600, 450))
        msg = @depwarn_message scene.px_area
        @test occursin(
            ".px_area` got renamed to `.viewport`, and means the area the scene maps to in device independent units",
            msg
        )
        # @test_deprecated seems to be broken on 1.10?!
        msg = @depwarn_message pixelarea(scene)
        # only works with depwarn on
        @test occursin("`pixelarea` is deprecated, use `viewport` instead.", msg)
    end
    @testset "Plot -> Combined" begin
        logger = Test.TestLogger()
        msg = @depwarn_message Makie.Combined()
        @test occursin("Combined() is deprecated", msg)
    end
    @testset "Surface Traits" begin
        msg = @depwarn_message Makie.DiscreteSurface()
        @test occursin("DiscreteSurface() is deprecated", msg)
        msg = @depwarn_message Makie.ContinuousSurface()
        @test occursin("ContinuousSurface() is deprecated", msg)
    end
    @testset "AbstractVector ImageLike" begin
        @test_throws ErrorException image(1:10, 1 .. 10, zeros(10, 10))
        @test_throws ErrorException image(1 .. 10, 1:10, zeros(10, 10))
        @test_throws ErrorException image(collect(1:10), 1:10, zeros(10, 10))
    end
end
