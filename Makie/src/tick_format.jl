# Tick number formatting for axes.
#
# This module vendors the small subset of Showoff.jl that Makie used to depend
# on, but emits a `RichText` superscript span directly for scientific notation
# rather than the unicode superscript glyphs (`⁻`, `⁵`, ...) Showoff produced.
# Makie's default font does not fully cover the unicode superscript block, so
# the rich-text form renders reliably across fonts.
#
# Underlying number formatting uses `Base.Ryu`, the same engine Showoff used.

# The hyphen used in negative-number strings is shorter than the dedicated
# minus sign in most fonts; the minus glyph looks more balanced with numbers,
# especially inside superscripts.
const MINUS_SIGN = "−" # −

# Smallest uniform precision (in decimal places) that captures all significant
# digits across `xs` when formatted in plain notation. Mirrors
# `Showoff.plain_precision_heuristic`.
function _plain_label_precision(xs)
    e10max = -(e10min = typemax(Int))
    for y in xs
        isfinite(y) || continue
        if isapprox(y, 0, atol = 1.0e-16)
            e10 = min(e10min, 0)
        else
            _, e10 = Base.Ryu.reduce_shortest(convert(Float32, y))
        end
        e10min = min(e10min, e10)
        e10max = max(e10max, e10)
    end
    return min(-e10min, -e10max + 16)
end

# Uniform precision (in fractional digits) for scientific notation across `xs`.
# Each value is normalized into `[1, 10)` (the "mantissa") and the plain-notation
# precision of those mantissas is the precision the scientific bases need.
# Showoff added an extra `+1` here to always show at least one decimal in
# scientific form, but that just pads `1.1×10⁻⁷` into `1.10×10⁻⁷`; we skip it.
function _scientific_label_precision(xs)
    ys = [
        x == 0.0 ? 0.0 : round(10.0^(z = log10(abs(Float64(x))); z - floor(z)); sigdigits = 15)
            for x in xs if isfinite(x)
    ]
    return _plain_label_precision(ys)
end

_replace_leading_hyphen(s::AbstractString) = startswith(s, '-') ? MINUS_SIGN * SubString(s, 2) : String(s)

_format_plain_label(x::AbstractFloat, precision::Integer) = _replace_leading_hyphen(Base.Ryu.writefixed(x, precision))

# Format `xs` as plain decimal strings with a uniform precision.
function format_ticks_plain(xs::AbstractArray{<:AbstractFloat})
    precision = _plain_label_precision(xs)
    return [_format_plain_label(x, precision) for x in xs]
end

# Fallback for non-float inputs (e.g. integer tick ranges): just stringify.
format_ticks_plain(xs::AbstractArray) = string.(xs)

# Split a Ryu scientific string like "1.500e-05" into (base, exponent), with
# the leading hyphen normalized to MINUS_SIGN. The fractional zeros that Ryu
# pads to reach `precision` are kept here; whether to strip them is decided
# after looking at all bases together so the labels stay visually consistent.
function _split_scientific(x::AbstractFloat, precision::Integer)
    s = Base.Ryu.writeexp(x, precision)
    e_idx = something(findfirst('e', s))
    base = SubString(s, 1, prevind(s, e_idx))
    exponent = parse(Int, SubString(s, nextind(s, e_idx)))
    return _replace_leading_hyphen(base), exponent
end

_strip_trailing_zeros(s::AbstractString) = '.' in s ? String(rstrip(rstrip(s, '0'), '.')) : String(s)

# True when `base` has no fractional part or its entire fractional part is `0`s
# (the padding Ryu adds to reach a uniform precision).
function _has_only_zero_fraction(base::AbstractString)
    dot_idx = findfirst('.', base)
    dot_idx === nothing && return true
    return all(==('0'), @view base[nextind(base, dot_idx):end])
end

function _scientific_rich(base::AbstractString, exponent::Integer)
    exp_str = exponent < 0 ? MINUS_SIGN * string(-exponent) : string(exponent)
    return rich(String(base), "×10", superscript(exp_str, offset = Vec2f(0.1f0, 0.0f0)))
end

# Decide whether `xs` should be displayed in plain or scientific notation. The
# threshold of 4 orders of magnitude matches Showoff's `:auto` behavior.
function _pick_label_style(xs)
    isempty(xs) && return :plain
    x_min, x_max = extrema(xs)
    return (x_max != x_min && abs(log10(x_max - x_min)) > 4) ? :scientific : :plain
end

# Format `xs` as tick labels, returning RichText for scientific notation and
# plain strings otherwise. This is the default tick formatter for linear axes.
function format_ticks_auto(xs::AbstractArray{<:AbstractFloat})
    _pick_label_style(xs) === :plain && return format_ticks_plain(xs)

    precision = _scientific_label_precision(xs)
    pairs = [iszero(x) ? nothing : _split_scientific(x, precision) for x in xs]

    # Only strip the fractional `.0…0` padding when every non-zero base
    # reduces to a whole number. Otherwise keep the padding so the bases stay
    # aligned (e.g. `1.50×10⁻⁵` and `2.00×10⁻⁵` rather than mixing
    # `1.5×10⁻⁵` with `2×10⁻⁵`).
    can_strip = all(p -> p === nothing || _has_only_zero_fraction(p[1]), pairs)

    return map(pairs) do p
        p === nothing && return "0"
        base, exponent = p
        base_clean = can_strip ? _strip_trailing_zeros(base) : base
        return _scientific_rich(base_clean, exponent)
    end
end

format_ticks_auto(xs::AbstractArray) = string.(xs)

# Scientific notation as a plain `Vector{String}` with unicode superscript
# glyphs. Used by `Formatters.scientific` (the public formatter wired into the
# old `Axis3D` recipe), which feeds tick strings into a `TextBuffer` that
# cannot consume `RichText`.
const _SUPERSCRIPT_DIGITS = ('⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹')

function _format_scientific_string_label(x::AbstractFloat, precision::Integer)
    iszero(x) && return "0"
    s = Base.Ryu.writeexp(x, precision)
    e_idx = something(findfirst('e', s))
    base = String(SubString(s, 1, prevind(s, e_idx)))
    exponent = parse(Int, SubString(s, nextind(s, e_idx)))
    io = IOBuffer()
    print(io, base, "×10")
    exponent < 0 && print(io, '⁻')
    for c in string(abs(exponent))
        print(io, _SUPERSCRIPT_DIGITS[c - '0' + 1])
    end
    return String(take!(io))
end

function format_ticks_scientific_string(xs::AbstractArray{<:AbstractFloat})
    precision = _scientific_label_precision(xs)
    return [_format_scientific_string_label(x, precision) for x in xs]
end
