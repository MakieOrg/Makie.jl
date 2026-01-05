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
        px_per_unit = 1.0f0

    end
    if !isnothing(Makie.to_value(intensity))
        data[:intensity] = intensity_convert_tex(screen.glscreen, intensity, position)
    end
    return RenderObject(screen.glscreen, data)
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
        px_per_unit = 1.0f0
        gl_primitive = GL_POINTS
    end
    return RenderObject(screen.glscreen, data)
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
        px_per_unit = 1.0f0
        scale_primitive = true
        gl_primitive = GL_POINTS
    end

    # Exception for intensity, to make it possible to handle intensity with a
    # different length compared to position. Intensities will be interpolated in that case
    data[:intensity] = intensity_convert(screen.glscreen, intensity, position)

    return RenderObject(screen.glscreen, data)
end

@specialize

function default_shader(screen::Screen, @nospecialize(::RenderObject), plot::MeshScatter, view::Dict{String, String})
    shading = Makie.get_shading_mode(plot)
    position = plot.positions_transformed_f32c[]
    view["position_calc"] = position_calc(position, TextureBuffer)
    view["shading"] = light_calc(shading)
    view["MAX_LIGHTS"] = "#define MAX_LIGHTS $(screen.config.max_lights)"
    view["MAX_LIGHT_PARAMETERS"] = "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)"

    shader = GLVisualizeShader(
        screen,
        "util.vert", "particles.vert",
        "fragment_output.frag", "lighting.frag", "mesh.frag",
        view = view
    )
    return shader
end

function get_prerender(plot::Scatter, name::Symbol)
    _prerender = get_default_prerender(plot, name)
    if plot.marker[] isa FastPixel
        prerender = () -> begin
            _prerender()
            glEnable(GL_VERTEX_PROGRAM_POINT_SIZE)
            return
        end
        return prerender
    else
        return _prerender
    end
end

function default_shader(screen::Screen, @nospecialize(::RenderObject), plot::Scatter, view::Dict{String, String})
    if plot.marker[] isa FastPixel
        return GLVisualizeShader(
            screen,
            "fragment_output.frag", "dots.vert", "dots.frag",
            view = view
        )
    else
        position = plot.positions_transformed_f32c[]
        view["position_calc"] = position_calc(position, GLBuffer)::String
        return GLVisualizeShader(
            screen,
            "fragment_output.frag", "util.vert", "sprites.geom",
            "sprites.vert", "distance_shape.frag",
            view = view
        )
    end
end

function default_shader(screen::Screen, @nospecialize(::RenderObject), plot::Text, view::Dict{String, String})
    position = plot.positions_transformed_f32c[]
    view["position_calc"] = position_calc(position, GLBuffer)::String
    shader = GLVisualizeShader(
        screen,
        "fragment_output.frag", "util.vert", "sprites.geom",
        "sprites.vert", "distance_shape.frag",
        view = view
    )
    return shader
end
