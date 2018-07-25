not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

#TODO only have one?
const Theme = Attributes

default_theme(scene, T) = Attributes()

function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = theme(scene, :color),
        linewidth = 1,
        visible = true,
        light = light,
        transformation = automatic,
        model = automatic,
        alpha = 1.0,
    )
end

"""
    `image(x, y, image)` / `image(image)`

Plots an image on range `x, y` (defaults to dimensions).
"""
@atomic(Image) do scene
    Theme(;
        default_theme(scene)...,
        colormap = [RGBAf0(0,0,0,1), RGBAf0(1,1,1,1)],
        colorrange = automatic,
        fxaa = false,
    )
end


# could be implemented via image, but might be optimized specifically by the backend
"""
    `heatmap(x, y, values)` or `heatmap(values)`

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).
"""
@atomic(Heatmap) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linewidth = 0.0,
        levels = 1,
        fxaa = true,
        interpolate = false
    )
end

"""
    `volume(volume_data)`

Plots a volume. Available algorithms are:
* `:iso` => IsoValue
* `:absorption` => Absorption
* `:mip` => MaximumIntensityProjection
* `:absorptionrgba` => AbsorptionRGBA
* `:indexedabsorption` => IndexedAbsorptionRGBA
"""
@atomic(Volume) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        algorithm = :iso,
        absorption = 1f0,
        isovalue = 0.5f0,
        isorange = 0.01f0,
        colormap = theme(scene, :colormap),
        colorrange = (0, 1)
    )
end

"""
    `surface(x, y, z)`

Plots a surface, where `(x, y, z)` are supposed to lie on a grid.
"""
@atomic(Surface) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        fxaa = true,
    )
end

"""
    `lines(x, y, z)` / `lines(x, y)` / or `lines(positions)`

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.
"""
@atomic(Lines) do scene
    Theme(;
        default_theme(scene)...,
        linewidth = 1.0,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linestyle = nothing,
        fxaa = false
    )
end

"""
    `linesegments(x, y, z)` / `linesegments(x, y)` / `linesegments(positions)`

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

**Attributes**:
The same as for [`lines`](@ref)
"""
@atomic(LineSegments) do scene
    default_theme(scene, Lines)
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    `mesh(x, y, z)`, `mesh(mesh_object)`, `mesh(x, y, z, faces)`, or `mesh(xyz, faces)`

Plots a 3D mesh.
"""
@atomic(Mesh) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        interpolate = false,
        shading = true,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
    )
end

"""
    `scatter(x, y, z)` / `scatter(x, y)` / `scatter(positions)`

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.
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
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        marker_offset = automatic,
        fxaa = false,
        transform_marker = false, # Applies the plots transformation to marker
    )
end

"""
    `meshscatter(x, y, z)` / `meshscatter(x, y)` / `meshscatter(positions)`

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`
"""
@atomic(MeshScatter) do scene
    Theme(;
        default_theme(scene)...,
        marker = Sphere(Point3f0(0), 1f0),
        markersize = 0.1,
        rotations = Quaternionf0(0, 0, 0, 1),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        fxaa = true
    )
end

"""
    `text(string)`

Plots a text.
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


function color_and_colormap!(plot, intensity = plot[:color])
    if isa(intensity[], AbstractArray{<: Number})
        haskey(plot, :colormap) || error("Plot $T needs to have a colormap to allow the attribute color to be an array of numbers")
        replace_automatic!(plot, :colorrange) do
            lift(extrema_nan, intensity)
        end
        true
    else
        delete!(plot, :colorrange)
        false
    end
end


"""
    `calculated_attributes!(plot::AbstractPlot)`

Fill in values that can only be calculated when we have all other attributes filled
"""
calculated_attributes!(plot::T) where T = calculated_attributes!(T, plot)

"""
    `calculated_attributes!(trait::Type{<: AbstractPlot}, plot)`
trait version of calculated_attributes
"""
calculated_attributes!(trait, plot) = nothing

function calculated_attributes!(::Type{<: Mesh}, plot)
    need_cmap = color_and_colormap!(plot)
    need_cmap || delete!(plot, :colormap)
    return
end

function calculated_attributes!(::Type{<: Union{Heatmap, Image}}, plot)
    plot[:color] = plot[3]
    color_and_colormap!(plot)
end
function calculated_attributes!(::Type{<: Surface}, plot)
    color_and_colormap!(plot, plot[3])
end
function calculated_attributes!(::Type{<: MeshScatter}, plot)
    color_and_colormap!(plot)
end

function calculated_attributes!(::Type{<: Scatter}, plot)
    # calculate base case
    color_and_colormap!(plot)
    replace_automatic!(plot, :marker_offset) do
        # default to middle
        lift(x-> Vec2f0.((x .* (-0.5f0))), plot[:markersize])
    end
end

function calculated_attributes!(::Type{<: Union{Lines, LineSegments}}, plot)
    color_and_colormap!(plot)
end


# # to allow one color per edge
# function calculated_attributes!(plot::LineSegments)
#     plot[:color] = lift(plot[:color], plot[1]) do c, p
#         if (length(p) ÷ 2) == length(c)
#             [c[k] for k in 1:length(c), l in 1:2]
#         else
#             c
#         end
#     end
# end

function (PT::Type{<: Combined})(parent, transformation, attributes, input_args, converted)
    PT(parent, transformation, attributes, input_args, converted, AbstractPlot[])
end
plotsym(::Type{<:AbstractPlot{F}}) where F = Symbol(typeof(F).name.mt.name)


function (PlotType::Type{<: AbstractPlot{Typ}})(scene::SceneLike, attributes::Attributes, args::Tuple) where Typ
    # make sure all arguments are a node
    # with a sensible name
    arg_nodes = node.(ntuple(i-> Symbol("input $i"), length(args)), args)
    args_converted = map(arg_nodes...) do args...
        # do the argument conversion inside a lift
        args = convert_arguments(PlotType, args...)
        PlotType2 = plottype(args...)
        args
    end
    # now get a signal node/signal for each argument
    N = length(value(args_converted))
    names = argument_names(PlotType, N)
    node_args_seperated = ntuple(N) do i
        map(args_converted, name = string(names[i])) do x
            if i <= length(x)
                x[i]
            else
                error("You changed the number of arguments for $PlotType. This isn't allowed!")
            end
        end
    end
    plot_attributes, rest = merged_get!(()-> default_theme(scene, PlotType), plotsym(PlotType), scene, attributes)
    trans = get(plot_attributes, :transformation, automatic)
    transformation = if to_value(trans) == automatic
        Transformation(scene)
    elseif isa(to_value(trans), Transformation)
        to_value(trans)
    else
        t = Transformation(scene)
        transform!(t, to_value(trans))
        t
    end

    replace_automatic!(plot_attributes, :model) do
        transformation.model
    end
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
    `plot_type(plot_args...)`

The default plot type for any argument is `lines`.
Any custom argument combination that has only one meaningful way to be plotted should overload this.
e.g.:
```example
    # make plot(rand(5, 5, 5)) plot as a volume
    plottype(x::Array{<: AbstractFlot, 3}) = Volume
```
"""
plottype(plot_args...) = Combined{Any, Tuple{typeof.(to_value.(plot_args))...}}


function Plot(args::Vararg{Any, N}) where N
    Combined{Any, <: Tuple{args...}}
end
Base.@pure function Plot(::Type{T}) where T
    Combined{Any, <: Tuple{T}}
end
Base.@pure function Plot(::Type{T1}, ::Type{T2}) where {T1, T2}
    Combined{Any, <: Tuple{T1, T2}}
end
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

# function plot!(scene::SceneLike, plot::Combined{F, Arg}) where {F, Arg}
#     plot!(plot, arguments(plot)...; attributes(plot)...)
# end
# function plot!(scene::SceneLike, plot::Atomic{F, Arg}) where {F, Arg}
#     plot!(plot, arguments(plot)...; attributes(plot)...)
# end

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
