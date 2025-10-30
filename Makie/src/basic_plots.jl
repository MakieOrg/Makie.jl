default_theme(scene) = generic_plot_attributes!(Attributes())
default_theme(::Type{<:Plot}) = Attributes(
    visible = true,
    transparency = false,
    inspectable = true,
    space = :data,
    inspector_label = automatic,
    inspector_clear = automatic,
    inspector_hover = automatic,
)

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
- `clip_planes::Vector{Plane3f} = Plane3f[]`: allows you to specify up to 8 planes behind which plot objects get clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene.
"""
function generic_plot_attributes!(attr)
    attr[:transformation] = :automatic
    attr[:model] = automatic
    attr[:visible] = true
    attr[:transparency] = false
    attr[:overdraw] = false
    attr[:inspectable] = true
    attr[:depth_shift] = 0.0f0
    attr[:space] = :data
    attr[:inspector_label] = automatic
    attr[:inspector_clear] = automatic
    attr[:inspector_hover] = automatic
    attr[:clip_planes] = automatic
    return attr
end

function generic_plot_attributes(attr)
    return (
        transformation = :automatic,
        model = automatic,
        visible = attr[:visible],
        transparency = attr[:transparency],
        overdraw = attr[:overdraw],
        ssao = attr[:ssao],
        inspectable = attr[:inspectable],
        depth_shift = attr[:depth_shift],
        space = attr[:space],
        inspector_label = attr[:inspector_label],
        inspector_clear = attr[:inspector_clear],
        inspector_hover = attr[:inspector_hover],
        clip_planes = attr[:clip_planes],
    )
end

function mixin_generic_plot_attributes()
    return @DocumentedAttributes begin
        """
        Controls the inheritance or directly sets the transformations of a plot.
        Transformations include the transform function and model matrix as generated
        by `translate!(...)`, `scale!(...)` and `rotate!(...)`. They can be set
        directly by passing a `Transformation()` object or inherited from the
        parent plot or scene. Inheritance options include:
        - `:automatic`: Inherit transformations if the parent and child `space` is compatible
        - `:inherit`: Inherit transformations
        - `:inherit_model`: Inherit only model transformations
        - `:inherit_transform_func`: Inherit only the transform function
        - `:nothing`: Inherit neither, fully disconnecting the child's transformations from the parent

        Another option is to pass arguments to the `transform!()` function which
        then get applied to the plot. For example `transformation = (:xz, 1.0)`
        which rotates the `xy` plane to the `xz` plane and translates by `1.0`.
        For this inheritance defaults to `:automatic` but can also be set through
        e.g. `(:nothing, (:xz, 1.0))`.
        """
        transformation = :automatic
        "Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`."
        model = automatic
        "Controls whether the plot gets rendered or not."
        visible = true
        "Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency."
        transparency = false
        "Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends"
        overdraw = false
        "Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`."
        ssao = false
        "Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene."
        inspectable = @inherit inspectable
        "Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw)."
        depth_shift = 0.0f0
        "Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs."
        space = :data
        """
        Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only).
        Note that some plots implement a better native anti-aliasing solution (scatter, text, lines).
        For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data
        (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.
        """
        fxaa = true
        "Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector."
        inspector_label = automatic
        "Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector."
        inspector_clear = automatic
        "Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods."
        inspector_hover = automatic
        """
        Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here,
        behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the
        parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.
        """
        clip_planes = @inherit clip_planes automatic
    end
end

"""
### Color attributes

- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
  `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils.
  To see all available color gradients, you can call `Makie.available_gradients()`.
- `colorscale::Function = identity` color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.
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
        alpha = attr[:alpha],
    )
end

function mixin_colormap_attributes(; kwargs...)
    attr = @DocumentedAttributes begin
        """
        Sets the colormap that is sampled for numeric `color`s.
        `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils.
        To see all available color gradients, you can call `Makie.available_gradients()`.
        """
        colormap = @inherit colormap :viridis
        """
        The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.
        """
        colorscale = identity
        "The values representing the start and end points of `colormap`."
        colorrange = automatic
        "The color for any value below the colorrange."
        lowclip = automatic
        "The color for any value above the colorrange."
        highclip = automatic
        "The color for NaN values."
        nan_color = :transparent
        "The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied."
        alpha = 1.0
    end
    return filter_attributes!(attr; kwargs...)
end

"""
### 3D shading attributes

- `shading = true` controls if the plot object is shaded by the parent scenes lights or not. The lighting algorithm used is controlled by the scenes `shading` attribute.
- `diffuse::Vec3f = Vec3f(1.0)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.4)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `backlight::Float32 = 0f0` sets a weight for secondary light calculation with inverted normals.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.
"""
function shading_attributes!(attr)
    attr[:shading] = true
    attr[:diffuse] = 1.0
    attr[:specular] = 0.2
    attr[:shininess] = 32.0f0
    attr[:backlight] = 0.0f0
    return attr[:ssao] = false
end

function shading_attributes(attr)
    return (
        shading = attr[:shading],
        diffuse = attr[:diffuse],
        specular = attr[:specular],
        shininess = attr[:shininess],
        backlight = attr[:backlight],
        ssao = attr[:ssao],
    )
end

function mixin_shading_attributes()
    return @DocumentedAttributes begin
        "Controls if the plot object is shaded by the parent scenes lights or not. The lighting algorithm used is controlled by the scenes `shading` attribute."
        shading = true
        "Sets how strongly the red, green and blue channel react to diffuse (scattered) light."
        diffuse = 1.0
        "Sets how strongly the object reflects light in the red, green and blue channels."
        specular = 0.2
        "Sets how sharp the reflection is."
        shininess = 32.0f0
        "Sets a weight for secondary light calculation with inverted normals."
        backlight = 0.0f0
        "RPRMakie only attribute to set complex RadeonProRender materials.
        *Warning*, how to set an RPR material may change and other backends will ignore this attribute"
        material = nothing
    end
end

"""
    calculated_attributes!(trait::Type{<: AbstractPlot}, plot)

trait version of `calculated_attributes`
"""
calculated_attributes!(trait, plot) = nothing

"""
    calculated_attributes!(plot::AbstractPlot)

Fill in values that can only be calculated when we have all other attributes filled
"""
calculated_attributes!(plot::T) where {T} = calculated_attributes!(T, plot)

"""
    image(x, y, image; attributes...)
    image(image; attributes...)

Plots an image on a rectangle bounded by `x` and `y` (defaults to size of image).

$(argument_docs(:ImageLike))
"""
@recipe Image (
    x::EndPoints,
    y::EndPoints,
    image::AbstractMatrix{<:Union{FloatType, Colorant}},
) begin
    "Sets whether colors should be interpolated between pixels."
    interpolate = true
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    fxaa = false
    """
    Sets a transform for uv coordinates, which controls how the image is mapped to its rectangular area.
    The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`,
    any of `:rotr90`, `:rotl90`, `:rot180`, `:swap_xy`/`:transpose`, `:flip_x`, `:flip_y`, `:flip_xy`, or most
    generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`.
    They can also be changed by passing a tuple `(op3, op2, op1)`.
    """
    uv_transform = automatic
    colormap = [:black, :white]
end

"""
    heatmap([xs, ys], data; attributes...)

Plots a `data` matrix as a heatmap, i.e. a collection of rectangles colored
based on the values in `data`.

Note that `heatmap` is slower to render than `image` so `image` should be
preferred for large, regularly spaced grids.

$(argument_docs(:CellGrid))
"""
@recipe Heatmap (
    x::Union{EndPoints, RealVector, RealMatrix},
    y::Union{EndPoints, RealVector, RealMatrix},
    image::AbstractMatrix{<:Union{FloatType, Colorant}},
) begin
    "Sets whether colors should be interpolated"
    interpolate = false
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

"""
    volume([x, y, z], volume_data; attributes...)

Plots a volume with optional physical dimensions `x, y, z`.

All volume plots are derived from casting rays for each drawn pixel. These rays
intersect with the volume data to derive some color, usually based on the given
colormap. How exactly the color is derived depends on the algorithm used.

$(argument_docs(:VolumeLike))
"""
@recipe Volume (
    x::EndPoints,
    y::EndPoints,
    z::EndPoints,
    # TODO: consider using RGB{N0f8}, RGBA{N0f8} instead of Vec/RGB(A){Float32}
    volume::AbstractArray{<:Union{Float32, Vec3f, RGB{Float32}, Vec4f, RGBA{Float32}}, 3},
) begin
    """
    Sets the volume algorithm that is used. Available algorithms are:
    * `:iso`: Shows an isovalue surface within the given float data. For this only samples within `isovalue - isorange .. isovalue + isorange` are included in the final color of a pixel.
    * `:absorption`: Accumulates color based on the float values sampled from volume data. At each ray step (starting from the front) a value is sampled from the volume data and then used to sample the colormap. The resulting color is weighted by the ray step size and blended the previously accumulated color. The weight of each step can be adjusted with the multiplicative `absorption` attribute.
    * `:mip`: Shows the maximum intensity projection of the given float data. This derives the color of a pixel from the largest value sampled from the respective ray.
    * `:absorptionrgba`: This algorithm matches :absorption, but samples colors directly from RGBA volume data. For each ray step a color is sampled from the data, weighted by the ray step size and blended with the previously accumulated color. Also considers `absorption`.
    * `:additive`: Accumulates colors using `accumulated_color = 1 - (1 - accumulated_color) * (1 - sampled_color)` where `sampled_color` is a sample of volume data at the current ray step.
    * `:indexedabsorption`: This algorithm acts the same as :absorption, but interprets the volume data as indices. They are used as direct indices to the colormap. Also considers `absorption`.
    """
    algorithm = :mip
    "Sets the target value for the :iso algorithm. `accepted = isovalue - isorange < value < isovalue + isorange`"
    isovalue = 0.5
    "Sets the maximum accepted distance from the isovalue for the :iso algorithm. `accepted = isovalue - isorange < value < isovalue + isorange`"
    isorange = 0.05
    "Sets whether the volume data should be sampled with interpolation."
    interpolate = true
    """
    Enables more accurate but slower depth handling. When turned off depth is based on the back vertices of the bounding
    box of the volume. When turned on it is based on the ray start point in front of the camera. For `algorithm = :iso`
    (and contours) it is based on the front most surface rendered.
    """
    enable_depth = true
    "Absorption multiplier for algorithm = :absorption, :absorptionrgba and :indexedabsorption. This changes how much light each voxel absorbs."
    absorption = 1.0f0
    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    mixin_colormap_attributes()...
end

const VecOrMat{T} = Union{AbstractVector{T}, AbstractMatrix{T}}

"""
    surface([xs, ys], zs; attributes...)
    surface(zs; attributes...)

Plots of surface defined by a grid of vertices.

$(argument_docs(:VertexGrid))
"""
@recipe Surface (x::VecOrMat{<:FloatType}, y::VecOrMat{<:FloatType}, z::VecOrMat{<:FloatType}) begin
    "Can be set to an `Matrix{<: Union{Number, Colorant}}` to color surface independent of the `z` component. If `color=nothing`, it defaults to `color=z`. Can also be a `Makie.AbstractPattern`."
    color = nothing
    """
    Applies a "material capture" texture to the generated mesh. A matcap encodes
    lighting and color data of a material on a circular texture which is sampled
    based on normal vectors.
    """
    matcap = nothing
    "Inverts the normals generated for the surface. This can be useful to illuminate the other side of the surface."
    invert_normals = false
    "[(W)GLMakie only] Specifies whether the surface matrix gets sampled with interpolation."
    interpolate = true
    """
    Sets a transform for uv coordinates, which controls how a texture is mapped to a surface.
    The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`,
    any of `:rotr90`, `:rotl90`, `:rot180`, `:swap_xy`/`:transpose`, `:flip_x`, `:flip_y`, `:flip_xy`, or most
    generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`.
    They can also be changed by passing a tuple `(op3, op2, op1)`.
    """
    uv_transform = automatic
    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    mixin_colormap_attributes()...
end

"""
    lines(positions; attributes...)
    lines([xs], ys; attributes...)
    lines(xs, ys, zs; attributes...)

Plots a line connecting consecutive positions. `NaN` values are displayed as
gaps in the line.

$(argument_docs(:PointBased))
"""
@recipe Lines (positions,) begin
    "The color of the line."
    color = @inherit linecolor
    "Sets the width of the line in screen units"
    linewidth = @inherit linewidth
    """
    Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`.
    These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`.
    For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

    For custom patterns have a look at [`Makie.Linestyle`](@ref).
    """
    linestyle = nothing
    """
    Sets the type of line cap used. Options are `:butt` (flat without extrusion),
    `:square` (flat with half a linewidth extrusion) or `:round`.
    """
    linecap = @inherit linecap
    """
    Controls the rendering at corners. Options are `:miter` for sharp corners,
    `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle
    is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.
    """
    joinstyle = @inherit joinstyle
    "Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`."
    miter_limit = @inherit miter_limit
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color]
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    fxaa = false
end

"""
    linesegments(positions; attributes...)
    linesegments(pairs; attributes...)
    linesegments([xs], ys; attributes...)
    linesegments(xs, ys, zs; attributes...)

Plots line segments between each consecutive pair of positions.

This does not draw a connected line. It connects positions 1 and 2, 3 and 4, etc.

$(argument_docs(:LineSegments))
"""
@recipe LineSegments (positions,) begin
    "The color of the line."
    color = @inherit linecolor
    "Sets the width of the line in pixel units"
    linewidth = @inherit linewidth
    """
    Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`.
    These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`.
    For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

    For custom patterns have a look at [`Makie.Linestyle`](@ref).
    """
    linestyle = nothing
    "Sets the type of linecap used, i.e. :butt (flat with no extrusion), :square (flat with 1 linewidth extrusion) or :round."
    linecap = @inherit linecap
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color]
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    fxaa = false
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    mesh(mesh_object; attributes...)
    mesh(xs, ys, zs; attributes...)
    mesh(xs, ys[, zs], faces; attributes...)
    mesh(positions[, faces]; attributes...)

Plots a 2D or 3D mesh.

## Arguments
- `mesh_object`: A [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl)
  `Mesh` or `MetaMesh` containing vertex and face data. The latter may also include
  material data for which Makie has some support.
- `xs, ys[, zs]`: An `AbstractVector{<:Real}` representing vertex positions per dimension.
- `positions`: An `AbstractVector{<:VecTypes{D, <:Real}}` representing vertex
  positions, where `VecTypes` include `Point`, `Vec` and `Tuple` and `D = 2` or
  `3` is the dimension of the data.
- `faces`: An `AbstractVector{<:GeometryBasics.AbstractFace}` containing information
  for how vertices connect to faces. If omitted, each consecutive triplet of vertex
  positions is connected as a triangle face with no overlap. E.g. `(1, 2, 3), (4, 5, 6)`.

Note that `meshscatter` is much better for plotting a single mesh at multiple positions.
"""
@recipe Mesh (mesh::Union{AbstractVector{<:GeometryBasics.Mesh}, GeometryBasics.Mesh, GeometryBasics.MetaMesh},) begin
    """
    Sets the color of the mesh. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`.
    A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain
    texture coordinates. A `<: AbstractPattern` can be used to apply a repeated, pixel sampled pattern to
    the mesh, e.g. for hatching.
    """
    color = @inherit patchcolor
    "sets whether colors should be interpolated"
    interpolate = true
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color => :patchcolor]
    """
    Applies a "material capture" texture to the generated mesh. A matcap encodes
    lighting and color data of a material on a circular texture which is sampled
    based on normal vectors.
    """
    matcap = nothing
    """
    Sets a transform for uv coordinates, which controls how a texture is mapped to a mesh.
    The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`,
    any of `:rotr90`, `:rotl90`, `:rot180`, `:swap_xy`/`:transpose`, `:flip_x`, `:flip_y`, `:flip_xy`, or most
    generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`.
    They can also be changed by passing a tuple `(op3, op2, op1)`.
    """
    uv_transform = automatic
    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    mixin_colormap_attributes()...
end

"""
    scatter([xs], ys; attributes...)
    scatter(xs, ys, zs; attributes...)
    scatter(positions; attributes...)

Plots a marker at each position.

$(argument_docs(:PointBased))
"""
@recipe Scatter (positions,) begin
    "Sets the color of the marker. If no color is set, multiple calls to `scatter!` will cycle through the axis color palette."
    color = @inherit markercolor
    "Sets the scatter marker."
    marker = @inherit marker
    """
    Sets the size of the marker by scaling it relative to its base size which can differ for each marker.
    A `Real` scales x and y dimensions by the same amount.
    A `Vec` or `Tuple` with two elements scales x and y separately.
    An array of either scales each marker separately.
    Humans perceive the area of a marker as its size which grows quadratically with `markersize`,
    so multiplying `markersize` by 2 results in a marker that is 4 times as large, visually.
    """
    markersize = @inherit markersize
    "Sets the color of the outline around a marker."
    strokecolor = @inherit markerstrokecolor
    "Sets the width of the outline around a marker."
    strokewidth = @inherit markerstrokewidth
    "Sets the color of the glow effect around the marker."
    glowcolor = (:black, 0.0)
    "Sets the size of a glow effect around the marker."
    glowwidth = 0.0

    "Sets the rotation of the marker. A `Billboard` rotation is always around the depth axis."
    rotation = Billboard()
    "The offset of the marker from the given position in `markerspace` units. An offset of 0 corresponds to a centered marker."
    marker_offset = Vec3f(0)
    "Controls whether the model matrix (without translation) applies to the marker itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the marker."
    transform_marker = false
    "Sets the font used for character markers. Can be a `String` specifying the (partial) name of a font or the file path of a font file"
    font = @inherit markerfont
    "Optional distancefield used for e.g. font and bezier path rendering. Will get set automatically."
    distancefield = nothing
    """
    Sets the font to be used for character markers
    """
    font = "default"
    "Sets the space in which `markersize` is given. See `Makie.spaces()` for possible inputs"
    markerspace = :pixel
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color]
    "Enables depth-sorting of markers which can improve border artifacts. Currently supported in GLMakie only."
    depthsorting = false
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    fxaa = false
end

function deprecated_attributes(::Type{<:Scatter})
    return (
        (; attribute = :rotations, message = "`rotations` has been renamed to `rotation` for consistency in Makie v0.21.", error = true),
    )
end

"""
    meshscatter(positions; attributes...)
    meshscatter(xs, ys; attributes...)
    meshscatter(xs, ys, zs; attributes...)

Plots a single mesh at multiple position. The mesh can be scaled and rotated
through attributes.

$(argument_docs(:PointBased))
"""
@recipe MeshScatter (positions,) begin
    matcap = nothing
    "Sets the color of the marker."
    color = @inherit markercolor
    "Sets the scattered mesh."
    marker = :Sphere
    "Sets the scale of the mesh. This can be given as a `Vector` to apply to each scattered mesh individually."
    markersize = 0.1
    "Sets the rotation of the mesh. A numeric rotation is around the z-axis, a `Vec3f` causes the mesh to rotate such that the the z-axis is now that vector, and a quaternion describes a general rotation. This can be given as a Vector to apply to each scattered mesh individually."
    rotation = 0.0
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color]
    """
    Sets a transform for uv coordinates, which controls how a texture is mapped to the scattered mesh.
    Note that the mesh needs to include uv coordinates for this, which is not the case by default
    for geometry primitives. You can use `GeometryBasics.uv_normal_mesh(prim)` with, for example `prim = Rect2f(0, 0, 1, 1)`.
    The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`,
    any of `:rotr90`, `:rotl90`, `:rot180`, `:swap_xy`/`:transpose`, `:flip_x`, `:flip_y`, `:flip_xy`, or most
    generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`.
    It can also be set per scattered mesh by passing a `Vector` of any of the above and operations
    can be changed by passing a tuple `(op3, op2, op1)`.
    """
    uv_transform = automatic
    "Controls whether the (complete) model matrix applies to the scattered mesh, rather than just the positions. (If this is false, `scale!`, `rotate!` and `translate!()` will not affect the scattered mesh.)"
    transform_marker = true
    "When using textures as colors, controls whether the texture is sampled with linear interpolation (true) or nearest interpolation (false). (This requires the scattered mesh to include uv coordinates.)"
    interpolate = true
    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    mixin_colormap_attributes()...
end

function deprecated_attributes(::Type{<:MeshScatter})
    return (
        (; attribute = :rotations, message = "`rotations` has been renamed to `rotation` for consistency in Makie v0.21.", error = true),
    )
end

"""
    text(positions; text, attributes...)
    text(xs, ys; text, attributes...)
    text(xs, ys, zs; text, attributes...)

Plots one or multiple texts passed via the `text` keyword.

$(argument_docs(:PointBased))
"""
@recipe Text (positions,) begin
    "Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`."
    text = ""
    "Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}`, or one colorant for the whole text. If color is a vector of numbers, the colormap args are used to map the numbers to colors."
    color = @inherit textcolor
    "Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file"
    font = @inherit font
    "Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`."
    fonts = @inherit fonts
    "Sets the color of the outline around a marker."
    strokecolor = (:black, 0.0)
    "Sets the width of the outline around a marker."
    strokewidth = 0
    "Sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions."
    align = (:left, :bottom)
    "Rotates text around the given position"
    rotation = 0.0
    "The fontsize in units depending on `markerspace`."
    fontsize = @inherit fontsize
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
    "Sets the color of the glow effect around the text."
    glowcolor = (:black, 0.0)
    "Sets the size of a glow effect around the text."
    glowwidth = 0.0
    "The offset of the text from the given position in `markerspace` units."
    offset = (0.0, 0.0)
    "Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping."
    word_wrap_width = -1
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
    fxaa = false
end

function deprecated_attributes(::Type{<:Text})
    return (
        (; attribute = :textsize, message = "`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version.", error = true),
    )
end

"""
    voxels([x, y, z], data; attributes...)
    voxels(data; attributes...)

Plots a 3D array of data as voxels (small cubes) within the limits defined by
`x`, `y` and `z`.

## Arguments (`VolumeLike()`)
- `data`: An `AbstractArray{<:Real, 3}` defining voxel data for colormapping or
  an `AbstractArray{<:UInt8, 3}` defining voxel ids for texture mapping.
- `x, y, z`: Defines the boundary of a 3D rectangle with a `Tuple{<:Real, <:Real}` \
or `ClosedInterval{<:Real}`. If omitted `x`, `y` and `z` default to `0 .. size(data)`.

See `conversion_docs(PlotType)` for a full list of applicable conversion methods.

Note that `voxels` is currently considered experimental and may still see breaking
changes in patch releases.
"""
@recipe Voxels (x, y, z, chunk) begin
    "A function that controls which values in the input data are mapped to invisible (air) voxels."
    is_air = x -> isnothing(x) || ismissing(x) || isnan(x)
    """
    Deprecated - use uv_transform
    """
    uvmap = nothing
    """
    To use texture mapping `uv_transform` needs to be defined and `color` needs to be an image.
    The `uv_transform` can be given as a `Vector` where each index maps to a `UInt8` voxel id (skipping 0),
    or as a `Matrix` where the second index maps to a side following the order `(-x, -y, -z, +x, +y, +z)`.
    Each element acts as a `Mat{2, 3, Float32}` which is applied to `Vec3f(uv, 1)`, where uv's are generated to run from 0..1 for each voxel.
    The result is then used to sample the texture.
    UV transforms have a bunch of shorthands you can use, for example `(Point2f(x, y), Vec2f(xscale, yscale))`.
    They are listed in `?Makie.uv_transform`.
    """
    uv_transform = nothing
    "Controls whether the texture map is sampled with interpolation (i.e. smoothly) or not (i.e. pixelated)."
    interpolate = false
    """
    Controls the render order of voxels. If set to `false` voxels close to the viewer are
    rendered first which should reduce overdraw and yield better performance. If set to
    `true` voxels are rendered back to front enabling correct order for transparent voxels.
    """
    depthsorting = false
    "Sets the gap between adjacent voxels in units of the voxel size. This needs to be larger than 0.01 to take effect."
    gap = 0.0

    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    mixin_colormap_attributes()...

    """
    Sets colors per voxel id, skipping `0x00`. This means that a voxel with id 1 will grab
    `plot.colors[1]` and so on up to id 255. This can also be set to a Matrix of colors,
    i.e. an image for texture mapping.
    """
    color = nothing
end


"""
    poly(vertices, indices; attributes...)
    poly(points; attributes...)
    poly(shape; attributes...)
    poly(mesh; attributes...)

Plots a polygon based on the arguments given.
When vertices and indices are given, it functions similarly to `mesh`.
When points are given, it draws one polygon that connects all the points in order.
When a shape is given (essentially anything decomposable by `GeometryBasics`), it
will plot `decompose(shape)`.

    poly(coordinates, connectivity; kwargs...)

Plots polygons, which are defined by `coordinates` (the coordinates of the
vertices) and `connectivity` (the edges between the vertices).
"""
@recipe Poly (polygon,) begin
    """
    Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`.
    A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates.
    Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors.
    One can also use a `<: AbstractPattern`, to cover the poly with a regular pattern, e.g. for hatching.
    """
    color = @inherit patchcolor
    "Sets the color of the outline around a marker."
    strokecolor = @inherit patchstrokecolor
    "Sets the colormap that is sampled for numeric `color`s."
    strokecolormap = @inherit colormap
    "Sets the width of the outline."
    strokewidth = @inherit patchstrokewidth
    """
    Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`.
    These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`.
    For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

    For custom patterns have a look at [`Makie.Linestyle`](@ref).
    """
    linestyle = nothing
    """
    Sets the type of line cap used for outlines. Options are `:butt` (flat without
    extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.
    """
    linecap = @inherit linecap
    """
    Controls the rendering of outline corners. Options are `:miter` for sharp corners,
    `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle
    is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.
    """
    joinstyle = @inherit joinstyle
    """
    Sets the minimum inner join angle below which miter line joins truncate.
    See also `Makie.miter_distance_to_angle`.
    """
    miter_limit = @inherit miter_limit
    "Controls whether lights affect the polygon."
    shading = false

    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color => :patchcolor]
    """
    Depth shift of stroke plot. This is useful to avoid z-fighting between the stroke and the fill.
    """
    stroke_depth_shift = -1.0f-5
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

"""
    wireframe(xs, ys, zs; attributes...)
    wireframe(mesh; attributes...)

Draws a wireframe of surface or mesh data.

## Arguments
- `xs, ys, zs`: Surface-like data where vertices are part of a grid. `xs, ys` are given
  as `AbstractVector{<:Real}` and `zs` is given as an `AbstractMatrix{<:Real}`. The
  lengths of `xs, ys` must match the size of `zs`.
- `mesh`: An object implementing [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl)
  `decompose()` methods for `Point` and `LineFace`. This is typically a GeometryBasics
  `Mesh`, `MetaMesh` or `GeometryPrimitive`.
"""
@recipe Wireframe begin
    documented_attributes(LineSegments)...
    depth_shift = -1.0f-5
end
