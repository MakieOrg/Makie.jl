using Logging
using IOCapture: IOCapture

module VideoBackend
    using Makie
    struct Screen <: MakieScreen
        size::Tuple{Int, Int}
    end
    struct ScreenConfig
    end
    Base.size(screen::Screen) = screen.size
    Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat) = Screen(size(scene))
    Makie.backend_showable(::Type{Screen}, ::MIME"text/html") = true
    Makie.backend_showable(::Type{Screen}, ::MIME"image/png") = true
    Makie.colorbuffer(screen::Screen) = zeros(RGBf, reverse(screen.size)...)
    Base.display(::Screen, ::Scene; kw...) = nothing
end

Makie.set_active_backend!(VideoBackend)
# We need a screenconfig in the theme for every backend!
set_theme!(VideoBackend = Attributes())


mktempdir() do tempdir
    @testset "Video encoding" begin
        n = 2
        x = 0:(n - 1)
        fig, ax, _ = lines(x, zeros(size(x)))
        # test for no throwing when encoding
        @testset "Encoding" begin
            for fmt in ("mkv", "mp4", "webm", "gif")
                dst = joinpath(tempdir, "out.$fmt")
                @test begin
                    record(fig, dst, 1:n) do i
                        lines!(ax, sin.(i .* x))
                        return nothing
                    end
                    true
                end
            end
        end

        # test that the proper warnings are thrown
        @testset "Warnings" begin
            function run_record(dst; kwargs...)
                record(fig, dst, 1:n; kwargs...) do i
                    lines!(ax, sin.(i .* x))
                    return nothing
                end
            end

            # kwarg => (value, (should_warn => format))
            warn_tests = [
                (:compression, 20, ["mkv", "gif"], ["mp4", "webm"]),
                (:profile, "high422", ["mkv", "webm", "gif"], ["mp4"]),
                (
                    kwarg = :pixel_format,
                    value = "yuv420p",
                    warn_fmts = ["mkv", "webm", "gif"],
                    no_warn_fmts = ["mp4"],
                ),
            ]

            for (kwarg, value, warn_fmts, no_warn_fmts) in warn_tests
                kwargs = Dict(kwarg => value)
                warning_re = Regex("^`$(kwarg)`, with value $(repr(value))")

                for fmt in warn_fmts
                    dst = joinpath(tempdir, "out.$fmt")
                    @test_logs (:warn, warning_re) run_record(dst; kwargs...)
                end

                for fmt in no_warn_fmts
                    dst = joinpath(tempdir, "out.$fmt")
                    @test_logs min_level = Logging.Warn run_record(dst; kwargs...)
                end
            end
        end
    end
end

@testset "No hang when closing IOCapture.capture over VideoStream" begin
    # @test_nowarn IOCapture.capture() do
    #     f = Figure()
    #     Makie.VideoStream(f)
    # end
end

Makie.set_active_backend!(missing)
