const atomic_funcs = (
    :contour => """
        contour(x, y, z)
    Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix
    """,
    :image => """
        image(x, y, image) / image(image)
    Plots an image on range x, y (defaults to dimensions)
    """,
    # could be implemented via image, but might be optimized specifically by the backend
    :heatmap => """
        heatmap(x, y, values) / heatmap(values)
    Plots a image on heatmap x, y (defaults to dimensions)
    """,
    :volume => """
        volume(volume_data)
    Plots a volume
    """,
    # alternatively, mesh2d?
    :poly => """

    """,
    :surface => """
        surface(x, y, z)
    Plots a surface, where x y z are supposed to lie on a grid
    """,
    :lines => """
        lines(x, y, z) / lines(x, y) / lines(positions)
    Plots a connected line for each element in xyz/positions
    """,
    :linesegments => """
        linesegments(x, y, z) / linesegments(x, y) / linesegments(positions)
    Plots a line for each pair of points in xyz/positions

    ## Attributes:

    The same as for [`lines`](@ref)
    """,
    # alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
    :mesh => """
        mesh(x, y, z) / mesh(mesh_object) / mesh(x, y, z, faces) / mesh(xyz, faces)
    Plots a 3D mesh
    """,
    :scatter => """
        scatter(x, y, z) / scatter(x, y) / scatter(positions)
    Plots a marker for each element in xyz/positions
    """,
    :meshscatter => """
        meshscatter(x, y, z) / meshscatter(x, y) / meshscatter(positions)
    Plots a mesh for each element in xyz/positions
    """,
    # :text => """
    # """,
    # Doesn't really need to be an atomic, could be implemented via lines
    :wireframe => """
        wireframe(x, y, z) / wireframe(positions) / wireframe(mesh)
    Draws a wireframe either interpreted as a surface or mesh
    """,

    :legend => """
        legend(series, labels)
    creates a legend from an array of plots and labels
    """,

    :axis => """
        axis(xrange, yrange, [zrange])

    Creates a axis from a x,y,z ranges
    """,

    :text => """
        text(string)

    Plots a text
    """,
    :annotations => """
        annotations(strings::Vector{String}, positions::Vector{Point})

    Plots an array of texts at each position in `positions`
    """
)
struct Billboard end


calculate_values!(scene::Scene, T, attributes, args) = attributes

Base.parent(x::AbstractPlot) = x.parent
function Base.getindex(x::AbstractPlot, key::Symbol)
    key == :x && return x.args[1]
    key == :y && return x.args[2]
    key == :z && return x.args[3]
    key == :position && return x.args[1]
    return x.attributes[key]
end

function Base.setindex!(x::T, value, key::Symbol) where T <: AbstractPlot
    key == :x && return setindex!(x.args[1], value)
    key == :y && return setindex!(x.args[2], value)
    key == :z && return setindex!(x.args[3], value)
    key == :positions && return setindex!(x.args[1], convert_arguments(T, value)...)
    x.attributes[key][] = value
end

for (func, docs) in atomic_funcs
    Typ = Symbol(titlecase(string(func)))
    inplace = Symbol(string(func, "!"))
    @eval begin
        struct $Typ{T} <: AbstractPlot
            args::T
            attributes::Attributes
            parent::RefValue{Scene}
        end
        $Typ(args, attributes) = $Typ(to_node.(args), attributes, RefValue{Scene}())
        $Typ(parent::Scene, args, attributes) = $Typ(to_node.(args), attributes, RefValue{Scene}(parent))
        plot_key(::$Typ) = Key{$(QuoteNode(func))}()

        $func(args...; kw_args...) = plot($Typ, args...; kw_args...)
        $func(scene::Scene, args...; kw_args...) = plot(scene, $Typ, args...; kw_args...)
        $func(scene::AbstractPlot, args...; kw_args...) = plot(parent(scene)[], $Typ, args...; kw_args...)
        $inplace(scene::AbstractPlot, args...; kw_args...) = plot(parent(scene)[], $Typ, args...; kw_args...)

        $inplace(args...; kw_args...) = plot!($Typ, args...; kw_args...)
        $inplace(scene::Scene, args...; kw_args...) = plot!(scene, $Typ, args...; kw_args...)

        function plot!(scene::Scene, T::Type{$Typ}, attributes::Attributes, args...)
            #cmap_or_color!(scene, attributes)
            attributes, rest = merged_get!($(QuoteNode(func)), scene, attributes) do
                default_theme(scene, T)
            end
            converted_args = map(to_node.(args)...) do args...
                convert_arguments(T, args...)
            end
            converted_args = ntuple(length(value(converted_args))) do i
                map(getindex, converted_args, Signal(i))
            end
            calculate_values!(scene, T, attributes, converted_args)
            plot!(scene, $Typ(converted_args, attributes), rest)
        end
        export $func, $inplace
    end
end

function to_modelmatrix(b, scale, offset, rotation)
    map(scale, offset, rotation) do s, o, r
        q = Quaternion(1f0,0f0,0f0,0f0)
        transformationmatrix(o, s, q)
    end
end

"""
Fill in values that can only be calculated when we have all other attributes filled
"""
function calculate_values!(scene::Scene, ::Type{T}, attributes, args) where T <: AbstractPlot
    calculate_values!(scene, attributes, args)
end
function calculate_values!(scene::Scene, attributes, args)
    if haskey(attributes, :colormap)
        delete!(attributes, :color) # color is overwritten by colormap
        get!(attributes, :colornorm) do
            map(to_node(args[3])) do arg
                x = extrema(arg)
                Vec2f0(x)
            end
        end
    end
    get!(attributes, :model) do
        t = scene.transformation
        map_once(t.scale, t.translation, t.rotation) do s, o, r
            q = Quaternions.Quaternion(1f0, 0f0, 0f0, 0f0)
            transformationmatrix(o, s, q)
        end
    end
end

function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = :blue,
        linewidth = 1,
        visible = true,
        light = light,
        #drawover = false,
    )
end

function default_theme(scene, ::Type{Scatter})
    Theme(;
        default_theme(scene)...,
        marker = Circle,
        markersize = 0.1,
        strokecolor = RGBA(0, 0, 0, 0),
        strokewidth = 0.0,
        glowcolor = RGBA(0, 0, 0, 0),
        glowwidth = 0.0,
        rotations = Billboard(),
        fxaa = false
    )
end
function calculate_values!(scene::Scene, ::Type{Scatter}, attributes, args)
    calculate_values!(scene::Scene, attributes, args)
    get!(attributes, :marker_offset) do
        # default to middle
        map(x-> Vec2f0((x .* (-0.5f0))), attributes[:markersize])
    end
end

function default_theme(scene, ::Type{Meshscatter})
    Theme(;
        default_theme(scene)...,
        marker = Sphere(Point3f0(0), 0.1f0),
        markersize = 0.1,
        rotations = Vec4f0(0, 0, 0, 1),
        fxaa = true
    )
end

function default_theme(scene, ::Type{<: Union{Lines, Linesegments}})
    Theme(;
        default_theme(scene)...,
        linewidth = 1.0,
        linestyle = nothing,
        fxaa = false
    )
end

function default_theme(scene, ::Type{Text})
    Theme(;
        default_theme(scene)...,
        color = :black,
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        font = "default",
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = Point2f0(0),
    )
end

function default_theme(scene, ::Type{Heatmap})
    Theme(;
        default_theme(scene)...,
        colormap = scene.theme[:colormap],
        linewidth = 0.0,
        levels = 1,
        fxaa = false,
        interpolate = false
    )
end

function default_theme(scene, ::Type{Mesh})
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        interpolate = false,
        shading = true
    )
end
