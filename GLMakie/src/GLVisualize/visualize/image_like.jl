"""
A matrix of colors is interpreted as an image
"""
_default(::AbstractObservable{Array{RGBA{N0f8}, 2}}, ::Style{:default}, ::Dict{Symbol,Any})


function _default(main::MatTypes{T}, ::Style, data::Dict) where T <: Colorant
    @gen_defaults! data begin
        spatialorder = "yx"
    end
    if !(spatialorder in ("xy", "yx"))
        error("Spatial order only accepts \"xy\" or \"yx\" as a value. Found: $spatialorder")
    end
    ranges = get(data, :ranges) do
        const_lift(main, spatialorder) do m, s
            (0:size(m, s == "xy" ? 1 : 2), 0:size(m, s == "xy" ? 2 : 1))
        end
    end
    delete!(data, :ranges)
    @gen_defaults! data begin
        image = main => (Texture, "image, can be a Texture or Array of colors")
        position_x = nothing => Texture
        position_y = nothing => Texture
        primitive = const_lift(ranges) do r
            x, y = minimum(r[1]), minimum(r[2])
            xmax, ymax = maximum(r[1]), maximum(r[2])
            return Rect2f(x, y, xmax - x, ymax - y)
        end => to_uvmesh
        preferred_camera = :orthographic_pixel
        fxaa = false
        transparency = false
        shader = GLVisualizeShader(
            "fragment_output.frag", "image.vert", "texture.frag",
            view = Dict(
                "uv_swizzle" => "o_uv.$(spatialorder)",
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
    end
end

function to_uvmesh(geom)
    return NativeMesh(const_lift(GeometryBasics.uv_mesh, geom))
end

function to_plainmesh(geom)
    return NativeMesh(const_lift(GeometryBasics.triangle_mesh, geom))
end

"""
A matrix of Intensities will result in a contourf kind of plot
"""
function gl_heatmap(main::MatTypes{T}, data::Dict) where T <: AbstractFloat
    @gen_defaults! data begin
        intensity = main => Texture
        primitive = Rect2(0f0,0f0,1f0,1f0) => native_triangle_mesh
        nan_color = RGBAf(1, 0, 0, 1)
        highclip = RGBAf(0, 0, 0, 0)
        lowclip = RGBAf(0, 0, 0, 0)
        color_map = nothing => Texture
        color_norm = nothing
        stroke_width::Float32 = 0.0f0
        levels::Float32 = 0f0
        stroke_color = RGBA{Float32}(0,0,0,0)
        transparency = false
        shader = GLVisualizeShader(
            "fragment_output.frag", "heatmap.vert", "intensity.frag",
            view = Dict(
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
        fxaa = false
    end
    return data
end

#Volumes
const VolumeElTypes = Union{Gray, AbstractFloat}

const default_style = Style{:default}()

using .GLAbstraction: StandardPrerender

struct VolumePrerender
    sp::StandardPrerender
end
VolumePrerender(a, b) = VolumePrerender(StandardPrerender(a, b))

function (x::VolumePrerender)()
    x.sp()
    glEnable(GL_CULL_FACE)
    glCullFace(GL_FRONT)
end

function _default(main::VolumeTypes{T}, s::Style, data::Dict) where T <: VolumeElTypes
    @gen_defaults! data begin
        volumedata = main => Texture
        hull = Rect3f(Vec3f(0), Vec3f(1)) => to_plainmesh
        model = Mat4f(I)
        modelinv = const_lift(inv, model)
        color_map = default(Vector{RGBA}, s) => Texture
        color_norm = color_map === nothing ? nothing : const_lift(extrema2f0, main)
        color = color_map === nothing ? default(RGBA, s) : nothing

        algorithm = MaximumIntensityProjection
        absorption = 1f0
        isovalue = 0.5f0
        isorange = 0.01f0
        enable_depth = true
        transparency = false
        shader = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "volume.vert", "volume.frag",
            view = Dict(
                "depth_init"  => vol_depth_init(to_value(enable_depth)),
                "depth_default"  => vol_depth_default(to_value(enable_depth)),
                "depth_main"  => vol_depth_main(to_value(enable_depth)),
                "depth_write" => vol_depth_write(to_value(enable_depth)),
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
        prerender = VolumePrerender(data[:transparency], data[:overdraw])
        postrender = () -> glDisable(GL_CULL_FACE)
    end
    return data
end

vol_depth_init(enable) = enable ? "float depth = 100000.0;" : ""
vol_depth_default(enable) = enable ? "gl_FragDepth = gl_FragCoord.z;" : ""
function vol_depth_main(enable)
    if enable
        """
        vec4 frag_coord = projectionview * model * vec4(pos, 1);
        depth = min(depth, frag_coord.z / frag_coord.w);
        """
    else "" end
end
function vol_depth_write(enable)
    if enable
        "gl_FragDepth = depth == 100000.0 ? gl_FragDepth : 0.5 * depth + 0.5;"
    else "" end
end

function _default(main::VolumeTypes{T}, s::Style, data::Dict) where T <: RGBA
    @gen_defaults! data begin
        volumedata = main => Texture
        hull = Rect3f(Vec3f(0), Vec3f(1)) => to_plainmesh
        model = Mat4f(I)
        modelinv = const_lift(inv, model)
        # These don't do anything but are needed for type specification in the frag shader
        color_map = nothing => Texture
        color_norm = nothing
        color = color_map === nothing ? default(RGBA, s) : nothing

        algorithm = AbsorptionRGBA
        transparency = false
        shader = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "volume.vert", "volume.frag",
            view = Dict(
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
        prerender = VolumePrerender(data[:transparency], data[:overdraw])
        postrender = () -> glDisable(GL_CULL_FACE)
    end
end
