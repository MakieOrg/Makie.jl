using Cairo

function rgbatuple(c::Colorant)
    rgba = RGBA(c)
    return (red(rgba), green(rgba), blue(rgba), alpha(rgba))
end

to_2d_scale(x::Number) = Vec2f(x)
to_2d_scale(x::Vec) = convert(Vec2f, x)

include("screen.jl")
include("drawing.jl")
