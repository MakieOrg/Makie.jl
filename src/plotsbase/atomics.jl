# Defaults for atomics

function to_modelmatrix(b, scale, offset, rotation)
    lift_node(scale, offset, rotation) do s, o, r
        q = Quaternion(r[4], r[1], r[2], r[3])
        transformationmatrix(o, s, q)
    end
end

@default function shared(scene, kw_args)
    visible = to_bool(visible)
    scale = to_scale(scale)
    offset = to_offset(offset)
    rotation = to_rotation(rotation)
    model = to_modelmatrix(scale, offset, rotation)
    camera = to_camera(camera)
    show = to_bool(show)
    light = to_static_vec(light)
end


# Note that this will create a function called surface_defaults
# This is not perfect, but for integrating this into the scene, it's the easiest to
# just have the default function name in the macro match the drawing function name.
@default function surface(scene, kw_args)
    x = to_surface(x)
    y = to_surface(y)
    z = to_surface(z)
    xor(
        begin # Colormap is first, so it will default to it
            colormap = to_colormap(colormap)
            # convert function should only have one argument right now, so we create this closure
            colornorm = ((s, colornorm) -> to_colornorm(s, colornorm, z))(colornorm)
        end,
        begin
            color = to_color(color)
        end,
        if (image,)
            image = to_image(image)
        end
    )
end

@default function lines(scene, kw_args)
    xor(
        begin
            positions = to_positions(positions)
        end,
        if (x, y, z)
            x = to_array(x)
            y = to_array(y)
            z = to_array(z)
            positions = to_positions((x, y, z))
        end,
        if (x, y)
            x = to_array(x)
            y = to_array(y)
            positions = to_positions((x, y))
        end
    )
    xor(
        begin
            color = to_color(color)
        end,
        begin
            colormap = to_colormap(colormap)
            intensity = to_intensity(intensity)
            colornorm = to_colornorm(colornorm, intensity)
        end
    )
    linewidth = to_float(linewidth)
    linestyle = to_linestyle(linestyle)
    drawover = to_bool(drawover)
end

@default function mesh(scene, kw_args)
    shading = to_bool(shading)
    attribute_id = to_attribut_id(attribute_id)
    color = to_color(color)

    xor(
        if (indices,)
            indices = to_faces(indices)
            xor(
                if (positions,)
                    positions = to_positions(positions)
                end,
                if (x, y, z)
                    x = to_array(x)
                    y = to_array(y)
                    z = to_array(z)
                    positions = to_positions((x, y, z))
                end
            )
            mesh = to_mesh(positions, indices, color, attribute_id)
        end,
        begin
            mesh = to_mesh(mesh)
        end
    )
end

@default function scatter(scene, kw_args)
    xor(
        begin
            positions = to_positions(positions)
        end,
        if (x, y, z)
            x = to_array(x)
            y = to_array(y)
            z = to_array(z)
            positions = to_positions((x, y, z))
        end,
        if (x, y)
            x = to_array(x)
            y = to_array(y)
            positions = to_positions((x, y))
        end
    )
    # Either you give a color, or a colormap.
    # For a colormap, you'll also need intensities
    xor(
        begin
            color = to_color(color)
        end,
        begin
            colormap = to_colormap(colormap)
            intensity = to_intensity(intensity)
            colornorm = to_colornorm(colornorm, intensity)
        end
    )
    marker = to_spritemarker(marker)

    strokecolor = to_color(strokecolor)
    strokewidth = to_float(strokewidth)

    glowcolor = to_color(glowcolor)
    glowwidth = to_float(glowwidth)

    markersize = to_markersize2d(markersize)

    rotations = to_rotations(rotations)
end

@default function meshscatter(scene, kw_args)
    xor(
        begin
            positions = to_positions(positions)
        end,
        if (x, y, z)
            x = to_array(x)
            y = to_array(y)
            z = to_array(z)
            positions = to_positions((x, y, z))
        end,
        if (x, y)
            x = to_array(x)
            y = to_array(y)
            positions = to_positions((x, y))
        end
    )
    # Either you give a color, or a colormap.
    # For a colormap, you'll also need intensities
    xor(
        begin
            color = to_color(color)
        end,
        begin
            colormap = to_colormap(colormap)
            intensity = to_intensity(intensity)
            colornorm = to_colornorm(colornorm, intensity)
        end
    )

    marker = to_mesh(marker)
    markersize = to_markersize3d(markersize)
    rotations = to_rotations(rotations)
end

@default function image(scene, kw_args)
    spatialorder = to_spatial_order(spatialorder)
    x = to_interval(x)
    y = to_interval(y)
    image = to_image(image)
end

@default function volume(scene, kw_args)
    volume = to_array(volume)
    xor(
        begin
            color = to_color(color)
        end,
        begin
            colormap = to_colormap(colormap)
            # convert function should only have one argument right now, so we create this closure
            colornorm = ((b, colornorm) -> to_colornorm(b, colornorm, volume))(colornorm)
        end
    )
    algorithm = to_volume_algorithm(algorithm)
    absorption = to_float(absorption)
    isovalue = to_float(isovalue)
    isorange = to_float(isorange)
end

@default function heatmap(scene, kw_args)
    linewidth = to_float(linewidth)
    levels = to_float(levels)
    heatmap = to_array(heatmap)

    colormap = to_colormap(colormap)
    # convert function should only have one argument right now, so we create this closure
    colornorm = ((b, colornorm) -> to_colornorm(b, colornorm, heatmap))(colornorm)
end

@default function axis(scene, kw_args)
    axisnames = to_text(axisnames)

    showticks = to_bool(showticks)
    tickfont2d = to_font(tickfont2d)
    tickfont3d = to_font(tickfont3d)
    showaxis = to_bool(showaxis)
    showgrid = to_bool(showgrid)

    scalefuncs = to_scalefunc(scalefuncs)
    gridcolors = to_color(gridcolors)
    gridthickness = to_3floats(gridthickness)
    axiscolors = to_color(axiscolors)
end


function expand_kwargs(scene, kw_args)
    # TODO get in all the shorthands from Plots.jl
    attributes = Dict{Symbol, Any}(kw_args)
    shared_defaults(scene, attributes)
end

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
    # :poly => """
    # """,
    :surface => """
        surface(x, y, z)
    Plots a surface, where x y z are supposed to lie on a grid
    """,
    :lines => """
        lines(x, y, z) / lines(x, y) / lines(positions)
    Plots a connected line for each element in xyz/positions
    """,
    :linesegment => """
        linesegment(x, y, z) / linesegment(x, y) / linesegment(positions)
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
    """
)


for (func, docstring) in atomic_funcs
    adoc = try
        f = eval(Symbol("$(func)_defaults"))
        sprint(x-> Markdown.plain(x, Docs.doc(f)))
    catch e
        ""
    end
    docstring = docstring * "\n\n ## Attributes:\n\n" * adoc
    @eval begin
        """
        $($(docstring))
        """
        function $func(a::T, args...; kw_args...) where T
            if T != Scene
                $func(get_global_scene(), a, args...; kw_args...)
            else
                # keyword argument signature should never contain the backend.
                # if so, it must come from the function defined below
                ts = join(typeof.(args), ", ")
                error("Signature $func($ts) is not implemented")
            end
        end
        function $func(scene::Scene, args...; kw_args...)
            $func(scene, args..., expand_kwargs(scene, kw_args))
        end
        export $func
    end
end


"""
Get's the function a scene got created with
"""
function plotfunction(scene::Scene)
    # TODO if we actually make new types per atomic primitive, we could do this performant and more elegantly
    scene.name == :scatter && return scatter
    scene.name == :lines && return lines
    scene.name == :linesegment && return linesegment
    scene.name == :mesh && return mesh
    scene.name == :poly && return poly
    scene.name == :surface && return surface
    scene.name == :wireframe && return wireframe
    scene.name == :image && return image
    scene.name == :heatmap && return heatmap
    scene.name == :volume && return volume
    scene.name == :meshscatter && return meshscatter
    error("$(scene.name) wasn't created by any plot command")
end


"""
Recreates a similar plot with new data
"""
function Base.similar(scene::Scene, newdata...; kw_args...)
    f = plotfunction(scene)
    p = parent(scene)
    attributes = expand_kwargs(scene, kw_args)
    attributes = merge(scene.data, attributes)
    for elem in (:positions, :x, :y, :z)
        delete!(attributes, elem)
    end
    f(p, newdata..., attributes)
end



for func in (:image, :heatmap, :lines, :surface)
    # Higher level atomic signatures
    @eval begin
        function $func(scene::Scene, data::AbstractMatrix, attributes::Dict)
            $func(scene, 1:size(data, 1), 1:size(data, 2), data, attributes)
        end
        function $func(scene::Scene, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function, attributes::Dict) where {T1, T2}
            if !applicable(f, x[1], y[1])
                error("You need to pass a function like f(x::$T1, y::$T2). Found: $f")
            end
            T = typeof(f(x[1], y[1]))
            z = similar(x, T, (length(x), length(y)))
            z .= f.(x, y')
            $func(scene, x, y, z, attributes)
        end
    end
end
