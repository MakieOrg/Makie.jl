const Attributes = Dict{Symbol, Any}
const RealVector{T} = AbstractVector{T} where T <: Number
const Node = Signal

const Rect{N, T} = HyperRectangle{N, T}
const Rect2D{T} = HyperRectangle{2, T}
const FRect2D = Rect2D{Float32}

const Rect3D{T} = Rect{3, T}
const FRect3D = Rect3D{Float32}
const IRect3D = Rect3D{Int}


const IRect2D = Rect2D{Int}

const Point2d{T} = NTuple{2, T}
const Vec2d{T} = NTuple{2, T}
const VecTypes{N, T} = Union{StaticVector{N, T}, NTuple{N, T}}
const RGBAf0 = RGBA{Float32}

const Font = Vector{Ptr{FreeType.FT_FaceRec}}

abstract type AbstractScreen end
using Base: RefValue


function IRect(x, y, w, h)
    HyperRectangle{2, Int}(Vec(round(Int, x), round(Int, y)), Vec(round(Int, w), round(Int, h)))
end
function IRect(xy::VecTypes, w, h)
    IRect(xy[1], xy[2], w, h)
end
function IRect(x, y, wh::VecTypes)
    IRect(x, y, wh[1], wh[2])
end
function IRect(xy::VecTypes, wh::VecTypes)
    IRect(xy[1], xy[2], wh[1], wh[2])
end

function positive_widths(rect::HyperRectangle{N, T}) where {N, T}
    mini, maxi = minimum(rect), maximum(rect)
    realmin = min.(mini, maxi)
    realmax = max.(mini, maxi)
    HyperRectangle{N, T}(realmin, realmax .- realmin)
end

function FRect(x, y, w, h)
    HyperRectangle{2, Float32}(Vec2f0(x, y), Vec2f0(w, h))
end
function FRect(r::SimpleRectangle)
    FRect(r.x, r.y, r.w, r.h)
end
function FRect(r::Rect)
    FRect(minimum(r), widths(r))
end
function FRect(xy::VecTypes, w, h)
    FRect(xy[1], xy[2], w, h)
end
function FRect(x, y, wh::VecTypes)
    FRect(x, y, wh[1], wh[2])
end
function FRect(xy::VecTypes, wh::VecTypes)
    FRect(xy[1], xy[2], wh[1], wh[2])
end

function FRect3D(x::Tuple{Tuple{<: Number, <: Number}, Tuple{<: Number, <: Number}})
    FRect3D(Vec3f0(x[1]..., 0), Vec3f0(x[2]..., 0))
end
function FRect3D(x::Tuple{Tuple{<: Number, <: Number, <: Number}, Tuple{<: Number, <: Number, <: Number}})
    FRect3D(Vec3f0(x[1]...), Vec3f0(x[2]...))
end

function FRect3D(x::Rect2D)
    FRect3D(Vec3f0(minimum(x)..., 0), Vec3f0(widths(x)..., 0.0))
end


const Vecf0{N} = Vec{N, Float32}
const Pointf0{N} = Point{N, Float32}
export Vecf0, Pointf0
