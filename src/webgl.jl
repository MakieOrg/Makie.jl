using Colors, WebIO
using JSCall, JSExpr
using ShaderAbstractions: InstancedProgram, Program
using AbstractPlotting: Key, plotkey
using GeometryTypes: Mat4f0
using Colors: N0f8

tlength(T) = length(T)
tlength(::Type{<: Real}) = 1

function JSInstanceBuffer(context, attribute::AbstractVector{T}) where T
    flat = reinterpret(eltype(T), attribute)
    js_f32 = window.new.Float32Array(flat)
    return THREE.new.InstancedBufferAttribute(js_f32, tlength(T))
end



function JSBuffer(context, buff::AbstractVector{T}) where T
    flat = reinterpret(eltype(T), buff)
    return THREE.new.Float32BufferAttribute(flat, tlength(T))
end

jl2js(val::Number) = val
function jl2js(val::Mat4f0)
    x = THREE.new.Matrix4()
    x.fromArray(vec(val))
    return x
end

jl2js(val::Quaternion) = THREE.new.Vector4(val.data...)
jl2js(val::Vec4f0) = THREE.new.Vector4(val...)
jl2js(val::Vec3f0) = THREE.new.Vector3(val...)
jl2js(val::Vec2f0) = THREE.new.Vector2(val...)

function jl2js(val::RGBA)
    return THREE.new.Vector4(red(val), green(val), blue(val), alpha(val))
end
function jl2js(val::RGB)
    return THREE.new.Vector3(red(val), green(val), blue(val))
end

function jl2js(color::Sampler{T}) where T
    data = to_js_buffer(color.data)
    tex = THREE.new.DataTexture(
        data, size(color, 1), size(color, 2),
        three_format(T), three_type(eltype(T))
    )
    tex.minFilter = three_filter(color.minfilter)
    tex.magFilter = three_filter(color.magfilter)
    tex.wrapS = three_repeat(color.repeat[1])
    tex.wrapT = three_repeat(color.repeat[2])
    tex.anisotropy = color.anisotropic
    tex.needsUpdate = true
    return tex
end

function to_js_uniforms(context, dict::Dict)
    result = window.new.Object()
    for (k, v) in dict
        setproperty!(result, k, Dict(:value => jl2js(to_value(v))))
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
            :side => $(THREE).DoubleSide,
            :transparent => true
            # :depthTest => true,
            # :depthWrite => true
        ),
    )
    return material
end

three_format(::Type{<: Real}) = THREE.AlphaFormat
three_format(::Type{<: RGB}) = THREE.RGBFormat
three_format(::Type{<: RGBA}) = THREE.RGBAFormat

three_type(::Type{Float16}) = THREE.FloatType
three_type(::Type{Float32}) = THREE.FloatType
three_type(::Type{N0f8}) = THREE.UnsignedByteType

function to_js_buffer(array::AbstractArray{T}) where T
    return to_js_buffer(reinterpret(eltype(T), array))
end
function to_js_buffer(array::AbstractArray{Float32})
    return window.Float32Array.from(vec(array))
end
function to_js_buffer(array::AbstractArray{Float16})
    return window.Float32Array.from(vec(Float32.(array)))
end
function to_js_buffer(array::AbstractArray{T}) where T <: Union{N0f8, UInt8}
    return window.Uint8Array.from(vec(array))
end

function three_filter(sym)
    sym == :linear && return THREE.LinearFilter
    sym == :nearest && return THREE.NearestFilter
end
function three_repeat(s::Symbol)
    s == :clamp_to_edge && return THREE.ClampToEdgeWrapping
    s == :mirrored_repeat && return THREE.MirroredRepeatWrapping
    s == :repeat && return THREE.RepeatWrapping
end
using StaticArrays

lasset(paths...) = read(joinpath(dirname(pathof(WGLMakie)), "..", "assets", paths...), String)

isscalar(x::StaticArrays.StaticArray) = true
isscalar(x::AbstractArray) = false
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true
ShaderAbstractions.type_string(context::ShaderAbstractions.AbstractContext, t::Type{<: AbstractPlotting.Quaternion}) = "vec4"
ShaderAbstractions.convert_uniform(context::ShaderAbstractions.AbstractContext, t::Quaternion) = convert(Quaternion, t)

function wgl_convert(value, key1, key2)
    AbstractPlotting.convert_attribute(value, key1, key2)
end

function wgl_convert(value::AbstractMatrix, ::key"colormap", key2)
    ShaderAbstractions.Sampler(value)
end

AbstractPlotting.plotkey(::Nothing) = :scatter
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

function wgl_convert(context, ip::InstancedProgram)
    # bufferGeometry = THREE.new.BoxBufferGeometry(0.1, 0.1, 0.1);
    js_vbo = THREE.new.InstancedBufferGeometry()
    for (name, buff) in pairs(ip.program.vertexarray)
        js_buff = JSBuffer(context, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    indices = GeometryBasics.faces(getfield(ip.program.vertexarray, :data))
    indices = reinterpret(UInt32, indices) .- UInt32(1)
    js_vbo.setIndex(indices)
    js_vbo.maxInstancedCount = length(ip.per_instance)

    # per instance data
    for (name, buff) in pairs(ip.per_instance)
        js_buff = JSInstanceBuffer(context, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    uniforms = to_js_uniforms(context, ip.program.uniforms)

    material = WGLMakie.create_material(
        ip.program.vertex_source,
        ip.program.fragment_source,
        to_js_uniforms(context, ip.program.uniforms)
    )
    return THREE.new.Mesh(js_vbo, material)
end


function wgl_convert(context, program::Program)
    # bufferGeometry = THREE.new.BoxBufferGeometry(0.1, 0.1, 0.1);
    js_vbo = THREE.new.BufferGeometry()

    for (name, buff) in pairs(program.vertexarray)
        js_buff = JSBuffer(context, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    indices = GeometryBasics.faces(getfield(program.vertexarray, :data))
    indices = reinterpret(UInt32, indices) .- UInt32(1)
    js_vbo.setIndex(indices)
    # per instance data
    uniforms = to_js_uniforms(context, program.uniforms)

    material = WGLMakie.create_material(
        program.vertex_source,
        program.fragment_source,
        to_js_uniforms(context, program.uniforms)
    )
    return THREE.new.Mesh(js_vbo, material)
end
