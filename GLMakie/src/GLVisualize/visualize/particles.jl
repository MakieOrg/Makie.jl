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

function to_mesh(mesh::TOrSignal{<: GeometryPrimitive})
    return NativeMesh(const_lift(GeometryBasics.normal_mesh, mesh))
end

function to_mesh(mesh::TOrSignal{<: GeometryBasics.Mesh})
    return NativeMesh(mesh)
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

"""
returns the Shape for the distancefield algorithm
"""
primitive_shape(::Union{AbstractString, Char}) = DISTANCEFIELD
primitive_shape(x::X) where {X} = primitive_shape(X)
primitive_shape(::Type{T}) where {T <: Circle} = CIRCLE
primitive_shape(::Type{T}) where {T <: Rect2} = RECTANGLE
primitive_shape(x::Shape) = x

"""
Extracts the scale from a primitive.
"""
primitive_scale(prim::GeometryPrimitive) = Vec2f(widths(prim))
primitive_scale(::Union{Shape, Char}) = Vec2f(40)
primitive_scale(c) = Vec2f(0.1)

"""
Extracts the offset from a primitive.
"""
primitive_offset(x, scale::Nothing) = Vec2f(0) # default offset
primitive_offset(x, scale) = const_lift(/, scale, -2f0)  # default offset


"""
Extracts the uv offset and width from a primitive.
"""
primitive_uv_offset_width(c::Char) = glyph_uv_width!(c)
primitive_uv_offset_width(str::AbstractString) = map(glyph_uv_width!, collect(str))
primitive_uv_offset_width(x) = Vec4f(0,0,1,1)

"""
Gets the texture atlas if primitive is a char.
"""
primitive_distancefield(x) = nothing
primitive_distancefield(::Union{AbstractString, Char}) = get_texture!(get_texture_atlas())
primitive_distancefield(x::Observable) = primitive_distancefield(x[])

function char_scale_factor(char, font)
    # uv * size(ta.data) / Makie.PIXELSIZE_IN_ATLAS[] is the padded glyph size
    # normalized to the size the glyph was generated as.
    ta = Makie.get_texture_atlas()
    lbrt = glyph_uv_width!(ta, char, font)
    width = Vec(lbrt[3] - lbrt[1], lbrt[4] - lbrt[2])
    width * Vec2f(size(ta.data)) / Makie.PIXELSIZE_IN_ATLAS[]
end

# This works the same for x being widths and offsets
rescale_glyph(char::Char, font, x) = x * char_scale_factor(char, font)
function rescale_glyph(char::Char, font, xs::Vector)
    f = char_scale_factor(char, font)
    map(x -> f * x, xs)
end
function rescale_glyph(str::String, font, x)
    [x * char_scale_factor(char, font) for char in collect(str)]
end
function rescale_glyph(str::String, font, xs::Vector)
    map((char, x) -> x * char_scale_factor(char, font), collect(str), xs)
end

@nospecialize
"""
This is the main function to assemble particles with a GLNormalMesh as a primitive
"""
function draw_mesh_particle(p, data)
    rot = get!(data, :rotation, Vec4f(0, 0, 0, 1))
    rot = vec2quaternion(rot)
    delete!(data, :rotation)
    @gen_defaults! data begin
        primitive = p[1] => to_mesh
        position = p[2] => TextureBuffer
        position_x = nothing => TextureBuffer
        position_y = nothing => TextureBuffer
        position_z = nothing => TextureBuffer

        scale = Vec3f(1) => TextureBuffer
        scale_x = nothing => TextureBuffer
        scale_y = nothing => TextureBuffer
        scale_z = nothing => TextureBuffer

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
        uv_scale = Vec2f(1)

        instances = const_lift(length, position)
        shading = true
        transparency = false
        shader = GLVisualizeShader(
            "util.vert", "particles.vert", "standard.frag", "fragment_output.frag",
            view = Dict(
                "position_calc" => position_calc(position, nothing, nothing, nothing, TextureBuffer),
                "light_calc" => light_calc(shading),
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
    end
    if Makie.to_value(intensity) != nothing
        if Makie.to_value(position) != nothing
            data[:intensity] = intensity_convert_tex(intensity, position)
            data[:len] = const_lift(length, position)
        else
            data[:intensity] = intensity_convert_tex(intensity, position_x)
            data[:len] = const_lift(length, position_x)
        end
    end
    return assemble_shader(data)
end


"""
This is the most primitive particle system, which uses simple points as primitives.
This is supposed to be the fastest way of displaying particles!
"""
function draw_pixel_scatter(position::VectorTypes, data::Dict)
    @gen_defaults! data begin
        vertex       = position => GLBuffer
        color_map    = nothing  => Texture
        color        = (color_map === nothing ? default(RGBA{Float32}, s) : nothing) => GLBuffer
        color_norm   = nothing
        scale        = 2f0
        transparency = false
        shader       = GLVisualizeShader(
            "fragment_output.frag", "dots.vert", "dots.frag",
            view = Dict(
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
        gl_primitive = GL_POINTS
    end
    data[:prerender] = PointSizeRender(data[:scale])
    return assemble_shader(data)
end

function draw_scatter(
        p::Tuple{TOrSignal{Matrix{C}}, VectorTypes{P}}, data::Dict
    ) where {C <: Colorant, P <: Point}
    data[:image] = p[1] # we don't want this to be overwritten by user
    @gen_defaults! data begin
        scale = lift(x-> Vec2f(size(x)), p[1])
        offset = Vec2f(0)
    end
    draw_scatter((RECTANGLE, p[2]), data)
end

function draw_scatter(
        p::Tuple{VectorTypes{Matrix{C}}, VectorTypes{P}}, data::Dict
    ) where {C <: Colorant, P <: Point}
    images = to_value(p[1])
    isempty(images) && error("Can not display empty vector of images as primitive")
    sizes = map(size, images)
    if !all(x-> x == sizes[1], sizes) # if differently sized
        # create texture atlas
        maxdims = sum(map(Vec{2, Int}, sizes))
        rectangles = map(x->Rect2(0, 0, x...), sizes)
        rpack = RectanglePacker(Rect2(0, 0, maxdims...))
        uv_coordinates = [push!(rpack, rect).area for rect in rectangles]
        max_xy = maximum(maximum.(uv_coordinates))
        texture_atlas = Texture(C, (max_xy...,))
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
        offset = Vec2f(0)
    end
    return draw_scatter(p, data)
end

"""
Main assemble functions for scatter particles.
Sprites are anything like distance fields, images and simple geometries
"""
function draw_scatter((marker, position), data)
    rot = get!(data, :rotation, Vec4f(0, 0, 0, 1))
    rot = vec2quaternion(rot)
    delete!(data, :rotation)
    # Rescale to include glyph padding and shape
    if isa(to_value(marker), Union{AbstractString, Char})
        scale = data[:scale]
        font = get(data, :font, Observable(Makie.defaultfont()))
        offset = get(data, :offset, Observable(Vec2f(0)))

        # The same scaling that needs to be applied to scale also needs to apply
        # to offset.
        data[:offset] = map(rescale_glyph, marker, font, offset)
        data[:scale] = map(rescale_glyph, marker, font, scale)
    end

    @gen_defaults! data begin
        shape       = const_lift(x-> Int32(primitive_shape(x)), marker)
        position    = position => GLBuffer
        scale       = const_lift(primitive_scale, marker) => GLBuffer
        rotation    = rot => GLBuffer
        image       = nothing => Texture
    end

    @gen_defaults! data begin
        offset          = primitive_offset(marker, scale) => GLBuffer
        intensity       = nothing => GLBuffer
        color_map       = nothing => Texture
        color_norm      = nothing
        color           = nothing => GLBuffer

        glow_color      = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_color    = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_width    = 0f0
        glow_width      = 0f0
        uv_offset_width = const_lift(primitive_uv_offset_width, marker) => GLBuffer

        distancefield   = primitive_distancefield(marker) => Texture
        indices         = const_lift(length, position) => to_index_buffer
        # rotation and billboard don't go along
        billboard        = rotation == Vec4f(0,0,0,1) => "if `billboard` == true, particles will always face camera"
        fxaa             = false
        transparency     = false
        shader           = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "sprites.geom",
            "sprites.vert", "distance_shape.frag",
            view = Dict(
                "position_calc" => position_calc(position, nothing, nothing, nothing, GLBuffer),
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
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
