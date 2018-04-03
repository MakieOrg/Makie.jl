abstract type AbstractPlot end
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

include("iodevices.jl")

struct Events
    window_area::Node{IRect2D}
    window_dpi::Node{Float64}
    window_open::Node{Bool}

    mousebuttons::Node{Set{Mouse.Button}}
    mouseposition::Node{Point2d{Float64}}
    mousedrag::Node{Mouse.DragEnum}
    scroll::Node{Vec2d{Float64}}

    keyboardbuttons::Node{Set{Keyboard.Button}}

    unicode_input::Node{Vector{Char}}
    dropped_files::Node{Vector{String}}
    hasfocus::Node{Bool}
    entered_window::Node{Bool}
end

function Events()
    Events(
        node(:window_area, IRect(0, 0, 1, 1)),
        node(:window_dpi, 100.0),
        node(:window_open, false),

        node(:mousebuttons, Set{Mouse.Button}()),
        node(:mouseposition, (0.0, 0.0)),
        node(:mousedrag, Mouse.notpressed),
        node(:scroll, (0.0, 0.0)),

        node(:keyboardbuttons, Set{Keyboard.Button}()),

        node(:unicode_input, Char[]),
        node(:dropped_files, String[]),
        node(:hasfocus, false),
        node(:entered_window, false),
    )
end


struct Key{K} end
macro key_str(arg)
    :(Key{$(QuoteNode(Symbol(arg)))})
end
