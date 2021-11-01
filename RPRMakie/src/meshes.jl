function mesh_material(context, matsys, plot, color_obs = plot.color)
    ambient = plot.ambient[]
    diffuse = plot.diffuse[]
    specular = plot.specular[]
    shininess = plot.shininess[]

    color = to_value(color_obs)
    @show typeof(color)
    color_signal = if color isa AbstractMatrix{<:Number}
        tex = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_IMAGE_TEXTURE)
        map(color_obs, plot.colormap, plot.colorrange) do color, cmap, crange
            color_interp = Makie.interpolated_getindex.((to_colormap(cmap),), color, (crange,))
            img = RPR.Image(context, collect(color_interp'))
            set!(tex, RPR.RPR_MATERIAL_INPUT_DATA, img)
            return tex
        end
    elseif color isa AbstractMatrix{<:Colorant}
        tex = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_IMAGE_TEXTURE)
        map(color_obs) do color
            println("Setting color images: $(typeof(color))")
            img = RPR.Image(context, collect(color'))
            set!(tex, RPR.RPR_MATERIAL_INPUT_DATA, img)
            return tex
        end
    elseif color isa Colorant || color isa Union{String, Symbol}
        map(to_color, color_obs)
    else
        error("Unsupported color type for RadeonProRender backend: $(typeof(color))")
    end

    material = to_value(get(plot, :material, RPR.DiffuseMaterial(matsys)))

    map(color_signal) do color
        @show typeof(color)
        @show hasproperty(material, :color)
        if hasproperty(material, :color)
            material.color = color
        end
    end

    return material.node
end

function to_rpr_object(context, matsys, scene, plot::Makie.Mesh)
    # Potentially per instance attributes
    rpr_mesh = RPR.Shape(context, to_value(plot[1]))
    material = mesh_material(context, matsys, plot)
    map(plot.model) do m
        RPR.transform!(rpr_mesh, m)
    end
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
        material = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_DIFFUSE)
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
    x = plot[1]
    y = plot[2]
    z = plot[3]

    function grid(x, y, z, trans)
        g = map(CartesianIndices(z)) do i
            p = Point3f(Makie.get_dim(x, i, 1, size(z)), Makie.get_dim(y, i, 2, size(z)), z[i])
            return Makie.apply_transform(trans, p)
        end
        return vec(g)
    end

    positions = lift(grid, x, y, z, Makie.transform_func_obs(plot))
    r = Tesselation(Rect2f((0, 0), (1, 1)), size(z[]))
    # decomposing a rectangle into uv and triangles is what we need to map the z coordinates on
    # since the xyz data assumes the coordinates to have the same neighouring relations
    # like a grid
    faces = decompose(GLTriangleFace, r)
    uv = decompose_uv(r)
    # with this we can beuild a mesh
    mesh = GeometryBasics.Mesh(meta(vec(positions[]), uv=uv), faces)

    rpr_mesh = RPR.Shape(context, mesh)
    color = plot.color[]
    material = mesh_material(context, matsys, plot, color isa AbstractMatrix ? plot.color : z)
    set!(rpr_mesh, material)
    return rpr_mesh
end
