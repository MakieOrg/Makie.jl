# Regression tests for the small Showoff.jl subset that lives in
# Makie/src/tick_format.jl. The cases mirror the unit tests Showoff
# itself shipped, adapted to our public API; deliberate behavioral
# changes (rich-text scientific, unicode minus sign for negative
# numbers, no `+1` padding on scientific precision) are documented
# inline.
@testset "Tick label formatting (vendored Showoff)" begin

    @testset "plain notation" begin
        # Plain precision heuristic picks the smallest uniform precision
        # that captures all significant digits in the array — verbatim from
        # Showoff's `plain_precision_heuristic` test.
        @test Makie._plain_label_precision([1.12345, 4.5678]) == 5

        # Plain output pads every value to that uniform precision so the
        # decimals line up; "4.5678" becomes "4.56780".
        @test Makie.format_ticks_plain([1.12345, 4.5678]) == ["1.12345", "4.56780"]

        # Negatives use the unicode minus (−, U+2212) rather than the
        # ASCII hyphen so the glyph balances better with digits.
        @test Makie._format_plain_label(-10.0, 0) == "−10"
        @test Makie._format_plain_label(0.012345, 3) == "0.012"

        # Singleton zero special-cases cleanly.
        @test Makie.format_ticks_plain([0.0]) == ["0"]
    end

    @testset "auto style selection" begin
        # A range spanning ≤ 4 orders of magnitude stays plain.
        @test Makie._pick_label_style([0.0, 1000.0]) == :plain
        @test Makie.format_ticks_auto([0.0, 1000.0]) == ["0", "1000"]

        # A range spanning > 4 orders of magnitude flips to scientific.
        @test Makie._pick_label_style([0.0, 50000.0]) == :scientific

        # Single-value vectors fall back to plain (no range to compare).
        @test Makie._pick_label_style([0.0]) == :plain
    end

    @testset "scientific notation" begin
        # All non-zero bases reduce to whole numbers → strip `.0` padding
        # uniformly across the array.
        labels = Makie.format_ticks_auto([1.0e-5, 2.0e-5, 3.0e-5])
        @test String.(labels) == ["1×10−5", "2×10−5", "3×10−5"]

        # A mixed-precision array keeps the trailing zeros so the decimals
        # stay aligned (we never produce `1.5×10⁻⁵` next to `2×10⁻⁵`).
        labels = Makie.format_ticks_auto([1.5e-5, 2.5e-5])
        @test String.(labels) == ["1.5×10−5", "2.5×10−5"]

        labels = Makie.format_ticks_auto([1.25e-5, 2.5e-5])
        @test String.(labels) == ["1.25×10−5", "2.50×10−5"]

        # Zero in the middle of an otherwise-scientific range stays as
        # plain "0" rather than rendering as `0×10⁰`.
        labels = Makie.format_ticks_auto([-1.0e7, 0.0, 1.0e7])
        @test String(labels[1]) == "−1×107"
        @test labels[2] == "0"
        @test String(labels[3]) == "1×107"

        # Very wide ranges (the Showoff `[1, 1e39]` test).
        labels = Makie.format_ticks_auto([1.0, 1.0e39])
        @test String.(labels) == ["1×100", "1×1039"]

        # Showoff returned "5.0×10⁴" here because its scientific precision
        # heuristic adds 1. We dropped that extra padding so plain bases
        # stay plain — see comment in `_scientific_label_precision`.
        labels = Makie.format_ticks_auto([0.0, 50000.0])
        @test labels[1] == "0"
        @test String(labels[2]) == "5×104"
    end

    @testset "Formatters (Axis3D backward-compat)" begin
        # The public `Formatters` submodule used to wrap `Showoff.showoff`;
        # it still returns `Vector{String}` so Axis3D's `TextBuffer` keeps
        # working. The strings mirror the old Showoff output, including the
        # ASCII hyphen on negative numbers.
        @test Makie.Formatters.plain([1.0, 2.0, 3.0]) == ["1", "2", "3"]
        @test Makie.Formatters.plain([1.0, 1.5, 2.0]) == ["1.0", "1.5", "2.0"]
        @test Makie.Formatters.plain([-10.0, 0.0, 10.0]) == ["-10", "0", "10"]

        # Scientific keeps the unicode-superscript string form Showoff
        # produced (TextBuffer can't consume RichText). The `.0` padding
        # is no longer added — `Formatters.scientific` now reflects the
        # same precision rule as `format_ticks_auto`.
        @test Makie.Formatters.scientific([1.0e-5, 2.0e-5]) == ["1×10⁻⁵", "2×10⁻⁵"]
    end
end
