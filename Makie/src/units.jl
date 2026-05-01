#########
## Move attributes into certain unit spaces
# Future:
# Every plot / scene axis will hold a space attribute
# with the following allowed (per axis):
# (may not actually be a type hierarchy, just here for illustration)
# abstract type DataSpace end
# abstract type DisplaySpace end
# #...
# struct Log <: DataSpace end
# struct Polar <: DataSpace end
# struct GeoProjection <: DataSpace end
# # and more!
# #...
# struct Pixel <: DisplaySpace end
# struct DPI <: DisplaySpace end
# struct DIP <: DisplaySpace end
#########

function to_screen(scene::Scene, mpos)
    return Point2f(mpos) .- Point2f(minimum(viewport(scene)[]))
end

number(x::Unit) = x.value
number(x) = x

Base.:(*)(a::T, b::Number) where {T <: Unit} = basetype(T)(number(a) * b)
Base.:(*)(a::Number, b::T) where {T <: Unit} = basetype(T)(a * number(b))
Base.convert(::Type{T}, x::Unit) where {T <: Number} = convert(T, number(x))

"""
Unit space of the scene it's displayed on.
Also referred to as data units
"""
struct SceneSpace{T} <: Unit{T}
    value::T
end

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
basetype(::Type{<:DeviceIndependentPixel}) = DeviceIndependentPixel

const DIP = DeviceIndependentPixel
const dip = DIP(1)
const dip_in_millimeter = 0.15875
const dip_in_inch = 1 / 160

basetype(::Type{<:Pixel}) = Pixel

"""
Millimeter on screen. This unit respects the dimension and pixel density of the screen
to represent millimeters on the screen. This is the must use unit for layouting,
that needs to look the same on all kind of screens. Similar as with the `Pixel` unit,
a camera can change the actually displayed dimensions of any object using the millimeter unit.
"""
struct Millimeter{T} <: Unit{T}
    value::T
end
basetype(::Type{<:Millimeter}) = Millimeter
const mm = Millimeter(1)

Base.show(io::IO, x::DIP) = print(io, number(x), "dip")
Base.:(*)(a::Number, b::DIP) = DIP(a * number(b))

dpi(scene::Scene) = events(scene).window_dpi[]

function pixel_per_mm(scene)
    return dpi(scene) ./ 25.4
end

function Base.convert(::Type{<:Millimeter}, scene::Scene, x::SceneSpace)
    pixel = convert(Pixel, scene, x)
    return Millimeter(number(pixel_per_mm(scene) / pixel))
end

function Base.convert(::Type{<:SceneSpace}, scene::Scene, x::DIP)
    mm = convert(Millimeter, scene, x)
    return SceneSpace(number(mm * dip_in_millimeter))
end

function Base.convert(::Type{<:Millimeter}, scene::Scene, x::DIP)
    return Millimeter(number(x * dip_in_millimeter))
end

function Base.convert(::Type{<:Pixel}, scene::Scene, x::Millimeter)
    px = pixel_per_mm(scene) * x
    return Pixel(number(px))
end

function Base.convert(::Type{<:Pixel}, scene::Scene, x::DIP)
    inch = (x * dip_in_inch)
    dots = dpi(scene) * inch
    return Pixel(number(dots))
end

function Base.convert(::Type{<:SceneSpace}, scene::Scene, x::Vec{2, <:Pixel})
    zero = to_world(scene, to_screen(scene, Point2f(0)))
    s = to_world(scene, to_screen(scene, number.(Point(x))))
    return SceneSpace.(Vec(s .- zero))
end

function Base.convert(::Type{<:SceneSpace}, scene::Scene, x::Pixel)
    zero = to_world(scene, to_screen(scene, Point2f(0)))
    s = to_world(scene, to_screen(scene, Point2f(number(x), 0.0)))
    return SceneSpace(norm(s .- zero))
end

function Base.convert(::Type{<:SceneSpace}, scene::Scene, x::Millimeter)
    pix = convert(Pixel, scene, x)
    return (SceneSpace, mm)
end

to_2d_scale(x::Pixel) = Vec2f(number(x))
to_2d_scale(x::Tuple{<:Pixel, <:Pixel}) = Vec2f(number.(x))
to_2d_scale(x::VecTypes{2, <:Pixel}) = Vec2f(number.(x))

# Exports of units
export px

########################################

"""
    spaces()

Returns the currently available `space` values:
- `:data`: Corresponds to the space defined by the parent scenes camera.
- `:pixel`: Corresponds to a space using pixel units as defined by the parent scenes viewport.
- `:relative`: Corresponds to a space where (x, y, z) is normalized to a 0..1 range (within the parent scenes viewport).
- `:clip`: Corresponds to a -1..1 normalized space (within the parent scenes viewport).

Note that `space` only affects projections, i.e. it has no effect on plot transformations.
As such `:data` space does not correspond to the data passed to a plot, but the data after transformations are applied.

`space` may also be set to a tuple of these symbols to use a different space per
axis, e.g. `space = (:data, :relative)` for an x value in data space and a y
value in relative space. Axes not covered by the tuple default to `:data`, so
`(:data, :relative)` is equivalent to `(:data, :relative, :data)`. Mixed-space
projections only consider the diagonal entries of each underlying projection
matrix and therefore expect orthographic, axis-aligned cameras (the typical 2D
`Axis`).
"""
spaces() = (:data, :pixel, :relative, :clip)

is_data_space(p::Plot) = is_data_space(to_value(get(p, :space, :data)))
is_pixel_space(p::Plot) = is_pixel_space(to_value(get(p, :space, :data)))
is_relative_space(p::Plot) = is_relative_space(to_value(get(p, :space, :data)))
is_clip_space(p::Plot) = is_clip_space(to_value(get(p, :space, :data)))

is_data_space(space::Observable) = is_data_space(space[])
is_pixel_space(space::Observable) = is_pixel_space(space[])
is_relative_space(space::Observable) = is_relative_space(space[])
is_clip_space(space::Observable) = is_clip_space(space[])

is_data_space(space::Symbol) = space === :data
is_pixel_space(space::Symbol) = space === :pixel
is_relative_space(space::Symbol) = space === :relative
is_clip_space(space::Symbol) = space === :clip

# Tuple/per-axis space: true only when every axis matches.
is_data_space(space::Tuple) = !isempty(space) && all(is_data_space, space)
is_pixel_space(space::Tuple) = !isempty(space) && all(is_pixel_space, space)
is_relative_space(space::Tuple) = !isempty(space) && all(is_relative_space, space)
is_clip_space(space::Tuple) = !isempty(space) && all(is_clip_space, space)

"""
    is_homogeneous_space(space)

Returns `true` if `space` uses the same space on every axis, `false` for a
mixed per-axis tuple.
"""
is_homogeneous_space(space::Symbol) = true
is_homogeneous_space(space::Tuple) = isempty(space) || all(==(first(space)), space)
is_homogeneous_space(space::Observable) = is_homogeneous_space(space[])
is_homogeneous_space(p::Plot) = is_homogeneous_space(to_value(get(p, :space, :data)))

"""
    axis_space(space, dim::Int)

Returns the space symbol used on axis `dim`. For homogeneous (Symbol) spaces
this is the space itself; for tuple spaces it is `space[dim]`, or `:data` if
`dim` exceeds the tuple length.
"""
axis_space(space::Symbol, ::Int) = space
axis_space(space::NTuple{N, Symbol}, dim::Int) where {N} = dim <= N ? space[dim] : :data
axis_space(space::Observable, dim::Int) = axis_space(space[], dim)
axis_space(p::Plot, dim::Int) = axis_space(to_value(get(p, :space, :data)), dim)

"""
    is_axis_data_space(space, dim::Int)

Returns whether axis `dim` of `space` is `:data` space (i.e. participates in
data limits / autolimits).
"""
is_axis_data_space(space, dim::Int) = is_data_space(axis_space(space, dim))
is_axis_data_space(p::Plot, dim::Int) = is_data_space(axis_space(p, dim))

# Pad a 1-3 element space tuple to NTuple{3,Symbol}, defaulting unspecified axes to :data.
_padded_space_tuple(s::Symbol) = (s, s, s)
function _padded_space_tuple(t::Tuple)
    isempty(t) && error("`space` tuple must not be empty.")
    return ntuple(i -> i <= length(t) ? t[i]::Symbol : :data, 3)
end
