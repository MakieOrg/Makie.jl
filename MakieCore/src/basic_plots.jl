default_theme(scene) = generic_plot_attributes!(Attributes())


"""
### Generic attributes

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `space::Symbol = :data` sets the transformation space for box encompassing the volume plot. See `Makie.spaces()` for possible inputs.
"""
function generic_plot_attributes!(attr)
    attr[:transformation] = automatic
    attr[:model] = automatic
    attr[:visible] = true
    attr[:transparency] = false
    attr[:overdraw] = false
    attr[:ssao] = false
    attr[:inspectable] = true
    attr[:depth_shift] = 0.0f0
    attr[:space] = :data
    return attr
end

function generic_plot_attributes(attr)
    return (
        transformation = attr[:transformation],
        model = attr[:model],
        visible = attr[:visible],
        transparency = attr[:transparency],
        overdraw = attr[:overdraw],
        ssao = attr[:ssao],
        inspectable = attr[:inspectable],
        depth_shift = attr[:depth_shift],
        space = attr[:space]
    )
end

function mixin_generic_plot_attributes()
    quote
        transformation = automatic
        "Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`."
        model = automatic
        "Controls whether the plot will be rendered or not."
        visible = true
        "Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency."
        transparency = false
        "Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends"
        overdraw = false
        "Enables screen-space ambient occlusion."
        ssao = false
        "sets whether this plot should be seen by `DataInspector`."
        inspectable = true
        "adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw)."
        depth_shift = 0.0f0
        "sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs."
        space = :data
        "adjusts whether the plot is rendered with fxaa (anti-aliasing)."
        fxaa = true
    end
end

"""
### Color attributes

- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
  `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils.
  To see all available color gradients, you can call `Makie.available_gradients()`.
- `colorscale::Function = identity` color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `lowclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value below the colorrange.
- `highclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value above the colorrange.
- `alpha = 1.0` sets the alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.
"""
function colormap_attributes!(attr, colormap)
    attr[:colormap] = colormap
    attr[:colorscale] = identity
    attr[:colorrange] = automatic
    attr[:lowclip] = automatic
    attr[:highclip] = automatic
    attr[:nan_color] = :transparent
    attr[:alpha] = 1.0
    return attr
end

function colormap_attributes(attr)
    return (
        colormap = attr[:colormap],
        colorscale = attr[:colorscale],
        colorrange = attr[:colorrange],
        lowclip = attr[:lowclip],
        highclip = attr[:highclip],
        nan_color = attr[:nan_color],
        alpha = attr[:alpha]
    )
end

function mixin_colormap_attributes()
    quote
        """
        Sets the colormap that is sampled for numeric `color`s.
        `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils.
        To see all available color gradients, you can call `Makie.available_gradients()`.
        """
        colormap = @inherit :colormap :viridis
        """
        The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.
        """
        colorscale = identity
        "The values representing the start and end points of `colormap`."
        colorrange = automatic
        "The color for any value below the colorrange."
        lowclip = automatic
        "The color for any value above the colorrange."
        highclip = automatic
        nan_color = :transparent
        "The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied."
        alpha = 1.0
    end
end

"""
### 3D shading attributes

- `shading = Makie.automatic` sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.
- `diffuse::Vec3f = Vec3f(1.0)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.4)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `backlight::Float32 = 0f0` sets a weight for secondary light calculation with inverted normals.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.
"""
function shading_attributes!(attr)
    attr[:shading] = automatic
    attr[:diffuse] = 1.0
    attr[:specular] = 0.2
    attr[:shininess] = 32.0f0
    attr[:backlight] = 0f0
    attr[:ssao] = false
end

function shading_attributes(attr)
    return (
        shading = attr[:shading],
        diffuse = attr[:diffuse],
        specular = attr[:specular],
        shininess = attr[:shininess],
        backlight = attr[:backlight],
        ssao = attr[:ssao]
    )
end

function mixin_shading_attributes()
    quote
        "Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie."
        shading = automatic
        "Sets how strongly the red, green and blue channel react to diffuse (scattered) light."
        diffuse = 1.0
        "Sets how strongly the object reflects light in the red, green and blue channels."
        specular = 0.2
        "Sets how sharp the reflection is."
        shininess = 32.0f0
        "Sets a weight for secondary light calculation with inverted normals."
        backlight = 0f0
        "Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`."
        ssao = false
    end
end

"""
    `calculated_attributes!(trait::Type{<: AbstractPlot}, plot)`
trait version of calculated_attributes
"""
calculated_attributes!(trait, plot) = nothing

"""
    `calculated_attributes!(plot::AbstractPlot)`
Fill in values that can only be calculated when we have all other attributes filled
"""
calculated_attributes!(plot::T) where T = calculated_attributes!(T, plot)

"""
    image(x, y, image)
    image(image)

Plots an image on a rectangle bounded by `x` and `y` (defaults to size of image).
"""
@recipe Image x y image begin
    "Sets whether colors should be interpolated between pixels."
    interpolate = true
    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
    fxaa = false
    colormap = [:black, :white]
end

"""
    heatmap(x, y, matrix)
    heatmap(x, y, func)
    heatmap(matrix)
    heatmap(xvector, yvector, zvector)

Plots a heatmap as a collection of rectangles.
`x` and `y` can either be of length `i` and `j` where
`(i, j)` is `size(matrix)`, in this case the rectangles will be placed
around these grid points like voronoi cells. Note that
for irregularly spaced `x` and `y`, the points specified by them
are not centered within the resulting rectangles.

`x` and `y` can also be of length `i+1` and `j+1`, in this case they
are interpreted as the edges of the rectangles.

Colors of the rectangles are derived from `matrix[i, j]`.
The third argument may also be a `Function` (i, j) -> v which is then evaluated over the
grid spanned by `x` and `y`.

Another allowed form is using three vectors `xvector`, `yvector` and `zvector`.
In this case it is assumed that no pair of elements `x` and `y` exists twice.
Pairs that are missing from the resulting grid will be treated as if `zvector` had a `NaN`
    element at that position.

If `x` and `y` are omitted with a matrix argument, they default to `x, y = axes(matrix)`.

Note that `heatmap` is slower to render than `image` so `image` should be preferred for large, regularly spaced grids.
"""
@recipe Heatmap x y values begin
    "Sets whether colors should be interpolated"
    interpolate = false
    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
end

"""
    volume(volume_data)
    volume(x, y, z, volume_data)

Plots a volume, with optional physical dimensions `x, y, z`.
Available algorithms are:
* `:iso` => IsoValue
* `:absorption` => Absorption
* `:mip` => MaximumIntensityProjection
* `:absorptionrgba` => AbsorptionRGBA
* `:additive` => AdditiveRGBA
* `:indexedabsorption` => IndexedAbsorptionRGBA
"""
@recipe Volume x y z volume begin
    "Sets the volume algorithm that is used."    
    algorithm = :mip
    "Sets the range of values picked up by the IsoValue algorithm."
    isovalue = 0.5
    "Sets the target value for the IsoValue algorithm."
    isorange = 0.05
    "Sets whether the volume data should be sampled with interpolation."
    interpolate = true
    enable_depth = true
    absorption = 1f0
    @mixin mixin_generic_plot_attributes
    @mixin mixin_shading_attributes
    @mixin mixin_colormap_attributes
end

"""
    surface(x, y, z)
    surface(z)

Plots a surface, where `(x, y)` define a grid whose heights are the entries in `z`.
`x` and `y` may be `Vectors` which define a regular grid, **or** `Matrices` which define an irregular grid.
"""
@recipe Surface x y z begin
    "Can be set to an `Matrix{<: Union{Number, Colorant}}` to color surface independent of the `z` component. If `color=nothing`, it defaults to `color=z`."
    color = nothing
    "Inverts the normals generated for the surface. This can be useful to illuminate the other side of the surface."
    invert_normals = false
    @mixin mixin_generic_plot_attributes
    @mixin mixin_shading_attributes
    @mixin mixin_colormap_attributes
end

"""
    lines(positions)
    lines(x, y)
    lines(x, y, z)

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.

`NaN` values are displayed as gaps in the line.
"""
@recipe Lines positions begin
    "The color of the line."
    color = @inherit :linecolor :black
    "Sets the width of the line in pixel units"
    linewidth = @inherit :linewidth 1.0
    "Sets the pattern of the line e.g. `:solid`, `:dot`, `:dashdot`. For custom patterns look at `Linestyle(Number[...])`"
    linestyle = nothing
    "Sets which attributes to cycle when creating multiple plots."
    cycle = [:color]
    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
    fxaa = false
end

"""
    linesegments(positions)
    linesegments(vector_of_2tuples_of_points)
    linesegments(x, y)
    linesegments(x, y, z)

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

## Attributes

### Specific to `LineSegments`

- `color=theme(scene, :linecolor)` sets the color of the linesegments. If no color is set, multiple calls to `linesegments!` will cycle through the axis color palette.
  Otherwise, one can set one color per line point or one color per linesegment by passing a `Vector{<:Colorant}`, or one colorant for the whole line. If color is a vector of numbers, the colormap args are used to map the numbers to colors.
- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `linestyle::Union{Nothing, Symbol, Vector} = nothing` sets the pattern of the line (e.g. `:solid`, `:dot`, `:dashdot`)
- `linewidth::Union{Real, Vector} = 1.5` sets the width of the line in pixel units.

$(Base.Docs.doc(colormap_attributes!))

$(Base.Docs.doc(MakieCore.generic_plot_attributes!))
"""
@recipe LineSegments positions begin
    "The color of the line."
    color = @inherit :linecolor :black
    "Sets the width of the line in pixel units"
    linewidth = @inherit :linewidth 1.0
    "Sets the pattern of the line e.g. `:solid`, `:dot`, `:dashdot`. For custom patterns look at `Linestyle(Number[...])`"
    linestyle = nothing
    "Sets which attributes to cycle when creating multiple plots."
    cycle = [:color]
    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
    fxaa = false
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    mesh(x, y, z)
    mesh(mesh_object)
    mesh(x, y, z, faces)
    mesh(xyz, faces)

Plots a 3D or 2D mesh. Supported `mesh_object`s include `Mesh` types from [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl).
"""
@recipe Mesh mesh begin
    "Sets the color of the mesh. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates."
    color = @inherit :patchcolor :black
    "sets whether colors should be interpolated"
    interpolate = true
    cycle = [:color => :patchcolor]
    matcap = nothing
    @mixin mixin_generic_plot_attributes
    @mixin mixin_shading_attributes
    @mixin mixin_colormap_attributes
end

"""
    scatter(positions)
    scatter(x, y)
    scatter(x, y, z)

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.
"""
@recipe Scatter positions begin
    "Sets the color of the marker. If no color is set, multiple calls to `scatter!` will cycle through the axis color palette."
    color = @inherit :markercolor :black
    "Sets the scatter marker."
    marker = @inherit :marker :circle
    "Sets the size of the marker."
    markersize = @inherit :markersize 8
    "Sets the color of the outline around a marker."
    strokecolor = @inherit :markerstrokecolor :transparent
    "Sets the width of the outline around a marker."
    strokewidth = @inherit :markerstrokewidth 0
    "Sets the color of the glow effect around the marker."
    glowcolor = (:black, 0.0)
    "Sets the size of a glow effect around the marker."
    glowwidth = 0.0

    "Sets the rotation of the marker. A `Billboard` rotation is always around the depth axis."
    rotations = Billboard()
    marker_offset = automatic
    "Controls whether the model matrix (without translation) applies to the marker itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the marker."
    transform_marker = false
    distancefield = nothing
    uv_offset_width = (0.0, 0.0, 0.0, 0.0)
    "Sets the space in which `markersize` is given. See `Makie.spaces()` for possible inputs"
    markerspace = :pixel
    "Sets which attributes to cycle when creating multiple plots"
    cycle = [:color]
    "Enables depth-sorting of markers which can improve border artifacts. Currently supported in GLMakie only."
    depthsorting = false
    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
    fxaa = false
end

"""
    meshscatter(positions)
    meshscatter(x, y)
    meshscatter(x, y, z)

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`.
"""
@recipe MeshScatter positions begin
    "Sets the color of the marker."
    color = @inherit :markercolor :black
    "Sets the scattered mesh."
    marker = :Sphere
    "Sets the scale of the mesh. This can be given as a `Vector` to apply to each scattered mesh individually."
    markersize = 0.1
    "Sets the rotation of the mesh. A numeric rotation is around the z-axis, a `Vec3f` causes the mesh to rotate such that the the z-axis is now that vector, and a quaternion describes a general rotation. This can be given as a Vector to apply to each scattered mesh individually."
    rotations = 0.0
    space = :data
    fxaa = true
    cycle = [:color]
    @mixin mixin_generic_plot_attributes
    @mixin mixin_shading_attributes
    @mixin mixin_colormap_attributes
end

"""
    text(positions; text, kwargs...)
    text(x, y; text, kwargs...)
    text(x, y, z; text, kwargs...)

Plots one or multiple texts passed via the `text` keyword.
`Text` uses the `PointBased` conversion trait.
"""
@recipe Text positions begin
    "Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`."
    text = ""
    "Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}`, or one colorant for the whole text. If color is a vector of numbers, the colormap args are used to map the numbers to colors."
    color = @inherit :textcolor :black
    "Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file"
    font = @inherit :font :regular
    "Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`."
    fonts = @inherit :fonts Attributes()
    "Sets the color of the outline around a marker."
    strokecolor = (:black, 0.0)
    "Sets the width of the outline around a marker."
    strokewidth = 0
    "Sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions."
    align = (:left, :bottom)
    "Rotates text around the given position"
    rotation = 0.0
    "The fontsize in units depending on `markerspace`."
    fontsize = @inherit :fontsize 16
    "Deprecated: Specifies the position of the text. Use the positional argument to `text` instead."
    position = (0.0, 0.0)
    "Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`."
    justification = automatic
    "The lineheight multiplier."
    lineheight = 1.0
    "Sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs."
    markerspace = :pixel
    "Controls whether the model matrix (without translation) applies to the glyph itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the text glyphs.)"
    transform_marker = false
    "The offset of the text from the given position in `markerspace` units."
    offset = (0.0, 0.0)
    "Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping."
    word_wrap_width = -1
    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
    fxaa = false
end

function deprecated_attributes(::Type{<:Text})
    (
        (; attribute = :textsize, message = "`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version.", error = true),
    )
end

"""
    poly(vertices, indices; kwargs...)
    poly(points; kwargs...)
    poly(shape; kwargs...)
    poly(mesh; kwargs...)

Plots a polygon based on the arguments given.
When vertices and indices are given, it functions similarly to `mesh`.
When points are given, it draws one polygon that connects all the points in order.
When a shape is given (essentially anything decomposable by `GeometryBasics`), it will plot `decompose(shape)`.

    poly(coordinates, connectivity; kwargs...)

Plots polygons, which are defined by
`coordinates` (the coordinates of the vertices) and
`connectivity` (the edges between the vertices).
"""
@recipe Poly begin
    """
    Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`.
    A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates.
    Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors.
    One can also use `Makie.LinePattern`, to cover the poly with a regular stroke pattern.
    """
    color = @inherit :patchcolor :black
    "Sets the color of the outline around a marker."
    strokecolor = @inherit :patchstrokecolor :transparent
    "Sets the colormap that is sampled for numeric `color`s."
    strokecolormap = @inherit :colormap :viridis
    "Sets the width of the outline."
    strokewidth = @inherit :patchstrokewidth 0
    "Sets the pattern of the line (e.g. `:solid`, `:dot`, `:dashdot`)"
    linestyle = nothing

    shading = NoShading
    fxaa = true

    cycle = [:color => :patchcolor]

    @mixin mixin_generic_plot_attributes
    @mixin mixin_colormap_attributes
end

@recipe(Wireframe) do scene
    attr = Attributes(;
        depth_shift = -1f-5,
    )
    return merge!(attr, default_theme(scene, LineSegments))
end

@recipe(Arrows, points, directions) do scene
    attr = Attributes(
        color = :black,

        arrowsize = automatic,
        arrowhead = automatic,
        arrowtail = automatic,

        linecolor = automatic,
        linestyle = nothing,
        align = :origin,

        normalize = false,
        lengthscale = 1f0,

        colorscale = identity,

        quality = 32,
        markerspace = :pixel,
    )

    generic_plot_attributes!(attr)
    shading_attributes!(attr)
    colormap_attributes!(attr, theme(scene, :colormap))

    attr[:fxaa] = automatic
    attr[:linewidth] = automatic
    # connect arrow + linecolor by default
    get!(attr, :arrowcolor, attr[:linecolor])
    return attr
end
