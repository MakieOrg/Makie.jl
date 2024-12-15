using ShaderAbstractions: InstancedProgram, Program
using Makie: Key, plotkey
using Colors: N0f8

function lift_convert(key, value, ::Attributes)
    convert(value) = wgl_convert(value, Key{key}())
    if value isa Observable
        val = lift(convert, value)
    else
        val = convert(value)
    end
    if key === :colormap && val[] isa AbstractArray
        return ShaderAbstractions.Sampler(val)
    else
        return val
    end
end


function lift_convert(key, value, plot)
    convert(value) = wgl_convert(value, Key{key}(), Key{plotkey(plot)}())
    if value isa Observable
        val = lift(convert, plot, value)
    else
        val = convert(value)
    end
    if key === :colormap && val[] isa AbstractArray
        return ShaderAbstractions.Sampler(val)
    else
        return val
    end
end

tlength(T) = length(T)
tlength(::Type{<:Real}) = 1

serialize_three(val::Number) = val
serialize_three(val::Vec2f) = convert(Vector{Float32}, val)
serialize_three(val::Vec3f) = convert(Vector{Float32}, val)
serialize_three(val::Vec4f) = convert(Vector{Float32}, val)
serialize_three(val::Quaternion) = convert(Vector{Float32}, collect(val.data))
serialize_three(val::RGB) = Float32[red(val), green(val), blue(val)]
serialize_three(val::RGBA) = Float32[red(val), green(val), blue(val), alpha(val)]
serialize_three(val::Mat4f) = collect(vec(val))
serialize_three(val::Mat3) = collect(vec(val))

function serialize_three(array::AbstractArray)
    return serialize_three(flatten_buffer(array))
end

function serialize_three(array::Buffer)
    return serialize_three(flatten_buffer(array))
end

function serialize_three(array::AbstractArray{T}) where {T<:Union{N0f8,UInt8,Int32,UInt32,Float32,Float16,Float64}}
    vec(convert(Array, array))
end

function serialize_three(p::Makie.AbstractPattern)
    return serialize_three(Makie.to_image(p))
end

three_format(::Type{<:Integer}) = "RedIntegerFormat"
three_format(::Type{<:Real}) = "RedFormat"
three_format(::Type{<:RGB}) = "RGBFormat"
three_format(::Type{<:RGBA}) = "RGBAFormat"

three_format(::Type{<: Makie.VecTypes{1}}) = "RedFormat"
three_format(::Type{<: Makie.VecTypes{2}}) = "RGFormat"
three_format(::Type{<: Makie.VecTypes{3}}) = "RGBFormat"
three_format(::Type{<: Makie.VecTypes{4}}) = "RGBAFormat"

three_type(::Type{Float16}) = "FloatType"
three_type(::Type{Float32}) = "FloatType"
three_type(::Type{N0f8}) = "UnsignedByteType"
three_type(::Type{UInt8}) = "UnsignedByteType"

function three_filter(sym::Symbol)
    sym === :linear && return "LinearFilter"
    sym === :nearest && return "NearestFilter"
    sym == :nearest_mipmap_nearest && return "NearestMipmapNearestFilter"
    sym == :nearest_mipmap_linear  && return "NearestMipmapLinearFilter"
    sym == :linear_mipmap_nearest  && return "LinearMipmapNearestFilter"
    sym == :linear_mipmap_linear   && return "LinearMipmapLinearFilter"
    error("Unknown filter mode '$sym'")
end

function three_repeat(s::Symbol)
    s === :clamp_to_edge && return "ClampToEdgeWrapping"
    s === :mirrored_repeat && return "MirroredRepeatWrapping"
    s === :repeat && return "RepeatWrapping"
    error("Unknown repeat mode '$s'")
end

function serialize_three(color::Sampler{T,N}) where {T,N}
    tex = Dict(:type => "Sampler", 
               :data => serialize_three(color.data),
               :size => Int32[size(color.data)...], 
               :three_format => three_format(T),
               :three_type => three_type(eltype(T)),
               :minFilter => three_filter(color.minfilter),
               :magFilter => three_filter(color.magfilter),
               :wrapS => three_repeat(color.repeat[1]), 
               :mipmap => color.mipmap,
               :anisotropy => color.anisotropic)
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
        # we don't send observables and instead use
        # uniform_updater(dict)
        result[k] = serialize_three(to_value(v))
    end
    return result
end



"""
    flatten_buffer(array::AbstractArray)

Flattens `array` array to be a 1D Vector of Float32 / UInt8.
If presented with AbstractArray{<: Colorant/Tuple/SVector}, it will flatten those
to their element type.
"""
function flatten_buffer(array::AbstractArray{<: Number})
    return array
end
function flatten_buffer(array::AbstractArray{<:AbstractFloat})
    return convert(Array{Float32}, array)
end
function flatten_buffer(array::Buffer)
    return flatten_buffer(getfield(array, :data))
end

function flatten_buffer(array::AbstractArray{T}) where {T<:N0f8}
    return collect(reinterpret(UInt8, array))
end

function flatten_buffer(array::AbstractArray{T}) where {T}
    return flatten_buffer(collect(reinterpret(eltype(T), array)))
end

const ASSETS_DIR = @path joinpath(@__DIR__, "..", "assets")
lasset(paths...) = read(joinpath(ASSETS_DIR, paths...), String)

isscalar(x::StaticVector) = true
isscalar(x::Mat) = true
isscalar(x::AbstractArray) = false
isscalar(x::Billboard) = isscalar(x.rotation)
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true

function ShaderAbstractions.type_string(::ShaderAbstractions.AbstractContext,
                                        ::Type{<:Makie.Quaternion})
    return "vec4"
end

function ShaderAbstractions.convert_uniform(::ShaderAbstractions.AbstractContext,
                                            t::Quaternion)
    return convert(Quaternion, t)
end

function wgl_convert(value, key1, key2...)
    val = Makie.convert_attribute(value, key1, key2...)
    return if val isa AbstractArray{<:Float64}
        return Makie.el32convert(val)
    else
        return val
    end
end

function wgl_convert(value::AbstractMatrix, ::key"colormap", key2...)
    return ShaderAbstractions.Sampler(value)
end

function serialize_buffer_attribute(buffer::AbstractVector{T}) where {T}
    return Dict(:flat => serialize_three(buffer), :type_length => tlength(T))
end

function serialize_named_buffer(va::ShaderAbstractions.VertexArray)
    return Dict(map(ShaderAbstractions.buffers(va)) do (name, buff)
                    return name => serialize_buffer_attribute(buff)
                end)
end

function register_geometry_updates(@nospecialize(plot), update_buffer::Observable, named_buffers::ShaderAbstractions.VertexArray)
    for (name::Symbol, buffer::Buffer) in ShaderAbstractions.buffers(named_buffers)
        on(plot, ShaderAbstractions.updater(buffer).update) do (f, args)
            # update to replace the whole buffer!
            if f === ShaderAbstractions.update!
                new_array = args[1]
                flat = flatten_buffer(new_array)
                update_buffer[] = [name, serialize_three(flat), length(new_array)]
            end
            return
        end
    end
    return update_buffer
end

function register_geometry_updates(@nospecialize(plot), update_buffer::Observable, program::Program)
    return register_geometry_updates(plot, update_buffer, program.vertexarray)
end

function register_geometry_updates(@nospecialize(plot), update_buffer::Observable, program::InstancedProgram)
    return register_geometry_updates(plot, update_buffer, program.per_instance)
end

function uniform_updater(@nospecialize(plot), uniforms::Dict)
    updater = Observable{Any}(Any[:none, []])
    for (name, value) in uniforms
        if value isa Sampler
            on(plot, ShaderAbstractions.updater(value).update) do (f, args)
                if f === ShaderAbstractions.update!
                    update = [name, [Int32[size(value.data)...], serialize_three(args[1])]]
                    updater[] = isdefined(Bonito, :LargeUpdate) ? Bonito.LargeUpdate(update) : update
                end
                return
            end
        else
            value isa Observable || continue
            on(plot, value) do value
                updater[] = [name, serialize_three(value)]
                return
            end
        end
    end
    return updater
end

function serialize_three(@nospecialize(plot), ip::InstancedProgram)
    program = serialize_three(plot, ip.program)
    program[:instance_attributes] = serialize_named_buffer(ip.per_instance)
    register_geometry_updates(plot, program[:attribute_updater], ip)
    return program
end

reinterpret_faces(p, faces::AbstractVector) = collect(reinterpret(UInt32, decompose(GLTriangleFace, faces)))

function reinterpret_faces(@nospecialize(plot), faces::Buffer)
    result = Observable(reinterpret_faces(plot, ShaderAbstractions.data(faces)))
    on(plot, ShaderAbstractions.updater(faces).update) do (f, args)
        if f === ShaderAbstractions.update!
            result[] = reinterpret_faces(plot, args[1])
        end
    end
    return result
end


function serialize_three(@nospecialize(plot), program::Program)
    facies = reinterpret_faces(plot, ShaderAbstractions.indexbuffer(program.vertexarray))
    indices = convert(Observable, facies)
    uniforms = serialize_uniforms(program.uniforms)
    attribute_updater = Observable(["", [], 0])
    register_geometry_updates(plot, attribute_updater, program)
    # TODO, make this configurable in ShaderAbstractions
    update_shader(x) = replace(x, "#version 300 es" => "")
    return Dict(:vertexarrays => serialize_named_buffer(program.vertexarray),
                :faces => indices, :uniforms => uniforms,
                :vertex_source => update_shader(program.vertex_source),
                :fragment_source => update_shader(program.fragment_source),
                :uniform_updater => uniform_updater(plot, program.uniforms),
                :attribute_updater => attribute_updater)
end

function serialize_scene(scene::Scene)

    hexcolor(c) = "#" * hex(Colors.color(to_color(c)))
    pixel_area = lift(area -> Int32[minimum(area)..., widths(area)...], scene, viewport(scene))

    cam_controls = cameracontrols(scene)

    cam3d_state = if cam_controls isa Camera3D
        fields = (:lookat, :upvector, :eyeposition, :fov, :near, :far)
        dict = Dict((f => lift(x -> serialize_three(Float32.(x)), scene, getfield(cam_controls, f)) for f in fields))
        dict[:resolution] = lift(res -> Int32[res...], scene, scene.camera.resolution)
        dict
    else
        nothing
    end

    children = map(child-> serialize_scene(child), scene.children)

    dirlight = Makie.get_directional_light(scene)
    light_dir = isnothing(dirlight) ? Observable(Vec3f(1)) : dirlight.direction
    cam_rel = isnothing(dirlight) ? false : dirlight.camera_relative

    serialized = Dict(
        :viewport => pixel_area,
        :backgroundcolor => lift(hexcolor, scene, scene.backgroundcolor),
        :backgroundcolor_alpha => lift(Colors.alpha, scene, scene.backgroundcolor),
        :clearscene => scene.clear,
        :camera => serialize_camera(scene),
        :light_direction => light_dir,
        :camera_relative_light => cam_rel,
        :plots => serialize_plots(scene, scene.plots),
        :cam3d_state => cam3d_state,
        :visible => scene.visible,
        :uuid => js_uuid(scene),
        :children => children
    )
    return serialized
end

function serialize_plots(scene::Scene, plots::Vector{Plot}, result=[])
    for plot in plots
        # if no plots inserted, this truly is an atomic
        if isempty(plot.plots)
            plot_data = serialize_three(scene, plot)
            plot_data[:uuid] = js_uuid(plot)
            push!(result, plot_data)
        else
            serialize_plots(scene, plot.plots, result)
        end
    end
    return result
end

# TODO: lines overwrites this
function serialize_three(scene::Scene, @nospecialize(plot::AbstractPlot))
    program = create_shader(scene, plot)
    mesh = serialize_three(plot, program)
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = plot.visible
    mesh[:uuid] = js_uuid(plot)
    mesh[:transparency] = plot.transparency
    mesh[:overdraw] = plot.overdraw
    mesh[:zvalue] = Makie.zvalue2d(plot)

    uniforms = mesh[:uniforms]
    updater = mesh[:uniform_updater]

    dirlight = Makie.get_directional_light(scene)
    if !isnothing(dirlight)
        uniforms[:light_color] = serialize_three(dirlight.color[])
        on(plot, dirlight.color) do value
            updater[] = [:light_color, serialize_three(value)]
            return
        end
    end

    ambientlight = Makie.get_ambient_light(scene)
    if !isnothing(ambientlight)
        uniforms[:ambient] = serialize_three(ambientlight.color[])
        on(plot, ambientlight.color) do value
            updater[] = [:ambient, serialize_three(value)]
            return
        end
    end

    if haskey(plot, :markerspace)
        mesh[:markerspace] = plot.markerspace
    end
    mesh[:space] = plot.space

    key = haskey(plot, :markerspace) ? (:markerspace) : (:space)
    mesh[:cam_space] = to_value(get(plot, key, :data))

    # Handle clip planes
    if plot isa Voxels

        clip_planes = map(
                plot, plot.converted..., plot.model, plot.clip_planes, plot.space
            ) do xs, ys, zs, chunk, model, planes, space

            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            # model/modelinv has no perspective projection so we should be fine
            # with just applying it to the plane origin and transpose(inv(modelinv))
            # to plane.normal
            mini = minimum.((xs, ys, zs))
            width = maximum.((xs, ys, zs)) .- mini
            _model = Mat4f(model) *
                Makie.scalematrix(Vec3f(width ./ size(chunk))) *
                Makie.translationmatrix(Vec3f(mini))
            modelinv = inv(_model)
            @assert isapprox(modelinv[4, 4], 1, atol = 1e-6)

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                origin = modelinv * to_ndim(Point4f, planes[i].distance * planes[i].normal, 1)
                normal = transpose(_model) * to_ndim(Vec4f, planes[i].normal, 0)
                distance = dot(Vec3f(origin[1], origin[2], origin[3]) / origin[4],
                    Vec3f(normal[1], normal[2], normal[3]))
                output[i] = Vec4f(normal[1], normal[2], normal[3], distance)
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e9)
            end

            return output
        end

    elseif plot isa Volume

        # TODO: better solution (ShaderAbstractions doesn't like Vector uniforms)
        model2 = lift(plot, plot.model, plot[1], plot[2], plot[3]) do m, xyz...
            mi = minimum.(xyz)
            maxi = maximum.(xyz)
            w = maxi .- mi
            m2 = Mat4f(w[1], 0, 0, 0, 0, w[2], 0, 0, 0, 0, w[3], 0, mi[1], mi[2], mi[3], 1)
            return convert(Mat4f, m) * m2
        end

        clip_planes = map(plot, model2, plot.clip_planes, plot.space) do model, planes, space
            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            # model/modelinv has no perspective projection so we should be fine
            # with just applying it to the plane origin and transpose(inv(modelinv))
            # to plane.normal
            modelinv = inv(model)
            @assert isapprox(modelinv[4, 4], 1, atol = 1e-6)

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                origin = modelinv * to_ndim(Point4f, planes[i].distance * planes[i].normal, 1)
                normal = transpose(model2[]) * to_ndim(Vec4f, planes[i].normal, 0)
                distance = dot(Vec3f(origin[1], origin[2], origin[3]) / origin[4],
                    Vec3f(normal[1], normal[2], normal[3]))
                output[i] = Vec4f(normal[1], normal[2], normal[3], distance)
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e9)
            end

            return output
        end

    else

        clip_planes = map(plot, plot.clip_planes, plot.space) do planes, space
            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            if length(planes) > 8
                @warn("Only up to 8 clip planes are supported. The rest are ignored!", maxlog = 1)
            end

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                output[i] = Makie.gl_plane_format(planes[i])
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e10)
            end

            return output
        end

    end

    uniforms[:clip_planes] = serialize_three(clip_planes[])
    on(plot, clip_planes) do value
        updater[] = [:clip_planes, serialize_three(value)]
        return
    end

    uniforms[:num_clip_planes] = serialize_three(
        Makie.is_data_space(plot.space[]) ? length(clip_planes[]) : 0
    )
    onany(plot, plot.clip_planes, plot.space) do planes, space
        N = Makie.is_data_space(space) ? length(planes) : 0
        updater[] = [:num_clip_planes, serialize_three(N)]
        return
    end

    return mesh
end

function serialize_camera(scene::Scene)
    cam = scene.camera
    return lift(scene, cam.view, cam.projection, cam.resolution) do view, proj, res
        # eyeposition updates with viewmatrix, since an eyepos change will trigger
        # a view matrix change!
        ep = cam.eyeposition[]
        return [vec(collect(Mat4f(view))), vec(collect(Mat4f(proj))), Int32[res...], Float32[ep...]]
    end
end
