"""
    pathtext(path; text = "", kwargs...)

Draw `text` along a path. `path` can be a `Vector{<: Point2}` (with optional
`NaN` separators between sub-paths) or a `BezierPath`.

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
- `align = :left`: Alignment along the path. One of `:left`, `:center`, `:right`.
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
    "Alignment of the text along the path. One of `:left`, `:center`, `:right`, or a `Real` fraction between 0 (start) and 1 (end) controlling the start position of the text relative to the slack between path and text length."
    align = :left
    "Perpendicular offset (in pixels) from the path. Positive values shift the text to the left of the path's direction of travel."
    offset = 0.0f0
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

conversion_trait(::Type{<:PathText}) = PointBased()

# -- arc-length utilities for polylines with NaN separators -------------------

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

# Perpendicular normal (90° CCW) of the segment p1->p2, or `nothing` if invalid.
function _seg_normal(p1, p2)
    (any(isnan, p1) || any(isnan, p2)) && return nothing
    v = p2 - p1
    len = norm(v)
    iszero(len) && return nothing
    return Vec2f(-v[2] / len, v[1] / len)
end

"""
Offset a polyline perpendicularly by `d` pixels (positive = left of path
direction). Uses the angle-bisector at interior vertices to keep the offset
polyline roughly at distance `d` from both incident segments. `NaN` separators
are preserved as separators between sub-paths, each offset independently.
"""
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
                # near reversal; avoid huge miter
                result[i] = Point2f(p) + d * Point2f(n_in)
            else
                avg = n_in + n_out
                result[i] = Point2f(p) + (d / denom) * Point2f(avg)
            end
        end
    end
    return result
end

"""
Sample a polyline at arc-length `s`, skipping over `NaN` separators between
sub-paths. Returns `(point, unit_tangent)` as `Point2f`, or `nothing` if `s` is
beyond the end of the path.
"""
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

# -- layout --------------------------------------------------------------------

function _pathtext_layout(pixel_path, text::AbstractString, fontsize, font, fonts, align, offset)
    positions = Point2f[]
    rotations = Quaternionf[]
    chars = String[]

    (isempty(text) || length(pixel_path) < 2) && return (positions, rotations, chars)

    _font = to_font(fonts, font)
    _fontsize = Float32(to_fontsize(fontsize))
    _offset = Float32(offset)

    # Offset the polyline first so the text is laid out along the already-offset
    # path. This keeps glyph spacing uniform on curves (without this the convex
    # side would stretch characters apart and the concave side would crowd them).
    working_path = iszero(_offset) ? pixel_path : _offset_polyline(pixel_path, _offset)

    text_chars = collect(text)
    advances = Float32[Float32(GlyphExtent(_font, c).hadvance) * _fontsize for c in text_chars]
    total_text_len = sum(advances; init = 0.0f0)
    total_path_len = _polyline_arc_length(working_path)

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
    start_s = frac * (total_path_len - total_text_len)

    s = start_s
    for (c, adv) in zip(text_chars, advances)
        sample = _sample_polyline_at(working_path, s)
        sample === nothing && break
        pt, tangent = sample
        # "up" of the text is perpendicular to tangent, rotated 90° CCW.
        normal = Point2f(-tangent[2], tangent[1])
        push!(positions, pt)
        push!(rotations, to_rotation(Vec2f(normal)))
        push!(chars, string(c))
        s += adv
    end

    return (positions, rotations, chars)
end

# -- plot! ---------------------------------------------------------------------

function plot!(p::PathText)
    map!(p.attributes, [:text], :_pathtext_validated_text) do text
        occursin('\n', text) && throw(ArgumentError("`pathtext` does not support newlines in `text`."))
        return String(text)
    end

    # Project the path from its input space (plot.space = :data or :pixel) to pixel space.
    # The result is reactive on camera / transform changes so text stays aligned on zoom/pan.
    register_projected_positions!(
        p, Point2f;
        input_name = :path,
        output_name = :_pathtext_path_pixel,
        input_space = :space,
        output_space = :pixel,
    )

    map!(
        p.attributes,
        [:_pathtext_path_pixel, :_pathtext_validated_text, :fontsize, :font, :fonts, :align, :offset],
        [:_pathtext_positions, :_pathtext_rotations, :_pathtext_chars]
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
    return if p.space[] === :data
        pts = p.path[]
        isempty(pts) ? Rect3d(Point3d(NaN), Vec3d(NaN)) : Rect3d(Rect2d(pts))
    else
        Rect3d(Point3d(NaN), Vec3d(NaN))
    end
end
boundingbox(p::PathText, space::Symbol = :data) = apply_transform_and_model(p, data_limits(p))
