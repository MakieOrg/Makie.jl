default_theme(scene) = default_theme!(Attributes())

function default_theme!(attr)
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

function colormap_args!(attr, colormap)
    attr[:colormap] = colormap
    attr[:colorscale] = identity
    attr[:colorrange] = automatic
    attr[:lowclip] = automatic
    attr[:highclip] = automatic
    attr[:nan_color] = :transparent
    attr[:alpha] = 1.0
    return attr
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

Plots an image on range `x, y` (defaults to dimensions).

## Attributes

### Specific to `Image`

- `lowclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value below the colorrange.
- `highclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value above the colorrange.
- `interpolate::Bool = true` sets whether colors should be interpolated.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` is set by the plot.
- `colormap::Union{Symbol, Vector{<:Colorant}} = [:black, :white` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for the position of the image. See `Makie.spaces()` for possible inputs.
"""
@recipe(Image, x, y, image) do scene
    attr = Attributes(;
        interpolate = true,
        fxaa = false,
    )
    default_theme!(attr)
    return colormap_args!(attr, [:black, :white])
end

"""
    heatmap(x, y, values)
    heatmap(values)

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).

## Attributes

### Specific to `Heatmap`

- `lowclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value below the colorrange.
- `highclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value above the colorrange.
- `interpolate::Bool = false` sets whether colors should be interpolated.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` is set by the plot.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for the position of the heatmap. See `Makie.spaces()` for possible inputs.
"""
@recipe(Heatmap, x, y, values) do scene
    attr = Attributes(;

        interpolate = false,

        linewidth = 0.0,
        fxaa = true,
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
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

## Attributes

### Specific to `Volume`

- `algorithm::Union{Symbol, RaymarchAlgorithm} = :mip` sets the volume algorithm that is used.
- `isorange::Real = 0.05` sets the range of values picked up by the IsoValue algorithm.
- `isovalue = 0.5` sets the target value for the IsoValue algorithm.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for box encompassing the volume plot. See `Makie.spaces()` for possible inputs.
### Generic 3D

- `shading = true` enables lighting.
- `diffuse::Vec3f = Vec3f(0.4)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.2)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.
"""
@recipe(Volume, x, y, z, volume) do scene
    attr = Attributes(;

        algorithm = :mip,
        isovalue = 0.5,
        isorange = 0.05,

        fxaa = true,

        diffuse=0.4,
        specular=0.2,
        shininess=32.0f0
    )
    default_theme!(attr, )
    return colormap_args!(attr, theme(scene, :colormap))
end

"""
    surface(x, y, z)

Plots a surface, where `(x, y)`  define a grid whose heights are the entries in `z`.
`x` and `y` may be `Vectors` which define a regular grid, **or** `Matrices` which define an irregular grid.

`Surface` has the conversion trait `ContinuousSurface <: SurfaceLike`.

## Attributes

### Specific to `Surface`

- `lowclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value below the colorrange.
- `highclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value above the colorrange.
- `invert_normals::Bool = false` inverts the normals generated for the surface. This can be useful to illuminate the other side of the surface.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for vertices generated by surface. See `Makie.spaces()` for possible inputs.

### Generic 3D

- `shading = true` enables lighting.
- `diffuse::Vec3f = Vec3f(0.4)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.2)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.
"""
@recipe(Surface, x, y, z) do scene
    attr = Attributes(;
        color = nothing,
        backlight = 0f0,
        shading = true,
        invert_normals = false,
        diffuse=0.4,
        specular=0.2,
        shininess=32.0f0,

        fxaa = true,
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
end

"""
    lines(positions)
    lines(x, y)
    lines(x, y, z)

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.

`NaN` values are displayed as gaps in the line.

## Attributes

### Specific

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `linestyle::Union{Nothing, Symbol, Vector} = nothing` sets the pattern of the line (e.g. `:solid`, `:dot`, `:dashdot`)
- `linewidth::Union{Real, Vector} = 1.5` sets the width of the line in pixel units.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing). Note that line plots already use a different form of anti-aliasing.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each point in the line by passing a `Vector` of colors or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for line position. See `Makie.spaces()` for possible inputs.
"""
@recipe(Lines, positions) do scene
    attr = Attributes(;

        color = theme(scene, :linecolor),
        linewidth = theme(scene, :linewidth),

        linestyle = nothing,
        fxaa = false,
        cycle = [:color],
    )
    default_theme!(attr, )
    return colormap_args!(attr, theme(scene, :colormap))
end

"""
    linesegments(positions)
    linesegments(vector_of_2tuples_of_points)
    linesegments(x, y)
    linesegments(x, y, z)

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

## Attributes

### Specific to `LineSegments`

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `linestyle::Union{Nothing, Symbol, Vector} = nothing` sets the pattern of the line (e.g. `:solid`, `:dot`, `:dashdot`)
- `linewidth::Union{Real, Vector} = 1.5` sets the width of the line in pixel units.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing). Note that line plots already use a different form of anti-aliasing.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each point in the line by passing a `Vector` or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for line position. See `Makie.spaces()` for possible inputs.
"""
@recipe(LineSegments, positions) do scene
    default_theme(scene, Lines)
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    mesh(x, y, z)
    mesh(mesh_object)
    mesh(x, y, z, faces)
    mesh(xyz, faces)

Plots a 3D or 2D mesh. Supported `mesh_object`s include `Mesh` types from [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl).

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. A `Vector` of any of these can be passed to define the color per vertex. (It may be helpful to check `GeometryBasics.coordinates(my_mesh)` for this.) A `Vector{<: Real}` can also be passed to sample a colormap for each vertex. And finally, if the mesh includes uv coordinates you can pass a `Matrix` of colors to be used as a texture.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `lowclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value below the colorrange.
- `highclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value above the colorrange.
- `space::Symbol = :data` sets the transformation space for vertex positions. See `Makie.spaces()` for possible inputs.
- `interpolate::Bool = true` wether color=Matrix gets interpolated or not

### Generic 3D

- `shading = true` enables lighting.
- `diffuse::Vec3f = Vec3f(0.4)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.2)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.
"""
@recipe(Mesh, mesh) do scene
    attr = Attributes(;
        color = :black,
        interpolate = true,

        fxaa = true,
        cycle = [:color => :patchcolor],

        shading = true,
        backlight = 0f0,
        diffuse = 0.4,
        specular = 0.2,
        shininess = 32f0,
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
end

"""
    scatter(positions)
    scatter(x, y)
    scatter(x, y, z)

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.

## Attributes

### Specific to `Scatter`

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `marker::Union{Symbol, Char, Matrix{<:Colorant}, BezierPath, Polygon}` sets the scatter marker.
- `markersize::Union{<:Real, Vec2f} = 9` sets the size of the marker.
- `markerspace::Symbol = :pixel` sets the space in which `markersize` is given. See `Makie.spaces()` for possible inputs.
- `strokewidth::Real = 0` sets the width of the outline around a marker.
- `strokecolor::Union{Symbol, <:Colorant} = :black` sets the color of the outline around a marker.
- `glowwidth::Real = 0` sets the size of a glow effect around the marker.
- `glowcolor::Union{Symbol, <:Colorant} = (:black, 0)` sets the color of the glow effect.
- `rotations::Union{Real, Billboard, Quaternion} = Billboard(0f0)` sets the rotation of the marker. A `Billboard` rotation is always around the depth axis.
- `transform_marker::Bool = false` controls whether the model matrix (without translation) applies to the marker itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the marker.)

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing). Note that scatter plots already include a different form of anti-aliasing when plotting non-image markers.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each scattered marker by passing a `Vector` of colors or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `lowclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value below the colorrange.
- `highclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value above the colorrange.
- `space::Symbol = :data` sets the transformation space for positions of markers. See `Makie.spaces()` for possible inputs.
"""
@recipe(Scatter, positions) do scene
    attr = Attributes(;
        color = theme(scene, :markercolor),

        marker = theme(scene, :marker),
        markersize = theme(scene, :markersize),

        strokecolor = theme(scene, :markerstrokecolor),
        strokewidth = theme(scene, :markerstrokewidth),
        glowcolor = (:black, 0.0),
        glowwidth = 0.0,

        rotations = Billboard(),
        marker_offset = automatic,

        transform_marker = false, # Applies the plots transformation to marker
        distancefield = nothing,
        uv_offset_width = (0.0, 0.0, 0.0, 0.0),
        markerspace = :pixel,

        fxaa = false,
        cycle = [:color],
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
end

"""
    meshscatter(positions)
    meshscatter(x, y)
    meshscatter(x, y, z)

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`.

## Attributes

### Specific to `MeshScatter`

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `marker::Union{Symbol, GeometryBasics.GeometryPrimitive, GeometryBasics.Mesh}` sets the scattered mesh.
- `markersize::Union{<:Real, Vec3f} = 0.1` sets the scale of the mesh. This can be given as a Vector to apply to each scattered mesh individually.
- `rotations::Union{Real, Vec3f, Quaternion} = 0` sets the rotation of the mesh. A numeric rotation is around the z-axis, a `Vec3f` causes the mesh to rotate such that the the z-axis is now that vector, and a quaternion describes a general rotation. This can be given as a Vector to apply to each scattered mesh individually.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each scattered mesh by passing a `Vector` of colors or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `lowclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value below the colorrange.
- `highclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value above the colorrange.
- `space::Symbol = :data` sets the transformation space for the positions of meshes. See `Makie.spaces()` for possible inputs.

### Generic 3D

- `shading = true` enables lighting.
- `diffuse::Vec3f = Vec3f(0.4)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.2)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.
"""
@recipe(MeshScatter, positions) do scene
    attr = Attributes(;
        color = :black,

        marker = :Sphere,
        markersize = 0.1,
        rotations = 0.0,
        space = :data,

        shading = true,
        backlight = 0f0,
        diffuse = 0.4,
        specular = 0.2,
        shininess = 32f0,

        fxaa = true,
        cycle = [:color],
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
end

"""
    text(positions; text, kwargs...)
    text(x, y; text, kwargs...)
    text(x, y, z; text, kwargs...)

Plots one or multiple texts passed via the `text` keyword.
`Text` uses the `PointBased` conversion trait.

## Attributes

### Specific to `Text`

- `text` specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`.
- `align::Tuple{Union{Symbol, Real}, Union{Symbol, Real}} = (:left, :bottom)` sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.
- `font::Union{String, Vector{String}} = :regular` sets the font for the string or each character.
- `justification::Union{Real, Symbol} = automatic` sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.
- `rotation::Union{Real, Quaternion}` rotates text around the given position.
- `fontsize::Union{Real, Vec2f}` sets the size of each character.
- `markerspace::Symbol = :pixel` sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs.
- `strokewidth::Real = 0` sets the width of the outline around a marker.
- `strokecolor::Union{Symbol, <:Colorant} = :black` sets the color of the outline around a marker.
- `glowwidth::Real = 0` sets the size of a glow effect around the marker.
- `glowcolor::Union{Symbol, <:Colorant} = (:black, 0)` sets the color of the glow effect.
- `word_wrap_with::Real = -1` specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping.

### Generic attributes

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing). Note that text plots already include a different form of anti-aliasing.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each character by passing a `Vector` of colors.
- `space::Symbol = :data` sets the transformation space for text positions. See `Makie.spaces()` for possible inputs.

"""
@recipe(Text, positions) do scene
    attr = Attributes(;
        color = theme(scene, :textcolor),

        font = theme(scene, :font),
        fonts = theme(scene, :fonts),

        strokecolor = (:black, 0.0),
        strokewidth = 0,
        align = (:left, :bottom),
        rotation = 0.0,
        fontsize = theme(scene, :fontsize),
        position = (0.0, 0.0),
        justification = automatic,
        lineheight = 1.0,
        markerspace = :pixel,

        offset = (0.0, 0.0),
        word_wrap_width = -1,
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
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

## Attributes

### Specific to `Poly`

- `lowclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value below the colorrange.
- `highclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value above the colorrange.
- `strokecolor::Union{Symbol, <:Colorant} = :black` sets the color of the outline around a marker.
- `strokewidth::Real = 0` sets the width of the outline around a marker.
- `linestyle::Union{Nothing, Symbol, Vector} = nothing` sets the pattern of the line (e.g. `:solid`, `:dot`, `:dashdot`)

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `color` is set by the plot.
- `colormap::Union{Symbol, Vector{<:Colorant}} = [:black, :white` sets the colormap that is sampled for numeric `color`s.
- `colorscale::Function = identity` color transform function.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `lowclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value below the colorrange.
- `highclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value above the colorrange.
- `space::Symbol = :data` sets the transformation space for the position of the image. See `Makie.spaces()` for possible inputs.
- `cycle::Vector{Symbol} = [:color => :patchcolor]` sets which attributes to cycle when creating multiple plots.
- `shading = false` enables lighting.
"""
@recipe(Poly) do scene
    attr = Attributes(;
        color = theme(scene, :patchcolor),

        strokecolor = theme(scene, :patchstrokecolor),
        strokewidth = theme(scene, :patchstrokewidth),
        linestyle = nothing,

        shading = false,
        fxaa = true,

        cycle = [:color => :patchcolor],
    )
    default_theme!(attr)
    return colormap_args!(attr, theme(scene, :colormap))
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
        inspectable = theme(scene, :inspectable),
        markerspace = :pixel,

        diffuse=0.4,
        specular=0.2,
        shininess=32.0f0
    )

    colormap_args!(attr, theme(scene, :colormap))

    attr[:fxaa] = automatic
    attr[:linewidth] = automatic
    # connect arrow + linecolor by default
    get!(attr, :arrowcolor, attr[:linecolor])
    return attr
end
