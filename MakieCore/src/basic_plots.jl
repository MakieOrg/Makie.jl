
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

"""
@recipe(Image, x, y, image) do scene
    Attributes(;
        default_theme(scene)...,
        colormap = [:black, :white],
        colorrange = automatic,
        interpolate = true,
        fxaa = false,
        lowclip = nothing,
        highclip = nothing,
        inspectable = theme(scene, :inspectable)
    )
end

"""
    heatmap(x, y, values)
    heatmap(values)

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).

"""
@recipe(Heatmap, x, y, values) do scene
    Attributes(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linewidth = 0.0,
        interpolate = false,
        levels = 1,
        fxaa = true,
        lowclip = nothing,
        highclip = nothing,
        inspectable = theme(scene, :inspectable)
    )
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
@recipe(Volume, x, y, z, volume) do scene
    Attributes(;
        default_theme(scene)...,
        algorithm = :mip,
        isovalue = 0.5,
        isorange = 0.05,
        color = nothing,
        colormap = theme(scene, :colormap),
        colorrange = (0, 1),
        fxaa = true,
        inspectable = theme(scene, :inspectable)
    )
end

"""
    surface(x, y, z)

Plots a surface, where `(x, y)`  define a grid whose heights are the entries in `z`.
`x` and `y` may be `Vectors` which define a regular grid, **or** `Matrices` which define an irregular grid.

"""
@recipe(Surface, x, y, z) do scene
    Attributes(;
        default_theme(scene)...,
        color = nothing,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        shading = true,
        fxaa = true,
        lowclip = nothing,
        highclip = nothing,
        invert_normals = false,
        inspectable = theme(scene, :inspectable)
    )
end

"""
    lines(positions)
    lines(x, y)
    lines(x, y, z)

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.

!!! tip
    You can separate segments by inserting `NaN`s.
"""
@recipe(Lines, positions) do scene
    Attributes(;
        default_theme(scene)...,
        linewidth = theme(scene, :linewidth),
        color = theme(scene, :linecolor),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linestyle = nothing,
        fxaa = false,
        cycle = [:color],
        inspectable = theme(scene, :inspectable)
    )
end

"""
    linesegments(positions)
    linesegments(x, y)
    linesegments(x, y, z)

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

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

"""
@recipe(Mesh, mesh) do scene
    Attributes(;
        default_theme(scene)...,
        color = :black,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        interpolate = false,
        shading = true,
        fxaa = true,
        inspectable = theme(scene, :inspectable),
        cycle = [:color => :patchcolor],
    )
end

"""
    scatter(positions)
    scatter(x, y)
    scatter(x, y, z)

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.

"""
@recipe(Scatter, positions) do scene
    Attributes(;
        default_theme(scene)...,
        color = theme(scene, :markercolor),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
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
        markerspace = Pixel,
        fxaa = false,
        cycle = [:color],
        inspectable = theme(scene, :inspectable)
    )
end

"""
    meshscatter(positions)
    meshscatter(x, y)
    meshscatter(x, y, z)

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`.

"""
@recipe(MeshScatter, positions) do scene
    Attributes(;
        default_theme(scene)...,
        color = :black,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        marker = :Sphere,
        markersize = 0.1,
        rotations = 0.0,
        # markerspace = relative,
        shading = true,
        fxaa = true,
        inspectable = theme(scene, :inspectable),
        cycle = [:color],
    )
end

"""
    text(string)

Plots a text.

"""
@recipe(Text, text) do scene
    Attributes(;
        default_theme(scene)...,
        color = theme(scene, :textcolor),
        font = theme(scene, :font),
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = (0.0, 0.0),
        justification = automatic,
        lineheight = 1.0,
        space = :screen, # or :data
        offset = (0.0, 0.0),
        inspectable = theme(scene, :inspectable)
    )
end
