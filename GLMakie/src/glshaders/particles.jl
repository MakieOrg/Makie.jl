using Makie: RectanglePacker

function to_meshcolor(color::TOrSignal{Vector{T}}) where T <: Colorant
    TextureBuffer(color)
end

function to_meshcolor(color::TOrSignal{Matrix{T}}) where T <: Colorant
    Texture(color)
end
function to_meshcolor(color)
    color
end

using Makie: get_texture_atlas

vec2quaternion(rotation::StaticVector{4}) = rotation

function vec2quaternion(r::StaticVector{2})
    vec2quaternion(Vec3f(r[1], r[2], 0))
end
function vec2quaternion(rotation::StaticVector{3})
    Makie.rotation_between(Vec3f(0, 0, 1), Vec3f(rotation))
end

vec2quaternion(rotation::Vec4f) = rotation
vec2quaternion(rotation::VectorTypes) = const_lift(x-> vec2quaternion.(x), rotation)
vec2quaternion(rotation::Observable) = lift(vec2quaternion, rotation)
vec2quaternion(rotation::Makie.Quaternion)= Vec4f(rotation.data)
vec2quaternion(rotation)= vec2quaternion(to_rotation(rotation))
GLAbstraction.gl_convert(rotation::Makie.Quaternion)= Vec4f(rotation.data)
to_pointsize(x::Number) = Float32(x)
to_pointsize(x) = Float32(x[1])
struct PointSizeRender
    size::Observable
end
(x::PointSizeRender)() = glPointSize(to_pointsize(x.size[]))



@nospecialize
"""
This is the main function to assemble particles with a GLNormalMesh as a primitive
"""
function draw_mesh_particle(screen, p, data)
    rot = get!(data, :rotation, Vec4f(0, 0, 0, 1))
    rot = vec2quaternion(rot)
    delete!(data, :rotation)
    to_opengl_mesh!(data, p[1])
    @gen_defaults! data begin
        position = p[2] => TextureBuffer
        scale = Vec3f(1) => TextureBuffer
        rotation = rot => TextureBuffer
        texturecoordinates = nothing
        shading = true
    end

    @gen_defaults! data begin
        color_map = nothing => Texture
        color_norm = nothing
        intensity = nothing
        image = nothing
        color = nothing => to_meshcolor
        vertex_color = Vec4f(1)
        matcap = nothing => Texture
        fetch_pixel = false
        interpolate_in_fragment_shader = false
        uv_scale = Vec2f(1)

        instances = const_lift(length, position)
        shading = true
        transparency = false
        shader = GLVisualizeShader(
            screen,
            "util.vert", "particles.vert", "mesh.frag", "fragment_output.frag",
            view = Dict(
                "position_calc" => position_calc(position, nothing, nothing, nothing, TextureBuffer),
                "light_calc" => light_calc(shading),
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
    end
    if !isnothing(Makie.to_value(intensity))
        data[:intensity] = intensity_convert_tex(intensity, position)
        data[:len] = const_lift(length, position)
    end
    return assemble_shader(data)
end


"""
This is the most primitive particle system, which uses simple points as primitives.
This is supposed to be the fastest way of displaying particles!
"""
function draw_pixel_scatter(screen, position::VectorTypes, data::Dict)
    @gen_defaults! data begin
        vertex       = position => GLBuffer
        color_map    = nothing  => Texture
        color        = (color_map === nothing ? default(RGBA{Float32}, s) : nothing) => GLBuffer
        color_norm   = nothing
        scale        = 2f0
        transparency = false
        shader       = GLVisualizeShader(
            screen,
            "fragment_output.frag", "dots.vert", "dots.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        gl_primitive = GL_POINTS
    end
    data[:prerender] = PointSizeRender(data[:scale])
    return assemble_shader(data)
end

function draw_scatter(
    screen, p::Tuple{TOrSignal{Matrix{C}}, VectorTypes{P}}, data::Dict
    ) where {C <: Colorant, P <: Point}
    data[:image] = p[1] # we don't want this to be overwritten by user
    @gen_defaults! data begin
        scale = lift(x-> Vec2f(size(x)), p[1])
        offset = Vec2f(0)
    end
    draw_scatter(screen, (RECTANGLE, p[2]), data)
end

function draw_scatter(
        screen, p::Tuple{VectorTypes{Matrix{C}}, VectorTypes{P}}, data::Dict
    ) where {C <: Colorant, P <: Point}
    images = map(el32convert, to_value(p[1]))
    isempty(images) && error("Can not display empty vector of images as primitive")
    sizes = map(size, images)
    if !all(x-> x == sizes[1], sizes) # if differently sized
        # create texture atlas
        maxdims = sum(map(Vec{2, Int}, sizes))
        rectangles = map(x->Rect2(0, 0, x...), sizes)
        rpack = RectanglePacker(Rect2(0, 0, maxdims...))
        uv_coordinates = [push!(rpack, rect).area for rect in rectangles]
        max_xy = mapreduce(maximum, (a,b)-> max.(a, b), uv_coordinates)
        texture_atlas = Texture(eltype(images[1]), (max_xy...,))
        for (area, img) in zip(uv_coordinates, images)
            texture_atlas[area] = img #transfer to texture atlas
        end
        data[:uv_offset_width] = map(uv_coordinates) do uv
            m = max_xy .- 1
            mini = reverse((minimum(uv)) ./ m)
            maxi = reverse((maximum(uv) .- 1) ./ m)
            return Vec4f(mini..., maxi...)
        end
        images = texture_atlas
    end
    data[:image] = images # we don't want this to be overwritten by user
    @gen_defaults! data begin
        shape = RECTANGLE
        quad_offset = Vec2f(0)
    end
    return draw_scatter(screen, (RECTANGLE, p[2]), data)
end

function texture_distancefield(shape)
    df = Makie.primitive_distancefield(to_value(shape))
    isnothing(df) && return nothing
    return get_texture!(df)
end

"""
Main assemble functions for scatter particles.
Sprites are anything like distance fields, images and simple geometries
"""
function draw_scatter(screen, (marker, position), data)
    rot = get!(data, :rotation, Vec4f(0, 0, 0, 1))
    rot = vec2quaternion(rot)
    delete!(data, :rotation)

    @gen_defaults! data begin
        shape       = Makie.marker_to_sdf_shape(marker)
        position    = position => GLBuffer
        marker_offset = Vec3f(0) => GLBuffer;
        scale       = Vec2f(0) => GLBuffer
        rotation    = rot => GLBuffer
        image       = nothing => Texture
    end

    @gen_defaults! data begin
        quad_offset     = Vec2f(0) => GLBuffer
        intensity       = nothing => GLBuffer
        color_map       = nothing => Texture
        color_norm      = nothing
        color           = nothing => GLBuffer

        glow_color      = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_color    = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_width    = 0f0
        glow_width      = 0f0
        uv_offset_width = Makie.primitive_uv_offset_width(marker) => GLBuffer

        distancefield   = texture_distancefield(shape) => Texture
        indices         = const_lift(length, position) => to_index_buffer
        # rotation and billboard don't go along
        billboard        = rotation == Vec4f(0,0,0,1) => "if `billboard` == true, particles will always face camera"
        fxaa             = false
        transparency     = false
        shader           = GLVisualizeShader(
            screen,
            "fragment_output.frag", "util.vert", "sprites.geom",
            "sprites.vert", "distance_shape.frag",
            view = Dict(
                "position_calc" => position_calc(position, nothing, nothing, nothing, GLBuffer),
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        scale_primitive = true
        gl_primitive = GL_POINTS
    end
    # Exception for intensity, to make it possible to handle intensity with a
    # different length compared to position. Intensities will be interpolated in that case
    data[:intensity] = intensity_convert(intensity, position)
    data[:len] = const_lift(length, position)
    return assemble_shader(data)
end

@specialize
