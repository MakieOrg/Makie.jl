function to_opengl_mesh!(context, result, mesh_obs::TOrSignal{<:GeometryBasics.Mesh})
    m = convert(Observable, mesh_obs)

    result[:faces] = indexbuffer(context, map(faces, m))
    result[:vertices] = GLBuffer(context, map(coordinates, m))

    function to_buffer(name, target)
        return if hasproperty(m[], name)
            val = getproperty(m[], name)
            if mesh_obs isa Observable
                val = map(m -> getproperty(m, name), m)
            end
            if to_value(val) isa AbstractVector
                result[target] = GLBuffer(context, val)
            elseif to_value(val) isa AbstractMatrix
                result[target] = Texture(context, val)
            else
                error("unsupported attribute: $(name)")
            end
        end
    end

    to_buffer(:color, :vertex_color)
    to_buffer(:uv, :texturecoordinates)
    to_buffer(:uvw, :texturecoordinates)

    # Only emit normals, when we shadin'
    shading = get!(result, :shading, NoShading)::Makie.ShadingAlgorithm
    matcap_active = !isnothing(to_value(get(result, :matcap, nothing)))
    if matcap_active || shading != NoShading
        to_buffer(:normal, :normals)
    end
    to_buffer(:attribute_id, :attribute_id)

    return result
end

function draw_mesh(screen, data::Dict)
    @gen_defaults! data begin
        vertices = nothing => GLBuffer
        faces = nothing => indexbuffer
        normals = nothing => GLBuffer
        backlight = 0.0f0
        vertex_color = nothing => GLBuffer
        image = nothing => Texture
        matcap = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        fetch_pixel = false
        texturecoordinates = nothing => GLBuffer
        uv_transform = Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1)
        transparency = false
        px_per_unit = 1.0f0
        interpolate_in_fragment_shader = true
    end

    return RenderObject(screen.glscreen, data)
end

function default_shader(screen, robj, plot::Union{Mesh, Image}, param)
    shading = get!(robj.uniforms, :shading, NoShading)::Makie.ShadingAlgorithm
    shader = GLVisualizeShader(
        screen,
        "util.vert", "mesh.vert",
        "fragment_output.frag", "mesh.frag",
        "lighting.frag",
        view = Dict(
            "shading" => light_calc(shading),
            "picking_mode" => to_value(get(robj.uniforms, :picking_mode, "")),
            "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
            "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
            param...
        )
    )
    return shader
end