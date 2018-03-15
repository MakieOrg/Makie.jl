module Units

using ..Makie: VecTypes
#=
Absolute is the default, so any number not having a unit is treated as absolute
struct Absolute{T}
    number::T
end
=#
using AbstractNumbers, StaticArrays, GeometryTypes

abstract type Unit{T} <: AbstractNumber{T} end

# We should always poison any calculation involving Units
promote_rule(::Type{<: Unit}, ::Type{T}) where T <: Number = Unit{T}
promote_rule(::Type{T}, ::Type{<: Unit}) where T <: Number = Unit{T}

# This is kind of wrong, since we need a scene for correct conversion.
# The correct version is to_absolute(scene, x::Unit)
Base.convert(::Type{Number}, x::Unit) = x.number

"""
Unit is relative to bounding frame.
E.g. if the area is IRect(0, 0, 100, 100)
Point(0.5rel, 0.5rel) == Point(50, 50)
"""
struct Relative{T <: Number} <: Unit{T}
    number::T
end
AbstractNumbers.basetype(::Type{<: Relative}) = Relative

"""
Unit is pixels on screen.
This one is a bit tricky, since it refers to a static attribute (pixels on screen don't change)
but since every visual is attached to a camera, the exact scale might change.
So in the end, this is just relative to some normed camera - the value on screen, depending on the camera,
will not actually sit on those pixels. Only camera that guarantees the correct mapping is the
`:pixel` camera type.
"""
struct Pixel{T} <: Unit{T}
    number::T
end
AbstractNumbers.basetype(::Type{<: Pixel}) = Pixel

"""
Millimeter on screen. This unit respects the dimension and pixel density of the screen
to represent millimeters on the screen. This is the must use unit for layouting,
that needs to look the same on all kind of screens. Similar as with the [`Pixel`](@ref) unit,
a camera can change the actually displayed dimensions of any object using the millimeter unit.
"""
struct Millimeter{T} <: Unit{T}
    number::T
end
AbstractNumbers.basetype(::Type{<: Millimeter}) = Millimeter

const rel = Relative(1)
const px = Pixel(1)
const mm = Millimeter(1)


"""
Default doesn't do anything
"""
function to_absolute(scene, x)
    x
end

function to_absolute(scene, x::AbstractVector{<: Millimeter})
    to_pixel(scene, x .* pixel_per_mm(scene))
end

function to_absolute(scene, x::Relative)
    x * minimum(widths(scene))
end

similar_vec(::Type{V}, T) where V <: StaticVector = similar_type(V, T)
similar_vec(::Type{NTuple{N, T}}, t) where {N, T} = NTuple{N, t}

function to_absolute(scene, x::V) where V <: VecTypes{N, T} where {N, T <: Relative}
    x .* convert(V, Relative.(widths(scene)))
end

function to_absolute(scene, x::VecTypes{N, <: Pixel}) where N
    vec3 = to_nd(x, Val{3}, 0)
    vec4 = to_nd(vec3, Val{4}, isa(x, Point) ? 1 : 0)
    projected = to_value(scene[:camera].projectionview) .* vec4
    vec3 = to_nd(projected ./ projected[4], Val{3}, 0)
end


function get_scaled_dpi(window)
    monitor = GLFW.GetPrimaryMonitor()
    props = GLWindow.MonitorProperties(monitor)
    # it seems like small displays with high dpi make mm look quite big.
    # so lets scale it a bit. 518 is a bit arbitrary, but the scale of my
    # screen on which I test everything, hence it will make you see things as I do.
    scaling = minimum(props.physicalsize) / 518
    min(props.dpi...) * scaling # we do not start fiddling with differently scaled xy dpi's
end

end

using .Units

using .Units: px, rel, mm, Millimeter, Pixel, Relative, to_absolute
export px, rel, mm, Millimeter, Pixel, Relative, to_absolute
