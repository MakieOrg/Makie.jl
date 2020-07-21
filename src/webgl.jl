using Colors
using ShaderAbstractions: InstancedProgram, Program
using AbstractPlotting: Key, plotkey
using Colors: N0f8

tlength(T) = length(T)
tlength(::Type{<: Real}) = 1

serialize_three(val::Number) = val
serialize_three(val::Vec2f0) = Float32[val...]
serialize_three(val::Vec3f0) = Float32[val...]
serialize_three(val::Vec4f0) = Float32[val...]
serialize_three(val::Quaternion) = Float32[val.data...]
serialize_three(val::RGB) = Float32[red(val), green(val), blue(val)]
serialize_three(val::RGBA) = Float32[red(val), green(val), blue(val), alpha(val)]
serialize_three(val::Mat4f0) = Float32[val...]

function serialize_three(color::Sampler{T, N}) where {T, N}
    data = serialize_three(jsctx, color.data)
    tex = Dict(
        :type => "Sampler",
        :data => data,
        :size => [size(color.data)...],
        :three_format => three_format(T),
        :three_type => three_type(eltype(T)),

        :minFilter => three_filter(color.minfilter),
        :magFilter => three_filter(color.magfilter),
        :wrapS => three_repeat(color.repeat[1]),
        :anisotropy => color.anisotropic,
    )
    if N > 1
        tex[:wrapT] = three_repeat(color.repeat[2])
    end
    if N > 2
        tex[:wrapR] = three_repeat(color.repeat[3])
    end
    return tex
end

function serialize_three(dict::Dict)
    result = Dict{Symbol, Any}()
    for (k, v) in dict
        result[k] = Dict(:value => serialize_three(to_value(v)))
    end
    return result
end

function connect_uniforms(mesh, dict::Dict)
    for (k, v) in dict
        # Sampler + Buffers won't come through as Observables,
        # Since they update themselves
        # atm we also allow other values to be non Observables
        v isa Observable || continue
        if v isa Sampler
            flat_data = Observable([])
            on(ShaderAbstractions.updater(color).update) do (f, args)
                if args[2] isa Colon && f == setindex!
                    newdata = args[1]
                    flat_data[] = serialize_three(newdata)
                    tex.needsUpdate = true
                end
            end
            onjs(mesh, flat_data, js"""function (data){
                const tex = $(mesh).material.uniforms[$(k)]
                tex.array.set(three_deserialize(data))
                tex.needsUpdate = true
            }""")
        else
            serialized = lift(serialize_three, v)
            onjs(mesh, serialized, js"""function (val){
                const prop = $(mesh).material.uniforms[$(k)]
                prop.value = deserialize_three(val)
                prop.needsUpdate = true
            }""")
        end
    end
    return result
end

three_format(::Type{<: Real}) = "RedFormat"
three_format(::Type{<: RGB}) = "RGBFormat"
three_format(::Type{<: RGBA}) = "RGBAFormat"

three_type(::Type{Float16}) = "FloatType"
three_type(::Type{Float32}) = "FloatType"
three_type(::Type{N0f8}) = "UnsignedByteType"

function three_filter(sym)
    sym == :linear && return "LinearFilter"
    sym == :nearest && return "NearestFilter"
end

function three_repeat(s::Symbol)
    s == :clamp_to_edge && return "ClampToEdgeWrapping"
    s == :mirrored_repeat && return "MirroredRepeatWrapping"
    s == :repeat && return "RepeatWrapping"
end

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

function serialize_three(array::AbstractArray)
    return serialize_three(flatten_buffer(array))
end

function serialize_three(array::Vector{UInt8})
    return Dict(:type => "Uint8Array", :data => array)
end

function serialize_three(array::Vector{Int32})
    return Dict(:type => "Int32Array", :data => array)
end

function serialize_three(array::Vector{UInt32})
    return Dict(:type => "Uint32Array", :data => array)
end

function serialize_three(array::Vector{Float32})
    return Dict(:type => "Float32Array", :data => array)
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
    return ShaderAbstractions.Sampler(value)
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

function Base.pairs(mesh::GeometryBasics.Mesh)
    return GeometryBasics.attributes(mesh)
end

function GeometryBasics.faces(x::VertexArray)
    return GeometryBasics.faces(getfield(x, :data))
end

serialize_buffer_attribute(buffer::AbstractVector{T}) where {T} = Dict(
    :flat => flatten_buffer(buffer)
    :type_length => tlength(T)
)

function serialize_named_buffer(buffer)
    return Dict(map(pairs(buffer)) do (name, buff)
        name => serialize_buffer_attribute(buff)
    end)
end

function serialize_program(THREE, ip::InstancedProgram)
    program = serialize_program(ip.program)
    program[:instance_attributes] = serialize_named_buffer(ip.per_instance)
    return program
end

function serialize_program(THREE, program::Program)
    indices = GeometryBasics.faces(program.vertexarray)
    indices = reinterpret(UInt32, indices)
    uniforms = serialize_three(program.uniforms)
    return Dict(
        :vertexarrays => serialize_named_buffer(program.vertexarray),
        :faces => indices,
        :uniforms => uniforms,
        :vertex_source => program.vertex_source,
        :fragment_source => program.fragment_source,
    )
end

function debug_shader(name, program)
    dir = joinpath(@__DIR__, "..", "debug")
    isdir(dir) || mkdir(dir)
    write(joinpath(dir, "$(name).frag"), program.fragment_source)
    write(joinpath(dir, "$(name).vert"), program.vertex_source)
end

function update_model!(geom, plot)
    geom.matrixAutoUpdate = false
    geom.matrix.set(plot.model[]'...)
    on(plot.model) do model
        geom.matrix.set((model')...)
    end
end

function resize_pogram(jsctx, program::InstancedProgram, mesh)
    real_size = Ref(length(program.per_instance))
    buffers = [v for (k, v) in pairs(program.per_instance)]
    resize = Observable(Set{Symbol}())
    update_buffer = Observable(["name", [], 0])
    onjs(jsctx, update_buffer, js"""function (val){
        const name = val[0];
        const flat = deserialize_js(val[1]);
        const len = val[2];
        const geometry = $(mesh).geometry
        const jsb = geometry.attributes[name]
        jsb.set(flat, 0)
        jsb.needsUpdate = true
        geometry.instanceCount = len
    }""")
    for (name, buffer) in pairs(program.per_instance)
        if buffer isa Buffer
            on(ShaderAbstractions.updater(buffer).update) do (f, args)
                # update to replace the whole buffer!
                if f === (setindex!) && args[1] isa AbstractArray && args[2] isa Colon
                    new_array = args[1]
                    flat = flatten_buffer(new_array)
                    len = length(new_array)
                    if real_size[] >= length(new_array)
                        update_buffer[] = [name, flat, len]
                    else
                        push!(resize[], name)
                        if (length(resize[]) == length(buffers)) || all(buffers) do buff
                                    length(new_array) == length(buff)
                                end
                            real_size[] = length(buffer)
                            resize[] = resize[]
                            empty!(resize[])
                        end
                    end
                end
            end
        end
    end
    on(resize) do new_data
        JSServe.fuse(jsctx) do
            js_vbo = jsctx.new.InstancedBufferGeometry()
            for (name, buff) in pairs(program.program.vertexarray)
                js_buff = JSBuffer(jsctx, buff)
                js_vbo.setAttribute(name, js_buff)
            end
            indices = GeometryBasics.faces(program.program.vertexarray)
            indices = reinterpret(UInt32, indices)
            js_vbo.setIndex(indices)
            js_vbo.instanceCount = length(program.per_instance)
            for (name, buff) in pairs(program.per_instance)
                js_buff = JSInstanceBuffer(jsctx, buff)
                js_vbo.setAttribute(name, js_buff)
            end
            js_vbo.boundingSphere = jsctx.new.Sphere()
            # don't use intersection / culling
            js_vbo.boundingSphere.radius = 10000000000000f0
            mesh.geometry = js_vbo
            mesh.needsUpdate = true
        end
    end
end

function resize_pogram(jsctx, program::Program, mesh)
    real_size = Ref(length(program.vertexarray))
    buffers = [v for (k, v) in pairs(program.vertexarray)]
    resize = Observable(Set{Symbol}())
    update_buffer = Observable(["name", [], 0])
    onjs(jsctx, update_buffer, js"""function (val){
        const name = val[0];
        const flat = deserialize_js(val[1]);
        const len = val[2];
        const geometry = $(mesh).geometry
        const jsb = geometry.attributes[name]
        jsb.set(flat, 0)
        jsb.needsUpdate = true
        geometry.instanceCount = len
        geometry.needsUpdate = true
    }""")
    for (name, buffer) in pairs(program.vertexarray)
        if buffer isa Buffer
            on(ShaderAbstractions.updater(buffer).update) do (f, args)
                # update to replace the whole buffer!
                if f === (setindex!) && args[1] isa AbstractArray && args[2] isa Colon
                    new_array = args[1]
                    flat = flatten_buffer(new_array)
                    len = length(new_array)
                    if real_size[] >= length(new_array)
                        update_buffer[] = [name, flat, len]
                    else
                        push!(resize[], name)
                        if length(resize[]) == length(buffers)
                            real_size[] = length(buffer)
                            resize[] = resize[]
                            empty!(resize[])
                        end
                    end
                end
            end
        end
    end
    on(resize) do new_data
        JSServe.fuse(jsctx) do
            js_vbo = jsctx.new.BufferGeometry()
            for (name, buff) in pairs(program.vertexarray)
                js_buff = JSBuffer(jsctx, buff)
                js_vbo.setAttribute(name, js_buff)
            end
            indices = GeometryBasics.faces(program.vertexarray)
            indices = reinterpret(UInt32, indices)
            js_vbo.setIndex(indices)
            js_vbo.boundingSphere = jsctx.new.Sphere()
            # don't use intersection / culling
            js_vbo.boundingSphere.radius = 10000000000000f0
            mesh.geometry = js_vbo
            mesh.needsUpdate = true
        end
    end
end
