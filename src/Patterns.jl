# TODO move this?

abstract type AbstractPattern{T, D} <: AbstractArray{T, D} end

# TODO do we need all of those?
function show(io::IO, mime, p::AbstractPattern)
    println(io, typeof(p))
    show(io, mime, image(p))
end
display(x, p::AbstractPattern) = display(x, image(p))
display(p::AbstractPattern) = display(image(p))



struct ImagePattern{T, D} <: AbstractPattern{T, D}
    img::Array{T, D}
    ImagePattern(img::Array{T, 2}) where {T <: Colorant} = new{T, 2}(img)
end

Pattern(img::Array{<: Colorant, 2}) = ImagePattern(img)

function Pattern(mask::Array{<: Real, 2}; color1=RGBA(0,0,0,1), color2=RGBA(1,1,1,0))
    img = map(x -> to_color(color1) * x + to_color(color2) * (1-x), mask)
    ImagePattern(img)
end

image(p::ImagePattern) = p.img



struct LinePattern{T, D} <: AbstractPattern{T, D}
    dirs::Vector{Vec2}
    widths::Vector{AbstractFloat}
    shifts::Vector{Vec2}

    tilesize::NTuple{2, Integer}
    colors::NTuple{2, T}
end

function LinePattern(;
        direction = Vec2f0(1), width = 2f0, tilesize = (10,10),
        shift = map(w -> Vec2f0(0.5 - 0.5(w%2)), width),
        color1 = RGBA(0,0,0,1), color2 = RGBA(1,1,1,0)
    )
    N = 1
    direction isa Vector{<:Vec2} && (N = length(direction))
    width isa Vector && (length(width) > N) && (N = length(width))
    shift isa Vector{<:Vec2} && (length(shift) > N) && (N = length(shift))

    dirs = direction isa Vector{<:Vec2} ? direction : [direction for _ in 1:N]
    widths = width isa Vector ? width : [width for _ in 1:N]
    shifts = shift isa Vector{<:Vec2} ? shift : [shift for _ in 1:N]
    colors = (to_color(color1), to_color(color2))

    LinePattern{typeof(colors[1]), 2}(dirs, widths, shifts, tilesize, colors)
end

# Pattern from String/Character
Pattern(style::String; kwargs...) = Pattern(style[1]; kwargs...)
function Pattern(style::Char = '/'; kwargs...)
    if style == '/'
        LinePattern(direction=Vec2f0(1); kwargs...)
    elseif style == '\\'
        LinePattern(direction=Vec2f0(1, -1); kwargs...)
    elseif style == '-'
        LinePattern(direction=Vec2f0(1, 0); kwargs...)
    elseif style == '|'
        LinePattern(direction=Vec2f0(0, 1); kwargs...)
    elseif style == 'x'
        LinePattern(direction=[Vec2f0(1), Vec2f0(1, -1)]; kwargs...)
    elseif style == '+'
        LinePattern(direction=[Vec2f0(1, 0), Vec2f0(0, 1)]; kwargs...)
    else
        LinePattern(; kwargs...)
    end
end


function image(p::LinePattern)
    tilesize = p.tilesize
    full_mask = zeros(tilesize...)
    for (dir, width, shift) in zip(p.dirs, p.widths, p.shifts)
        mask = zeros(tilesize...)
        width -= 1 # take away center
        if abs(dir[1]) < abs(dir[2])
            # m = dx / dy; x = m * (y-1) + 1
            m = dir[1] / dir[2]
            for y in 1:tilesize[2]
                cx = m * (y-shift[2]) + shift[1]
                r = floor(Int64, cx-0.5width):ceil(Int64, cx+0.5width)
                for x in r[2:end-1]
                    mask[mod1(x, tilesize[1]), y] = 1.0
                end
                mask[mod1(r[1], tilesize[1]), y] = 1 - abs(cx-0.5width - r[1])
                mask[mod1(r[end], tilesize[1]), y] = 1 - abs(cx+0.5width - r[end])
            end
        else
            # m = dy / dx; y = m * (x-1) + 1
            m = dir[2] / dir[1]
            for x in 1:tilesize[1]
                cy = m * (x-shift[1]) + shift[2]
                r = floor(Int64, cy-0.5width):ceil(Int64, cy+0.5width)
                for y in r[2:end-1]
                    mask[x, mod1(y, tilesize[2])] = 1.0
                end
                mask[x, mod1(r[1], tilesize[2])] = 1 - abs(cy-0.5width - r[1])
                mask[x, mod1(r[end], tilesize[2])] = 1 - abs(cy+0.5width - r[end])
            end
        end
        full_mask .+= mask
    end

    return map(full_mask) do x
        p.colors[1] * clamp(x, 0, 1) + p.colors[2] * (1-clamp(x, 0, 1))
    end
end
