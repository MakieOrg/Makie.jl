using Colors
using ShaderAbstractions: InstancedProgram, Program
using AbstractPlotting: Key, plotkey
using Colors: N0f8
AbstractPlotting.plotkey(::Nothing) = :scatter

function lift_convert(key, value, plot)
    val = lift(value) do value
        return wgl_convert(value, Key{key}(), Key{plotkey(plot)}())
    end
    return if key == :colormap && val[] isa AbstractArray
        return ShaderAbstractions.Sampler(val)
    else
        val
    end
end

function Base.pairs(mesh::GeometryBasics.Mesh)
    return (kv for kv in GeometryBasics.attributes(mesh))
end

function GeometryBasics.faces(x::VertexArray)
    return GeometryBasics.faces(getfield(x, :data))
end

tlength(T) = length(T)
tlength(::Type{<:Real}) = 1

serialize_three(val::Number) = val
serialize_three(val::Vec2f0) = Float32[val...]
serialize_three(val::Vec3f0) = Float32[val...]
serialize_three(val::Vec4f0) = Float32[val...]
serialize_three(val::Quaternion) = Float32[val.data...]
serialize_three(val::RGB) = Float32[red(val), green(val), blue(val)]
serialize_three(val::RGBA) = Float32[red(val), green(val), blue(val), alpha(val)]
serialize_three(val::Mat4f0) = vec(val)
function serialize_three(observable::Observable)
    return Dict(:type => "Observable", :id => observable.id,
                :value => serialize_three(observable[]))
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

# Make sure we preserve pointer identity for uploaded textures, so
# we can actually find duplicated before uploading
const SAVE_POINTER_IDENTITY_FOR_TEXTURES = IdDict()
function serialize_texture_data(x)
    buffer = get!(SAVE_POINTER_IDENTITY_FOR_TEXTURES, x) do
        return serialize_three(x)
    end
    # Since we copy the data, and the data in x might have changed
    # we still need to copy the new data!
    buffer[:data] .= flatten_buffer(x)
    return buffer
end

function serialize_three(color::Sampler{T,N}) where {T,N}
    tex = Dict(:type => "Sampler", :data => serialize_texture_data(color.data),
               :size => [size(color.data)...], :three_format => three_format(T),
               :three_type => three_type(eltype(T)),
               :minFilter => three_filter(color.minfilter),
               :magFilter => three_filter(color.magfilter),
               :wrapS => three_repeat(color.repeat[1]), :anisotropy => color.anisotropic)
    if N > 1
        tex[:wrapT] = three_repeat(color.repeat[2])
    end
    if N > 2
        tex[:wrapR] = three_repeat(color.repeat[3])
    end
    return tex
end

function serialize_uniforms(dict::Dict)
    result = Dict{Symbol,Any}()
    for (k, v) in dict
        result[k] = serialize_three(to_value(v))
    end
    return result
end

three_format(::Type{<:Real}) = "RedFormat"
three_format(::Type{<:RGB}) = "RGBFormat"
three_format(::Type{<:RGBA}) = "RGBAFormat"

three_type(::Type{Float16}) = "FloatType"
three_type(::Type{Float32}) = "FloatType"
three_type(::Type{N0f8}) = "UnsignedByteType"

function three_filter(sym)
    sym == :linear && return "LinearFilter"
    return sym == :nearest && return "NearestFilter"
end

function three_repeat(s::Symbol)
    s == :clamp_to_edge && return "ClampToEdgeWrapping"
    s == :mirrored_repeat && return "MirroredRepeatWrapping"
    return s == :repeat && return "RepeatWrapping"
end

"""
    flatten_buffer(array::AbstractArray)
Flattens `array` array to be a 1D Vector of Float32 / UInt8.
If presented with AbstractArray{<: Colorant/Tuple/SVector}, it will flatten those
to their element type.
"""
function flatten_buffer(array::AbstractArray{T}) where {T}
    return flatten_buffer(reinterpret(eltype(T), array))
end

function flatten_buffer(array::AbstractArray{<:AbstractFloat}) where {T}
    return convert(Vector{Float32}, vec(array))
end

function flatten_buffer(array::AbstractArray{<:Integer}) where {T}
    return convert(Vector{Int32}, vec(array))
end

function flatten_buffer(array::AbstractArray{<:Unsigned}) where {T}
    return convert(Vector{UInt32}, vec(array))
end

function flatten_buffer(array::AbstractArray{T}) where {T<:UInt8}
    return convert(Vector{T}, vec(array))
end

function flatten_buffer(array::AbstractArray{T}) where {T<:N0f8}
    return flatten_buffer(reinterpret(UInt8, array))
end

lasset(paths...) = read(joinpath(@__DIR__, "..", "assets", paths...), String)

isscalar(x::StaticArrays.StaticArray) = true
isscalar(x::AbstractArray) = false
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true

function ShaderAbstractions.type_string(context::ShaderAbstractions.AbstractContext,
                                        t::Type{<:AbstractPlotting.Quaternion})
    return "vec4"
end
function ShaderAbstractions.convert_uniform(context::ShaderAbstractions.AbstractContext,
                                            t::Quaternion)
    return convert(Quaternion, t)
end

function wgl_convert(value, key1, key2)
    val = AbstractPlotting.convert_attribute(value, key1, key2)
    return if val isa AbstractArray{<:Float64}
        return AbstractPlotting.el32convert(val)
    else
        return val
    end
end

function wgl_convert(value::AbstractMatrix, ::key"colormap", key2)
    return ShaderAbstractions.Sampler(value)
end

function serialize_buffer_attribute(buffer::AbstractVector{T}) where {T}
    return Dict(:flat => serialize_three(buffer), :type_length => tlength(T))
end

function serialize_named_buffer(buffer)
    return Dict(map(pairs(buffer)) do (name, buff)
                    return name => serialize_buffer_attribute(buff)
                end)
end

function register_geometry_updates(update_buffer::Observable, named_buffers)
    for (name, buffer) in pairs(named_buffers)
        if buffer isa Buffer
            on(ShaderAbstractions.updater(buffer).update) do (f, args)
                # update to replace the whole buffer!
                if f === (setindex!) && args[1] isa AbstractArray && args[2] isa Colon
                    new_array = args[1]
                    flat = flatten_buffer(new_array)
                    update_buffer[] = [name, serialize_three(flat), length(new_array)]
                end
                return
            end
        end
    end
    return update_buffer
end

function register_geometry_updates(update_buffer::Observable, program::Program)
    return register_geometry_updates(update_buffer, program.vertexarray)
end

function register_geometry_updates(update_buffer::Observable, program::InstancedProgram)
    return register_geometry_updates(update_buffer, program.per_instance)
end

function uniform_updater(uniforms::Dict)
    updater = Observable(Any[:none, []])
    for (name, value) in uniforms
        if value isa Sampler
            on(ShaderAbstractions.updater(value).update) do (f, args)
                if args[2] isa Colon && f == setindex!
                    updater[] = [name, serialize_three(args[1])]
                end
                return
            end
        else
            value isa Observable || continue
            on(value) do value
                updater[] = [name, serialize_three(value)]
                return
            end
        end
    end
    return updater
end

function serialize_three(ip::InstancedProgram)
    program = serialize_three(ip.program)
    program[:instance_attributes] = serialize_named_buffer(ip.per_instance)
    register_geometry_updates(program[:attribute_updater], ip)
    return program
end

function serialize_three(program::Program)
    indices = GeometryBasics.faces(program.vertexarray)
    indices = reinterpret(UInt32, indices)
    uniforms = serialize_uniforms(program.uniforms)
    attribute_updater = Observable(["", [], 0])
    register_geometry_updates(attribute_updater, program)
    return Dict(:vertexarrays => serialize_named_buffer(program.vertexarray),
                :faces => indices, :uniforms => uniforms,
                :vertex_source => program.vertex_source,
                :fragment_source => program.fragment_source,
                :uniform_updater => uniform_updater(program.uniforms),
                :attribute_updater => attribute_updater)
end

function serialize_scene(scene::Scene, serialized_scenes=[])
    hexcolor(c) = "#" * hex(Colors.color(to_color(c)))
    pixel_area = lift(area -> [minimum(area)..., widths(area)...], pixelarea(scene))
    cam_controls = cameracontrols(scene)
    cam3d_state = if cam_controls isa Camera3D
        fields = (:lookat, :upvector, :eyeposition, :fov, :near, :far)
        Dict((f => serialize_three(getfield(cam_controls, f)[]) for f in fields))
    else
        nothing
    end
    serialized = Dict(:pixelarea => pixel_area,
                      :backgroundcolor => lift(hexcolor, scene.backgroundcolor),
                      :clearscene => scene.clear,
                      :camera => serialize_camera(scene),
                      :plots => serialize_plots(scene, scene.plots),
                      :cam3d_state => cam3d_state,
                      :visible => scene.visible)
    push!(serialized_scenes, serialized)
    foreach(child -> serialize_scene(child, serialized_scenes), scene.children)
    return serialized_scenes
end

function serialize_plots(scene::Scene, plots::Vector{T}, result=[]) where {T<:AbstractPlot}
    for plot in plots
        # if no plots inserted, this truely is an atomic
        if isempty(plot.plots)
            push!(result, serialize_three(scene, plot))
        else
            serialize_plots(scene, plot.plots, result)
        end
    end
    return result
end

function serialize_three(scene::Scene, plot::AbstractPlot)
    program = create_shader(scene, plot)
    mesh = serialize_three(program)
    mesh[:name] = string(AbstractPlotting.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = plot.visible
    uniforms = mesh[:uniforms]
    delete!(uniforms, :lightposition)
    if haskey(plot, :lightposition)
        eyepos = scene.camera.eyeposition
        lightpos = lift(plot.lightposition, eyepos,
                                        typ=Vec3f0) do pos, eyepos
            return ifelse(pos == :eyeposition, eyepos, pos)::Vec3f0
        end
        uniforms[:lightposition] = serialize_three(lightpos[])
        updater = mesh[:uniform_updater]
        on(lightpos) do value
            updater[] = [:lightposition, serialize_three(value)]
            return
        end
    end
    return mesh
end

function serialize_camera(scene::Scene)
    cam = scene.camera
    return lift(cam.view, cam.projection, cam.resolution) do v, p, res
        # projectionview updates with projection & view
        pv = cam.projectionview[]
        # same goes for eyeposition, since an eyepos change will trigger
        # a view matrix change!
        ep = cam.eyeposition[]
        return [serialize_three.((v, p, pv, res, ep))...]
    end
end

function recurse_object(f, object::AbstractDict)
    # we only search for duplicates in objects, not keys
    # if you put big objects in keys - well so be it :D
    return Dict((k => f(v) for (k, v) in object))
end

function recurse_object(f, object::Union{Tuple,AbstractVector,Pair})
    return map(f, object)
end

const BasicTypes = Union{Array{<:Number},Number,Bool, Nothing}

recurse_object(f, x::BasicTypes) = x
recurse_object(f, x::String) = x
recurse_object(f, x) = x

_replace_dublicates(object::BasicTypes, objects=IdDict(), duplicates=[]) = object

function _replace_dublicates(object, objects=IdDict(), duplicates=[])
    if object isa String && length(object) < 30
        return object
    end
    if object isa StaticArray
        return object
    end
    return if haskey(objects, object)
        idx = objects[object]
        if idx === nothing
            push!(duplicates, object)
            idx = length(duplicates)
            objects[object] = idx
        end
        return Dict(:type => "Reference", :index => idx)
    else
        objects[object] = nothing
        # we only search for duplicates in objects, not keys
        # if you put big objects in keys - well so be it :D
        return recurse_object(x -> _replace_dublicates(x, objects, duplicates), object)
    end
end

function replace_dublicates(object)
    duplicates = []
    result = _replace_dublicates(object, IdDict(), duplicates)
    return [result, duplicates]
end
