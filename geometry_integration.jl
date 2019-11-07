using AbstractPlotting
using AbstractPlotting: Rect2D
import AbstractPlotting: IRect2D

const BBox = Rect2D{Float32}

left(rect::Rect2D) = minimum(rect)[1]
right(rect::Rect2D) = maximum(rect)[1]

bottom(rect::Rect2D) = minimum(rect)[2]
top(rect::Rect2D) = maximum(rect)[2]

abstract type Side end

struct Left <: Side end
struct Right <: Side end
struct Top <: Side end
struct Bottom <: Side end

Base.getindex(bbox::Rect2D, ::Left) = left(bbox)
Base.getindex(bbox::Rect2D, ::Right) = right(bbox)
Base.getindex(bbox::Rect2D, ::Bottom) = bottom(bbox)
Base.getindex(bbox::Rect2D, ::Top) = top(bbox)

mutable struct LayoutedAxis
    parent::Scene
    scene::Scene
    bboxnode::Node{BBox}
    xlabel::Node{String}
    ylabel::Node{String}
    title::Node{String}
    titlesize::Node{Float32}
    titlegap::Node{Float32}
    titlevisible::Node{Bool}
    limits::Node{BBox}
    protrusions::Node{Tuple{Float32, Float32, Float32, Float32}}
    needs_update::Node{Bool}
    xlabelsize::Node{Float32}
    ylabelsize::Node{Float32}
    xlabelvisible::Node{Bool}
    ylabelvisible::Node{Bool}
    xlabelpadding::Node{Float32}
    ylabelpadding::Node{Float32}
    xticklabelsize::Node{Float32}
    yticklabelsize::Node{Float32}
    xticklabelsvisible::Node{Bool}
    yticklabelsvisible::Node{Bool}
    xticksize::Node{Float32}
    yticksize::Node{Float32}
    xticksvisible::Node{Float32}
    yticksvisible::Node{Float32}
end

struct LayoutedSlider
    scene::Scene
    bboxnode::Node{BBox}
    height::Node{Float32}
    slider::Slider
end

function LayoutedSlider(scene::Scene, height::Real, sliderrange)

    bboxnode = Node(BBox(0, 1, 1, 0))
    heightnode = Node(Float32(height))
    position = Node(Point2f0(0, 0))
    widthnode = Node(Float32(100))
    slider = slider!(scene, sliderrange, position=position,
        sliderheight=heightnode, sliderlength=widthnode, raw=true)[end]

    on(bboxnode) do bbox
        position[] = Point(left(bbox), bottom(bbox))
        widthnode[] = width(bbox)
    end

    LayoutedSlider(scene, bboxnode, heightnode, slider)
end


width(rect::Rect2D) = right(rect) - left(rect)
height(rect::Rect2D) = top(rect) - bottom(rect)


function BBox(left::Number, right::Number, top::Number, bottom::Number)
    mini = (left, bottom)
    maxi = (right, top)
    return BBox(mini, maxi .- mini)
end

function IRect2D(bbox::Rect2D)
    return IRect2D(
        round.(Int, minimum(bbox)),
        round.(Int, widths(bbox))
    )
end

struct RowCols{T <: Union{Number, Vector{Float64}}}
    lefts::T
    rights::T
    tops::T
    bottoms::T
end

function RowCols(ncols::Int, nrows::Int)
    return RowCols(
        zeros(ncols),
        zeros(ncols),
        zeros(nrows),
        zeros(nrows)
    )
end

Base.getindex(rowcols::RowCols, ::Left) = rowcols.lefts
Base.getindex(rowcols::RowCols, ::Right) = rowcols.rights
Base.getindex(rowcols::RowCols, ::Top) = rowcols.tops
Base.getindex(rowcols::RowCols, ::Bottom) = rowcols.bottoms

"""
    eachside(f)
Calls f over all sides (Left, Right, Top, Bottom), and creates a BBox from the result of f(side)
"""
function eachside(f)
    return BBox(map(f, (Left(), Right(), Top(), Bottom()))...)
end

"""
mapsides(
       f, first::Union{Rect2D, RowCols}, rest::Union{Rect2D, RowCols}...
   )::BBox
Maps f over all sides of the rectangle like arguments.
e.g.
```
mapsides(BBox(left, right, top, bottom)) do side::Side, side_val::Number
    return ...
end::BBox
```
"""
function mapsides(
        f, first::Union{Rect2D, RowCols}, rest::Union{Rect2D, RowCols}...
    )
    return eachside() do side
        f(side, getindex.((first, rest...), (side,))...)
    end
end
