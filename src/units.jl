using AbstractNumbers
import AbstractNumbers: number, basetype

function to_screen(scene::Scene, mpos)
    return Point2f0(mpos) .- Point2f0(minimum(pixelarea(scene)[]))
end

abstract type Unit{T} <: AbstractNumbers.AbstractNumber{T} end

number(x::Unit) = x.value


"""
Unit space of the scene it's displayed on.
Also referred to as data units
"""
struct SceneSpace{T} <: Unit{T}
    value::T
end
basetype(::Type{<: SceneSpace}) = SceneSpace

"""
Unit is relative to bounding frame.
E.g. if the area is IRect(0, 0, 100, 100)
Point(0.5rel, 0.5rel) == Point(50, 50)
"""
struct Relative{T <: Number} <: Unit{T}
    value::T
end
basetype(::Type{<: Relative}) = Relative
const rel = Relative(1)

"""
https://en.wikipedia.org/wiki/Device-independent_pixel
A device-independent pixel (also: density-independent pixel, dip, dp) is a
physical unit of measurement based on a coordinate system held by a
computer and represents an abstraction of a pixel for use by an
application that an underlying system then converts to physical pixels.
"""
struct DeviceIndependentPixel{T <: Number} <: Unit{T}
    value::T
end
const DIP = DeviceIndependentPixel
const dip = DIP(1)
const dip_in_millimeter = 0.15875
const dip_in_inch = 1/160

basetype(::Type{<: DIP}) = DIP

"""
Unit in pixels on screen.
This one is a bit tricky, since it refers to a static attribute (pixels on screen don't change)
but since every visual is attached to a camera, the exact scale might change.
So in the end, this is just relative to some normed camera - the value on screen, depending on the camera,
will not actually sit on those pixels. Only camera that guarantees the correct mapping is the
`:pixel` camera type.
"""
struct Pixel{T} <: Unit{T}
    value::T
end
basetype(::Type{<: Pixel}) = Pixel
(::Type{Pixel{T}})(x::Pixel{T}) where T = x
const px = Pixel(1)

"""
Millimeter on screen. This unit respects the dimension and pixel density of the screen
to represent millimeters on the screen. This is the must use unit for layouting,
that needs to look the same on all kind of screens. Similar as with the [`Pixel`](@ref) unit,
a camera can change the actually displayed dimensions of any object using the millimeter unit.
"""
struct Millimeter{T} <: Unit{T}
    value::T
end
basetype(::Type{<: Millimeter}) = Millimeter
const mm = Millimeter(1)


Base.show(io::IO, x::DIP) = print(io, number(x), "dip")
Base.:(*)(a::Number, b::DIP) = DIP(a * number(b))

dpi(scene::Scene) = events(scene).window_dpi[]


function pixel_per_mm(scene)
    dpi(scene) ./ 25.4
end

function Base.convert(::Type{<: Millimeter}, scene::Scene, x::SceneSpace)
    pixel = convert(Pixel, scene, x)
    Millimeter(number(pixel_per_mm(scene) / pixel))
end

function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::Relative{T}) where T
    rel = maximum(widths(scene_limits(scene)[])) .* number(x)
    SceneSpace(rel)
end
function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::Point{2, Relative{T}}) where T
    idx = Vec(1, 2)
    lims = scene_limits(scene)
    rel = widths(lims)[idx] .* number.(x)
    SceneSpace(origin(lims)[idx] .+ rel)
end

function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::DIP)
    mm = convert(Millimeter, scene, x)
    SceneSpace(number(mm * dip_in_millimeter))
end

function Base.convert(::Type{<: Millimeter}, scene::Scene, x::DIP)
    Millimeter(number(x * dip_in_millimeter))
end


function Base.convert(::Type{<: Pixel}, scene::Scene, x::Millimeter)
    px = pixel_per_mm(scene) * x
    Pixel(number(px))
end
function Base.convert(::Type{<: Pixel}, scene::Scene, x::DIP)
    inch = (x * dip_in_inch)
    dots = dpi(scene) * inch
    Pixel(number(dots))
end
# function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::DIP)
#     px = convert(Pixel, scene, x)
#     convert(SceneSpace, scene, px)
# end

# function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::Point{2, <: Pixel})
#     s = to_world(scene, to_screen(scene, number.(x)))
#     SceneSpace.(s)
# end

function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::Vec{2, <:Pixel})
    zero = to_world(scene, to_screen(scene, Point2f0(0)))
    s = to_world(scene, to_screen(scene, number.(Point(x))))
    SceneSpace.(Vec(s .- zero))
end

function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::Pixel)
    zero = to_world(scene, to_screen(scene, Point2f0(0)))
    s = to_world(scene, to_screen(scene, Point2f0(number(x), 0.0)))
    SceneSpace(norm(s .- zero))
end

function Base.convert(::Type{<: SceneSpace}, scene::Scene, x::Millimeter)
    pix = convert(Pixel, scene, x)
    (SceneSpace, mm)
end
