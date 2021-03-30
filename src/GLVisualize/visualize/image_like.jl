"""
A matrix of colors is interpreted as an image
"""
_default(::Node{Array{RGBA{N0f8}, 2}}, ::Style{:default}, ::Dict{Symbol,Any})


function _default(main::MatTypes{T}, ::Style, data::Dict) where T <: Colorant
    @gen_defaults! data begin
        spatialorder = "yx"
    end
    if !(spatialorder in ("xy", "yx"))
        error("Spatial order only accepts \"xy\" or \"yz\" as a value. Found: $spatialorder")
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
            return FRect2D(x, y, xmax - x, ymax - y)
        end => to_uvmesh
        preferred_camera = :orthographic_pixel
        fxaa = false
        shader = GLVisualizeShader("fragment_output.frag", "uv_vert.vert", "texture.frag",
            view = Dict("uv_swizzle" => "o_uv.$(spatialorder)"))
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
    instances = map(data[:position_x], data[:position_y]) do xs, ys
        (length(xs)-1) * (length(ys)-1)
    end 
    @gen_defaults! data begin
        intensity = main => Texture
        color_map = default(Vector{RGBA{N0f8}},s) => Texture
        primitive = Rect2D(0f0,0f0,1f0,1f0) => native_triangle_mesh
        instances = instances => "number of planes used to render the heatmap"
        # instances = const_lift(x->(size(x,1)) * (size(x,2)), main) => "number of planes used to render the heatmap"
        nan_color = RGBAf0(1, 0, 0, 1)
        highclip = RGBAf0(0, 0, 0, 0)
        lowclip = RGBAf0(0, 0, 0, 0)
        color_norm = const_lift(extrema2f0, main)
        stroke_width::Float32 = 0.05f0
        levels::Float32 = 5f0
        stroke_color = RGBA{Float32}(1,1,1,1)
        shader = GLVisualizeShader("fragment_output.frag", "uv_vert.vert", "intensity.frag")
        fxaa = false
    end
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
        hull = FRect3D(Vec3f0(0), Vec3f0(1)) => to_plainmesh
        model = Mat4f0(I)
        modelinv = const_lift(inv, model)
        color_map = default(Vector{RGBA}, s) => Texture
        color_norm = color_map == nothing ? nothing : const_lift(extrema2f0, main)
        color = color_map == nothing ? default(RGBA, s) : nothing

        algorithm = MaximumIntensityProjection
        absorption = 1f0
        isovalue = 0.5f0
        isorange = 0.01f0
        shader = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender = VolumePrerender(data[:transparency], data[:overdraw])
        postrender = () -> glDisable(GL_CULL_FACE)
    end
    return data
end

function _default(main::VolumeTypes{T}, s::Style, data::Dict) where T <: RGBA
    @gen_defaults! data begin
        volumedata = main => Texture
        hull = FRect3D(Vec3f0(0), Vec3f0(1)) => to_plainmesh
        model = Mat4f0(I)
        modelinv = const_lift(inv, model)
        # These don't do anything but are needed for type specification in the frag shader
        color_map = nothing => Texture
        color_norm = nothing
        color = color_map === nothing ? default(RGBA, s) : nothing

        algorithm = AbsorptionRGBA
        shader = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender = VolumePrerender(data[:transparency], data[:overdraw])
        postrender = () -> glDisable(GL_CULL_FACE)
    end
end
