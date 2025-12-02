using ShaderAbstractions: InstancedProgram, Program
using Makie: Key, plotkey
using Colors: N0f8


tlength(T) = length(T)
tlength(::Type{<:Real}) = 1

serialize_three(::Nothing) = false
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
function serialize_three(array::AbstractVector{T}) where {T <: OffsetInteger}
    return serialize_three(map(GeometryBasics.raw, array))
end
function serialize_three(array::AbstractArray{T}) where {T <: Union{N0f8, UInt8, Int32, UInt32, Float32, Float16, Float64}}
    return vec(convert(Array, array))
end

three_format(::Type{<:Integer}) = "RedIntegerFormat"
three_format(::Type{<:Real}) = "RedFormat"
three_format(::Type{<:RGB}) = "RGBFormat"
three_format(::Type{<:RGBA}) = "RGBAFormat"

three_format(::Type{<:Makie.VecTypes{1}}) = "RedFormat"
three_format(::Type{<:Makie.VecTypes{2}}) = "RGFormat"
three_format(::Type{<:Makie.VecTypes{3}}) = "RGBFormat"
three_format(::Type{<:Makie.VecTypes{4}}) = "RGBAFormat"

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

"""
    NoDataTextureAtlas(texture_atlas_size)

Optimization to just send the texture atlas one time to JS and then look it up from there in wglmakie.js,
instead of uploading this texture 10x in every plot.
"""
struct NoDataTextureAtlas <: ShaderAbstractions.AbstractSampler{Float16, 2}
    dims::NTuple{2, Int}
end
Base.size(x::NoDataTextureAtlas) = x.dims
Base.show(io::IO, ::NoDataTextureAtlas) = print(io, "NoDataTextureAtlas()")

function serialize_three(fta::NoDataTextureAtlas)
    tex = Dict(
        :type => "Sampler", :data => "texture_atlas",
        :size => [fta.dims...], :three_format => three_format(Float16),
        :three_type => three_type(Float16),
        :minFilter => three_filter(:linear),
        :magFilter => three_filter(:linear),
        :wrapS => "RepeatWrapping",
        :anisotropy => 16.0f0
    )
    tex[:wrapT] = "RepeatWrapping"
    return tex
end

function serialize_three(color::Sampler{T, N}) where {T, N}
    tex = Dict(
        :type => "Sampler",
        :data => serialize_three(color.data),
        :size => Int32[size(color.data)...],
        :three_format => three_format(T),
        :three_type => three_type(eltype(T)),
        :minFilter => three_filter(color.minfilter),
        :magFilter => three_filter(color.magfilter),
        :wrapS => three_repeat(color.repeat[1]),
        :mipmap => color.mipmap,
        :anisotropy => color.anisotropic
    )
    if N > 1
        tex[:wrapT] = three_repeat(color.repeat[2])
    end
    if N > 2
        tex[:wrapR] = three_repeat(color.repeat[3])
    end
    return tex
end

function serialize_uniforms(dict::Dict)
    result = Dict{Symbol, Any}()
    for (k, v) in dict
        # we don't send observables and instead use
        # uniform_updater(dict)
        result[k] = serialize_three(v)
    end
    return result
end

serialize_three(x::Dict) = x

"""
    flatten_buffer(array::AbstractArray)

Flattens `array` array to be a 1D Vector of Float32 / UInt8.
If presented with AbstractArray{<: Colorant/Tuple/SVector}, it will flatten those
to their element type.
"""
function flatten_buffer(array::AbstractArray{<:Number})
    return array
end
function flatten_buffer(array::AbstractArray{<:AbstractFloat})
    return convert(Array{Float32}, array)
end
function flatten_buffer(array::Buffer)
    return flatten_buffer(getfield(array, :data))
end

function flatten_buffer(array::AbstractArray{T}) where {T <: N0f8}
    return collect(reinterpret(UInt8, array))
end

function flatten_buffer(array::AbstractArray{T}) where {T}
    return flatten_buffer(collect(reinterpret(eltype(T), array)))
end

const ALL_SHADERS = Dict{String, String}()
function lasset(paths...)
    return get!(ALL_SHADERS, joinpath(paths...)) do
        read(joinpath(@__DIR__, "..", "assets", paths...), String)
    end
end


function ShaderAbstractions.type_string(
        ::ShaderAbstractions.AbstractContext,
        ::Type{<:Makie.Quaternion}
    )
    return "vec4"
end

function ShaderAbstractions.convert_uniform(
        ::ShaderAbstractions.AbstractContext,
        t::Quaternion
    )
    return convert(Quaternion, t)
end

function serialize_buffer_attribute(buffer::AbstractVector{T}) where {T}
    return Dict(:flat => serialize_three(buffer), :type_length => tlength(T))
end


reinterpret_faces(p, faces::AbstractVector) = collect(reinterpret(UInt32, decompose(GLTriangleFace, faces)))

function reinterpret_faces(@nospecialize(plot), faces::Buffer)
    return reinterpret_faces(plot, ShaderAbstractions.data(faces))
end

function serialize_scene(scene::Scene)

    hexcolor(c) = "#" * hex(Colors.color(to_color(c)))
    pixel_area = lift(area -> Int32[minimum(area)..., widths(area)...], scene, viewport(scene); ignore_equal_values = true)

    cam_controls = cameracontrols(scene)

    cam3d_state = if cam_controls isa Camera3D
        fields = (:lookat, :upvector, :eyeposition, :fov, :near, :far)
        dict = Dict((f => lift(x -> serialize_three(Float32.(x)), scene, getfield(cam_controls, f)) for f in fields))
        dict[:resolution] = lift(res -> Int32[res...], scene, scene.camera.resolution; ignore_equal_values = true)
        dict
    else
        nothing
    end

    children = map(child -> serialize_scene(child), scene.children)

    light_dir = Observable(serialize_three(Vec3f(1)), ignore_equal_values = true)
    cam_rel = Observable(serialize_three(false), ignore_equal_values = true)
    ambient = Observable(serialize_three(RGBf(0, 0, 1)), ignore_equal_values = true)
    light_color = Observable(serialize_three(RGBf(1, 0, 0)), ignore_equal_values = true)

    on(scene.compute.onchange, update = true) do _
        ambient[] = serialize_three(scene.compute[:ambient_color][])
        light_color[] = serialize_three(scene.compute[:dirlight_color][])
        light_dir[] = serialize_three(scene.compute[:dirlight_direction][])
        cam_rel[] = serialize_three(scene.compute[:dirlight_cam_relative][])
        return
    end

    serialized = Dict(
        :viewport => pixel_area,
        :backgroundcolor => lift(hexcolor, scene, scene.backgroundcolor; ignore_equal_values = true),
        :backgroundcolor_alpha => lift(Colors.alpha, scene, scene.backgroundcolor; ignore_equal_values = true),
        :clearscene => scene.clear,
        :camera => serialize_camera(scene),
        :light_direction => light_dir,
        :camera_relative_light => cam_rel,
        :ambient => ambient,
        :light_color => light_color,
        :plots => serialize_plots(scene, scene.plots),
        :cam3d_state => cam3d_state,
        :visible => scene.visible,
        :uuid => js_uuid(scene),
        :children => children
    )
    return serialized
end

function serialize_plots(scene::Scene, plots::Vector{Plot}, result = [])
    for plot in plots
        # if no plots inserted, this truly is an atomic
        if Makie.is_atomic_plot(plot)
            plot_data = serialize_three(scene, plot)
            plot_data[:uuid] = js_uuid(plot)
            push!(result, plot_data)
        end
        if !isempty(plot.plots)
            serialize_plots(scene, plot.plots, result)
        end
    end
    return result
end

function flat_m4f(x::AbstractArray)
    result = Vector{Float32}(undef, length(x))
    copyto!(result, Mat4f(x))
    return result
end

function serialize_camera(scene::Scene)
    cam = scene.camera
    # somehow ignore_equal_values=true is not enough,
    # so we manually check if previous values are the same
    last_view = Base.RefValue(Mat4d(I))
    last_proj = Base.RefValue(Mat4d(I))
    last_res = Base.RefValue(Vec2f(0))
    last_eyepos = Base.RefValue(Vec3f(0))
    obs = Observable([Float32[], Float32[], Int32[], Float32[]])

    onany(scene, cam.view, cam.projection, cam.resolution, cam.eyeposition; update = true) do view, proj, res, ep
        # eyeposition updates with viewmatrix, since an eyepos change will trigger
        # a view matrix change!
        if !(view ≈ last_view[] && proj ≈ last_proj[] && res ≈ last_res[] && ep ≈ last_eyepos[])
            obs[] = [flat_m4f(view), flat_m4f(proj), Int32[res...], Float32[ep...]]
        end
        last_eyepos[] = ep
        last_view[] = view
        last_proj[] = proj
        last_res[] = res
        return
    end
    return obs
end
