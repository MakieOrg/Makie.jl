# Line topology on host and device, against the sequential reference.
#
# `lines_generate_indices` and `lines_sumlengths` were host loops that a device
# position array had to be copied back for. They are now scans and scatters that
# run wherever the positions live. The loops they replaced are kept HERE, as the
# reference — the parallel versions have to agree with them element for element,
# on a `Vector` and on a device array alike.

using Test, RayMakie, Makie, Mantle, GeometryBasics, LinearAlgebra
using RayMakie: lines_generate_indices, lines_sumlengths
using GeometryBasics: VecTypes

# ── The sequential originals, verbatim ───────────────────────────────────────

function ref_generate_indices(ps, indices = UInt32[], valid = Float32[])
    empty!(indices)
    resize!(valid, length(ps))
    if length(ps) < 2
        valid .= 0f0
        return (indices, valid)
    end
    sizehint!(indices, length(ps) + 2)
    last_start_pos = eltype(ps)(NaN)
    last_start_idx = -1
    for (i, p) in enumerate(ps)
        not_nan = isfinite(p)
        valid[i] = Float32(not_nan)
        if not_nan
            if last_start_idx == -1
                push!(indices, UInt32(max(1, i - 1)))
                last_start_idx = length(indices) + 1
                last_start_pos = p
            end
            push!(indices, UInt32(i))
        elseif (last_start_idx != -1) && (length(indices) - last_start_idx > 2) &&
               (ps[max(1, i - 1)] ≈ last_start_pos)
            indices[last_start_idx - 1] = UInt32(max(1, i - 2))
            push!(indices, UInt32(indices[last_start_idx + 1]), UInt32(i))
            valid[i - 2] = 2f0
            valid[indices[last_start_idx + 1]] = 2f0
            last_start_idx = -1
        elseif last_start_idx != -1
            push!(indices, UInt32(i))
            last_start_idx = -1
        end
    end
    if (last_start_idx != -1) && (length(indices) - last_start_idx > 2) && (ps[end] ≈ last_start_pos)
        indices[last_start_idx - 1] = UInt32(length(ps) - 1)
        push!(indices, UInt32(indices[last_start_idx + 1]))
        valid[end - 1] = 2f0
        valid[indices[last_start_idx + 1]] = 2f0
    elseif last_start_idx != -1
        push!(indices, UInt32(length(ps)))
    end
    indices .-= UInt32(1)
    return (indices, valid)
end

function ref_sumlengths(points, resolution)
    f(p::VecTypes{4}) = p[Vec(1, 2)] / p[4]
    f(p::VecTypes) = p[Vec(1, 2)]
    invalid(p::VecTypes{4}) = p[4] <= 1.0f-6
    invalid(p::VecTypes) = false
    result = zeros(Float32, length(points))
    for (i, idx) in enumerate(eachindex(points))
        idx0 = max(idx - 1, 1)
        p1, p2 = points[idx0], points[idx]
        if any(map(isnan, p1)) || any(map(isnan, p2)) || invalid(p1) || invalid(p2)
            result[i] = 0f0
        else
            result[i] = result[max(i - 1, 1)] + 0.5f0 * norm(resolution .* (f(p1) - f(p2)))
        end
    end
    return result
end

# ── Inputs, chosen so every branch of the reference is exercised ─────────────

const NAN3 = Point3f(NaN)
# Wrapped, because a `Point3f` IS a `StaticVector`: `[NAN3; pts]` concatenates
# its three components as scalars rather than appending one point.
const GAP = [NAN3]

"A closed ring of `n` points whose last point equals its first."
ring(n) = [Point3f(cos(2pi * i / (n - 1)), sin(2pi * i / (n - 1)), 0) for i in 0:(n - 1)]

function topology_cases()
    cases = Pair{String,Vector{Point3f}}[]
    push!(cases, "empty" => Point3f[])
    push!(cases, "single point" => [Point3f(0)])
    push!(cases, "two points" => [Point3f(0), Point3f(1, 0, 0)])
    push!(cases, "open line" => [Point3f(i, 0, 0) for i in 1:10])
    push!(cases, "all NaN" => fill(NAN3, 6))
    push!(cases, "leading NaN" => [GAP; [Point3f(i, 0, 0) for i in 1:5]])
    push!(cases, "trailing NaN" => [[Point3f(i, 0, 0) for i in 1:5]; GAP])
    push!(cases, "two runs" => [[Point3f(i, 0, 0) for i in 1:4]; GAP; [Point3f(i, 1, 0) for i in 1:4]])
    push!(cases, "consecutive NaNs" => [[Point3f(i, 0, 0) for i in 1:4]; GAP; GAP;
                                        [Point3f(i, 1, 0) for i in 1:4]])
    # Runs of every length around the loop threshold (a loop needs > 3 points).
    for L in 1:5
        push!(cases, "run of $L" => [[Point3f(i, 0, 0) for i in 1:L]; GAP])
        push!(cases, "closed run of $L" => [ring(L); GAP])
    end
    push!(cases, "loop at end" => ring(8))
    push!(cases, "loop then line" => [ring(8); GAP; [Point3f(i, 2, 0) for i in 1:4]])
    push!(cases, "line then loop" => [[Point3f(i, 2, 0) for i in 1:4]; GAP; ring(8)])
    push!(cases, "two loops" => [ring(6); GAP; ring(9)])
    # Randomised, with NaNs sprinkled at a rate that makes short runs common.
    rng_pts = Point3f[]
    for i in 1:200
        push!(rng_pts, iseven(i) && (i % 7 == 0) ? NAN3 : Point3f(sin(i), cos(i), i / 200))
    end
    push!(cases, "random 200" => rng_pts)
    return cases
end

@testset "line topology" begin
    back = Mantle.defaultbackend()
    cases = topology_cases()

    @testset "indices match the sequential reference — host" begin
        for (name, ps) in cases
            ri, rv = ref_generate_indices(ps, UInt32[], Float32[])
            gi, gv = lines_generate_indices(ps, UInt32[], Float32[])
            @test gi == ri
            @test gv == rv
        end
    end

    @testset "indices match the sequential reference — device" begin
        for (name, ps) in cases
            ri, rv = ref_generate_indices(ps, UInt32[], Float32[])
            dps = Mantle.devicearray(back, ps)
            gi, gv = lines_generate_indices(dps, similar(dps, UInt32, 0), similar(dps, Float32, 0))
            @test Mantle.isdevicearray(gi)
            @test Array(gi) == ri
            @test Array(gv) == rv
        end
    end

    @testset "buffers are reused across calls" begin
        ps = [Point3f(i, 0, 0) for i in 1:10]
        idx = UInt32[]; val = Float32[]
        i1, v1 = lines_generate_indices(ps, idx, val)
        @test i1 === idx && v1 === val
        # A second call with a different point count must resize, not append.
        i2, _ = lines_generate_indices([Point3f(i, 0, 0) for i in 1:4], idx, val)
        @test i2 === idx
        @test length(idx) == length(first(ref_generate_indices([Point3f(i, 0, 0) for i in 1:4])))
    end

    @testset "cumulative lengths match the reference" begin
        res = Vec2f(800, 600)
        for (name, ps) in cases
            isempty(ps) && continue
            r = ref_sumlengths(ps, res)
            @test lines_sumlengths(ps, res) ≈ r
            dps = Mantle.devicearray(back, ps)
            @test Array(lines_sumlengths(dps, res)) ≈ r
        end
    end

    @testset "cumulative lengths handle projected (w) points" begin
        res = Vec2f(800, 600)
        # A w at or below 1e-6 is behind the eye and breaks the run.
        ps = [Vec4f(1, 2, 0, 1), Vec4f(3, 4, 0, 2), Vec4f(5, 6, 0, 1f-9),
              Vec4f(7, 8, 0, 1), Vec4f(9, 10, 0, 1)]
        r = ref_sumlengths(ps, res)
        @test lines_sumlengths(ps, res) ≈ r
        @test Array(lines_sumlengths(Mantle.devicearray(back, ps), res)) ≈ r
    end
end
