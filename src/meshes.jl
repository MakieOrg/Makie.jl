

function create_shader(scene::Scene, plot::Mesh)
    # Potentially per instance attributes
    mesh = plot[1]

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, plot))
    end

    uniforms = filter(plot.attributes.attributes) do (k, v)
        (!haskey(per_instance, k)) && isscalar(v[])
    end

    uniform_dict = Dict{Symbol, Any}()
    for (k, v) in uniforms
        k in (:shading, :overdraw, :fxaa, :visible, :transformation, :alpha, :linewidth, :transparency, :marker) && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end
    color = to_value(get(uniform_dict, :color, nothing))
    if color isa Colorant || color isa AbstractVector{<: Colorant} || color === nothing
        delete!(uniform_dict, :colormap)
    end

    instance = VertexArray(map(GLNormalMesh, plot.marker))
    if !GeometryBasics.hascolumn(instance, :texturecoordinate)
        uniform_dict[:texturecoordinate] = Vec2f0(0)
    end
    uniform_dict[:model] = plot.model

    p = Program(
        WebGL(),
        lasset("mesh.vert"),
        lasset("mesh.frag"),
        instance,
        VertexArray(; per_instance...)
        ; uniform_dict...
    )
end

function draw_js(jsscene, mscene::Scene, plot::Mesh)
    normalmesh = plot[1][]
    @get_attribute plot (color, model)
    geometry = THREE.new.BufferGeometry()
    cmap = vec(reinterpret(UInt8, RGB{Colors.N0f8}.(color)))
    data = window.Uint8Array.from(cmap)
    tex = THREE.new.DataTexture(
        data, size(color, 1), size(color, 2),
        THREE.RGBFormat, THREE.UnsignedByteType
    );
    tex.needsUpdate = true
    material = THREE.new.MeshLambertMaterial(
        color = 0xdddddd, map = tex,
        transparent = true
    )
    set_positions!(geometry, vertices(normalmesh))
    set_normals!(geometry, normals(normalmesh))
    set_uvs!(geometry, texturecoordinates(normalmesh))
    indices = faces(normalmesh)
    indices = reinterpret(UInt32, indices)
    geometry.setIndex(indices);
    mesh = THREE.new.Mesh(geometry, material)
    mesh.matrixAutoUpdate = false;
    mesh.matrix.set(model...)
    jsscene.add(mesh)
    return mesh
end
