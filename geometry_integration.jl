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
    limits::Node{BBox}
    protrusions::Node{Tuple{Float32, Float32, Float32, Float32}}
    needs_update::Node{Bool}
    attributes::Attributes
end

function default_attributes(::Type{LayoutedAxis})
    Attributes(
        xlabel = "x label",
        ylabel = "y label",
        title = "Title",
        titlefont = "DejaVu Sans",
        titlesize = 30f0,
        titlegap = 10f0,
        titlevisible = true,
        titlealign = :center,
        xlabelcolor = RGBf0(0, 0, 0),
        ylabelcolor = RGBf0(0, 0, 0),
        xlabelsize = 20f0,
        ylabelsize = 20f0,
        xlabelvisible = true,
        ylabelvisible = true,
        xlabelpadding = 5f0,
        ylabelpadding = 5f0,
        xticklabelsize = 20f0,
        yticklabelsize = 20f0,
        xticklabelsvisible = true,
        yticklabelsvisible = true,
        xticksize = 10f0,
        yticksize = 10f0,
        xticksvisible = true,
        yticksvisible = true,
        xticklabelpad = 20f0,
        yticklabelpad = 20f0,
        xtickalign = 0f0,
        ytickalign = 0f0,
        xtickwidth = 1f0,
        ytickwidth = 1f0,
        xtickcolor = RGBf0(0, 0, 0),
        ytickcolor = RGBf0(0, 0, 0),
        xpanlock = false,
        ypanlock = false,
        xzoomlock = false,
        yzoomlock = false,
        spinewidth = 1f0,
        xgridvisible = true,
        ygridvisible = true,
        xgridwidth = 1f0,
        ygridwidth = 1f0,
        xgridcolor = RGBAf0(0, 0, 0, 0.1),
        ygridcolor = RGBAf0(0, 0, 0, 0.1),
        xidealtickdistance = 100f0,
        yidealtickdistance = 100f0,
        topspinevisible = true,
        rightspinevisible = true,
        leftspinevisible = true,
        bottomspinevisible = true,
        topspinecolor = RGBf0(0, 0, 0),
        leftspinecolor = RGBf0(0, 0, 0),
        rightspinecolor = RGBf0(0, 0, 0),
        bottomspinecolor = RGBf0(0, 0, 0),
        aspect = AxisAspect(nothing),
        alignment = (0.5f0, 0.5f0),
        maxsize = (Inf32, Inf32)
    )
end

mutable struct LayoutedColorbar
    parent::Scene
    scene::Scene
    bboxnode::Node{BBox}
    limits::Node{Tuple{Float32, Float32}}
    protrusions::Node{Tuple{Float32, Float32, Float32, Float32}}
    needs_update::Node{Bool}
    attributes::Attributes
end

function default_attributes(::Type{LayoutedColorbar})
    Attributes(
        label = "label",
        title = "Title",
        titlefont = "DejaVu Sans",
        titlesize = 30f0,
        titlegap = 10f0,
        titlevisible = true,
        titlealign = :center,
        labelcolor = RGBf0(0, 0, 0),
        labelsize = 20f0,
        labelvisible = true,
        labelpadding = 5f0,
        ticklabelsize = 20f0,
        ticklabelsvisible = true,
        ticksize = 10f0,
        ticksvisible = true,
        ticklabelpad = 20f0,
        tickalign = 0f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
        spinewidth = 1f0,
        idealtickdistance = 100f0,
        topspinevisible = true,
        rightspinevisible = true,
        leftspinevisible = true,
        bottomspinevisible = true,
        topspinecolor = RGBf0(0, 0, 0),
        leftspinecolor = RGBf0(0, 0, 0),
        rightspinecolor = RGBf0(0, 0, 0),
        bottomspinecolor = RGBf0(0, 0, 0),
    )
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

struct LayoutedButton
    scene::Scene
    bboxnode::Node{BBox}
    width::Node{Float32}
    height::Node{Float32}
    button::Button
end

function LayoutedButton(scene::Scene, width::Real, height::Real, label::String, textsize=20)

    bboxnode = Node(BBox(0, 1, 1, 0))
    heightnode = Node(Float32(height))
    widthnode = Node(Float32(width))
    position = Node(Point2f0(0, 0))

    button = button!(
        scene, label,
        dimensions = lift((w, h) -> (w, h), widthnode, heightnode),
        position = position,
        textsize=textsize, raw=true)[end]

    on(bboxnode) do bbox
        position[] = Point(left(bbox), bottom(bbox))
    end

    LayoutedButton(scene, bboxnode, widthnode, heightnode, button)
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
