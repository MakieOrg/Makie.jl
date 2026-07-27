"""
Draw `text` along a path. `path` can be a `Vector{<: Point2}` (with optional
`NaN` separators between sub-paths) or a `BezierPath`.

When a `BezierPath` is provided, glyphs are positioned and oriented using exact
cubic-Bézier evaluation, giving smooth tangent rotations. A polyline input is
sampled piecewise-linearly.

The path itself may be given in `:data` or `:pixel` space, controlled by the `space` attribute.

Newlines in `text` are currently not supported.
"""
@recipe PathText (path::Union{PointVector{2, <:Real}, BezierPath},) begin
    "The text to place along the path. May be `String` or `RichText`. Must not contain newlines."
    text = ""
    "The color of the text. To color parts of the text differently, use `rich` text."
    color = @inherit textcolor
    "Sets the font. Can be a `Symbol` that is looked up in `fonts` or a font path/name."
    font = @inherit font
    "Dictionary of fonts that can be referenced by `Symbol`."
    fonts = @inherit fonts
    "Color of the text stroke."
    strokecolor = :black
    "Width of the text stroke in pixels."
    strokewidth = 0
    "Font size in pixels."
    fontsize = @inherit fontsize
    "Alignment of the text relative to the path, as a `(halign, valign)` tuple. `halign` controls position along the path (`:left`, `:center`, `:right`, or a `Real` fraction 0–1). `valign` controls perpendicular placement (`:baseline`, `:bottom`, `:center`, `:top`)."
    align = (:left, :baseline)
    "Additional perpendicular offset (in pixels) from the path, applied on top of `valign`. Positive values shift the text to the left of the path's direction of travel."
    offset = 0.0f0
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    fxaa = false
end

# Convert as PointBased() unless we have a BezierPath
conversion_trait(::Type{<:PathText}) = PointBased()
convert_arguments(::Type{<:PathText}, path::BezierPath) = (path,)

# RichText helpers
function _richtext_chars(rt::RichText)
    chars = Char[]
    _collect_richtext_chars!(chars, rt)
    return chars
end

function _collect_richtext_chars!(chars, rt::RichText)
    for child in rt.children
        _collect_richtext_chars!(chars, child)
    end
    return
end

function _collect_richtext_chars!(chars, s::String)
    for c in s
        c == '\n' && throw(ArgumentError("`pathtext` does not support newlines in `text`."))
        push!(chars, c)
    end
    return
end

################################################################################
# Cubic Bézier math
#
# Arc-length (Gauss-Legendre quadrature) and inverse arc-length (binary search)
# techniques are adapted from the `kurbo` Rust crate (MIT-licensed), specifically
# its `cubicbez.rs` and `param_curve.rs` modules.
# See https://github.com/linebender/kurbo
################################################################################

# 8-point Gauss-Legendre nodes and weights on [0, 1]  (transformed from [-1, 1])
const _GL8 = (
    weights = (
        0.181341891689181, 0.181341891689181,
        0.15685332293894365, 0.15685332293894365,
        0.11119051722668723, 0.11119051722668723,
        0.05061426814518813, 0.05061426814518813,
    ),
    nodes = (
        0.4082826787521751, 0.5917173212478249,
        0.2372337950418355, 0.7627662049581645,
        0.10166676130026867, 0.8983332386997313,
        0.01985507175123188, 0.9801449282487681,
    ),
)

# p(t) = (1-t)³p0 + 3(1-t)²t·p1 + 3(1-t)t²·p2 + t³·p3
function _cubic_eval(p0, p1, p2, p3, t)
    mt = 1.0 - t
    return mt^3 .* p0 .+ (3 * mt^2 * t) .* p1 .+ (3 * mt * t^2) .* p2 .+ t^3 .* p3
end

# p'(t) = 3[(1-t)²(p1-p0) + 2(1-t)t(p2-p1) + t²(p3-p2)]
function _cubic_deriv(p0, p1, p2, p3, t)
    mt = 1.0 - t
    d01 = p1 .- p0
    d12 = p2 .- p1
    d23 = p3 .- p2
    return 3.0 .* (mt^2 .* d01 .+ (2 * mt * t) .* d12 .+ t^2 .* d23)
end

# p''(t) = 6[(1-t)(p2-2p1+p0) + t(p3-2p2+p1)]
function _cubic_second_deriv(p0, p1, p2, p3, t)
    mt = 1.0 - t
    a = p2 .- 2.0 .* p1 .+ p0
    b = p3 .- 2.0 .* p2 .+ p1
    return 6.0 .* (mt .* a .+ t .* b)
end

# Arc length of a cubic Bézier on [t0, t1] via 8-point GL quadrature.
function _cubic_arclen(p0, p1, p2, p3, t0 = 0.0, t1 = 1.0)
    dt = t1 - t0
    total = 0.0
    for (w, x) in zip(_GL8.weights, _GL8.nodes)
        t = t0 + x * dt
        d = _cubic_deriv(p0, p1, p2, p3, t)
        total += w * sqrt(d[1]^2 + d[2]^2)
    end
    return total * dt
end

# Arc length of the offset curve  p(t) + d·n(t)  on [t0, t1].
# Speed of offset curve = |p'(t)| · |1 - d·κ(t)|  where κ is signed curvature.
function _cubic_offset_arclen(p0, p1, p2, p3, d, t0 = 0.0, t1 = 1.0)
    iszero(d) && return _cubic_arclen(p0, p1, p2, p3, t0, t1)
    dt = t1 - t0
    total = 0.0
    for (w, x) in zip(_GL8.weights, _GL8.nodes)
        t = t0 + x * dt
        dp = _cubic_deriv(p0, p1, p2, p3, t)
        speed = sqrt(dp[1]^2 + dp[2]^2)
        if speed > 1.0e-12
            ddp = _cubic_second_deriv(p0, p1, p2, p3, t)
            kappa = (dp[1] * ddp[2] - dp[2] * ddp[1]) / speed^3
            total += w * speed * abs(1.0 - d * kappa)
        end
    end
    return total * dt
end

# Find parameter t ∈ [0,1] such that the (offset) arc length from 0 to t equals `target`.
function _cubic_inv_arclen(p0, p1, p2, p3, target, total_len, d = 0.0)
    target <= 0 && return 0.0
    target >= total_len && return 1.0
    lo, hi = 0.0, 1.0
    # 20 iterations of bisection → ≈ 1e-6 precision on the parameter, which is
    # below sub-pixel accuracy for any realistic font size.
    for _ in 1:20
        mid = 0.5 * (lo + hi)
        s = iszero(d) ? _cubic_arclen(p0, p1, p2, p3, 0.0, mid) :
            _cubic_offset_arclen(p0, p1, p2, p3, d, 0.0, mid)
        if s < target
            lo = mid
        else
            hi = mid
        end
    end
    return 0.5 * (lo + hi)
end

# Point on the offset curve at parameter t.
function _cubic_offset_point(p0, p1, p2, p3, t, d)
    pt = _cubic_eval(p0, p1, p2, p3, t)
    dp = _cubic_deriv(p0, p1, p2, p3, t)
    speed = sqrt(dp[1]^2 + dp[2]^2)
    speed < 1.0e-12 && return Point2f(pt[1], pt[2])
    nx, ny = -dp[2] / speed, dp[1] / speed
    return Point2f(pt[1] + d * nx, pt[2] + d * ny)
end

# Unit tangent of a cubic at parameter t.
function _cubic_unit_tangent(p0, p1, p2, p3, t)
    dp = _cubic_deriv(p0, p1, p2, p3, t)
    speed = sqrt(dp[1]^2 + dp[2]^2)
    speed < 1.0e-12 && return Point2f(1, 0)
    return Point2f(dp[1] / speed, dp[2] / speed)
end

################################################################################
# Prepared BezierPath: precomputed per-segment (offset) arc lengths
################################################################################

struct _PreparedSegment
    kind::Symbol          # :line or :cubic
    p0::Point2d           # start
    p1::Point2d           # end (line) / control 1 (cubic)
    p2::Point2d           # control 2 (cubic)
    p3::Point2d           # end (cubic)
    arclen::Float64       # (offset) arc length
    cum_end::Float64      # cumulative arc length at the end of this segment
    subpath_id::Int       # incremented on each MoveTo (to detect sub-path gaps)
end

function _prepare_bezierpath(bp::BezierPath, d::Real = 0.0)
    bp2 = replace_nonfreetype_commands(bp)
    segs = _PreparedSegment[]
    last_pt = Point2d(0, 0)
    subpath_id = 0
    cum = 0.0
    started = false
    for cmd in bp2.commands
        if cmd isa MoveTo
            last_pt = cmd.p
            if started
                subpath_id += 1
            end
            started = true
        elseif cmd isa LineTo
            started || (subpath_id += 1; started = true)
            len = norm(cmd.p - last_pt)
            cum += len
            push!(segs, _PreparedSegment(:line, last_pt, cmd.p, Point2d(0), Point2d(0), len, cum, subpath_id))
            last_pt = cmd.p
        elseif cmd isa CurveTo
            started || (subpath_id += 1; started = true)
            len = iszero(d) ? _cubic_arclen(last_pt, cmd.c1, cmd.c2, cmd.p) :
                _cubic_offset_arclen(last_pt, cmd.c1, cmd.c2, cmd.p, d)
            cum += len
            push!(segs, _PreparedSegment(:cubic, last_pt, cmd.c1, cmd.c2, cmd.p, len, cum, subpath_id))
            last_pt = cmd.p
        end
    end
    return segs
end

_total_arclen(segs::Vector{_PreparedSegment}) = isempty(segs) ? 0.0 : segs[end].cum_end

"""
Sample a prepared BezierPath at arc-length `s`. Returns `(point, tangent)` or
`nothing` if past the end. When `d ≠ 0`, positions are offset perpendicularly.
"""
function _sample_bezierpath_at(segs::Vector{_PreparedSegment}, s::Real, d::Real = 0.0)
    s < 0 && return nothing

    # Binary search the segment whose cumulative arc-length range contains `s`.
    lo, hi = 1, length(segs)
    hi == 0 && return nothing
    while lo < hi
        mid = (lo + hi) >> 1
        if segs[mid].cum_end < s
            lo = mid + 1
        else
            hi = mid
        end
    end
    seg = segs[lo]
    seg.cum_end < s && return nothing
    local_s = s - (seg.cum_end - seg.arclen)

    if seg.kind === :line
        frac = seg.arclen > 0 ? local_s / seg.arclen : 0.0
        v = seg.p1 - seg.p0
        len = norm(v)
        tangent = len > 0 ? Point2f(v[1] / len, v[2] / len) : Point2f(1, 0)
        pt = Point2f(seg.p0[1] + frac * v[1], seg.p0[2] + frac * v[2])
        if !iszero(d)
            nx, ny = -tangent[2], tangent[1]
            pt = pt + Float32(d) * Point2f(nx, ny)
        end
        return (pt, tangent, seg.subpath_id)
    else # :cubic
        t = _cubic_inv_arclen(seg.p0, seg.p1, seg.p2, seg.p3, local_s, seg.arclen, d)
        tangent = _cubic_unit_tangent(seg.p0, seg.p1, seg.p2, seg.p3, t)
        pt = iszero(d) ? Point2f(_cubic_eval(seg.p0, seg.p1, seg.p2, seg.p3, t)...) :
            _cubic_offset_point(seg.p0, seg.p1, seg.p2, seg.p3, t, d)
        return (pt, tangent, seg.subpath_id)
    end
end

################################################################################
# Polyline utilities (for Vector{Point} input)
################################################################################

function _polyline_arc_length(points::AbstractVector{<:VecTypes})
    total = 0.0
    @inbounds for i in 1:(length(points) - 1)
        p1 = points[i]
        p2 = points[i + 1]
        (any(isnan, p1) || any(isnan, p2)) && continue
        total += norm(p2 - p1)
    end
    return Float32(total)
end

function _seg_normal(p1, p2)
    (any(isnan, p1) || any(isnan, p2)) && return nothing
    v = p2 - p1
    len = norm(v)
    iszero(len) && return nothing
    return Vec2f(-v[2] / len, v[1] / len)
end

function _offset_polyline(points::AbstractVector{<:VecTypes}, d::Real)
    n = length(points)
    result = Vector{Point2f}(undef, n)
    iszero(d) && return Point2f[Point2f(p) for p in points]
    d = Float32(d)

    for i in 1:n
        p = points[i]
        if any(isnan, p)
            result[i] = Point2f(NaN, NaN)
            continue
        end
        n_in = i > 1 ? _seg_normal(points[i - 1], p) : nothing
        n_out = i < n ? _seg_normal(p, points[i + 1]) : nothing
        if n_in === nothing && n_out === nothing
            result[i] = Point2f(p)
        elseif n_in === nothing
            result[i] = Point2f(p) + d * Point2f(n_out)
        elseif n_out === nothing
            result[i] = Point2f(p) + d * Point2f(n_in)
        else
            denom = 1 + dot(n_in, n_out)
            if denom < 1.0f-3
                result[i] = Point2f(p) + d * Point2f(n_in)
            else
                avg = n_in + n_out
                result[i] = Point2f(p) + (d / denom) * Point2f(avg)
            end
        end
    end
    return result
end

function _sample_polyline_at(points::AbstractVector{<:VecTypes}, s::Real)
    s < 0 && return nothing
    accum = 0.0
    subpath_id = 0
    prev_was_nan = true   # so the very first valid segment starts sub-path 0
    @inbounds for i in 1:(length(points) - 1)
        p1 = points[i]
        p2 = points[i + 1]
        if any(isnan, p1) || any(isnan, p2)
            prev_was_nan = true
            continue
        end
        if prev_was_nan
            subpath_id += 1
            prev_was_nan = false
        end
        v = p2 - p1
        seglen = norm(v)
        iszero(seglen) && continue
        if accum + seglen >= s
            t = (s - accum) / seglen
            unit_tangent = Point2f(v[1] / seglen, v[2] / seglen)
            pt = Point2f(p1[1] + t * v[1], p1[2] + t * v[2])
            return (pt, unit_tangent, subpath_id)
        end
        accum += seglen
    end
    return nothing
end

################################################################################
# Control-point extraction / reassembly (for projecting BezierPath to pixel)
################################################################################

function _extract_control_points(path::AbstractVector{<:VecTypes})
    return path
end

function _extract_control_points(bp::BezierPath)
    bp2 = replace_nonfreetype_commands(bp)
    points = Point2d[]
    for cmd in bp2.commands
        if cmd isa MoveTo
            push!(points, cmd.p)
        elseif cmd isa LineTo
            push!(points, cmd.p)
        elseif cmd isa CurveTo
            push!(points, cmd.c1, cmd.c2, cmd.p)
        end
    end
    return points
end

function _reassemble_path(px_pts::AbstractVector, ::AbstractVector{<:VecTypes})
    return px_pts
end

function _reassemble_path(px_pts::AbstractVector, bp::BezierPath)
    bp2 = replace_nonfreetype_commands(bp)
    cmds = PathCommand[]
    i = 1
    for cmd in bp2.commands
        if cmd isa MoveTo
            push!(cmds, MoveTo(Point2d(px_pts[i])))
            i += 1
        elseif cmd isa LineTo
            push!(cmds, LineTo(Point2d(px_pts[i])))
            i += 1
        elseif cmd isa CurveTo
            push!(cmds, CurveTo(Point2d(px_pts[i]), Point2d(px_pts[i + 1]), Point2d(px_pts[i + 2])))
            i += 3
        end
    end
    return BezierPath(cmds)
end

################################################################################
# Layout
################################################################################

# Layout a single-line RichText with the baseline at y=0. We call the layout
# sub-steps directly, skipping apply_justification! since a single line has no
# unused width to distribute (which also means the layout box is irrelevant here).
function _layout_richtext_for_path(text::RichText, fontsize, font, fonts)
    lines = [GlyphInfo[]]
    gs = GlyphState(0, 0, Vec2f(fontsize), font, RGBAf(0, 0, 0, 1))
    process_rt_node!(lines, gs, text, fonts)
    return glyph_arrays(reduce(vcat, lines), Rect2f(0, 0, 0, 0), 0.0f0)
end

# `sample_fn(s)` returns `(point, tangent, subpath_id)` or `nothing`.
# `advances` are the horizontal advance widths per glyph; the chord between
# arc-length `s` and `s + adv` determines the glyph's rotation (so wide letters
# span the curvature naturally).
# `y_offsets` (optional) are per-glyph perpendicular shifts from the path
# baseline (e.g. sub/superscript displacement in RichText).
function _place_glyphs_on_path(
        x_positions, advances, sample_fn, frac, total_path_len;
        y_offsets = nothing,
    )
    positions = Point2f[]
    rotations = Quaternionf[]

    total_text_len = isempty(x_positions) ? 0.0f0 : x_positions[end] + advances[end]
    start_s = frac * (total_path_len - total_text_len)

    for (i, (x, adv)) in enumerate(zip(x_positions, advances))
        s0 = start_s + x
        sample_start = sample_fn(s0)
        sample_start === nothing && break
        pt, start_tangent, start_subpath = sample_start

        # Fall back to the start tangent when the chord would bridge a NaN or
        # MoveTo gap between two sub-paths.
        sample_end = sample_fn(s0 + adv)
        tangent = if sample_end !== nothing
            pt_end, _, end_subpath = sample_end
            if end_subpath != start_subpath
                start_tangent
            else
                chord = pt_end - pt
                chord_len = norm(chord)
                chord_len > 1.0f-6 ? Point2f(chord[1] / chord_len, chord[2] / chord_len) : start_tangent
            end
        else
            start_tangent
        end

        normal = Point2f(-tangent[2], tangent[1])
        if y_offsets !== nothing && !iszero(y_offsets[i])
            pt = pt + y_offsets[i] * normal
        end
        push!(positions, pt)
        push!(rotations, to_rotation(Vec2f(normal)))
    end

    # the loop only ever breaks, so what got placed is the prefix `1:length(positions)`
    return (positions, rotations)
end

# Perpendicular baseline shift (in pixels) from valign and font metrics.
# Positive result shifts to the left of the path's travel direction.
function _valign_shift(va, fontsize, font)
    va === :baseline && return 0.0f0
    asc = Float32(FreeTypeAbstraction.ascender(font)) * fontsize
    desc = Float32(FreeTypeAbstraction.descender(font)) * fontsize  # negative
    return if va === :bottom
        -desc
    elseif va === :top
        -asc
    elseif va === :center
        -(asc + desc) / 2
    else
        throw(ArgumentError("Invalid valign $(repr(va)) for `pathtext`. Expected `:baseline`, `:bottom`, `:center`, or `:top`."))
    end
end

# What the text side of layout hands to the path side. `colors` is `nothing` for
# plain strings, where the recipe's own `color` attribute is used as-is; `RichText`
# carries a color per glyph. `y_offsets` are perpendicular shifts from the path
# baseline (sub/superscript displacement), also `nothing` when there are none.
const _PathtextGlyphs = @NamedTuple{
    glyphindices::Vector{UInt64},
    fonts::Vector{NativeFont},
    scales::Vector{Vec2f},
    colors::Union{Nothing, Vector{RGBAf}},
    x_positions::Vector{Float32},
    y_offsets::Union{Nothing, Vector{Float32}},
    advances::Vector{Float32},
}

_empty_glyphs() = convert(
    _PathtextGlyphs, (
        glyphindices = UInt64[], fonts = NativeFont[], scales = Vec2f[], colors = nothing,
        x_positions = Float32[], y_offsets = nothing, advances = Float32[],
    )
)

_empty_layout() = (Point2f[], Quaternionf[], UInt64[], NativeFont[], Vec2f[], nothing)

# Dispatch for the text side of layout.
function _layout_glyphs(text::AbstractString, fontsize::Float32, font, fonts)
    chars = collect(text)
    # advances come from the requested font, while a glyph missing from it renders
    # from a fallback font, so the two can disagree for such glyphs
    advances = Float32[Float32(GlyphExtent(font, c).hadvance) * fontsize for c in chars]
    x_positions = similar(advances)
    acc = 0.0f0
    @inbounds for i in eachindex(advances)
        x_positions[i] = acc
        acc += advances[i]
    end
    glyph_fonts = NativeFont[find_font_for_char(c, font) for c in chars]
    return convert(
        _PathtextGlyphs, (
            glyphindices = UInt64[FreeTypeAbstraction.glyph_index(f, c) for (f, c) in zip(glyph_fonts, chars)],
            fonts = glyph_fonts,
            scales = fill(to_2d_scale(fontsize), length(chars)),
            colors = nothing,
            x_positions = x_positions,
            y_offsets = nothing,
            advances = advances,
        )
    )
end

function _layout_glyphs(text::RichText, fontsize::Float32, font, fonts)
    layout = _layout_richtext_for_path(text, fontsize, font, fonts)
    n = length(layout.glyphindices)
    n == 0 && return _empty_glyphs()

    return convert(
        _PathtextGlyphs, (
            glyphindices = layout.glyphindices,
            fonts = layout.fonts,
            scales = layout.scales,
            colors = layout.colors,
            x_positions = Float32[o[1] for o in layout.origins],
            y_offsets = Float32[o[2] for o in layout.origins],
            advances = Float32[layout.extents[i].hadvance * layout.scales[i][1] for i in 1:n],
        )
    )
end

# Dispatch for the path side of layout. Returns `(total_path_len, sample_fn)`
# or `nothing` if the path is too short/empty.
function _prepare_path_sampler(pixel_path::AbstractVector{<:VecTypes}, d::Real)
    length(pixel_path) < 2 && return nothing
    working = iszero(d) ? pixel_path : _offset_polyline(pixel_path, d)
    total = _polyline_arc_length(working)
    return (total, s -> _sample_polyline_at(working, s))
end

function _prepare_path_sampler(pixel_bp::BezierPath, d::Real)
    segs = _prepare_bezierpath(pixel_bp, d)
    isempty(segs) && return nothing
    total = Float32(_total_arclen(segs))
    return (total, s -> _sample_bezierpath_at(segs, s, d))
end

function _pathtext_layout(pixel_path, text, fontsize, font, fonts, align, offset)
    _font = to_font(fonts, font)
    _fontsize = Float32(to_fontsize(fontsize))
    halign, valign = align
    perp_offset = Float64(offset) + _valign_shift(valign, _fontsize, _font)

    glyphs = _layout_glyphs(text, _fontsize, _font, fonts)
    isempty(glyphs.glyphindices) && return _empty_layout()

    prepared = _prepare_path_sampler(pixel_path, perp_offset)
    prepared === nothing && return _empty_layout()
    total_path_len, sample_fn = prepared

    error_msg = "Invalid halign $(repr(halign)) for `pathtext`. Expected `:left`, `:center`, `:right`, or a `Real`."
    frac = halign2num(halign, error_msg)
    pos, rot = _place_glyphs_on_path(
        glyphs.x_positions, glyphs.advances, sample_fn, frac, total_path_len;
        y_offsets = glyphs.y_offsets,
    )

    # a path too short for the whole string places a prefix of the glyphs
    placed = 1:length(pos)
    colors = glyphs.colors === nothing ? nothing : glyphs.colors[placed]
    return (pos, rot, glyphs.glyphindices[placed], glyphs.fonts[placed], glyphs.scales[placed], colors)
end

################################################################################
# plot!
################################################################################

function _single_pathtext_value(value, name::Symbol)
    isscalar(value) && return value
    return error(
        "`pathtext` takes a single $name, got $(length(value)) values. " *
            "To style parts of the text differently, use `rich` text."
    )
end

function _validate_pathtext(text::AbstractString)
    occursin('\n', text) && throw(ArgumentError("`pathtext` does not support newlines in `text`."))
    return text
end

function _validate_pathtext(text::RichText)
    _richtext_chars(text) # walks the tree; throws if newline found
    return text
end

function plot!(p::PathText)
    map!(_validate_pathtext, p, :text, :_pathtext_validated_text)

    map!(_extract_control_points, p, :path, :_pathtext_control_points)

    register_projected_positions!(
        p, Point2f;
        input_name = :_pathtext_control_points,
        output_name = :_pathtext_control_points_pixel,
        input_space = :space,
        output_space = :pixel,
    )

    map!(_reassemble_path, p, [:_pathtext_control_points_pixel, :path], :_pathtext_pixel_path)

    # Bending the text is per-glyph positions and rotations, which is exactly what
    # `Glyphs` takes, so the glyphs go there directly rather than through `text`.
    map!(
        _pathtext_layout, p,
        [:_pathtext_pixel_path, :_pathtext_validated_text, :fontsize, :font, :fonts, :align, :offset],
        [
            :_pathtext_positions, :_pathtext_rotations, :_pathtext_glyphindices,
            :_pathtext_fonts, :_pathtext_scales, :_pathtext_layout_colors,
        ]
    )

    # `pathtext` draws one string, so each style attribute takes one value. Styling
    # parts of the text differently is `rich` text's job: shaping can merge several
    # code points into one glyph, so a vector indexed per character has nothing
    # well-defined to index (`text` dropped the same thing).
    for name in (:color, :strokecolor, :strokewidth)
        map!(v -> _single_pathtext_value(v, name), p, [name], Symbol(:_pathtext_single_, name))
    end

    # RichText brings a color per glyph; a plain string uses the recipe's `color`.
    map!(p, [:_pathtext_layout_colors, :_pathtext_single_color], :_pathtext_color) do layout_colors, user_color
        return layout_colors === nothing ? user_color : layout_colors
    end

    # positions are already the glyph origins, in pixels
    map!(p, [:_pathtext_positions], :_pathtext_marker_offsets) do positions
        return fill(Point3f(0), length(positions))
    end

    glyphs!(
        p,
        shared_attributes(p, Glyphs; drop = [:color, :strokecolor, :strokewidth, :rotation, :space, :markerspace]),
        p._pathtext_positions;
        glyphindices = p._pathtext_glyphindices,
        font_per_char = p._pathtext_fonts,
        scale = p._pathtext_scales,
        marker_offset = p._pathtext_marker_offsets,
        rotation = p._pathtext_rotations,
        color = p._pathtext_color,
        strokecolor = p._pathtext_single_strokecolor,
        strokewidth = p._pathtext_single_strokewidth,
        space = :pixel,
        markerspace = :pixel,
        transformation = :nothing,
    )

    return p
end

function data_limits(p::PathText)
    path = p.path[]
    if path isa BezierPath
        return Rect3d(bbox(path))
    elseif path isa AbstractVector && !isempty(path)
        return Rect3d(Rect2d(path))
    else
        return Rect3d()
    end
end

boundingbox(p::PathText, space::Symbol = :data) = apply_transform_and_model(p, data_limits(p))
