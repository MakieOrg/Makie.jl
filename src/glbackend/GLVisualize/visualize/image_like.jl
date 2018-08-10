"""
A matrix of colors is interpreted as an image
"""
_default(::Signal{Array{RGBA{N0f8}, 2}}, ::Style{:default}, ::Dict{Symbol,Any})


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
            SimpleRectangle{Float32}(x, y, xmax - x, ymax - y)
        end
        preferred_camera      = :orthographic_pixel
        fxaa                  = false
        shader                = GLVisualizeShader(
            "fragment_output.frag", "uv_vert.vert", "texture.frag",
            view = Dict("uv_swizzle" => "o_uv.$(spatialorder)")
        )
    end
end
function _default(main::VecTypes{T}, ::Style, data::Dict) where T <: Colorant
    @gen_defaults! data begin
        image                 = main => (Texture, "image, can be a Texture or Array of colors")
        primitive::GLUVMesh2D = SimpleRectangle{Float32}(0f0, 0f0, length(value(main)), 50f0) => "the 2D mesh the image is mapped to. Can be a 2D Geometry or mesh"
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
function _default(main::MatTypes{T}, s::Style, data::Dict) where T <: Intensity
    main_v = value(main)
    @gen_defaults! data begin
        ranges = (0:size(main_v, 1), 0:size(main_v, 2))
    end
    x, y, xw, yh = minimum(ranges[1]), minimum(ranges[2]), maximum(ranges[1]), maximum(ranges[2])
    @gen_defaults! data begin
        intensity             = main => Texture
        color_map             = default(Vector{RGBA{N0f8}},s) => Texture
        primitive::GLUVMesh2D = SimpleRectangle{Float32}(x, y, xw-x, yh-y)
        color_norm            = const_lift(extrema2f0, main)
        stroke_width::Float32 = 0.05f0
        levels::Float32       = 5f0
        stroke_color          = RGBA{Float32}(1,1,1,1)
        shader                = GLVisualizeShader("fragment_output.frag", "uv_vert.vert", "intensity.frag")
        preferred_camera      = :orthographic_pixel
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
    rect = SimpleRectangle{Float32}(0f0,0f0, size(value(main))...)
    _default((rect, Point2f0[0]), s, data)
end


export play
"""
    play(img, timedim, t)

Slice a 3D array along axis `timedim` at time `t`.
This can be used to treat a 3D array like a video and create an image stream from it.
"""
function play(array::Array{T, 3}, timedim::Integer, t::Integer) where T
    index = ntuple(dim-> dim == timedim ? t : Colon(), Val{3})
    array[index...]
end

"""
    play(buffer, video_stream, t)

Plays a video stream from VideoIO.jl. You need to supply the image `buffer`,
which will be reused for better performance.
"""
function play(buffer::Array{T, 2}, video_stream, t) where T
    eof(video_stream) && seekstart(video_stream)
    w, h = size(buffer)
    buffer = reinterpret(UInt8, buffer, (3, w,h))
    read!(video_stream, buffer) # looses type and shape
    return reinterpret(T, buffer, (w,h))
end


unwrap(img::AxisArrays.AxisArray) = unwrap(img.data)
unwrap(img::AbstractArray) = img

GLAbstraction.gl_convert(::Type{T}, img::AbstractArray) where {T} = _gl_convert(T, unwrap(img))
_gl_convert(::Type{T}, img::Array) where {T} = gl_convert(T, img)

"""
    play(img)

Turns an Image into a video stream
"""
function play(img::HasAxesArray{T, 3}) where T
    ax = ImageAxes.timeaxis(img)
    if ImageAxes.timeaxis(img) != nothing
        return const_lift(play, unwrap(img), ImageAxes.timedim(img), loop(1:length(ax)))
    end
    error("Image has no time axis: axes(img) = $(axes(img))")
end

"""
Takes a 3D image and decides if it is a volume or an animated Image.
"""
function _default(img::HasAxesArray{T, 3}, s::Style, data::Dict) where T
    # We could do this as a @traitfn, except that those don't
    # currently mix well with non-trait specialization.
    if ImageAxes.timeaxis(img) != nothing
        data[:spatialorder] = "yx"
        td = ImageAxes.timedim(img)
        video_signal = const_lift(play, unwrap(img), td, loop(1:size(img, timedim)))
        return _default(video_signal, s, data)
    else
        ps = ImageAxes.pixelspacing(img)
        spacing = Vec3f0(map(x-> x / maximum(ps), ps))
        pdims   = Vec3f0(map(length, indices(img)))
        dims    = pdims .* spacing
        dims    = dims/maximum(dims)
        data[:dimensions] = dims
        _default(unwrap(img), s, data)
    end
end
function _default(img::TOrSignal{T}, s::Style, data::Dict) where T <: AxisMatrix
    @gen_defaults! data begin
        ranges = const_lift(img) do img
            ps = ImageAxes.pixelspacing(img)
            spacing = Vec2f0(map(x-> x / maximum(ps), ps))
            pdims   = Vec2f0(map(length, indices(img)))
            dims    = pdims .* spacing
            dims    = dims / maximum(dims)
            (0:dims[1], 0:dims[2])
        end
    end
    _default(const_lift(unwrap, img), s, data)
end

"""
Displays 3D array as movie with 3rd dimension as time dimension
"""
function _default(img::AbstractArray{T, 3}, s::Style, data::Dict) where T
    video_signal = const_lift(play, unwrap(img), 3, loop(1:size(img, 3)))
    return _default(video_signal, s, data)
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
    primitive::GLUVMesh2D = SimpleRectangle{Float32}(0f0,0f0, dimensions...)
    preferred_camera      = :orthographic_pixel
    fxaa                  = false
    shader                = GLVisualizeShader(
        "fragment_output.frag", "parametric.vert", "parametric.frag",
        view = Dict("function" => func)
    )
end


#Volumes
const VolumeElTypes = Union{Gray, AbstractFloat, Intensity}

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

modeldefault(dimensions) = SMatrix{4,4,Float32}([eye(3,3) -dimensions/2; zeros(1,3) 1])

struct VolumePrerender
end
function (::VolumePrerender)()
    GLAbstraction.StandardPrerender()()
    glEnable(GL_CULL_FACE)
    glCullFace(GL_FRONT)
end

function _default(main::VolumeTypes{T}, s::Style, data::Dict) where T <: VolumeElTypes
    @gen_defaults! data begin
        dimensions = Vec3f0(1)
    end
    modeldflt = modeldefault(data[:dimensions])
    modelinv = const_lift(inv, get(data, :model, modeldflt))
    @gen_defaults! data begin
        volumedata       = main => Texture
        hull::GLUVWMesh  = AABB{Float32}(Vec3f0(0), dimensions)
        light_position   = Vec3f0(0.25, 1.0, 3.0)
        light_intensity  = Vec3f0(15.0)
        modelinv         = modelinv

        color_map        = default(Vector{RGBA}, s) => Texture
        color_norm       = color_map == nothing ? nothing : const_lift(extrema2f0, main)
        color            = color_map == nothing ? default(RGBA, s) : nothing

        algorithm        = MaximumIntensityProjection
        absorption       = 1f0
        isovalue         = 0.5f0
        isorange         = 0.01f0
        shader           = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender        = VolumePrerender()
        postrender       = () -> begin
            glDisable(GL_CULL_FACE)
        end
    end
end

function _default(main::VolumeTypes{T}, s::Style, data::Dict) where T <: RGBA
    @gen_defaults! data begin
        dimensions = Vec3f0(1)
    end
    modeldflt = modeldefault(data[:dimensions])
    model = const_lift(identity, get(data, :model, modeldflt))
    modelinv = const_lift(inv, get(data, :model, modeldflt))
    @gen_defaults! data begin
        volumedata       = main => Texture
        hull::GLUVWMesh  = AABB{Float32}(Vec3f0(0), dimensions)
        model            = model
        modelinv         = modelinv

        # These don't do anything but are needed for type specification in the frag shader
        color_map        = nothing
        color_norm       = nothing
        color            = color_map == nothing ? default(RGBA, s) : nothing

        algorithm        = AbsorptionRGBA
        shader           = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender        = VolumePrerender()
        postrender       = () -> begin
            glDisable(GL_CULL_FACE)
        end
    end
end

function _default(main::IndirectArray{T}, s::Style, data::Dict) where T <: RGBA
    @gen_defaults! data begin
        dimensions       = Vec3f0(1)
    end
    modeldflt = modeldefault(data[:dimensions])
    model = const_lift(identity, get(data, :model, modeldflt))
    modelinv = const_lift(inv, get(data, :model, modeldflt))
    @gen_defaults! data begin
        volumedata       = main.index => Texture
        hull::GLUVWMesh  = AABB{Float32}(Vec3f0(0), dimensions)
        model            = model
        modelinv         = modelinv

        color_map        = main.values => TextureBuffer
        color_norm       = nothing
        color            = nothing

        algorithm        = IndexedAbsorptionRGBA
        shader           = GLVisualizeShader("fragment_output.frag", "util.vert", "volume.vert", "volume.frag")
        prerender        = VolumePrerender()
        postrender       = () -> begin
            glDisable(GL_CULL_FACE)
        end
    end
end
