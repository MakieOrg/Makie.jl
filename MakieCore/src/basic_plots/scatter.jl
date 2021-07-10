const MarkerSizeTypes{N} = TorVector{Union{Float32, Vec{N, Float32}}}
const MarkerTypes = TorVector{<:Union{Symbol,Char, Type{Circle}, Type{Rect2D}}}
const DistanceFieldType = Union{Nothing, AbstractMatrix{<: Union{Colorant, Number}}}

mutable struct Scatter{N} <: AbstractPlot{Any}
    parent::Any

    position::AbstractVector{Point{N,Float32}}
    color::TorVector{RGBAf0}
    marker::MarkerTypes
    markersize::MarkerSizeTypes{N}
    marker_offset::TorVector{Vec{N,Float32}}
    strokecolor::TorVector{RGBAf0}
    strokewidth::TorVector{Float32}
    markerspace::Space
    transform_marker::Bool
    distancefield::DistanceFieldType
    cycle::Vector{Symbol}
    inspectable::Bool

    anti_aliasing::AntiAliasing
    visible::Bool
    basics::PlotBasics

    function Scatter(
                parent,
                position::AbstractVector{Point{N, Float32}},
                color,
                marker,
                markersize,
                marker_offset,
                strokecolor,
                strokewidth,
                markerspace,
                transform_marker,
                distancefield,
                cycle,
                inspectable,

                anti_aliasing,
                visible,
                basics,
            ) where N
        obj = new{N}()
        # Set fields with setfield to trigger conversion!
        obj.basics = basics
        obj.parent = parent
        obj.position = position
        obj.color = color
        obj.marker = marker
        obj.markersize = markersize
        obj.marker_offset = marker_offset
        obj.strokecolor = strokecolor
        obj.strokewidth = strokewidth
        obj.markerspace = markerspace
        obj.transform_marker = transform_marker
        obj.distancefield = distancefield
        obj.cycle = cycle
        obj.inspectable = inspectable

        obj.anti_aliasing = anti_aliasing
        obj.visible = visible
        return obj
    end

    function Scatter(position;
            parent = nothing,
            color = :black,
            marker = Circle,
            markersize = 5,
            marker_offset = automatic,
            strokecolor = :black,
            strokewidth = 0.0,
            markerspace = Pixel,
            transform_marker = false,
            distancefield = nothing,
            cycle = [:color],
            inspectable = true,

            anti_aliasing = NOAA,
            visible = true,
            basics = PlotBasics())

        return Scatter(
            parent,
            convert_arguments(Scatter, position)[1],
            color,
            marker,
            markersize,
            marker_offset,
            strokecolor,
            strokewidth,
            markerspace,
            transform_marker,
            distancefield,
            cycle,
            inspectable,

            anti_aliasing,
            visible,
            basics,
        )
    end
end

function convert_attribute(scatter::Scatter, ::Automatic, ::key"marker_offset")
    return scatter[:markersize] ./ 2
end

function scatter(args...; attributes...)
    plot(Scatter, args...; attributes...)
end

function scatter!(args...; attributes...)
    plot!(Scatter, args...; attributes...)
end

function plot!(::Type{<:Scatter}, scene::AbstractScene, args...; attributes...)
    scatter = Scatter(args...; attributes...)
    plot!(scene, scatter)
    return scatter
end

function plot!(P::PlotFunc, scene::SceneLike, args...; kw_attributes...)
    attributes = Attributes(kw_attributes)
    plot!(scene, P, attributes, args...)
end

function plot!(scene::SceneLike, scatter::Scatter)
    push!(scene.plots, scatter)
end

export Scatter, scatter, scatter!
