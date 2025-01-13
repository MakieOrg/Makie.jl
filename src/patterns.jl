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
    print(io, typeof(p))
end

function Base.show(io::IO, ::MIME"text/plain", p::AbstractPattern)
    print(io, typeof(p))
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
Pattern(img::Array{<: Colorant, 2}) = ImagePattern(img)

function Pattern(mask::Matrix{<: Real}; color1=RGBAf(0,0,0,1), color2=RGBAf(1,1,1,0))
    img = map(x -> to_color(color1) * x + to_color(color2) * (1-x), mask)
    return ImagePattern(img)
end

to_image(p::ImagePattern) = p.img

struct LinePattern <: AbstractPattern{RGBAf}
    dirs::Vector{Vec2f}
    widths::Vector{Float32}
    shifts::Vector{Vec2f}

    tilesize::NTuple{2, Int}
    colors::NTuple{2, RGBAf}
end

Base.size(pattern::LinePattern) = pattern.tilesize


"""
    LinePattern([; kwargs...])

Creates a `LinePattern` for the given keyword arguments:
- `direction`: The direction of the line.
- `width`: The width of the line
- `tilesize`: The size of the image on which the line is drawn. This should be
compatible with the direction.
- `shift`: Sets the starting point for the line.
- `linecolor`: The color with which the line is replaced.
- `background_color`:: The background color.

Multiple `direction`s, `width`s and `shift`s can also be given to create more
complex patterns, e.g. a cross-hatching pattern.
"""
function LinePattern(;
        direction = Vec2f(1), width = 2f0, tilesize = (10,10),
        shift = map(w -> Vec2f(0.5 - 0.5(w%2)), width),
        linecolor = RGBAf(0,0,0,1), backgroundcolor = RGBAf(1,1,1,0)
    )
    N = 1
    direction isa Vector{<:Vec2} && (N = length(direction))
    width isa Vector && (length(width) > N) && (N = length(width))
    shift isa Vector{<:Vec2} && (length(shift) > N) && (N = length(shift))

    dirs = direction isa Vector{<:Vec2} ? direction : Vec2f[direction for _ in 1:N]
    widths = width isa Vector ? width : Float32[width for _ in 1:N]
    shifts = shift isa Vector{<:Vec2} ? shift : Vec2f[shift for _ in 1:N]
    colors = (to_color(linecolor), to_color(backgroundcolor))

    return LinePattern(dirs, widths, shifts, tilesize, colors)
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
    if style == '/'
        LinePattern(direction=Vec2f(1); kwargs...)
    elseif style == '\\'
        LinePattern(direction=Vec2f(1, -1); kwargs...)
    elseif style == '-'
        LinePattern(direction=Vec2f(1, 0); kwargs...)
    elseif style == '|'
        LinePattern(direction=Vec2f(0, 1); kwargs...)
    elseif style == 'x'
        LinePattern(direction=[Vec2f(1), Vec2f(1, -1)]; kwargs...)
    elseif style == '+'
        LinePattern(direction=[Vec2f(1, 0), Vec2f(0, 1)]; kwargs...)
    else
        throw(ArgumentError("Pattern('$style') not defined, use one of ['/', '\\', '-', '|', 'x', '+']"))
    end
end

function to_image(p::LinePattern)
    Nx, Ny = p.tilesize

    # positive distance outside, negative inside
    sdf = fill(Float32(Nx + Ny), Nx, Ny)
    for (dir, width, shift) in zip(p.dirs, p.widths, p.shifts)

        origin = shift
        normal = Vec2f(-dir[2], dir[1])
        shift_distances = [abs(dot(v, normal)) for v in [Vec2f(Nx, 0), Vec2f(0, Ny)]]
        for y in 1:Ny, x in 1:Nx
            dist = dot(Point2f(x, y) - origin, normal)
            dist = min(abs(dist), abs(abs(dist) - shift_distances[1]), abs(abs(dist) - shift_distances[2]))
            sdf[x, y] = min(sdf[x, y], dist - 0.5width)
        end
    end

    AA_radius = 1/sqrt(2)
    c1 = p.colors[1]; c2 = p.colors[2]
    # If both colors are at the same alpha we want to do: c1 * (1-f) + c2 * f
    # If c2 is at alpha = 0 we want: RGBAf(c1.rgb, c1.a * (1-f)) (or - f?)
    # If both have different nonzero alpha... what do we want then?
    c1 = ifelse(c1.alpha == 0, RGBAf(c2.r, c2.g, c2.b, 0), c1)
    c2 = ifelse(c2.alpha == 0, RGBAf(c1.r, c1.g, c1.b, 0), c2)
    return map(sdf) do dist
        f = Float32(clamp((dist + AA_radius) / (2 * AA_radius), 0, 1))
        return c1 * (1f0 - f) + c2 * f
    end
end


# Consider applying model[] here too, so that patterns move with translate too
function pattern_offset(projectionview::Mat4, resolution::Vec2)
    clip = projectionview[] * Point4f(0,0,0,1)
    return (-0.5f0, 0.5f0) .* resolution .* clip[Vec(1,2)] / clip[4]
    return Mat{2, 3, Float32}(1,0, 0,1, o[1], o[2])
end

function pattern_uv_transform(uv_transform, projectionview::Mat4, resolution::Vec2, pattern::AbstractPattern)
    origin = pattern_offset(projectionview, resolution)
    px_to_uv = Makie.uv_transform(-origin, Vec2f(1.0 ./ size(pattern)))

    if uv_transform === Makie.automatic
        return convert_attribute(px_to_uv, Makie.key"uv_transform"())
    elseif uv_transform isa Vector
        return map(T  -> T * pv_to_uv, convert_attribute(uv_transform, Makie.key"uv_transform"()))
    else # Mat{2,3,Float32}
        return convert_attribute(uv_transform, Makie.key"uv_transform"()) * px_to_uv
    end
end