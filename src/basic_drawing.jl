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
    """,

    :text => """
        text(string)

    Plots a text
    """
)
struct Billboard end

for (func, docs) in atomic_funcs
    Typ = Symbol(titlecase(string(func)))
    inplace = Symbol(string(func, "!"))
    @eval begin
        struct $Typ{T} <: AbstractPlot
            args::T
            attributes::Attributes
        end
        $func(scene::Scene, args...; kw_args...) = plot(scene, $Typ, args...; kw_args...)
        $func(args...; kw_args...) = plot($Typ, args...; kw_args...)
        $inplace(scene::Scene, args...; kw_args...) = plot(scene, $Typ, args...; kw_args...)
        $inplace(args...; kw_args...) = plot($Typ, args...; kw_args...)
        function plot(scene::Scene, T::Type{$Typ}, attributes::Attributes, positions::AbstractVector{<: Point}) where T
            #cmap_or_color!(scene, attributes)
            attributes, rest = merged_get!(:scatter, scene, attributes) do
                default_theme(T, attributes)
            end
            calculate_values!(T, attributes, positions)
            plot(scene, $Typ(positions, scatter_attributes), rest)
        end
        export $func
    end
end
"""
Fill in values that can only be calculated when we have all other attributes filled
"""
function calculate_values!(::Type{T}, attributes, args) where Union{Scatter, Lines, Heatmap, Surface}
    if haskey(attributes, :colormap)
        delete!(attributes, :color)
        get!(attributes, :colornorm) do
            extrema(args)
        end
    end
end

function default_theme(::Type{Scatter})
    Theme(
        marker = Circle,
        markersize = 0.1,
        color = :black,
        strokecolor = RGBA(0, 0, 0, 0),
        strokewidth = 0.0,
        glowcolor = RGBA(0, 0, 0, 0),
        glowwidth = 0.0,
        rotations = Billboard()
    )
end

function default_theme(::Type{Lines})
    Theme(
        linewidth = 1.0,
        color = :black,
        linestyle = nothing,
        #drawover = false,
    )
end


function to_modelmatrix(b, scale, offset, rotation)
    lift_node(scale, offset, rotation) do s, o, r
        q = Quaternion(1f0,0f0,0f0,0f0)
        transformationmatrix(o, s, q)
    end
end

function shared(scene, kw_args)
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
function default_theme(::Type{Surface})
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

function default_theme(::Type{Lines})
    colormap()
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

function mesh(scene, kw_args)
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

function scatter(scene, kw_args)
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

function meshscatter(scene, kw_args)
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

function image(scene, kw_args)
    spatialorder = to_spatial_order(spatialorder)
    x = to_interval(x)
    y = to_interval(y)
    image = to_image(image)
end

function heatmap(scene, kw_args)
    x = to_interval(x)
    y = to_interval(y)

    linewidth = to_float(linewidth)
    levels = to_float(levels)
    heatmap = to_array(heatmap)

    colormap = to_colormap(colormap)
    # convert function should only have one argument right now, so we create this closure
    colornorm = ((b, colornorm) -> to_colornorm(b, colornorm, heatmap))(colornorm)
end

function volume(scene, kw_args)
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


dontcare(b, x) = x
function axis(scene, kw_args)
    axisnames = to_text(axisnames)

    axisnames_color = to_color(axisnames_color)
    axisnames_rotation_align = dontcare(axisnames_rotation_align)
    axisnames_size = to_3floats(axisnames_size)
    axisnames_font = to_font(axisnames_font)

    showticks = to_bool(showticks)
    tickfont2d = to_text(tickfont2d)
    tickfont3d = to_text(tickfont3d)
    showaxis = to_bool(showaxis)
    showgrid = to_bool(showgrid)

    scalefuncs = to_scalefunc(scalefuncs)
    gridcolors = to_color(gridcolors)
    gridthickness = to_3floats(gridthickness)
    axiscolors = to_color(axiscolors)
end
function text(scene, kw_args)
    text = to_string(text)
    color = to_color(color)
    strokecolor = to_color(strokecolor)
    strokewidth = to_float(strokewidth)
    font = to_font(font)
    align = to_textalign(align)
    rotation = to_rotation(rotation)
    textsize = to_float(textsize)
    position = to_position(position)
end
