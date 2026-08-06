"""
    streaklets(velocity, limits; time = 1, times = range(0, 1, 60), kwargs...)
    streaklets(velocity, xrange, yrange, zrange; kwargs...)

Animated **streaklets**: short, flowing pathline trails advected through a
(possibly time-dependent) 3D vector field — a livelier way to show unsteady flow
than instantaneous streamlines.

`velocity` is a callback `velocity(point::Point3, t::Real) -> VecTypes{3}` giving
the flow velocity at a point and time. A pool of tracers is seeded within
`limits`, advected through the field, and their recent trails are rendered as a
single `lines` object. Trails fade from head (bright) to tail, tracers are
recycled with staggered lifetimes, and — for periodic fields — can wrap
toroidally (`boundary = :wrap`).

All frames are **precomputed once** over `times`; the `time` attribute then only
selects which frame to draw, so animation/scrubbing is a cheap lookup and the
plot is fully backend-agnostic (pure `lines`).

## Attributes
- `time`: 1-based frame index to display — drive it with a slider to animate.
- `times`: the time samples at which frames are precomputed.
- `nparticles`, `trail`, `substeps`, `lifetime`, `fade`: tracer-pool and trail controls.
- `color`: a `(point, t) -> Real` scalar for per-vertex color (`automatic` = speed `|velocity|`).
- `importance`: a `(point, t) -> Real`; tracers are seeded preferentially where this is
  large (`nothing` = uniform seeding).
- `boundary`: `:kill` recycles tracers that leave `limits`, `:wrap` wraps them toroidally.

Example:
```julia
v(p, t) = Point3f(sin(p[3] + t), sin(p[1] + t), sin(p[2] + t))   # unsteady ABC-like flow
streaklets(v, Rect3f(-3, -3, -3, 6, 6, 6); times = range(0, 2pi, 120), colormap = :inferno)
```
"""
@recipe Streaklets (velocity, limits) begin
    "1-based frame index to display; drive with a slider to animate."
    time = 1
    "Time samples at which frames are precomputed."
    times = range(0.0, 1.0, length = 60)
    "Number of tracer particles."
    nparticles = 1500
    "Number of points in each tracer's trail."
    trail = 30
    "Advection sub-steps taken per frame (higher = more accurate, slower)."
    substeps = 1
    "`(min, max)` tracer lifetime, in frames, before it is recycled."
    lifetime = (400, 900)
    "Birth/death fade length, in frames."
    fade = 12
    "Per-vertex color scalar `(point, t) -> Real`; `automatic` uses speed `|velocity|`."
    color = automatic
    "Seeding importance `(point, t) -> Real`; larger values attract more tracers. `nothing` seeds uniformly."
    importance = nothing
    "Boundary handling: `:kill` recycles tracers leaving `limits`, `:wrap` wraps them toroidally."
    boundary = :kill
    "RNG seed for reproducible tracer placement."
    seed = 1
    "Sets the width of the streaklet lines."
    linewidth = @inherit linewidth
    mixin_colormap_attributes()...
    mixin_generic_plot_attributes()...
end

function convert_arguments(::Type{<:Streaklets}, f, xrange, yrange, zrange)
    xmin, xmax = extrema(xrange)
    ymin, ymax = extrema(yrange)
    zmin, zmax = extrema(zrange)
    mini = Vec3(xmin, ymin, zmin)
    maxi = Vec3(xmax, ymax, zmax)
    return (f, Rect(mini, maxi .- mini))
end
convert_arguments(::Type{<:Streaklets}, f, limits::Rect) = (f, limits)

# Precomputed per-frame streaklet geometry (backend agnostic).
struct StreakletData
    positions::Vector{Vector{Point3f}}   # per frame: NaN-separated trail polylines
    color::Vector{Vector{Float32}}       # per-vertex color scalar
    alpha::Vector{Vector{Float32}}       # per-vertex fade (trail taper + birth/death)
    range::Vec2f                          # global extrema of `color`, for automatic colorrange
end

@inline function streaklet_rk4(f, r::Point3f, t::Float32, h::Float32)
    k1 = Point3f(f(r, t))
    k2 = Point3f(f(r + 0.5f0 * h * k1, t + 0.5f0 * h))
    k3 = Point3f(f(r + 0.5f0 * h * k2, t + 0.5f0 * h))
    k4 = Point3f(f(r + h * k3, t + h))
    return r + (h / 6f0) * (k1 + 2f0 * k2 + 2f0 * k3 + k4)
end

"""
    streaklets_impl(f, limits, times; kwargs...) -> StreakletData

Advect a pool of tracers through the time-dependent field `f(point, t)` and
return the precomputed per-frame streaklet geometry. See [`streaklets`](@ref)
for the meaning of the keyword arguments.
"""
function streaklets_impl(
        f, limits::Rect, times;
        nparticles = 1500, trail = 30, substeps = 1, lifetime = (400, 900), fade = 12,
        colorfunc = (p, t) -> Float32(norm(Point3f(f(p, t)))), importance = nothing,
        boundary = :kill, seed = 1
    )
    rng = Random.MersenneTwister(seed)
    lo = Point3f(minimum(limits)); hi = Point3f(maximum(limits)); w = hi .- lo
    lmin, lmax = Int(lifetime[1]), Int(lifetime[2])
    randlife() = rand(rng, lmin:lmax)
    seedpt() = begin
        importance === nothing && return lo .+ w .* Point3f(rand(rng), rand(rng), rand(rng))
        best = lo; bv = -Inf32
        for _ in 1:8
            p = lo .+ w .* Point3f(rand(rng), rand(rng), rand(rng))
            v = Float32(importance(p, first(times)))
            v > bv && (bv = v; best = p)
        end
        return best
    end

    P = Matrix{Point3f}(undef, trail, nparticles)
    W = zeros(Float32, trail, nparticles)
    age = zeros(Int, nparticles)
    life = [randlife() for _ in 1:nparticles]
    for j in 1:nparticles
        s = seedpt(); P[:, j] .= (s,); W[:, j] .= colorfunc(s, first(times)); age[j] = rand(rng, 0:life[j])
    end

    wrap = boundary === :wrap
    advance! = (t0, t1) -> begin
        h = Float32(t1 - t0) / substeps; tt = Float32(t0)
        for _ in 1:substeps
            @inbounds for j in 1:nparticles
                nh = streaklet_rk4(f, P[trail, j], tt, h)
                out = !(nh in limits); age[j] += 1
                if wrap && out
                    nh = lo .+ mod.(nh .- lo, w)                # wrapping is not a death
                    @views P[1:(end - 1), j] .= P[2:end, j]; @views W[1:(end - 1), j] .= W[2:end, j]
                    P[trail, j] = nh; W[trail, j] = colorfunc(nh, tt + h)
                elseif out || age[j] ≥ life[j]
                    s = seedpt(); P[:, j] .= (s,); W[:, j] .= colorfunc(s, tt); age[j] = 0; life[j] = randlife()
                else
                    @views P[1:(end - 1), j] .= P[2:end, j]; @views W[1:(end - 1), j] .= W[2:end, j]
                    P[trail, j] = nh; W[trail, j] = colorfunc(nh, tt + h)
                end
            end
            tt += h
        end
    end

    # warm the trails to full length before the first recorded frame
    dt0 = length(times) > 1 ? (times[2] - times[1]) : 1.0
    for _ in 1:trail
        advance!(first(times), first(times) + dt0)
    end

    positions = Vector{Vector{Point3f}}()
    colors = Vector{Vector{Float32}}()
    alphas = Vector{Vector{Float32}}()
    smin = Inf32; smax = -Inf32
    nanp = Point3f(NaN)
    for (i, t) in enumerate(times)
        i > 1 && advance!(times[i - 1], times[i])
        pts = Point3f[]; cs = Float32[]; al = Float32[]
        @inbounds for j in 1:nparticles
            lifef = min(clamp(age[j] / fade, 0f0, 1f0), clamp((life[j] - age[j]) / fade, 0f0, 1f0))
            for p in 1:trail
                cur = P[p, j]
                if p > 1 && wrap
                    pr = P[p - 1, j]
                    if abs(cur[1] - pr[1]) > 0.5f0 * w[1] || abs(cur[2] - pr[2]) > 0.5f0 * w[2] || abs(cur[3] - pr[3]) > 0.5f0 * w[3]
                        push!(pts, nanp); push!(cs, 0f0); push!(al, 0f0)   # break polyline across a wrap
                    end
                end
                s = W[p, j]; smin = min(smin, s); smax = max(smax, s)
                push!(pts, cur); push!(cs, s); push!(al, (p / trail)^1.3f0 * lifef)
            end
            push!(pts, nanp); push!(cs, 0f0); push!(al, 0f0)             # break between tracers
        end
        push!(positions, pts); push!(colors, cs); push!(alphas, al)
    end
    range = smax > smin ? Vec2f(smin, smax) : Vec2f(0f0, 1f0)
    return StreakletData(positions, colors, alphas, range)
end

function plot!(p::Streaklets)
    # Heavy step: advect the pool once. Re-runs only if the field/pool params change,
    # NOT when `time` changes — so scrubbing is a cheap lookup below.
    map!(
        p,
        [:velocity, :limits, :times, :nparticles, :trail, :substeps, :lifetime, :fade, :color, :importance, :boundary, :seed],
        :streaklet_data
    ) do f, limits, times, np, tr, ss, lt, fd, col, imp, bnd, sd
        colorfunc = col === automatic ? ((pt, t) -> Float32(norm(Point3f(f(pt, t))))) : ((pt, t) -> Float32(col(pt, t)))
        return streaklets_impl(
            f, limits, times;
            nparticles = np, trail = tr, substeps = ss, lifetime = lt, fade = fd,
            colorfunc = colorfunc, importance = imp, boundary = bnd, seed = sd
        )
    end

    map!(p, [:streaklet_data, :colorrange], :computed_colorrange) do data, cr
        return cr === automatic ? data.range : Vec2f(cr[1], cr[2])
    end

    # Cheap per-frame step: pick the frame and bake color scalar × fade → RGBAf.
    map!(p, [:streaklet_data, :time, :colormap, :computed_colorrange], [:streaklet_positions, :streaklet_colors]) do data, t, cmap, cr
        i = clamp(round(Int, t), 1, length(data.positions))
        cols = to_colormap(cmap); n = length(cols)
        lo, hi = cr; span = hi > lo ? hi - lo : 1f0
        scal = data.color[i]; alp = data.alpha[i]
        vc = Vector{RGBAf}(undef, length(scal))
        @inbounds for k in eachindex(scal)
            u = clamp((scal[k] - lo) / span, 0f0, 1f0)
            c = cols[clamp(round(Int, u * (n - 1)) + 1, 1, n)]
            vc[k] = RGBAf(c.r, c.g, c.b, alp[k])
        end
        return (data.positions[i], vc)
    end

    lines!(
        p, p.streaklet_positions;
        color = p.streaklet_colors, transparency = true, linewidth = p.linewidth, fxaa = false
    )
    return p
end
