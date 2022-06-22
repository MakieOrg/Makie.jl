function to_opengl_mesh!(result, mesh_obs::TOrSignal{<: GeometryBasics.AbstractMesh})
    m_attr = map(convert(Observable, mesh_obs)) do m
        return (m, GeometryBasics.meta(m))
    end

    result[:faces] = indexbuffer(map(((m,_),)-> faces(m), m_attr))
    result[:vertices] = GLBuffer(map(((m,_),)-> decompose(Point, m), m_attr))

    attribs = m_attr[][2]

    function to_buffer(name, target)
        if haskey(attribs, name)
            val = attribs[name]
            if mesh_obs isa Observable
                val = map(((m, a),)-> a[name], m_attr)
            end
            if val[] isa AbstractVector
                result[target] = GLBuffer(val)
            elseif val[] isa AbstractMatrix
                result[target] = Texture(val)
            else
                error("unsupported attribute: $(name)")
            end
        end
    end
    to_buffer(:color, :vertex_color)
    to_buffer(:uv, :texturecoordinates)
    to_buffer(:uvw, :texturecoordinates)
    to_buffer(:normals, :normals)
    to_buffer(:attribute_id, :attribute_id)

    return result
end

function draw_mesh(shader_cache, data::Dict)
    @gen_defaults! data begin
        shading = true
    end
    @gen_defaults! data begin
        faces = nothing => indexbuffer
        vertices = nothing => GLBuffer
        normals = nothing => GLBuffer
        backlight = 0f0
        vertex_color = Vec4f(0) => GLBuffer
        texturecoordinates = Vec2f(0) => GLBuffer
        image = nothing => Texture
        matcap = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        fetch_pixel = false
        uv_scale = Vec2f(1)
        transparency = false
        shader = GLVisualizeShader(
            shader_cache,
            "util.vert", "mesh.vert", "mesh.frag", "fragment_output.frag",
            view = Dict(
                "light_calc" => light_calc(shading),
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
    end
    return assemble_shader(data)
end
