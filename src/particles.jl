using Colors, WebIO
using JSCall, JSExpr
using ShaderAbstractions: InstancedProgram

function JSInstanceBuffer(context, attribute::AbstractVector{T}) where T
    flat = reinterpret(eltype(T), attribute)
    js_f32 = window.new.Float32Array(flat)
    return THREE.new.InstancedBufferAttribute(js_f32, length(T))
end

function JSBuffer(context, buff::AbstractVector{T}) where T
    flat = reinterpret(eltype(T), buff)
    # js_f32 = window.new.Float32Array(flat)
    return THREE.new.Float32BufferAttribute(flat, length(T))
end
using GeometryTypes: Mat4f0

jl2js(val::Number) = val
function jl2js(val::Mat4f0)
    x = THREE.new.Matrix4()
    x.fromArray(vec(val))
    return x
end
function jl2js(val::Vec3f0)
    return THREE.new.Vector3(val...)
end
function to_js_uniforms(context, dict::Dict)
    result = window.new.Object()
    for (k, v) in dict
        setproperty!(result, k, Dict(:value => jl2js(v[])))
    end
    # for (k, v) in dict
    #     # Sampler + Buffers won't come through as Observables,
    #     # Since they update themselves
    #     v isa Observable || continue
    #     onjs(v, @js function (val)
    #         $(result).$(k).value = val
    #         $(result).$(k).needsUpdate = true
    #     end)
    # end
    return result
end

JSCall.@jsfun function create_material(vert, frag, uniforms)
    @var material = @new $(THREE).RawShaderMaterial(
        Dict(
            :uniforms => uniforms,
            :vertexShader => vert,
            :fragmentShader => frag,
            :side => $(THREE).DoubleSide
        ),
    )
    return material
end


function wgl_convert(context, color::Sampler)
    cmap = vec(reinterpret(UInt8, RGB{Colors.N0f8}.(color.data)))
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
using AbstractPlotting: Key, plotkey

function lift_convert(key, value, plot)
    val = lift(value) do value
         wgl_convert(value, Key{key}(), Key{plotkey(plot)}())
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

    p = InstancedProgram(
        WebGL(), vshader,
        instance,
        VertexArray(; per_instance...)
        ; uniform_dict...
    )
end


function wgl_convert(context, ip::InstancedProgram)
    js_instances = THREE.new.InstancedBufferGeometry()
    for (name, buff) in columns(ip.program.vertexarray)
        js_buff = JSBuffer(context, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    # per instance data
    for (name, buff) in columns(ip.per_instance)
        js_buff = JSInstanceBuffer(context, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    material = create_material(
        ip.program.source,
        loadasset("particles.frag"),
        to_js_uniforms(context, ip.program.uniforms)
    )
    return THREE.new.Mesh(js_vbo, material)
end
#
function draw_js(jsscene, scene::Scene, plot::MeshScatter)
    program = create_shader(scene, plot)
    mesh = wgl_convert(jsscene, program)
    jsscene.add(mesh)
end
