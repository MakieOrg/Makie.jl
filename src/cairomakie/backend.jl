using Cairo

function rgbatuple(c::AbstractRGB)
    return (red(c), green(c), blue(c), 1.0)
end

function rgbatuple(c::RGBA)
    return (red(c), green(c), blue(c), alpha(c))
end

to_2d_scale(x::Number) = Vec2f((x, x))
to_2d_scale(x::Vec) = Vec2f((x[1], x[2]))

include("screen.jl")
include("drawing.jl")
