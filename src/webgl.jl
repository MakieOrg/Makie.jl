using Colors, WebIO
using JSCall, JSExpr
using ShaderAbstractions: InstancedProgram, Program
using AbstractPlotting: Key, plotkey
using GeometryTypes: Mat4f0
using Colors: N0f8

tlength(T) = length(T)
tlength(::Type{<: Real}) = 1

struct JSBuffer{T} <: AbstractVector{T}
    buffer::JSObject
    length::Int
end

Base.size(x::JSBuffer) = (x.length)

function Base.setindex!(x::JSBuffer{T}, value::T, index::Int) where T
    setindex!(x, [value], index:(index+1))
end
function Base.setindex!(x::JSBuffer, value::AbstractArray{T}, index::UnitRange) where T
    checkbounds(x, value, index)
    flat = reinterpret(eltype(T), attribute)
    x.buffer.set(value, first(index))
end
function JSInstanceBuffer(jsctx, attribute::AbstractVector{T}) where T
    flat = reinterpret(eltype(T), attribute)
    js_f32 = jsctx.window.new.Float32Array(flat)
    return jsctx.THREE.new.InstancedBufferAttribute(js_f32, tlength(T))
end


function JSBuffer(THREE, buff::AbstractVector{T}) where T
    flat = reinterpret(eltype(T), buff)
    return JSBuffer{T}(
        THREE.new.Float32BufferAttribute(flat, tlength(T)),
        length(buff)
    )
end

jl2js(jsctx, val::Number) = val
function jl2js(jsctx, val::Mat4f0)
    x = jsctx.THREE.new.Matrix4()
    x.fromArray(vec(val))
    return x
end

jl2js(jsctx, val::Quaternion) = jsctx.THREE.new.Vector4(val.data...)
jl2js(jsctx, val::Vec4f0) = jsctx.THREE.new.Vector4(val...)
jl2js(jsctx, val::Vec3f0) = jsctx.THREE.new.Vector3(val...)
jl2js(jsctx, val::Vec2f0) = jsctx.THREE.new.Vector2(val...)

function jl2js(jsctx, val::RGBA)
    return jsctx.THREE.new.Vector4(red(val), green(val), blue(val), alpha(val))
end
function jl2js(jsctx, val::RGB)
    return jsctx.THREE.new.Vector3(red(val), green(val), blue(val))
end

function jl2js(jsctx, color::Sampler{T, 1}) where T
    data = to_js_buffer(jsctx, color.data)
    tex = jsctx.THREE.new.DataTexture(
        data, size(color, 1), 1,
        three_format(jsctx, T), three_type(jsctx, eltype(T))
    )
    tex.minFilter = three_filter(jsctx, color.minfilter)
    tex.magFilter = three_filter(jsctx, color.magfilter)
    tex.wrapS = three_repeat(jsctx, color.repeat[1])
    tex.anisotropy = color.anisotropic
    tex.needsUpdate = true
    return tex
end

function jl2js(jsctx, color::Sampler{T, 2}) where T
    # cache texture by their pointer
    key = reinterpret(UInt64, pointer(color.data))
    return get!(jsctx.session_cache, key) do
        data = to_js_buffer(jsctx, color.data)
        tex = jsctx.THREE.new.DataTexture(
            data, size(color, 1), size(color, 2),
            three_format(jsctx, T), three_type(jsctx, eltype(T))
        )
        tex.minFilter = three_filter(jsctx, color.minfilter)
        tex.magFilter = three_filter(jsctx, color.magfilter)
        tex.wrapS = three_repeat(jsctx, color.repeat[1])
        tex.wrapT = three_repeat(jsctx, color.repeat[2])
        tex.anisotropy = color.anisotropic
        tex.needsUpdate = true
        return tex
    end
end

function jl2js(jsctx, color::Sampler{T, 3}) where T
    data = to_js_buffer(jsctx, color.data)
    tex = jsctx.THREE.new.DataTexture3D(
        data, size(color, 1), size(color, 2), size(color, 3)
    )
    tex.minFilter = three_filter(jsctx, color.minfilter)
    tex.magFilter = three_filter(jsctx, color.magfilter)
    tex.format = three_format(jsctx, T)
    tex.type = three_type(jsctx, eltype(T))

    tex.wrapS = three_repeat(jsctx, color.repeat[1])
    tex.wrapT = three_repeat(jsctx, color.repeat[2])
    tex.wrapR = three_repeat(jsctx, color.repeat[3])

    tex.anisotropy = color.anisotropic
    tex.needsUpdate = true
    return tex
end

function to_js_uniforms(scene, jsctx, dict::Dict)
    result = jsctx.window.new.Object()
    for (k, v) in dict
        setproperty!(result, k, Dict(:value => jl2js(jsctx, to_value(v))))
    end
    for (k, v) in dict
        # Sampler + Buffers won't come through as Observables,
        # Since they update themselves
        # atm we also allow other values to be non Observables
        v isa Observable || continue
        on(v) do val
            # TODO don't just use a random event like scroll to trigger
            # a new event to update the render loop!!!!
            try
                prop = getproperty(result, k)
                prop.value = jl2js(jsctx, val)
                prop.needsUpdate = true
            catch e
                @warn "Error in updating $k: " exception=e
            end
        end
    end
    return result
end

JSCall.@jsfun function create_material(THREE, vert, frag, uniforms)
    @var material = @new THREE.RawShaderMaterial(
        Dict(
            :uniforms => uniforms,
            :vertexShader => vert,
            :fragmentShader => frag,
            :side => THREE.DoubleSide,
            :transparent => true
            # :depthTest => true,
            # :depthWrite => true
        ),
    )
    return material
end

three_format(jsctx, ::Type{<: Real}) = jsctx.RedFormat
three_format(jsctx, ::Type{<: RGB}) = jsctx.RGBFormat
three_format(jsctx, ::Type{<: RGBA}) = jsctx.RGBAFormat

three_type(jsctx, ::Type{Float16}) = jsctx.FloatType
three_type(jsctx, ::Type{Float32}) = jsctx.FloatType
three_type(jsctx, ::Type{N0f8}) = jsctx.UnsignedByteType

function to_js_buffer(jsctx, array::AbstractArray{T}) where T
    return to_js_buffer(jsctx, reinterpret(eltype(T), array))
end
function to_js_buffer(jsctx, array::AbstractArray{Float32})
    return jsctx.window.Float32Array.from(vec(array))
end
function to_js_buffer(jsctx, array::AbstractArray{<: AbstractFloat})
    return jsctx.window.Float32Array.from(vec(array))
end
function to_js_buffer(jsctx, array::AbstractArray{T}) where T <: Union{N0f8, UInt8}
    return jsctx.window.Uint8Array.from(vec(array))
end

function three_filter(jsctx, sym)
    sym == :linear && return jsctx.LinearFilter
    sym == :nearest && return jsctx.NearestFilter
end
function three_repeat(jsctx, s::Symbol)
    s == :clamp_to_edge && return jsctx.ClampToEdgeWrapping
    s == :mirrored_repeat && return jsctx.MirroredRepeatWrapping
    s == :repeat && return jsctx.RepeatWrapping
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

function wgl_convert(scene, jsctx, ip::InstancedProgram)
    js_vbo = jsctx.THREE.new.InstancedBufferGeometry()
    for (name, buff) in pairs(ip.program.vertexarray)
        js_buff = JSBuffer(jsctx, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    indices = GeometryBasics.faces(getfield(ip.program.vertexarray, :data))
    indices = reinterpret(UInt32, indices) .- UInt32(1)
    js_vbo.setIndex(indices)
    js_vbo.maxInstancedCount = length(ip.per_instance)

    # per instance data
    for (name, buff) in pairs(ip.per_instance)
        js_buff = JSInstanceBuffer(jsctx, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    uniforms = to_js_uniforms(scene, jsctx, ip.program.uniforms)
    material = create_material(
        jsctx.THREE,
        ip.program.vertex_source,
        ip.program.fragment_source,
        uniforms
    )
    return jsctx.THREE.new.Mesh(js_vbo, material)
end


function wgl_convert(scene, jsctx, program::Program)
    js_vbo = jsctx.THREE.new.BufferGeometry()

    for (name, buff) in pairs(program.vertexarray)
        js_buff = JSBuffer(jsctx, buff).setDynamic(true)
        js_vbo.addAttribute(name, js_buff)
    end
    indices = GeometryBasics.faces(getfield(program.vertexarray, :data))
    indices = reinterpret(UInt32, indices) .- UInt32(1)
    js_vbo.setIndex(indices)
    # per instance data
    uniforms = to_js_uniforms(scene, jsctx, program.uniforms)

    material = create_material(
        jsctx.THREE,
        program.vertex_source,
        program.fragment_source,
        uniforms
    )
    return jsctx.THREE.new.Mesh(js_vbo, material)
end


function update_model!(geom, plot)
    geom.matrixAutoUpdate = false
    geom.matrix.set(plot.model[]'...)
    on(plot.model) do model
        geom.matrix.set((model')...)
    end
end
