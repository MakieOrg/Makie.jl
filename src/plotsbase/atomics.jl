# Defaults for atomics

# Note that this will create a function called surface_defaults
# This is not perfect, but for integrating this into the scene, it's the easiest to
# just have the default function name in the macro match the drawing function name.
@default function surface(backend, scene, kw_args)
    x = to_surface(x)
    y = to_surface(y)
    z = to_surface(z)
    xor(
        begin # Colormap is first, so it will default to it
            colormap = to_colormap(colormap)
            # convert function should only have one argument right now, so we create this closure
            colornorm = ((b, colornorm) -> to_colornorm(b, colornorm, z))(colornorm)
        end,
        begin
            color = to_color(color)
        end
    )
end

@default function lines(backend, scene, kw_args)
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
    pattern = to_pattern(linestyle, linewidth)
end

@default function mesh(backend, scene, kw_args)
    color = to_color(color)
    shading = shading::Bool
    positions = to_positions(positions)
    faces = to_faces(faces)
    attribute_id = to_attribut_id(attribute_id)
    vertexmesh = to_mesh(positions, faces, color, attribute_id)
end

@default function scatter(backend, scene, kw_args)
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

    markersize = to_markersize(markersize)

    rotations = to_rotations(rotations)
end



function expand_kwargs(kw_args)
    # TODO get in all the shorthands from Plots.jl
    Dict{Symbol, Any}(kw_args)
end

const atomic_funcs = (
    # :contour => """
    # """,
    # :image => """
    # """,
    # # could be implemented via image, but might be optimized specifically by the backend
    # :heatmap => """
    # """,
    # :volume => """
    # """,
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

    The same as for [lines](@ref)
    """,
    # alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
    :mesh => """
        mesh(x, y, z) / mesh(mesh_object)
    Plots a 3D mesh
    """,
    :scatter => """
        scatter(x, y, z) / scatter(x, y) / scatter(positions)
    Plots a marker for each element in xyz/positions
    """,
    # :text => """
    # """,
    # Doesn't really need to be an atomic, could be implemented via lines
    :wireframe => """
        wireframe(x, y, z) / wireframe(positions) / wireframe(mesh)
    Draws a wireframe either interpreted as a surface or mesh
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
        $func(args...; kw_args...) = $func(current_backend[], args...; kw_args...)
        function $func(backend::Backend, args...; kw_args...)
            $func(backend, args..., expand_kwargs(kw_args))
        end
        export $func
    end
end
