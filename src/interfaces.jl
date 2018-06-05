not_implemented_for(x) = error("Not implemented for $(typeof(x)). You might want to put:  `using Makie` into your code!")

Theme(; kw_args...) = Attributes(map(kw-> kw[1] => to_node(Any, kw[2], kw[1]), kw_args))
default_theme(scene, T) = not_implemented_for(T)

function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = theme(scene, :color),
        linewidth = 1,
        visible = true,
        light = light,
        transformation = nothing,
        model = nothing,
        alpha = 1.0,
    )
end

"""
    image(x, y, image) / image(image)
Plots an image on range x, y (defaults to dimensions)
"""
@atomic(Image) do scene
    Theme(;
        default_theme(scene)...,
        colormap = [RGBAf0(0,0,0,1), RGBAf0(1,1,1,1)],
        fxaa = false,
    )
end


# could be implemented via image, but might be optimized specifically by the backend
"""
    heatmap(x, y, values) / heatmap(values)
Plots a image on heatmap x, y (defaults to dimensions)
"""
@atomic(Heatmap) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        linewidth = 0.0,
        levels = 1,
        fxaa = true,
        interpolate = false
    )
end

"""
    volume(volume_data)
Plots a volume
"""
@atomic(Volume) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        isovalue = 0.6,
        algorithm = :iso,
        absorption = 1f0,
        isovalue = 0.5f0,
        isorange = 0.01f0,
        colormap = theme(scene, :colormap),
        colorrange = (0, 1)
    )
end

"""
    surface(x, y, z)
Plots a surface, where x y z are supposed to lie on a grid
"""
@atomic(Surface) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        image = nothing,
        fxaa = true,
    )
end

"""
    lines(x, y, z) / lines(x, y) / lines(positions)
Plots a connected line for each element in xyz/positions
"""
@atomic(Lines) do scene
    Theme(;
        default_theme(scene)...,
        linewidth = 1.0,
        linestyle = nothing,
        fxaa = false
    )
end

"""
    linesegments(x, y, z) / linesegments(x, y) / linesegments(positions)
Plots a line for each pair of points in xyz/positions

## Attributes:

The same as for [`lines`](@ref)
"""
@atomic(LineSegments) do scene
    default_theme(scene, Lines)
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    mesh(x, y, z) / mesh(mesh_object) / mesh(x, y, z, faces) / mesh(xyz, faces)
Plots a 3D mesh
"""
@atomic(Mesh) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        interpolate = false,
        shading = true
    )
end

"""
    scatter(x, y, z) / scatter(x, y) / scatter(positions)
Plots a marker for each element in xyz/positions
"""
@atomic(Scatter) do scene
    Theme(;
        default_theme(scene)...,
        marker = Circle,
        markersize = 0.1,
        strokecolor = RGBA(0, 0, 0, 0),
        strokewidth = 0.0,
        glowcolor = RGBA(0, 0, 0, 0),
        glowwidth = 0.0,
        rotations = Billboard(),
        intensity = nothing,
        colormap = nothing,
        colorrange = nothing,
        marker_offset = nothing,
        fxaa = false
    )
end

"""
    meshscatter(x, y, z) / meshscatter(x, y) / meshscatter(positions)
Plots a mesh for each element in xyz/positions
"""
@atomic(MeshScatter) do scene
    Theme(;
        default_theme(scene)...,
        marker = Sphere(Point3f0(0), 0.1f0),
        markersize = 0.1,
        rotations = Quaternionf0(0, 0, 0, 1),
        intensity = nothing,
        colormap = nothing,
        colorrange = nothing,
        fxaa = true
    )
end

"""
    text(string)

Plots a text
"""
@atomic(Text) do scene
    Theme(;
        default_theme(scene)...,
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        font = theme(scene, :font),
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = Point2f0(0),
    )
end

const atomic_function_symbols = (
        :text, :meshscatter, :scatter, :mesh, :linesegments,
        :lines, :surface, :volume, :heatmap, :image
)
const atomic_functions = getfield.(AbstractPlotting, atomic_function_symbols)

"""
        calculated_attributes!(plot::AbstractPlot)
Fill in values that can only be calculated when we have all other attributes filled
"""
function calculated_attributes!(plot::AbstractPlot)
    if haskey(plot, :colormap) && value(plot[:colormap]) != nothing
        delete!(plot, :color) # color is overwritten by colormap
        replace_nothing!(plot, :colorrange) do
            map(plot[3]) do arg
                Vec2f0(extrema_nan(arg))
            end
        end
    else
        delete!(plot, :colormap)
        delete!(plot, :colorrange)
    end
    return
end

function calculated_attributes!(plot::Scatter)
    # calculate base case
    invoke(calculated_attributes!, Tuple{AbstractPlot}, plot)
    replace_nothing!(plot, :marker_offset) do
        # default to middle
        map(x-> Vec2f0((x .* (-0.5f0))), plot[:markersize])
    end
end



function (PT::Type{<: Combined})(parent, transformation, attributes, input_args, output_args)
    PT(parent, transformation, attributes, input_args, output_args, AbstractPlot[])
end
plotsym(::Type{<:AbstractPlot{F}}) where F = Symbol(F)


function (PlotType::Type{<: AbstractPlot{Typ}})(scene::SceneLike, attributes::Attributes, args::Tuple) where Typ
    # make sure all arguments are a node
    # with a sensible name
    arg_nodes = node.(argument_names(PlotType, length(args)), args)
    args_converted = map(arg_nodes...) do args...
        # do the argument conversion inside a lift
        args = convert_arguments(PlotType, args...)
        PlotType2 = plottype(args...)
        args
    end
    # now get a signal node/signal for each argument
    node_args_seperated = ntuple(length(value(args_converted))) do i
        map(args_converted) do x
            if i <= length(x)
                x[i]
            else
                error("You changed the number of arguments for $PlotType. This isn't allowed!")
            end
        end
    end
    plot_attributes, rest = merged_get!(()-> default_theme(scene, PlotType), plotsym(PlotType), scene, attributes)
    replace_nothing!(plot_attributes, :transformation) do
        Transformation(scene)
    end
    replace_nothing!(plot_attributes, :model) do
        value(plot_attributes[:transformation]).model
    end
    transformation = value(pop!(plot_attributes, :transformation))
    # The argument type of the final plot object is the assumened to stay constant after
    # argument conversion. This might not always hold, but it simplifies
    # things quite a bit
    ArgTyp = typeof(value(args_converted))
    # construct the fully qualified plot type, from the possible incomplete (abstract)
    # PlotType
    FinalType = basetype(PlotType){Typ, ArgTyp}
    # create the plot, with the full attributes, the input signals, and the final signal nodes.
    plot_obj = FinalType(scene, transformation, plot_attributes, arg_nodes, node_args_seperated)
    calculated_attributes!(plot_obj)
    plot_obj, rest
end



"""
    plot_type(plot_args...)

The default plot type for any argument is `lines`.
Any custom argument combination that has only one meaningful way to be plotted should overload this.
E.g:
```example
    # make plot(rand(5, 5, 5)) plot as a volume
    plottype(x::Array{<: AbstractFlot, 3}) = Volume
```
"""
plottype(plot_args...) = Lines


# creates a new scene
plot(args...; kw_args...) = plot!(Scene(), Any, args...; kw_args...)
plot(P::Type, args...; kw_args...) = plot!(Scene(), P, args...; kw_args...)

# creates a new childscene
plot(scene::SceneLike, args...; kw_args...) = plot!(Scene(scene), Any, args...; kw_args...)
plot(scene::SceneLike, P::Type, args...; kw_args...) = plot!(Scene(scene), P, args...; kw_args...)

# plots to global current scene
plot!(args...; kw_args...) = plot!(current_scene(), Any, args...; kw_args...)
plot!(P::Type, args...; kw_args...) = plot!(current_scene(), P, Attributes(kw_args), args...)
plot!(P::Type, attributes::Attributes, args...) = plot!(current_scene(), P, attributes, args...)

# plots to scene
plot!(scene::SceneLike, args...; kw_args...) = plot!(scene, Any, args...; kw_args...)
plot!(scene::SceneLike, P::Type, args...; kw_args...) = plot!(scene, P, Attributes(kw_args), args...)

function plot!(scene::SceneLike, plot::Combined{F, Arg}) where {F, Arg}
    plot!(plot, arguments(plot)...; attributes(plot)...)
end
function plot!(scene::SceneLike, plot::Atomic{F, Arg}) where {F, Arg}
    plot!(plot, arguments(plot)...; attributes(plot)...)
end

function plot!(scene::SceneLike, ::Type{Any}, attributes::Attributes, args...)
    PlotType = plottype(value.(args)...)
    plot!(scene, PlotType, attributes, args...)
end

plot!(p::Atomic) = p
function plot!(scene::SceneLike, ::Type{PlotType}, attributes::Attributes, args...) where PlotType
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object, non_plot_kwargs = PlotType(scene, attributes, args)
    # call user defined overload to fill the plot type
    plot!(plot_object)
    # call the assembly recipe, that also adds this to the scene
    # kw_args not consumed by PlotType will be passed forward to plot! as non_plot_kwargs
    plot!(scene, plot_object, non_plot_kwargs)
end

function plot!(scene::Combined, ::Type{PlotType}, attributes::Attributes, args...) where PlotType
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object, non_plot_kwargs = PlotType(scene, attributes, args)
    # call user defined overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)
    scene
end
