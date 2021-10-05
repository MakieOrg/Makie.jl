function mesh_material(context, matsys, plot)
    ambient = plot.ambient[]
    diffuse = plot.diffuse[]
    specular = plot.specular[]
    shininess = plot.shininess[]

    color = to_color(plot.color[])

    color_signal = if color isa AbstractMatrix{<:Number}
        map(plot.color, plot.color_map, plot.colorrange) do color, cmap, crange
            Makie.interpolated_getindex.((cmap,), color, (crange,))
        end
    elseif color isa AbstractMatrix{<:Colorant}
        tex = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_IMAGE_TEXTURE)
        map(plot.color) do color
            img = RPR.Image(context, collect(color'))
            set!(tex, RPR.RPR_MATERIAL_INPUT_DATA, img)
            return tex
        end
    elseif color isa Colorant
        map(to_color, plot.color)
    else
        error("Unsupported color type for RadeonProRender backend: $(typeof(color))")
    end

    material = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_PHONG)
    map(color_signal) do color
        return set!(material, RPR.RPR_MATERIAL_INPUT_COLOR, color)
    end

    return material
end

function to_rpr_object(context, matsys, scene, plot::Makie.Mesh)
    # Potentially per instance attributes
    rpr_mesh = RPR.Shape(context, to_value(plot[1]))
    material = mesh_material(context, matsys, plot)
    set!(rpr_mesh, material)
    return rpr_mesh
end


function to_rpr_object(context, matsys, scene, plot::Makie.MeshScatter)
    # Potentially per instance attributes
    positions = to_value(plot[1])
    marker = RPR.Shape(context, convert_attribute(plot.marker[], key"marker"(), key"meshscatter"()))
    instances = [marker]
    n_instances = length(positions)
    for i in 1:(n_instances-1)
        push!(instances, RPR.Shape(context, marker))
    end

    materials = map(instances) do instance
        material = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_PHONG)
        set!(instance, material)
        material
    end

    color = plot.color[]
    colors = if color isa AbstractVector{<:Number}
        cmap = to_colormap(plot.colormap[])
        crange = plot.colorrange[]
        Makie.interpolated_getindex.((cmap,), color, (crange,))
    elseif color isa Colorant
        Iterators.repeated(to_color(color), n_instances)
    else
        error("Unsupported color type for RadeonProRender backend: $(typeof(color))")
    end

    markersize = Makie.to_3d_scale(plot.markersize[])

    scales = if markersize isa Vec
        Iterators.repeated(markersize, n_instances)
    else
        markersize
    end

    rotations = Makie.to_rotation(plot.rotations[])

    rotations = if rotations isa Makie.Quaternion
        Iterators.repeated(rotations, n_instances)
    else
        rotations
    end

    for (material, instance, color, position, scale, rotation) in zip(materials, instances, colors, positions, scales, rotations)
        set!(material, RPR.RPR_MATERIAL_INPUT_COLOR, color)
        mat = Makie.transformationmatrix(position, scale, rotation)
        transform!(instance, mat)
    end

    return instances
end


function to_rpr_object(context, matsys, scene, plot::Makie.Surface)
    x = plot[1][]
    y = plot[2][]
    z = plot[3][]

    xyz = Point3f[Point3f(x[i, j], y[i, j], z[i, j]) for i in 1:size(x, 1), j in 1:size(x, 2)]
    r = Tesselation(Rect2f((0, 0), (1, 1)), size(z))
    # decomposing a rectangle into uv and triangles is what we need to map the z coordinates on
    # since the xyz data assumes the coordinates to have the same neighouring relations
    # like a grid
    faces = decompose(GLTriangleFace, r)
    uv = decompose_uv(r)
    # with this we can beuild a mesh
    mesh = GeometryBasics.Mesh(meta(vec(xyz), uv=uv), faces)

    rpr_mesh = RPR.Shape(context, mesh)
    material = mesh_material(context, matsys, plot)
    set!(rpr_mesh, material)
    return rpr_mesh
end
