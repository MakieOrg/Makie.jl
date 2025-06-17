function extract_material(matsys, plot)
    if haskey(plot, :material) && !isnothing(to_value(plot.material))
        if plot.material isa Attributes
            return RPR.Material(matsys, Dict(map(((k, v),) -> k => to_value(v), plot.material)))
        else
            return plot.material[]
        end
    else
        return RPR.DiffuseMaterial(matsys)
    end
end

function mesh_material(context, matsys, plot, color_obs = plot.scaled_color)
    color = to_value(color_obs)
    color_signal = if color isa AbstractMatrix{<:Number}
        tex = RPR.ImageTextureMaterial(matsys)
        calc_color = to_value(plot.calculated_colors)
        lift(plot, color_obs, plot.colormap, plot.colorrange) do color, cmap, crange
            color_interp = to_color(calc_color)
            img = RPR.Image(context, collect(color_interp'))
            tex.data = img
            return tex
        end
    elseif color isa AbstractMatrix{<:Colorant}
        tex = RPR.ImageTextureMaterial(matsys)
        lift(plot, color_obs) do color
            img = RPR.Image(context, Makie.el32convert(color'))
            tex.data = img
            return tex
        end
    elseif color isa Colorant || color isa Union{String, Symbol}
        lift(to_color, plot, color_obs)
    elseif color isa Nothing
        # ignore!
        color_obs
    else
        error("Unsupported color type for RadeonProRender backend: $(typeof(color)) for $(typeof(plot))")
    end

    material = extract_material(matsys, plot)
    on(plot, color_signal; update = true) do color
        if !isnothing(color) && hasproperty(material, :color)
            material.color = color
        end
    end

    return material
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
    !plot.visible[] && return nothing
    positions = to_value(plot[1])
    m_mesh = plot.marker[]
    marker = RPR.Shape(context, m_mesh)
    instances = [marker]
    n_instances = length(positions)
    RPR.rprShapeSetObjectID(marker, 0)
    material = extract_material(matsys, plot)
    set!(marker, material)
    for i in 1:(n_instances - 1)
        inst = RPR.Shape(context, marker)
        RPR.rprShapeSetObjectID(inst, i)
        push!(instances, inst)
    end

    color = Makie.compute_colors(plot)
    if color isa AbstractVector{<:Union{Number, Colorant}}
        object_id = RPR.InputLookupMaterial(matsys)
        object_id.value = RPR.RPR_MATERIAL_NODE_LOOKUP_OBJECT_ID
        uv = object_id * Vec3f(0, 1 / (n_instances - 1), 0)
        tex = RPR.Texture(matsys, reverse(color)'; uv = uv)
        material.color = tex
    elseif color isa Union{Colorant, AbstractMatrix{<:Colorant}}
        material.color = color
    else
        error("Unsupported color type for RadeonProRender backend: $(typeof(color))")
    end

    markersize = Makie.to_3d_scale(plot.markersize[])

    scales = if markersize isa Vec
        Iterators.repeated(markersize, n_instances)
    else
        markersize
    end

    rotations = Makie.to_rotation(plot.rotation[])

    rotations = if rotations isa Makie.Quaternion
        Iterators.repeated(rotations, n_instances)
    else
        rotations
    end

    for (instance, position, scale, rotation) in zip(instances, positions, scales, rotations)
        mat = Makie.transformationmatrix(to_ndim(Point3f, position, 0), scale, rotation)
        transform!(instance, mat)
    end

    return instances
end


function to_rpr_object(context, matsys, scene, plot::Makie.Voxels)
    # Potentially per instance attributes
    positions = Makie.voxel_positions(plot)
    m_mesh = normal_mesh(Rect3f(Point3f(-0.5), Vec3f(1)))
    marker = RPR.Shape(context, m_mesh)
    instances = [marker]
    n_instances = length(positions)
    RPR.rprShapeSetObjectID(marker, 0)
    material = extract_material(matsys, plot)
    set!(marker, material)
    for i in 1:(n_instances - 1)
        inst = RPR.Shape(context, marker)
        RPR.rprShapeSetObjectID(inst, i)
        push!(instances, inst)
    end

    color_from_num = Makie.voxel_colors(plot)
    object_id = RPR.InputLookupMaterial(matsys)
    object_id.value = RPR.RPR_MATERIAL_NODE_LOOKUP_OBJECT_ID
    uv = object_id * Vec3f(0, 1 / n_instances, 0)
    tex = RPR.Texture(matsys, collect(color_from_num'); uv = uv)
    material.color = tex

    scales = Iterators.repeated(Makie.voxel_size(plot), n_instances)

    for (instance, position, scale) in zip(instances, positions, scales)
        mat = Makie.transformationmatrix(position, scale)
        transform!(instance, mat)
    end

    return instances
end


function to_rpr_object(context, matsys, scene, plot::Makie.Surface)
    !plot.visible[] && return nothing
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
    r = Tessellation(Rect2f((0, 0), (1, 1)), size(z[]))
    # decomposing a rectangle into uv and triangles is what we need to map the z coordinates on
    # since the xyz data assumes the coordinates to have the same neighbouring relations
    # like a grid
    faces = decompose(GLTriangleFace, r)
    uv = decompose_uv(r)
    # with this we can beuild a mesh
    mesh = GeometryBasics.Mesh(vec(positions[]), faces, uv = uv)

    rpr_mesh = RPR.Shape(context, mesh)
    color = plot.color[]
    material = mesh_material(context, matsys, plot, color isa AbstractMatrix ? plot.color : z)
    set!(rpr_mesh, material)
    return rpr_mesh
end

@recipe(Matball, material) do scene
    return Attributes(
        base = Makie.automatic,
        inner = Makie.automatic,
        outer = Makie.automatic,
        color = :blue
    )
end

function Makie.plot!(plot::Matball)
    base = plot.material[]
    for name in [:base, :inner, :outer]
        mat = getproperty(plot, name)[]
        mat = mat isa Makie.Automatic ? base : mat
        mesh = load(assetpath("matball_$(name).obj"))
        mesh!(plot, mesh, material = mat, color = plot.color)
    end
    return plot
end
