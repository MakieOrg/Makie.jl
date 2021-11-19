function mesh_material(context, matsys, plot, color_obs = plot.color)
    specular = plot.specular[]
    shininess = plot.shininess[]
    color = to_value(color_obs)
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
            img = RPR.Image(context, Makie.el32convert(color'))
            set!(tex, RPR.RPR_MATERIAL_INPUT_DATA, img)
            return tex
        end
    elseif color isa Colorant || color isa Union{String, Symbol}
        map(to_color, color_obs)
    elseif color isa Nothing
        # ignore!
        color_obs
    else
        error("Unsupported color type for RadeonProRender backend: $(typeof(color))")
    end

    material = to_value(get(plot, :material, RPR.DiffuseMaterial(matsys)))

    map(color_signal) do color
        if !isnothing(color) && hasproperty(material, :color)
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
    m_mesh = convert_attribute(plot.marker[], key"marker"(), key"meshscatter"())
    marker = RPR.Shape(context, m_mesh)
    instances = [marker]
    n_instances = length(positions)
    RPR.rprShapeSetObjectID(marker, 0)
    material = if haskey(plot, :material)
        plot.material[]
    else
        RPR.DiffuseMaterial(matsys)
    end
    set!(marker, material)
    for i in 1:(n_instances-1)
        inst = RPR.Shape(context, marker)
        RPR.rprShapeSetObjectID(inst, i)
        push!(instances, inst)
    end

    color = to_color(plot.color[])
    if color isa AbstractVector{<:Number}
        cmap = to_colormap(plot.colormap[])
        crange = plot.colorrange[]
        color_from_num = Makie.interpolated_getindex.((cmap,), color, (crange,))

        object_id = RPR.InputLookupMaterial(matsys)
        object_id.value = RPR.RPR_MATERIAL_NODE_LOOKUP_OBJECT_ID

        uv = object_id * Vec3f(0, 1/n_instances, 0)

        tex = RPR.Texture(context, matsys, collect(color_from_num'); uv = uv)

        material.color = tex
    elseif color isa Colorant
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

    rotations = Makie.to_rotation(plot.rotations[])

    rotations = if rotations isa Makie.Quaternion
        Iterators.repeated(rotations, n_instances)
    else
        rotations
    end

    for (instance, position, scale, rotation) in zip(instances, positions, scales, rotations)
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

using FileIO

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
        mesh!(plot, mesh, material=mat, color=plot.color)
    end
    return plot
end
