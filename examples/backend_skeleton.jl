
"""
    `scatter(x, y, z)` / `scatter(x, y)` / `scatter(positions)`

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.
"""
function draw(scene::Scene, plot::Scatter)
    # Extracts attributes from plot and makes them available in the current scope
    # This also applies all conversions + extracts the current value from them.
    # e.g. plot[:color] might be e.g. Node(:red), while @get_attribute(plot, (color,)) will be
    # RGBAf0(1, 0, 0, 1) in this case!
    @get_attribute(plot, (marker,
        markersize,strokecolor,strokewidth,glowcolor,glowwidth,rotations,
        colormap,colorrange,marker_offset,fxaa,transform_marker, # Applies the plots transformation to marker
        uv_offset_width, distancefield, model
    ))
    positions_node = plot[1] # a node with positions, that will update its value whenever changed by user
    #extract the current value - alternativel just use positions_node[] to extract! Will always be a vector of points...
    positions = to_value(positions_node)::AbstractVector{<: Point}

    projected_positions = map(positions) do pos
        # take camera from scene + model transformation matrix and apply it to pos
        Makie.CairoBackend.project_position(scene, pos, model)
    end
    projected_positions::Vector{Vec2f0} # now you get 2D positions correctly transformed by the camera to screen pixel coordinates
end


"""
    `image(x, y, image)` / `image(image)`

Plots an image on range `x, y` (defaults to dimensions).
"""
function draw(scene::Scene, plot::Image)
    @get_attribute plot (colormap, colorrange)
end


# could be implemented via image, but might be optimized specifically by the backend
"""
    `heatmap(x, y, values)` or `heatmap(values)`

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).
"""
function draw(scene::Scene, plot::Heatmap)
    @get_attribute(plot, (colormap,colorrange,linewidth,levels,fxaa,interpolate))
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
function draw(scene::Scene, plot::Volume)
    @get_attribute(plot, (algorithm,absorption,isovalue,isorange,colormap,colorrange))

end

"""
    `surface(x, y, z)`

Plots a surface, where `(x, y, z)` are supposed to lie on a grid.
"""
function draw(scene::Scene, plot::Surface)
    @get_attribute(plot, (colormap,colorrange,shading))
end

"""
    `lines(x, y, z)` / `lines(x, y)` / or `lines(positions)`

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.
"""
function draw(scene::Scene, plot::Lines)
    @get_attribute(plot, (linewidth,colormap,colorrange,linestyle))
end

"""
    `linesegments(x, y, z)` / `linesegments(x, y)` / `linesegments(positions)`

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

**Attributes**:
The same as for [`lines`](@ref)
"""
function draw(scene::Scene, plot::LineSegments)
    @get_attribute(plot, (linewidth,colormap,colorrange,linestyle))
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    `mesh(x, y, z)`, `mesh(mesh_object)`, `mesh(x, y, z, faces)`, or `mesh(xyz, faces)`

Plots a 3D mesh.
"""
function draw(scene::Scene, plot::Mesh)
    @get_attribute(plot, (interpolate,shading,colormap,colorrange))
end


"""
    `meshscatter(x, y, z)` / `meshscatter(x, y)` / `meshscatter(positions)`

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`
"""
function draw(scene::Scene, plot::MeshScatter)
    @get_attribute(plot, (marker,markersize,rotations,colormap,colorrange))
end

"""
    `text(string)`

Plots a text.
"""
function draw(scene::Scene, plot::Text)
    @get_attribute(plot, (strokecolor,strokewidth,font,align,rotation,textsize,position))
end
