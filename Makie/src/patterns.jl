"""
    AbstractPattern{T} <: AbstractArray{T, 2}

`AbstractPatterns` are image-like array types which can be used to color
plottable objects. There are currently two subtypes: `LinePattern` and
`ImagePattern`. Any abstract pattern must implement the `to_image(pat)`
function, which must return a `Matrix{<: AbstractRGB}`.
"""
abstract type AbstractPattern{T} <: AbstractArray{T, 2} end

# for print_array because we defined it as <: Base.AbstractArray
function Base.show(io::IO, p::AbstractPattern)
    return print(io, typeof(p), "()")
end

function Base.show(io::IO, ::MIME"text/plain", p::AbstractPattern)
    return print(io, typeof(p), "()")
end

struct ImagePattern <: AbstractPattern{RGBAf}
    img::Matrix{RGBAf}
end

Base.size(pattern::ImagePattern) = size(pattern.img)

"""
    Pattern(image)
    Pattern(mask[; color1, color2])

Creates an `ImagePattern` from an `image` (a matrix of colors) or a `mask`
(a matrix of real numbers). The pattern can be passed as a `color` to a plot to
texture it. If a `mask` is passed, one can specify to colors between which colors are
interpolated.
"""
Pattern(img::Array{<:Colorant, 2}) = ImagePattern(img)

function Pattern(mask::Matrix{<:Real}; color1 = RGBAf(0, 0, 0, 1), color2 = RGBAf(1, 1, 1, 0))
    img = map(x -> to_color(color1) * x + to_color(color2) * (1 - x), mask)
    return ImagePattern(img)
end

to_image(p::ImagePattern) = p.img

struct LinePattern <: AbstractPattern{RGBAf}
    dirs::Vector{Vec2f}
    widths::Vector{Float32}
    origins::Vector{Vec2f}

    tilesize::NTuple{2, Int}
    colors::NTuple{2, RGBAf}
end

Base.size(pattern::LinePattern) = pattern.tilesize


"""
    LinePattern([; kwargs...])

Creates a `LinePattern` for the given keyword arguments:
- `direction = Vec2f(1)`: One or multiple `::VecTypes{2}` setting the direction of one or multiple lines.
- `width = 2f0`: The width of the line(s).
- `tilesize = (10, 10)`: The size of the image on which the line is drawn. This should be
compatible with the direction, i.e. the line pattern should be continuous when placing
tiles next to each other. This effectively controls the gap between lines.
- `origin = Vec2f(0)`: Sets the starting point for the line.
- `linecolor`: The color with which the line is replaced.
- `backgroundcolor`: The background color.
"""
function LinePattern(;
        direction = Vec2f(1), width = 2.0f0, tilesize = (10, 10), origin = Vec2f(0),
        linecolor = RGBAf(0, 0, 0, 1), backgroundcolor = RGBAf(1, 1, 1, 0),
        background_color = nothing, shift = nothing
    )
    if !isnothing(background_color)
        @warn "LinePattern(background_color = ...) has been deprecated in favor of LinePattern(backgroundcolor = ...)"
        backgroundcolor = background_color
    end
    if !isnothing(shift)
        @warn "LinePattern(shift = ...) has been deprecated in favor of LinePattern(origin = ...)"
        origin = shift
    end

    N1 = ifelse(direction isa Vector, length(direction), 1)
    N2 = ifelse(width isa Vector, length(width), 1)
    N3 = ifelse(origin isa Vector, length(origin), 1)
    N = max(N1, N2, N3)
    if !((N == N1 || N1 == 1) && (N == N2 || N2 == 1) && (N == N3 || N3 == 1))
        error("If direction, origin and/or width is given as a Vector it must match the length of other Vectors.")
    end

    dirs = direction isa Vector ? direction : Vec2f[direction for _ in 1:N]
    widths = width isa Vector ? width : Float32[width for _ in 1:N]
    origins = origin isa Vector ? origin : Vec2f[origin for _ in 1:N]
    colors = (to_color(linecolor), to_color(backgroundcolor))

    return LinePattern(dirs, widths, origins, tilesize, colors)
end

"""
    Pattern(style::String = "/"; kwargs...)
    Pattern(style::Char = '/'; kwargs...)

Creates a line pattern based on the given argument. Available patterns are
`'/'`, `'\\'`, `'-'`, `'|'`, `'x'`, and `'+'`. All keyword arguments correspond
to the keyword arguments for `LinePattern`.
"""
Pattern(style::String; kwargs...) = Pattern(style[1]; kwargs...)
function Pattern(style::Char = '/'; kwargs...)
    return if style == '/'
        LinePattern(direction = Vec2f(1); kwargs...)
    elseif style == '\\'
        LinePattern(direction = Vec2f(1, -1); kwargs...)
    elseif style == '-'
        LinePattern(direction = Vec2f(1, 0); kwargs...)
    elseif style == '|'
        LinePattern(direction = Vec2f(0, 1); kwargs...)
    elseif style == 'x'
        LinePattern(direction = [Vec2f(1), Vec2f(1, -1)]; kwargs...)
    elseif style == '+'
        LinePattern(direction = [Vec2f(1, 0), Vec2f(0, 1)]; kwargs...)
    else
        throw(ArgumentError("Pattern('$style') not defined, use one of ['/', '\\', '-', '|', 'x', '+']"))
    end
end

function to_image(p::LinePattern)
    Nx, Ny = p.tilesize

    # positive distance outside, negative inside
    sdf = fill(Float32(Nx + Ny), Nx, Ny)
    for (dir, width, origin) in zip(p.dirs, p.widths, p.origins)
        normal = normalize(Vec2f(-dir[2], dir[1]))

        # Figure out maximum distance between periodic lines
        max_line_dist = min(abs(normal[1] * Nx), abs(normal[2] * Ny))
        # horizontal/vertical lines should repeat once per tile
        max_line_dist = ifelse(max_line_dist < 1, min(Nx, Ny), max_line_dist)

        for y in 1:Ny, x in 1:Nx
            # center on pixel with -0.5
            dist = dot(Point2f(x, y) - origin .- 0.5, normal)
            # shift distance by multiple of max_line_dist so that it is always
            # between -0.5max_line_dist and 0.5max_line_dist
            dist -= max_line_dist * div(dist + sign(dist) * 0.5max_line_dist, max_line_dist)
            sdf[x, y] = min(sdf[x, y], abs(dist) - 0.5width)
        end
    end

    AA_radius = 1 / sqrt(2)
    c1 = p.colors[1]; c2 = p.colors[2]
    # If both colors are at the same alpha we want to do: c1 * (1-f) + c2 * f
    # If c2 is at alpha = 0 we want: RGBAf(c1.rgb, c1.a * (1-f)) (or - f?)
    # If both have different nonzero alpha... what do we want then?
    c1 = ifelse(c1.alpha == 0, RGBAf(c2.r, c2.g, c2.b, 0), c1)
    c2 = ifelse(c2.alpha == 0, RGBAf(c1.r, c1.g, c1.b, 0), c2)
    return map(sdf) do dist
        f = Float32(clamp((dist + AA_radius) / (2 * AA_radius), 0, 1))
        return c1 * (1.0f0 - f) + c2 * f
    end
end


# Consider applying model[] here too, so that patterns move with translate too
function pattern_offset(projectionview::Mat4, resolution::Vec2, yflip = false)
    clip = projectionview * Point4f(0, 0, 0, 1)
    # clip space is -1..1, screen space 0..w so we need 0.5 prefactor
    maybe_flip = (1.0f0, ifelse(yflip, -1.0f0, 1.0f0))
    return 0.5f0 .* maybe_flip .* resolution .* clip[Vec(1, 2)] / clip[4]
end

function pattern_uv_transform(uv_transform, projectionview::Mat4, resolution::Vec2, pattern::AbstractPattern)
    origin = pattern_offset(projectionview, resolution ./ size(pattern))
    px_to_uv = Makie.uv_transform(-origin, Vec2f(1.0 ./ size(pattern)))

    if uv_transform === Makie.automatic
        uvt = convert_attribute(px_to_uv, Makie.key"uv_transform"())
    elseif uv_transform isa Vector
        uvt = map(T -> T * pv_to_uv, convert_attribute(uv_transform, Makie.key"uv_transform"()))
    else # Mat{2,3,Float32}
        uvt = convert_attribute(uv_transform, Makie.key"uv_transform"()) * px_to_uv
    end

    return uvt
end
