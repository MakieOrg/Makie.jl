__precompile__(true)
module Makie

using Reactive, GeometryTypes, Colors, StaticArrays

using Colors, GeometryTypes, GLVisualize, GLAbstraction, ColorVectorSpace
using StaticArrays, GLWindow, ModernGL, Contour
import Quaternions

using Base.Iterators: repeated, drop
using Base: RefValue
using Fontconfig, FreeType, FreeTypeAbstraction, UnicodeFun
using IntervalSets

include("types.jl")
include("utils.jl")

Base.getindex(x::Node) = value(x)
Base.setindex!(x::Node, value) = push!(x, value)

struct Scene
    events::Events

    px_area::Node{IRect2D}
    area::Node{FRect2D}
    view::Node{Mat4f0}
    projection::Node{Mat4f0}
    resolution::Node{Vec2f0}
    eyeposition::Node{Vec3f0}

    limits::Node{HyperRectangle{3, Float32}}
    scale::Node{Vec3f0}
    flip::Node{NTuple{3, Bool}}

    plots::Vector{<: AbstractPlot}
    theme::Attributes
    children::Vector{Scene}
end


function Scene(area = nothing)
    events = Events()
    if area == nothing
        area = map(x-> IRect(0, 0, widths(x)), events.window_area)
    end
    Scene(
        events,
        area,
        Node(FRect(0, 0, 1, 1)),
        Node(eye(Mat4f0)),
        Node(eye(Mat4f0)),
        map(a-> Vec2f0(widths(a)), events.window_area),
        Node(Vec3f0(1)),

        Signal(AABB(Vec3f0(0), Vec3f0(1))),
        Signal(Vec3f0(1)),
        Signal((false, false, false)),
        AbstractPlot[],
        Attributes(),
        Scene[]
    )
end

to_node(x::Node) = x
to_node(x) = Node(x)

function merged_get!(defaults, key, scene, input::Attributes)
    theme = get!(defaults, scene.theme, key)
    rest = Attributes()
    merged = Attributes()

    for key in union(keys(input), keys(theme))
        if haskey(input, key) && haskey(theme, key)
            merged[key] = to_node(input[key])
        elseif haskey(input, key)
            rest[key] = input[key]
        else # haskey(theme) must be true!
            merged[key] = theme[key]
        end
    end
    merged, rest
end

Theme(; kw_args...) = Attributes(map(kw-> kw[1] => to_node(kw[2]), kw_args))


function popkey!(dict::Dict, key)
    val = dict[key]
    delete!(dict, key)
    val
end

include("basic_drawing.jl")
include("layouting.jl")

include("attribute_conversion.jl")


include("events.jl")
include("glbackend/glbackend.jl")

include("plot.jl")
include("camera2d.jl")

export cam2d!, Scene, update_cam!, Screen, scatter

end
