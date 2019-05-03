using Colors, WebIO
using JSCall, JSExpr


function instanced_attribute(js_scene, attribute::AbstractVector{T}) where T
    window = WGLMakie.window; THREE = WGLMakie.THREE
    flat = reinterpret(eltype(T), attribute)
    js_f32 = window.new.Float32Array(flat)
    return THREE.new.InstancedBufferAttribute(js_f32, length(T))
end


JSCall.@jsfun function create_material(vert, frag, tex)
    @var material = @new $(WGLMakie.THREE).RawShaderMaterial(
        Dict(
            :uniforms => Dict(
                :map => Dict(:value => tex)
            ),
            :vertexShader => vert,
            :fragmentShader => frag,
        )
    )
    return material
end

using GLMakie
using GLMakie.GLAbstraction


function wgl_convert(sampler::Sampler)
    window = WGLMakie.window; THREE = WGLMakie.THREE
    cmap = vec(reinterpret(UInt8, RGB{Colors.N0f8}.(sampler.data)))
    data = window.Uint8Array.from(cmap)
    tex = THREE.new.DataTexture(
        data, size(color, 1), size(color, 2),
        THREE.RGBFormat, THREE.UnsignedByteType
    );
    tex.needsUpdate = true
    return tex
end


function wgl_convert(vao::VertexArray)

end

function convert_attribute(x::AbstractMatrix, ::key"color")
    typ_or_scalar(Sampler, x)
end

function convert_attribute(x::Abstra, ::key"color")
    typ_or_scalar(Sampler, x)
end

convert_uniform(sampler::Sampler) = sampler



construct_program(nothing, nothing, lasset("particles.vert"), scene[end])

scene = meshscatter(rand(Point3f0, 10), rotations = rand(Quaternionf0, 10))


function create_tex(color)
    window = WGLMakie.window; THREE = WGLMakie.THREE
    cmap = vec(reinterpret(UInt8, RGB{Colors.N0f8}.(color)))
    data = window.Uint8Array.from(cmap)
    tex = THREE.new.DataTexture(
        data, size(color, 1), size(color, 2),
        THREE.RGBFormat, THREE.UnsignedByteType
    );
    tex.needsUpdate = true
    return tex
ende

lasset(paths...) = read(joinpath(dirname(pathof(WGLMakie)), "..", "assets", paths...), String)

isscalar(x::AbstractArray) = false
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true

function WGLMakie.draw_js(jsscene, scene::Scene, plot::MeshScatter)
    vshader = loadasset("particles.vert")
    # Potentially per instance attributes
    per_instance_keys = (:position, :rotations, :markersize, :color, :intensity)
    per_instance = filter(plot.attributes) do (k, v)
        k in per_instance_keys && !(isscalar(v[]))
    end
    per_instance[:position] = plot[1]

    uniforms = filter(plot.attributes) do (k, v)
        (!haskey(per_instance_attributes, k)) && isscalar(v[])
    end
    InstancedProgram(
        vshader,
        VertexArray(plot.marker),
        VertexArray(; per_instance...)
        ; uniforms...
    )
    return
end

function WGLMakie.draw_js(jsscene, scene::Scene, plot::MeshScatter)
    THREE = WGLMakie.THREE
    @get_attribute plot (rotations, marker, model)

    bufferGeometry = THREE.new.BoxBufferGeometry(0.1, 0.1, 0.1)

    geometry = THREE.new.InstancedBufferGeometry();
    geometry.index = bufferGeometry.index;
    geometry.attributes.position = bufferGeometry.attributes.position;
    geometry.attributes.uv = bufferGeometry.attributes.uv;

    positions = plot[1][]
    # per instance data
    offsets = instanced_attribute(jsscene, positions)
    orientation = instanced_attribute(jsscene, rotations).setDynamic(true)
    geometry.addAttribute("offset", offsets)
    geometry.addAttribute("orientation", orientation)

    tex = create_tex(rand(RGB{Colors.N0f8}, 128, 128))
    material = create_material(
        loadasset("particles.vert"),
        loadasset("particles.frag"),
        tex
    )
    mesh = THREE.new.Mesh(geometry, material)
    jsscene.add(mesh)

end
using JSExpr: jsexpr
x = js_display(meshscatter(rand(Point3f0, 10), rotations = rand(Quaternionf0, 10)));
