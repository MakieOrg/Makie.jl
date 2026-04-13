using Pkg: Pkg

@testset "ffmpeg_path configuration" begin
    @test Makie.ffmpeg_path() === nothing

    Makie.ffmpeg_path!("/tmp/fake_ffmpeg")
    @test Makie.ffmpeg_path() == "/tmp/fake_ffmpeg"
    @test Makie.get_ffmpeg_path() == `/tmp/fake_ffmpeg`

    Makie.ffmpeg_path!(nothing)
    @test Makie.ffmpeg_path() === nothing
end

# Verify the helpful error when FFMPEG_jll cannot be auto-loaded. This must
# run BEFORE the auto-load test below, because once FFMPEG_jll is loaded into
# the session `Base.require` will succeed regardless of the active env.
@testset "get_ffmpeg_path errors helpfully when FFMPEG_jll unavailable" begin
    @assert !haskey(Base.loaded_modules, Makie._FFMPEG_JLL_PKGID) "FFMPEG_jll already loaded; this test would be a no-op"
    current_env = dirname(Pkg.project().path)
    saved_load_path = copy(LOAD_PATH)
    mktempdir() do tmpenv
        # Restrict LOAD_PATH to only the temp env so `Base.locate_package` can't
        # fall back to FFMPEG_jll installed in the user's default depot env.
        empty!(LOAD_PATH)
        push!(LOAD_PATH, tmpenv)
        Pkg.activate(tmpenv; io = devnull)
        try
            @test_throws "Video recording requires FFMPEG_jll" Makie.get_ffmpeg_path()
        finally
            empty!(LOAD_PATH)
            append!(LOAD_PATH, saved_load_path)
            Pkg.activate(current_env; io = devnull)
        end
    end
end

# When no path is configured, get_ffmpeg_path should auto-load FFMPEG_jll.
# FFMPEG_jll is in the test deps so this should succeed.
@testset "get_ffmpeg_path auto-loads FFMPEG_jll" begin
    @test Makie.get_ffmpeg_path() isa Cmd
end

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
