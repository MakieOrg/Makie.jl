using Parameters, Colors, GeometryBasics

@with_kw mutable struct Scatter{N} <: AbstractPlot
    parent::Union{Scene, Nothing} = nothing

    positions::AbstractVector{Point{N,Float32}}

    color::TorVector{RGBAf0} = :black
    marker::TorVector{<:Union{Symbol,Char, Type{Circle}, Type{Rect2D}}} = Circle
    markersize::TorVector{Union{Float32, Vec{N,Float32}}} = 5
    marker_offset::TorVector{Vec{N,Float32}} = automatic
    strokecolor::TorVector{RGBAf0} = :black
    strokewidth::TorVector{Float32} = 0.0
    markerspace::Space = Pixel
    transform_marker::Bool = false
    distancefield::Union{Nothing, AbstractMatrix{<: Union{Colorant, Number}}} = nothing
    cycle::Vector{Symbol} = [:color]
    inspectable::Bool = true

    anti_aliasing::Bool = :fxaa
    visible::Bool = true
    basics::PlotBasics = PlotBasics()
end

function Scatter(positions; kw...)
    pos = convert_arguments(Scatter, positions)
    fields = from_keywords(Scatter, kw)

    return Scatter(
        nothing,
        pos,
        fields...,
        true,
        PlotBasics()
    )
end
