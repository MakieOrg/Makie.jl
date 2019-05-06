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

function AbstractPlotting.convert_attribute(x::AbstractMatrix, ::key"color")
    typ_or_scalar(Sampler, x)
end

function AbstractPlotting.convert_attribute(x::AbstractSampler, ::key"color")
    typ_or_scalar(Sampler, x)
end

convert_uniform(sampler::Sampler) = sampler




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
end

lasset(paths...) = read(joinpath(dirname(pathof(WGLMakie)), "..", "assets", paths...), String)

isscalar(x::AbstractArray) = false
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true
ShaderAbstractions.type_string(context::ShaderAbstractions.AbstractContext, t::Type{<: AbstractPlotting.Quaternionf0}) = "vec4"

function wgl_convert(value, key1, key2)
    AbstractPlotting.convert_attribute(value, key1, key2)
end

function wgl_convert(value::AbstractMatrix, ::key"colormap", key2)
    ShaderAbstractions.Sampler(value)
end

function lift_convert(key, value, plot)
    val = lift(value) do value
         wgl_convert(value, AbstractPlotting.Key{key}(), AbstractPlotting.Key{AbstractPlotting.plotkey(plot)}())
     end
     if key == :colormap && val[] isa AbstractArray
         return ShaderAbstractions.Sampler(val)
     else
         val
     end
end


function create_shader(scene::Scene, plot::MeshScatter)
    vshader = lasset("particles.vert")
    # Potentially per instance attributes
    per_instance_keys = (:position, :rotations, :markersize, :color, :intensity)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        k in per_instance_keys && !(isscalar(v[]))
    end
    per_instance[:position] = plot[1]

    for (k, v) in per_instance
        per_instance[k] = Buffer(v)
    end

    uniforms = filter(plot.attributes.attributes) do (k, v)
        (!haskey(per_instance, k)) && isscalar(v[])
    end

    uniform_dict = Dict{Symbol, Any}()
    for (k,v) in uniforms
        k in (:shading, :overdraw, :fxaa, :visible, :transformation, :alpha, :linewidth, :transparency, :marker) && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end
    color = uniform_dict[:color][]
    if color isa Colorant || color isa AbstractVector{<: Colorant}
        delete!(uniform_dict, :colormap)
    end
    instance = VertexArray(map(GLNormalMesh, plot.marker))
    if !GeometryBasics.hascolumn(instance, :texturecoordinate)
        uniform_dict[:texturecoordinate] = Vec2f0(0)
    end
    for key in (:view, :projection, :resolution, :eyeposition, :projectionview)
        uniform_dict[key] = getfield(scene.camera, key)
    end
    uniform_dict[:model] = plot.model
    
    p = ShaderAbstractions.InstancedProgram(
        WebGL(), vshader,
        instance,
        VertexArray(; per_instance...)
        ; uniform_dict...
    )
end
#
# function WGLMakie.draw_js(jsscene, scene::Scene, plot::MeshScatter)
#     vshader = loadasset("particles.vert")
#     # Potentially per instance attributes
#     per_instance_keys = (:position, :rotations, :markersize, :color, :intensity)
#     per_instance = filter(plot.attributes) do (k, v)
#         k in per_instance_keys && !(isscalar(v[]))
#     end
#     per_instance[:position] = plot[1]
#     for (k, v) in per_instance
#         per_instance[k] = Buffer(v)
#     end
#     uniforms = filter(plot.attributes) do (k, v)
#         (!haskey(per_instance_attributes, k)) && isscalar(v[])
#     end
#     InstancedProgram(
#         vshader,
#         VertexArray(plot.marker),
#         VertexArray(; per_instance...)
#         ; uniforms...
#     )
#     return
# end
#
# function WGLMakie.draw_js(jsscene, scene::Scene, plot::MeshScatter)
#     THREE = WGLMakie.THREE
#     @get_attribute plot (rotations, marker, model)
#
#     bufferGeometry = THREE.new.BoxBufferGeometry(0.1, 0.1, 0.1)
#
#     geometry = THREE.new.InstancedBufferGeometry();
#     geometry.index = bufferGeometry.index;
#     geometry.attributes.position = bufferGeometry.attributes.position;
#     geometry.attributes.uv = bufferGeometry.attributes.uv;
#
#     positions = plot[1][]
#     # per instance data
#     offsets = instanced_attribute(jsscene, positions)
#     orientation = instanced_attribute(jsscene, rotations).setDynamic(true)
#     geometry.addAttribute("offset", offsets)
#     geometry.addAttribute("orientation", orientation)
#
#     tex = create_tex(rand(RGB{Colors.N0f8}, 128, 128))
#     material = create_material(
#         loadasset("particles.vert"),
#         loadasset("particles.frag"),
#         tex
#     )
#     mesh = THREE.new.Mesh(geometry, material)
#     jsscene.add(mesh)
#
# end
