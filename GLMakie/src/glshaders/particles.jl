using Makie: RectanglePacker

function to_meshcolor(context, color::TOrSignal{Vector{T}}) where {T <: Colorant}
    return TextureBuffer(context, color)
end

function to_meshcolor(context, color::TOrSignal{Matrix{T}}) where {T <: Colorant}
    return Texture(context, color)
end
function to_meshcolor(context, color)
    return color
end

GLAbstraction.gl_convert(::GLAbstraction.GLContext, rotation::Makie.Quaternion) = Vec4f(rotation.data)


intensity_convert(cotnext, intensity, verts) = intensity
function intensity_convert(context, intensity::VecOrSignal{T}, verts) where {T}
    return if length(to_value(intensity)) == length(to_value(verts))
        GLBuffer(context, intensity)
    else
        Texture(context, intensity)
    end
end
function intensity_convert_tex(context, intensity::VecOrSignal{T}, verts) where {T}
    return if length(to_value(intensity)) == length(to_value(verts))
        TextureBuffer(context, intensity)
    else
        Texture(context, intensity)
    end
end

function position_calc(
        position_xyz::VectorTypes{T}, target::Type{TextureBuffer}
    ) where {T <: StaticVector}
    return "pos = texelFetch(position, index).xyz;"
end

function position_calc(
        position_xyz::VectorTypes{T}, target::Type{GLBuffer}
    ) where {T <: StaticVector}
    len = length(T)
    filler = join(ntuple(x -> 0, 3 - len), ", ")
    needs_comma = len != 3 ? ", " : ""
    return "pos = vec3(position $needs_comma $filler);"
end


@nospecialize
"""
This is the main function to assemble particles with a GLNormalMesh as a primitive
"""
function draw_mesh_particle(screen, data)
    @gen_defaults! data begin
        vertices = nothing => GLBuffer
        faces = nothing => indexbuffer
        normals = nothing => GLBuffer
        texturecoordinates = nothing => GLBuffer

        position = Point3f[] => TextureBuffer
        scale = Vec3f(1) => TextureBuffer
        rotation = Quaternionf(0, 0, 0, 1) => TextureBuffer
        f32c_scale = Vec3f(1) # drawing_primitives.jl
    end

    shading = pop!(data, :shading)::Makie.ShadingAlgorithm
    data[:color] = to_meshcolor(screen.glscreen, get!(data, :color, nothing))
    @gen_defaults! data begin
        color_map = nothing => Texture
        color_norm = nothing
        intensity = nothing
        image = nothing => Texture
        vertex_color = Vec4f(1)
        matcap = nothing => Texture
        fetch_pixel = false
        scale_primitive = false
        interpolate_in_fragment_shader = false
        backlight = 0.0f0

        instances = const_lift(length, position)
        transparency = false
        px_per_unit = 1.0f0
        shader = GLVisualizeShader(
            screen,
            "util.vert", "particles.vert",
            "fragment_output.frag", "lighting.frag", "mesh.frag",
            view = Dict(
                "position_calc" => position_calc(position, TextureBuffer),
                "shading" => light_calc(shading),
                "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
                "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
    end
    if !isnothing(Makie.to_value(intensity))
        data[:intensity] = intensity_convert_tex(screen.glscreen, intensity, position)
    end
    return assemble_shader(data)
end


"""
This is the most primitive particle system, which uses simple points as primitives.
This is supposed to be the fastest way of displaying particles!
"""
function draw_pixel_scatter(screen, position::VectorTypes, data::Dict)
    @gen_defaults! data begin
        vertex = position => GLBuffer
        color_map = nothing => Texture
        color = nothing => GLBuffer
        marker_offset = Vec3f(0) => GLBuffer
        color_norm = nothing
        scale = 2.0f0
        f32c_scale = Vec3f(1)
        transparency = false
        px_per_unit = 1.0f0
        shader = GLVisualizeShader(
            screen,
            "fragment_output.frag", "dots.vert", "dots.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        gl_primitive = GL_POINTS
    end
    data[:prerender] = () -> glEnable(GL_VERTEX_PROGRAM_POINT_SIZE)
    return assemble_shader(data)
end

"""
Main assemble functions for scatter particles.
Sprites are anything like distance fields, images and simple geometries
"""
function draw_scatter(screen, position, data)
    @gen_defaults! data begin
        shape = Cint(0)
        position = position => GLBuffer
        marker_offset = Vec3f(0) => GLBuffer
        scale = Vec2f(0) => GLBuffer
        rotation = Quaternionf(0, 0, 0, 1) => GLBuffer
        image = nothing => Texture
    end

    @gen_defaults! data begin
        quad_offset = Vec2f(0) => GLBuffer
        intensity = nothing => GLBuffer
        color_map = nothing => Texture
        color_norm = nothing
        color = nothing => GLBuffer

        glow_color = RGBA{Float32}(0, 0, 0, 0) => GLBuffer
        stroke_color = RGBA{Float32}(0, 0, 0, 0) => GLBuffer
        stroke_width = 0.0f0
        glow_width = 0.0f0
        uv_offset_width = Vec4f(0) => GLBuffer
        f32c_scale = Vec3f(1)

        distancefield = nothing => Texture
        indices = const_lift(length, position) => to_index_buffer
        # rotation and billboard don't go along
        billboard = rotation == Vec4f(0, 0, 0, 1) => "if `billboard` == true, particles will always face camera"
        fxaa = false
        transparency = false
        px_per_unit = 1.0f0
        shader = GLVisualizeShader(
            screen,
            "fragment_output.frag", "util.vert", "sprites.geom",
            "sprites.vert", "distance_shape.frag",
            view = Dict(
                "position_calc" => position_calc(position, GLBuffer),
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        scale_primitive = true
        gl_primitive = GL_POINTS
    end

    # Exception for intensity, to make it possible to handle intensity with a
    # different length compared to position. Intensities will be interpolated in that case
    data[:intensity] = intensity_convert(screen.glscreen, intensity, position)

    return assemble_shader(data)
end

@specialize
