using Colors
using ShaderAbstractions: InstancedProgram, Program
using AbstractPlotting: Key, plotkey
using GeometryTypes: Mat4f0
using Colors: N0f8

tlength(T) = length(T)
tlength(::Type{<: Real}) = 1

struct JSBuffer{T} <: AbstractVector{T}
    three::ThreeDisplay
    buffer::JSObject
    length::Int
end

JSServe.session(jsb::JSBuffer) = JSServe.session(getfield(jsb, :three))
jsbuffer(x::JSBuffer) = getfield(x, :buffer)
Base.size(x::JSBuffer) = (getfield(x, :length),)

JSServe.serialize_js(jso::JSBuffer) = JSServe.serialize_js(jsbuffer(jso))

function JSServe.serialize_readable(io::IO, jso::JSBuffer)
    return JSServe.serialize_readable(io, jsbuffer(jso))
end

function Base.setindex!(x::JSBuffer{T}, value::T, index::Int) where T
    setindex!(x, [value], index:(index+1))
end
function Base.getindex(x::JSBuffer, idx::Int)
    # jlvalue(jsbuffer(x))[idx]
end

function Base.setindex!(x::JSBuffer, value::AbstractArray, index::Colon)
    x[1:length(x)] = value
end

function Base.setindex!(x::JSBuffer, value::AbstractArray{T}, index::UnitRange) where T
    JSServe.fuse(x) do
        flat = flatten_buffer(value)
        jsb = jsbuffer(x)
        off = (first(index) - 1) * tlength(T)
        jsb.set(flat, off)
        jsb.needsUpdate = true
        return value
    end
end

function JSInstanceBuffer(three, vector::AbstractVector{T}) where T
    js_f32 = to_js_buffer(three, vector)
    jsbuff = three.THREE.new.InstancedBufferAttribute(js_f32, tlength(T))
    jsbuff.setUsage(three.DynamicDrawUsage)
    buffer = JSBuffer{T}(three, jsbuff, length(vector))
    if vector isa Buffer
        ShaderAbstractions.connect!(vector, buffer)
    end
    return buffer
end


function JSBuffer(three, vector::AbstractVector{T}) where T
    flat = flatten_buffer(vector)
    jsbuff = three.new.Float32BufferAttribute(flat, tlength(T))
    jsbuff.setUsage(three.DynamicDrawUsage)
    buffer = JSBuffer{T}(three, jsbuff, length(vector))
    if vector isa Buffer
        ShaderAbstractions.connect!(vector, buffer)
    end
    return buffer
end

jl2js(jsctx, val::Number) = val
function jl2js(THREE, val::Mat4f0)
    x = THREE.new.Matrix4()
    x.fromArray(vec(val))
    return x
end

jl2js(THREE, val::Quaternion) = THREE.new.Vector4(val.data...)
jl2js(THREE, val::Vec4f0) = THREE.new.Vector4(val...)
jl2js(THREE, val::Vec3f0) = THREE.new.Vector3(val...)
jl2js(THREE, val::Vec2f0) = THREE.new.Vector2(val...)

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
    key = reinterpret(UInt, objectid(color.data))
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
        # TODO propperly connect
        on(ShaderAbstractions.updater(color).update) do (f, args)
            if args[2] isa Colon && f == setindex!
                newdata = args[1]
                data.set(to_js_buffer(jsctx, newdata))
                tex.needsUpdate = true
            end
        end
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
    on(ShaderAbstractions.updater(color).update) do (f, args)
        if args[2] isa Colon && f == setindex!
            newdata = args[1]
            data.set(to_js_buffer(jsctx, newdata))
            tex.needsUpdate = true
        end
    end
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
            JSServe.fuse(jsctx) do
                try
                    prop = getproperty(result, k)
                    prop.value = jl2js(jsctx, val)
                    prop.needsUpdate = true
                catch e
                    @warn "Error in updating $k: " exception=e
                end
            end
        end
    end
    return result
end

function create_material(THREE, vert, frag, uniforms)
    return THREE.new.RawShaderMaterial(
        uniforms = uniforms,
        vertexShader = vert,
        fragmentShader = frag,
        side = THREE.DoubleSide,
        transparent = true,
        # depthTest = true,
        # depthWrite = true
    )
end

three_format(jsctx, ::Type{<: Real}) = jsctx.RedFormat
three_format(jsctx, ::Type{<: RGB}) = jsctx.RGBFormat
three_format(jsctx, ::Type{<: RGBA}) = jsctx.RGBAFormat

three_type(jsctx, ::Type{Float16}) = jsctx.FloatType
three_type(jsctx, ::Type{Float32}) = jsctx.FloatType
three_type(jsctx, ::Type{N0f8}) = jsctx.UnsignedByteType

"""
    flatten_buffer(array::AbstractArray)
Flattens `array` array to be a 1D Vector of Float32 / UInt8.
If presented with AbstractArray{<: Colorant/Tuple/SVector}, it will flatten those
to their element type.
"""
function flatten_buffer(array::AbstractArray{T}) where T
    return flatten_buffer(reinterpret(eltype(T), array))
end

function flatten_buffer(array::AbstractArray{<:AbstractFloat}) where T
    return convert(Vector{Float32}, vec(array))
end

function flatten_buffer(array::AbstractArray{<:Integer}) where T
    return convert(Vector{Int32}, vec(array))
end

function flatten_buffer(array::AbstractArray{<:Unsigned}) where T
    return convert(Vector{UInt32}, vec(array))
end

function flatten_buffer(array::AbstractArray{T}) where T <: UInt8
    return convert(Vector{T}, vec(array))
end

function flatten_buffer(array::AbstractArray{T}) where T <: N0f8
    return flatten_buffer(reinterpret(UInt8, array))
end

function to_js_buffer(jsctx, array::AbstractArray)
    return to_js_buffer(jsctx, flatten_buffer(array))
end

function to_js_buffer(jsctx, array::Vector{UInt8})
    return jsctx.window.Uint8Array.from(array)
end
function to_js_buffer(jsctx, array::Vector{Int32})
    return jsctx.window.Int32Array.from(array)
end
function to_js_buffer(jsctx, array::Vector{UInt32})
    return jsctx.window.Uint32Array.from(array)
end
function to_js_buffer(jsctx, array::Vector{Float32})
    return jsctx.window.Float32Array.from(array)
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

lasset(paths...) = read(joinpath(@__DIR__, "..", "assets", paths...), String)

isscalar(x::StaticArrays.StaticArray) = true
isscalar(x::AbstractArray) = false
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true
ShaderAbstractions.type_string(context::ShaderAbstractions.AbstractContext, t::Type{<: AbstractPlotting.Quaternion}) = "vec4"
ShaderAbstractions.convert_uniform(context::ShaderAbstractions.AbstractContext, t::Quaternion) = convert(Quaternion, t)

function wgl_convert(value, key1, key2)
    val = AbstractPlotting.convert_attribute(value, key1, key2)
    if val isa AbstractArray{<: Float64}
        return AbstractPlotting.el32convert(val)
    else
        return val
    end
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

function wgl_convert(scene, THREE, ip::InstancedProgram)
    js_vbo = THREE.new.InstancedBufferGeometry()
    for (name, buff) in pairs(ip.program.vertexarray)
        js_buff = JSBuffer(THREE, buff)
        js_vbo.setAttribute(name, js_buff)
    end
    indices = GeometryBasics.faces(getfield(ip.program.vertexarray, :data))
    indices = reinterpret(UInt32, indices) .- UInt32(1)
    js_vbo.setIndex(indices)
    js_vbo.maxInstancedCount = length(ip.per_instance)

    # per instance data
    for (name, buff) in pairs(ip.per_instance)
        js_buff = JSInstanceBuffer(THREE, buff)
        js_vbo.setAttribute(name, js_buff)
    end
    uniforms = to_js_uniforms(scene, THREE, ip.program.uniforms)
    material = create_material(
        THREE,
        ip.program.vertex_source,
        ip.program.fragment_source,
        uniforms
    )
    js_vbo.computeBoundingSphere();
    mesh = THREE.new.Mesh(js_vbo, material)
end


function wgl_convert(scene, jsctx, program::Program)
    js_vbo = jsctx.THREE.new.BufferGeometry()

    for (name, buff) in pairs(program.vertexarray)
        js_buff = JSBuffer(jsctx, buff)
        js_vbo.setAttribute(name, js_buff)
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
    js_vbo.computeBoundingSphere();
    return jsctx.THREE.new.Mesh(js_vbo, material)
end


function debug_shader(name, program)
    # dir = joinpath(@__DIR__, "..", "debug")
    # isdir(dir) || mkdir(dir)
    # write(joinpath(dir, "$(name).frag"), program.fragment_source)
    # write(joinpath(dir, "$(name).vert"), program.vertex_source)
end

function update_model!(geom, plot)
    geom.matrixAutoUpdate = false
    geom.matrix.set(plot.model[]'...)
    on(plot.model) do model
        geom.matrix.set((model')...)
    end
end
