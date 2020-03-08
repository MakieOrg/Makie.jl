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
        primitive::GLUVMesh2D = const_lift(ranges) do r
            x, y = minimum(r[1]), minimum(r[2])
            xmax, ymax = maximum(r[1]), maximum(r[2])
            return FRect2D(x, y, xmax - x, ymax - y)
        end
        preferred_camera      = :orthographic_pixel
        fxaa                  = false
        shader                = GLVisualizeShader(
            "fragment_output.frag", "uv_vert.vert", "texture.frag",
            view = Dict("uv_swizzle" => "o_uv.$(spatialorder)")
        )
    end
end

function _default(main::VectorTypes{T}, ::Style, data::Dict) where T <: Colorant
    @gen_defaults! data begin
        image                 = main => (Texture, "image, can be a Texture or Array of colors")
        primitive::GLUVMesh2D = FRect2D(0f0, 0f0, length(to_value(main)), 50f0) => "the 2D mesh the image is mapped to. Can be a 2D Geometry or mesh"
        preferred_camera      = :orthographic_pixel
        fxaa                  = false
        shader                = GLVisualizeShader(
            "fragment_output.frag", "uv_vert.vert", "texture.frag",
            view = Dict("uv_swizzle" => "o_uv.xy")
        )
    end
end

"""
A matrix of Intensities will result in a contourf kind of plot
"""
function gl_heatmap(main::MatTypes{T}, data::Dict) where T <: AbstractFloat
    main_v = to_value(main)
    @gen_defaults! data begin
        ranges = (0:size(main_v, 1), 0:size(main_v, 2))
    end
    prim = const_lift(data[:ranges]) do ranges
        x, y, xw, yh = minimum(ranges[1]), minimum(ranges[2]), maximum(ranges[1]), maximum(ranges[2])
        return FRect2D(x, y, xw-x, yh-y)
    end
    delete!(data, :ranges)
    @gen_defaults! data begin
        intensity             = main => Texture
        color_map             = default(Vector{RGBA{N0f8}},s) => Texture
        primitive::GLUVMesh2D = prim
        nan_color             = RGBAf0(1, 0, 0, 1)
        color_norm            = const_lift(extrema2f0, main)
        stroke_width::Float32 = 0.05f0
        levels::Float32       = 5f0
        stroke_color          = RGBA{Float32}(1,1,1,1)
        shader                = GLVisualizeShader("fragment_output.frag", "uv_vert.vert", "intensity.frag")
        fxaa                  = false
    end
end

"""
Float matrix with the style distancefield will be interpreted as a distancefield.
A distancefield is describing a shape, with positive values denoting the inside
of the shape, negative values the outside and 0 the border
"""
function _default(main::MatTypes{T}, s::style"distancefield", data::Dict) where T <: AbstractFloat
    @gen_defaults! data begin
        distancefield = main => Texture
        shape         = DISTANCEFIELD
        fxaa          = false
    end
    rect = FRect2D(0f0,0f0, size(to_value(main))...)
    _default((rect, Point2f0[0]), s, data)
end

"""
Takes a shader as a parametric function. The shader should contain a function stubb
like this:
```GLSL
uniform float arg1; // you can add arbitrary uniforms and supply them via the keyword args
float function(float x) {
 return arg1*sin(1/tan(x));
}
```
"""
_default(func::String, s::Style{:shader}, data::Dict) = @gen_defaults! data begin
    color                 = default(RGBA, s) => Texture
    dimensions            = (120f0, 120f0)
    primitive::GLUVMesh2D = FRect2D(0f0,0f0, dimensions...)
    preferred_camera      = :orthographic_pixel
    fxaa                  = false
    shader                = GLVisualizeShader(
        "fragment_output.frag", "parametric.vert", "parametric.frag",
        view = Dict("function" => func)
    )
end

#Volumes
const VolumeElTypes = Union{Gray, AbstractFloat}

const default_style = Style{:default}()

function _default(a::VolumeTypes{T}, s::Style{:iso}, data::Dict) where T <: VolumeElTypes
    data = @gen_defaults! data begin
        isovalue  = 0.5f0
        algorithm = IsoValue
    end
     _default(a, default_style, data)
end

function _default(a::VolumeTypes{T}, s::Style{:absorption}, data::Dict) where T<:VolumeElTypes
    data = @gen_defaults! data begin
        absorption = 1f0
        algorithm  = Absorption
    end
    _default(a, default_style, data)
end

function _default(a::VolumeTypes{T}, s::Style{:absorption}, data::Dict) where T<:RGBA
    data = @gen_defaults! data begin
        algorithm  = AbsorptionRGBA
    end
    _default(a, default_style, data)
end

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
        volumedata       = main => Texture
        hull::GLUVWMesh  = FRect3D(Vec3f0(0), Vec3f0(1))
        light_position   = Vec3f0(0.25, 1.0, 3.0)
        light_intensity  = Vec3f0(15.0)
        model            = Mat4f0(I)
        modelinv         = const_lift(inv, model)

        color_map        = default(Vector{RGBA}, s) => Texture
        color_norm       = color_map == nothing ? nothing : const_lift(extrema2f0, main)
        color            = color_map == nothing ? default(RGBA, s) : nothing

        algorithm        = MaximumIntensityProjection
        absorption       = 1f0
        isovalue         = 0.5f0
        isorange         = 0.01f0
        shader           = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender        = VolumePrerender(data[:transparency], data[:overdraw])
        postrender       = () -> begin
            glDisable(GL_CULL_FACE)
        end
    end
end

function _default(main::VolumeTypes{T}, s::Style, data::Dict) where T <: RGBA
    @gen_defaults! data begin
        volumedata       = main => Texture
        hull::GLUVWMesh  = FRect3D(Vec3f0(0), Vec3f0(1))
        model            = Mat4f0(I)
        modelinv         = const_lift(inv, model)

        # These don't do anything but are needed for type specification in the frag shader
        color_map        = nothing => Texture
        color_norm       = nothing
        color            = color_map == nothing ? default(RGBA, s) : nothing

        algorithm        = AbsorptionRGBA
        shader           = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender        = VolumePrerender(data[:transparency], data[:overdraw])
        postrender       = () -> begin
            glDisable(GL_CULL_FACE)
        end
    end
end
