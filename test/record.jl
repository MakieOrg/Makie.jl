using Logging

mktempdir() do tempdir
    @testset "Video encoding" begin
        n = 2
        x = 0:(n - 1)
        fig, ax, _ = lines(x, zeros(size(x)))
        # test for no throwing when encoding
        @testset "Encoding" begin
            for fmt in ("mkv", "mp4", "webm", "gif")
                dst = joinpath(tempdir2, "out.$fmt")
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
                (kwarg=:compression, value=20, warn_fmts=["mkv", "gif"], no_warn_fmts=["mp4", "webm"]),
                (kwarg=:profile, value="high422", warn_fmts=["mkv", "webm", "gif"], no_warn_fmts=["mp4"]),
                (
                    kwarg=:pixel_format,
                    value="yuv420p",
                    warn_fmts=["mkv", "webm", "gif"],
                    no_warn_fmts=["mp4"],
                ),
            ]

            for (; kwarg, value, warn_fmts, no_warn_fmts) in warn_tests
                kwargs = Dict(kwarg => value)
                warning_re = Regex("^`$(kwarg)`, with value $(repr(value))")

                for fmt in warn_fmts
                    dst = joinpath(tempdir2, "out.$fmt")
                    @test_logs (:warn, warning_re) run_record(dst; kwargs...)
                end

                for fmt in no_warn_fmts
                    dst = joinpath(tempdir2, "out.$fmt")
                    @test_logs min_level = Logging.Warn run_record(dst; kwargs...)
                end
            end
        end
    end
end
