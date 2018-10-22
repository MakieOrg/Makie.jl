not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

#TODO only have one?
const Theme = Attributes

Theme(x::AbstractPlot) = x.attributes

default_theme(scene, T) = Attributes()

function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = theme(scene, :color),
        visible = theme(scene, :visible),
        linewidth = 1,
        light = light,
        transformation = automatic,
        model = automatic,
        alpha = 1.0,
        transparency = false,
        overdraw = false,
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
        isorange = 0.05f0,
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
        shading = true,
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
        uv_offset_width = Vec4f0(0),
        distancefield = nothing
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


const atomic_functions = getfield.(Ref(AbstractPlotting), atomic_function_symbols)


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
    args_converted = lift(arg_nodes...) do args...
        # do the argument conversion inside a lift
        args = convert_arguments(PlotType, args...)
        PlotType2 = plottype(args...)
        args
    end
    # now get a signal node/signal for each argument
    N = length(to_value(args_converted))
    names = argument_names(PlotType, N)
    node_args_seperated = ntuple(N) do i
        lift(args_converted, name = string(names[i])) do x
            if i <= length(x)
                x[i]
            else
                error("You changed the number of arguments for $PlotType. This isn't allowed!")
            end
        end
    end
    plot_attributes, scene_attributes = merged_get!(()-> default_theme(scene, PlotType), plotsym(PlotType), scene, attributes)
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
    ArgTyp = typeof(to_value(args_converted))
    # construct the fully qualified plot type, from the possible incomplete (abstract)
    # PlotType
    FinalType = basetype(PlotType){Typ, ArgTyp}
    # create the plot, with the full attributes, the input signals, and the final signal nodes.
    plot_obj = FinalType(scene, transformation, plot_attributes, arg_nodes, node_args_seperated)
    calculated_attributes!(plot_obj)
    plot_obj, scene_attributes
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


plottype(::AbstractVector, ::AbstractVector) = Lines
plottype(::AbstractMatrix) = Heatmap
plottype(::AbstractVector, ::AbstractVector) = Heatmap

"""
Returns the Combined type that represents the signature of `args`.
"""
function Plot(args::Vararg{Any, N}) where N
    Combined{Any, <: Tuple{args...}}
end
Base.@pure function Plot(::Type{T}) where T
    Combined{Any, <: Tuple{T}}
end
Base.@pure function Plot(::Type{T1}, ::Type{T2}) where {T1, T2}
    Combined{Any, <: Tuple{T1, T2}}
end

# all the plotting functions that get a plot type
const PlotFunc = Union{Type{Any}, Type{<: AbstractPlot}}

plot(P::PlotFunc, args...; kw_attributes...) = plot!(Scene(), P, Attributes(kw_attributes), args...)
plot!(P::PlotFunc, args...; kw_attributes...) = plot!(current_scene(), P, Attributes(kw_attributes), args...)
plot(scene::SceneLike, P::PlotFunc, args...; kw_attributes...) = plot!(Scene(scene), P, Attributes(kw_attributes), args...)
plot!(scene::SceneLike, P::PlotFunc, args...; kw_attributes...) = plot!(scene, P, Attributes(kw_attributes), args...)

plot(scene::SceneLike, P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(Scene(scene), P, merge!(Attributes(kw_attributes), attributes), args...)
plot!(scene::SceneLike, P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(scene, P, merge!(Attributes(kw_attributes), attributes), args...)
plot!(P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(current_scene(), P, merge!(Attributes(kw_attributes), attributes), args...)
plot(P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(Scene(), P, merge!(Attributes(kw_attributes), attributes), args...)

# Overload remaining functions
eval(default_plot_signatures(:plot, :plot!, :Any))

# plots to scene

"""
Main plotting signatures that plot/plot! route to if no Plot Type is given
"""
function plot!(scene::SceneLike, ::Type{Any}, attributes::Attributes, args...)
    PlotType = plottype(to_value.(args)...)
    plot!(scene, PlotType, attributes, args...)
end

plot!(p::Atomic) = p

function plot!(p::Combined{Any, T}) where T
    args = (T.parameters...,)
    typed_args = join(string.("::", args), ", ")
    error("Plotting for the arguments ($typed_args) not defined. If you want to support those arguments, overload plot!(plot::Plot$((T.parameters...,)))")
end



function plot!(scene::SceneLike, ::Type{PlotType}, attributes::Attributes, args...) where PlotType <: AbstractPlot
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object, scene_attributes = PlotType(scene, attributes, args)

    attributes, rest = merge_attributes!(scene_attributes, theme(scene, :scene))
    # TODO warn about rest - should be unused arguments!
    empty!(scene.attributes)
    # transfer the merged attributes from theme and user defined to the scene
    merge!(scene.attributes, attributes)
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)

    scene[:raw][] || update_limits!(scene)
    (!scene[:raw][] || scene[:camera][] != automatic) && setup_camera!(scene)
    scene[:raw][] || add_axis!(scene)
    # ! ∘ isaxis --> (x)-> !isaxis(x)
    # move axis to front, so that scene[end] gives back the last plot and not the axis!
    if !isempty(scene.plots) && isaxis(last(scene.plots))
        axis = pop!(scene.plots)
        pushfirst!(scene.plots, axis)
    end
    #compose_plot!(scene)
    # call the assembly recipe, that also adds this to the scene
    # kw_args not consumed by PlotType will be passed forward to plot! as non_plot_kwargs
    #plot!(scene, plot_object, scene_attributes)
    scene
end

function plot!(scene::Combined, ::Type{PlotType}, attributes::Attributes, args...) where PlotType <: AbstractPlot
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object, scene_attributes = PlotType(scene, attributes, args)
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)
    scene
end

Base.getindex(scene::Scene, key::Symbol) = scene.attributes[key]


function scale_scene!(scene)
    if is2d(scene)
        area = pixelarea(scene)[]
        lims = limits(scene)[]
        # not really sure how to scale 3D scenes in a reasonable way
        mini, maxi = minimum(lims), maximum(lims)
        l = ((mini[1], maxi[1]), (mini[2], maxi[2]))
        xyzfit = fit_ratio(area, l)
        s = to_ndim(Vec3f0, xyzfit, 1f0)
        scale!(scene, s)
    end
    return scene
end

function setup_camera!(scene::Scene)
    if scene[:camera][] == automatic
        cam = cameracontrols(scene)
        if cam == EmptyCamera()
            if is2d(scene)
                #@info("setting camera to 2D")
                cam2d!(scene)
            else
                #@info("setting camera to 3D")
                cam3d!(scene)
            end
        end
    elseif scene[:camera][] in (cam2d!, cam3d!, campixel!)
        scene[:camera][](scene)
    else
        error("Unrecogniced `camera` attribute type: $(typeof(scene[:camera][])). Use automatic, cam2d! or cam3d!")
    end
    scene
end


function add_axis!(scene::Scene)
    show_axis = scene[:show_axis][]
    show_axis isa Bool || error("show_axis needs to be a bool")
    axistype = if scene[:axis_type][] == automatic
        is2d(scene) ? axis2d! : axis3d!
    elseif scene[:axis_type][] in (axis2d!, axis3d!)
        scene[:axis_type][]
    else
        error("Unrecogniced `axis_type` attribute type: $(typeof(scene[:axis_type][])). Use automatic, axis2d! or axis3d!")
    end

    if show_axis && !(any(isaxis, plots(scene)))
        axis_attributes = scene[:axis]
        axistype(scene, axis_attributes, limits(scene))
    end
    scene
end

function add_labels!(scene::Scene)
    if plot_attributes[:show_legend][] && haskey(p.attributes, :colormap)
        legend_attributes = plot_attributes[:legend][]
        colorlegend(scene, p.attributes[:colormap], p.attributes[:colorrange], legend_attributes)
    end
    scene
end

update_limits!(scene::Scene) = update_limits!(scene, scene[:limits][], scene[:padding][])

function update_limits!(scene::Scene, limits::Automatic, padding)
    # for when scene is empty
    dlimits = data_limits(scene)
    tlims = (minimum(dlimits), maximum(dlimits))
    if !all(x-> all(isfinite, x), tlims)
        @warn "limits of scene contain non finite values: $(tlims[1]) .. $(tlims[2])"
        mini = map(x-> ifelse(isfinite(x), x, 0.0), tlims[1])
        maxi = Vec3f0(ntuple(3) do i
            x = tlims[2][i]
            ifelse(isfinite(x), x, tlims[1][i] + 1f0)
        end)
        tlims = (mini, maxi)
    end
    new_widths = Vec3f0(ntuple(3) do i
        a = tlims[1][i]; b = tlims[2][i]
        w = b - a
        # check for widths == 0.0... 3rd dimension is allowed to be 0 though.
        # TODO maybe we should allow any one dimension to be 0, and then use the other 2 as 2D
        with0 = (i != 3) && (w ≈ 0.0)
        with0 && @warn "Founds 0 width in scene limits: $(tlims[1]) .. $(tlims[2])"
        ifelse(with0, 1f0, w)
    end)
    update_limits!(scene, FRect3D(tlims[1], new_widths), padding)
end

function update_limits!(scene::Scene, new_limits::HyperRectangle, padding = Vec3f0(0))
    lims = FRect3D(new_limits)
    lim_w = widths(lims)
    # use the smallest widths for scaling, to have a consistently wide padding for all sides
    minw = if lim_w[3] ≈ 0.0
        m = min(lim_w[1], lim_w[2])
        Vec3f0(m, m, 0.0)
    else
        Vec3f0(minimum(lim_w))
    end
    padd_abs = minw .* to_ndim(Vec3f0, padding, 0.0)
    limits(scene)[] = FRect3D(minimum(lims) .- padd_abs, lim_w .+  2padd_abs)
    scene
end
