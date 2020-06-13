# TODO move this?

struct Pattern{T, D} <: AbstractArray{T, D}
    img::Array{T, D}
end

function Pattern(
        mask::Array{T, 2}, color1, color2; kwargs...
    ) where {T <: AbstractFloat}
    # to color
    img = map(x -> to_color(color1) * x + to_color(color2) * (1-x), mask)
    Pattern(img)
end

# Pattern from String/Character
Pattern(style::String; kwargs...) = Pattern(style[1]; kwargs...)
function Pattern(
        style::Char = '/';
        color1 = RGBA(0, 0, 0, 1), color2=RGBA(1, 1, 1, 0), kwargs...
    )
    mask = if style == '/'
        LineMask(direction=Vec2f0(1); kwargs...)
    elseif style == '\\'
        LineMask(direction=Vec2f0(1, -1); kwargs...)
    elseif style == '-'
        LineMask(direction=Vec2f0(1, 0); kwargs...)
    elseif style == '|'
        LineMask(direction=Vec2f0(0, 1); kwargs...)
    elseif style == 'x'
        mask1 = LineMask(direction=Vec2f0(1); kwargs...)
        mask2 = LineMask(direction=Vec2f0(1, -1); kwargs...)
        map((x, y) -> clamp(x+y, 0, 1), mask1, mask2)
    elseif style == '+'
        mask1 = LineMask(direction=Vec2f0(1, 0); kwargs...)
        mask2 = LineMask(direction=Vec2f0(0, 1); kwargs...)
        map((x, y) -> clamp(x+y, 0, 1), mask1, mask2)
    else
        LineMask(; kwargs...)
    end
    Pattern(mask, color1, color2; kwargs...)
end

# Pattern with line in some direction
# the line should be periodic in within a box of size tilesize
function LineMask(;
        direction = Vec2f0(1), width = 2f0, tilesize = (10,10),
        shift=Vec2f0(0), kwargs...
    ) where {CT <: Colorant}

    mask = zeros(tilesize...)
    width -= 1 # take away center
    if abs(direction[1]) < abs(direction[2])
        # m = dx / dy; x = m * (y-1) + 1
        m = direction[1] / direction[2]
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
        m = direction[2] / direction[1]
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

    # TODO better blurring
    mask
end
