"""
    pathtext(path; text = "", kwargs...)

Draw `text` along a path. `path` can be a `Vector{<: Point2}` (with optional
`NaN` separators between sub-paths) or a `BezierPath`.

When a `BezierPath` is provided, glyphs are positioned and oriented using exact
cubic-Bézier evaluation, giving smooth tangent rotations. A polyline input is
sampled piecewise-linearly.

Text is always rendered at pixel size (`fontsize` is in pixels) because the glyphs
are placed visually along the path. The path itself may be given in `:data` or
`:pixel` space, controlled by the `space` attribute.

Newlines in `text` are not supported.

# Attributes

- `text = ""`: The text to place along the path. Must not contain newlines.
- `fontsize`: The font size in pixels.
- `font`, `fonts`: Font settings (as for `text`).
- `color`: Text color. May be a single value or a vector with one entry per
  character.
- `strokecolor`, `strokewidth`: Stroke styling; may be per-character.
- `align = :left`: Alignment along the path. One of `:left`, `:center`, `:right`,
  or a `Real` fraction (0 = start, 1 = end).
- `offset = 0.0`: Perpendicular offset from the path in pixels. Positive values
  shift the text to the left of the path's direction of travel.
- `space = :data`: Coordinate space of the path; `:data` or `:pixel`.
"""
@recipe PathText (path,) begin
    "The text to place along the path. Must not contain newlines."
    text = ""
    "The color of the text. May be a single value or a vector with one entry per character."
    color = @inherit textcolor
    "Sets the font. Can be a `Symbol` that is looked up in `fonts` or a font path/name."
    font = @inherit font
    "Dictionary of fonts that can be referenced by `Symbol`."
    fonts = @inherit fonts
    "Color of the text stroke. May be per-character."
    strokecolor = (:black, 0.0)
    "Width of the text stroke in pixels. May be per-character."
    strokewidth = 0
    "Font size in pixels."
    fontsize = @inherit fontsize
    "Alignment of the text along the path. One of `:left`, `:center`, `:right`, or a `Real` fraction between 0 (start) and 1 (end)."
    align = :left
    "Perpendicular offset (in pixels) from the path. Positive values shift the text to the left of the path's direction of travel."
    offset = 0.0f0
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

# -- convert_arguments ---------------------------------------------------------

function convert_arguments(::Type{<:PathText}, path::AbstractVector{<:VecTypes{2}})
    return (convert(Vector{Point2d}, path),)
end

function convert_arguments(::Type{<:PathText}, path::BezierPath)
    return (path,)
end

# -- RichText helpers ----------------------------------------------------------

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

# ==============================================================================
# Cubic Bézier math
# ==============================================================================

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
    for _ in 1:30
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

# ==============================================================================
# Prepared BezierPath: precomputed per-segment (offset) arc lengths
# ==============================================================================

struct _PreparedSegment
    kind::Symbol          # :line or :cubic
    p0::Point2d           # start
    p1::Point2d           # end (line) / control 1 (cubic)
    p2::Point2d           # control 2 (cubic)
    p3::Point2d           # end (cubic)
    arclen::Float64       # (offset) arc length
end

function _prepare_bezierpath(bp::BezierPath, d::Real = 0.0)
    bp2 = replace_nonfreetype_commands(bp)
    segs = _PreparedSegment[]
    last_pt = Point2d(0, 0)
    for cmd in bp2.commands
        if cmd isa MoveTo
            last_pt = cmd.p
        elseif cmd isa LineTo
            len = norm(cmd.p - last_pt)
            push!(segs, _PreparedSegment(:line, last_pt, cmd.p, Point2d(0), Point2d(0), len))
            last_pt = cmd.p
        elseif cmd isa CurveTo
            len = iszero(d) ? _cubic_arclen(last_pt, cmd.c1, cmd.c2, cmd.p) :
                _cubic_offset_arclen(last_pt, cmd.c1, cmd.c2, cmd.p, d)
            push!(segs, _PreparedSegment(:cubic, last_pt, cmd.c1, cmd.c2, cmd.p, len))
            last_pt = cmd.p
        end
    end
    return segs
end

function _total_arclen(segs::Vector{_PreparedSegment})
    return sum(s.arclen for s in segs; init = 0.0)
end

"""
Sample a prepared BezierPath at arc-length `s`. Returns `(point, tangent)` or
`nothing` if past the end. When `d ≠ 0`, positions are offset perpendicularly.
"""
function _sample_bezierpath_at(segs::Vector{_PreparedSegment}, s::Real, d::Real = 0.0)
    s < 0 && return nothing
    accum = 0.0
    for seg in segs
        if accum + seg.arclen >= s
            local_s = s - accum
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
                return (pt, tangent)
            else # :cubic
                t = _cubic_inv_arclen(seg.p0, seg.p1, seg.p2, seg.p3, local_s, seg.arclen, d)
                tangent = _cubic_unit_tangent(seg.p0, seg.p1, seg.p2, seg.p3, t)
                pt = iszero(d) ? Point2f(_cubic_eval(seg.p0, seg.p1, seg.p2, seg.p3, t)...) :
                    _cubic_offset_point(seg.p0, seg.p1, seg.p2, seg.p3, t, d)
                return (pt, tangent)
            end
        end
        accum += seg.arclen
    end
    return nothing
end

# ==============================================================================
# Polyline utilities (for Vector{Point} input)
# ==============================================================================

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
    @inbounds for i in 1:(length(points) - 1)
        p1 = points[i]
        p2 = points[i + 1]
        (any(isnan, p1) || any(isnan, p2)) && continue
        v = p2 - p1
        seglen = norm(v)
        iszero(seglen) && continue
        if accum + seglen >= s
            t = (s - accum) / seglen
            unit_tangent = Point2f(v[1] / seglen, v[2] / seglen)
            pt = Point2f(p1[1] + t * v[1], p1[2] + t * v[2])
            return (pt, unit_tangent)
        end
        accum += seglen
    end
    return nothing
end

# ==============================================================================
# Control-point extraction / reassembly (for projecting BezierPath to pixel)
# ==============================================================================

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

# ==============================================================================
# Layout
# ==============================================================================

# Common helper: place glyphs along a path given their arc-length positions.
# `sample_fn(s)` returns `(point, tangent)` or `nothing`.
# `y_offsets` (optional) are per-glyph perpendicular shifts (e.g. from sub/superscript baseline).
function _place_glyphs_on_path(
        x_positions, chars, sample_fn, frac, total_text_len, total_path_len;
        y_offsets = nothing,
    )
    positions = Point2f[]
    rotations = Quaternionf[]
    placed_chars = String[]

    start_s = frac * (total_path_len - total_text_len)

    for (i, (x, c)) in enumerate(zip(x_positions, chars))
        sample = sample_fn(start_s + x)
        sample === nothing && break
        pt, tangent = sample
        normal = Point2f(-tangent[2], tangent[1])
        if y_offsets !== nothing && !iszero(y_offsets[i])
            pt = pt + y_offsets[i] * normal
        end
        push!(positions, pt)
        push!(rotations, to_rotation(Vec2f(normal)))
        push!(placed_chars, string(c))
    end

    return (positions, rotations, placed_chars)
end

function _parse_align(align)
    frac = if align === :left
        0.0f0
    elseif align === :center
        0.5f0
    elseif align === :right
        1.0f0
    elseif align isa Real
        Float32(align)
    else
        throw(ArgumentError("Invalid `align = $(repr(align))` for `pathtext`. Expected `:left`, `:center`, `:right`, or a `Real`."))
    end
    return frac
end

_empty_layout() = (Point2f[], Quaternionf[], String[], nothing)

# --- String on polyline -------------------------------------------------------

function _pathtext_layout(pixel_path::AbstractVector{<:VecTypes}, text::AbstractString, fontsize, font, fonts, align, offset)
    (isempty(text) || length(pixel_path) < 2) && return _empty_layout()

    _font = to_font(fonts, font)
    _fontsize = Float32(to_fontsize(fontsize))
    _offset = Float32(offset)

    working_path = iszero(_offset) ? pixel_path : _offset_polyline(pixel_path, _offset)

    text_chars = collect(text)
    advances = Float32[Float32(GlyphExtent(_font, c).hadvance) * _fontsize for c in text_chars]
    total_text_len = sum(advances; init = 0.0f0)
    total_path_len = _polyline_arc_length(working_path)

    # x_positions: cumulative advance (start of each glyph)
    x_positions = cumsum(advances) .- advances
    frac = _parse_align(align)
    sample_fn = s -> _sample_polyline_at(working_path, s)
    pos, rot, chars = _place_glyphs_on_path(x_positions, text_chars, sample_fn, frac, total_text_len, total_path_len)
    return (pos, rot, chars, nothing)
end

# --- String on BezierPath -----------------------------------------------------

function _pathtext_layout(pixel_bp::BezierPath, text::AbstractString, fontsize, font, fonts, align, offset)
    isempty(text) && return _empty_layout()

    _font = to_font(fonts, font)
    _fontsize = Float32(to_fontsize(fontsize))
    _offset = Float64(offset)

    segs = _prepare_bezierpath(pixel_bp, _offset)
    isempty(segs) && return _empty_layout()

    text_chars = collect(text)
    advances = Float32[Float32(GlyphExtent(_font, c).hadvance) * _fontsize for c in text_chars]
    total_text_len = sum(advances; init = 0.0f0)
    total_path_len = Float32(_total_arclen(segs))

    x_positions = cumsum(advances) .- advances
    frac = _parse_align(align)
    sample_fn = s -> _sample_bezierpath_at(segs, s, _offset)
    pos, rot, chars = _place_glyphs_on_path(x_positions, text_chars, sample_fn, frac, total_text_len, total_path_len)
    return (pos, rot, chars, nothing)
end

# --- RichText on polyline -----------------------------------------------------

function _pathtext_layout(pixel_path::AbstractVector{<:VecTypes}, text::RichText, fontsize, font, fonts, align, offset)
    length(pixel_path) < 2 && return _empty_layout()

    _fontsize = Float32(to_fontsize(fontsize))
    _font = to_font(fonts, font)
    _offset = Float32(offset)

    gc = layout_text(text, _fontsize, _font, fonts, (:left, :baseline), to_rotation(0), :left, 1.0, RGBAf(0, 0, 0, 1))
    n = length(gc.glyphs)
    n == 0 && return _empty_layout()

    text_chars = _richtext_chars(text)
    length(text_chars) != n && error("RichText character count ($(length(text_chars))) does not match glyph count ($n).")

    x_positions = Float32[gc.origins[i][1] for i in 1:n]
    y_offsets = Float32[gc.origins[i][2] for i in 1:n]
    scales = collect_vector(gc.scales, n)
    total_text_len = x_positions[end] + gc.extents[end].hadvance * scales[end][1]

    working_path = iszero(_offset) ? pixel_path : _offset_polyline(pixel_path, _offset)
    total_path_len = _polyline_arc_length(working_path)

    frac = _parse_align(align)
    sample_fn = s -> _sample_polyline_at(working_path, s)
    pos, rot, chars = _place_glyphs_on_path(
        x_positions, text_chars, sample_fn, frac, total_text_len, total_path_len;
        y_offsets,
    )

    # Wrap each placed glyph as a single-char RichText with its per-glyph style.
    # This lets the child text! handle font/color/size natively per block.
    m = length(pos)
    colors_vec = collect_vector(gc.colors, n)
    fonts_vec = collect_vector(gc.fonts, n)
    scales_vec = collect_vector(gc.scales, n)
    rt_chars = Union{String, RichText}[
        rich(string(placed_chars[j]); color = colors_vec[j], font = fonts_vec[j], fontsize = scales_vec[j][1])
            for j in 1:m
    ]
    return (pos, rot, rt_chars, nothing)
end

# --- RichText on BezierPath ---------------------------------------------------

function _pathtext_layout(pixel_bp::BezierPath, text::RichText, fontsize, font, fonts, align, offset)
    _fontsize = Float32(to_fontsize(fontsize))
    _font = to_font(fonts, font)
    _offset = Float64(offset)

    gc = layout_text(text, _fontsize, _font, fonts, (:left, :baseline), to_rotation(0), :left, 1.0, RGBAf(0, 0, 0, 1))
    n = length(gc.glyphs)
    n == 0 && return _empty_layout()

    text_chars = _richtext_chars(text)
    length(text_chars) != n && error("RichText character count ($(length(text_chars))) does not match glyph count ($n).")

    x_positions = Float32[gc.origins[i][1] for i in 1:n]
    y_offsets = Float32[gc.origins[i][2] for i in 1:n]
    scales = collect_vector(gc.scales, n)
    total_text_len = x_positions[end] + gc.extents[end].hadvance * scales[end][1]

    segs = _prepare_bezierpath(pixel_bp, _offset)
    isempty(segs) && return _empty_layout()
    total_path_len = Float32(_total_arclen(segs))

    frac = _parse_align(align)
    sample_fn = s -> _sample_bezierpath_at(segs, s, _offset)
    pos, rot, placed_chars = _place_glyphs_on_path(
        x_positions, text_chars, sample_fn, frac, total_text_len, total_path_len;
        y_offsets,
    )

    m = length(pos)
    colors_vec = collect_vector(gc.colors, n)
    fonts_vec = collect_vector(gc.fonts, n)
    scales_vec = collect_vector(gc.scales, n)
    rt_chars = Union{String, RichText}[
        rich(string(placed_chars[j]); color = colors_vec[j], font = fonts_vec[j], fontsize = scales_vec[j][1])
            for j in 1:m
    ]
    return (pos, rot, rt_chars, nothing)
end

# ==============================================================================
# plot!
# ==============================================================================

function _validate_pathtext(text::AbstractString)
    occursin('\n', text) && throw(ArgumentError("`pathtext` does not support newlines in `text`."))
    return text
end

function _validate_pathtext(text::RichText)
    _richtext_chars(text) # walks the tree; throws if newline found
    return text
end

function plot!(p::PathText)
    map!(p.attributes, [:text], :_pathtext_validated_text) do text
        return _validate_pathtext(text)
    end

    # Extract geometric control points from whatever path type we have.
    map!(p.attributes, [:path], :_pathtext_control_points) do path
        return _extract_control_points(path)
    end

    # Project control points from input space to pixel space.
    register_projected_positions!(
        p, Point2f;
        input_name = :_pathtext_control_points,
        output_name = :_pathtext_control_points_pixel,
        input_space = :space,
        output_space = :pixel,
    )

    # Reassemble projected path (BezierPath or polyline).
    map!(p.attributes, [:_pathtext_control_points_pixel, :path], :_pathtext_pixel_path) do px_pts, orig_path
        return _reassemble_path(px_pts, orig_path)
    end

    # Compute per-character positions, rotations, chars, and optional per-glyph styles.
    map!(
        p.attributes,
        [:_pathtext_pixel_path, :_pathtext_validated_text, :fontsize, :font, :fonts, :align, :offset],
        [:_pathtext_positions, :_pathtext_rotations, :_pathtext_chars, :_pathtext_glyph_styles]
    ) do pixel_path, text, fontsize, font, fonts, align, offset
        return _pathtext_layout(pixel_path, text, fontsize, font, fonts, align, offset)
    end

    text!(
        p,
        p._pathtext_positions;
        text = p._pathtext_chars,
        rotation = p._pathtext_rotations,
        fontsize = p.fontsize,
        font = p.font,
        fonts = p.fonts,
        color = p.color,
        strokecolor = p.strokecolor,
        strokewidth = p.strokewidth,
        colormap = p.colormap,
        colorscale = p.colorscale,
        colorrange = p.colorrange,
        lowclip = p.lowclip,
        highclip = p.highclip,
        nan_color = p.nan_color,
        alpha = p.alpha,
        visible = p.visible,
        transparency = p.transparency,
        overdraw = p.overdraw,
        inspectable = p.inspectable,
        align = (:left, :baseline),
        space = :pixel,
        markerspace = :pixel,
        transformation = :nothing,
    )

    return p
end

function data_limits(p::PathText)
    if p.space[] === :data
        path = p.path[]
        if path isa BezierPath
            return Rect3d(bbox(path))
        elseif path isa AbstractVector && !isempty(path)
            return Rect3d(Rect2d(path))
        end
    end
    return Rect3d(Point3d(NaN), Vec3d(NaN))
end
boundingbox(p::PathText, space::Symbol = :data) = apply_transform_and_model(p, data_limits(p))
