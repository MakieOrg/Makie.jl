
function draw_mesh(screen, plot::GLPlot, data::Dict)
    shading = pop!(data, :shading, NoShading)::Makie.MakieCore.ShadingAlgorithm

    # Vertex Attributes
    for (i, arg) in enumerate(plot.converted)
        data[Symbol("arg", i)] = GLBuffer(arg)
    end

    # uniforms
    for (key, val) in data
        if to_value(val) isa Array
            data[key] = Texture(key)
        end
    end

    # shaders
    sources = String[]
    if data[:vertex_shader][] isa String
        code = to_value(pop!(data, :vertex_shader))
        tempfile = joinpath(tempdir(), "vertex_shader.vert")
        open(file -> print(file, code), tempfile, 'w')
        push!(sources, tempfile)
    elseif data[:vertex_shader][] isa Union{Tuple, Vector}
        append!(sources, to_value(pop!(data, :vertex_shader)))
    else
        error("Failed to handle vertex shader - should be a String or Collection of paths, but is $(typeof(data[:vertex_shader][])).")
    end

    if data[:fragment_shader][] isa String
        code = to_value(pop!(data, :fragment_shader))
        tempfile = joinpath(tempdir(), "fragment_shader.vert")
        open(file -> print(file, code), tempfile, 'w')
        push!(sources, tempfile)
    elseif data[:fragment_shader][] isa Union{Tuple, Vector}
        append!(sources, to_value(pop!(data, :fragment_shader)))
    else
        error("Failed to handle fragment shader - should be a String or Collection of paths, but is $(typeof(data[:fragment_shader][])).")
    end

    if data[:geometry_shader][] isa String
        if !isempty(data[:geometry_shader][])
            code = to_value(pop!(data, :geometry_shader))
            tempfile = joinpath(tempdir(), "geometry_shader.vert")
            open(file -> print(file, code), tempfile, 'w')
            push!(sources, tempfile)
        end
    elseif data[:geometry_shader][] isa Union{Tuple, Vector}
        append!(sources, to_value(pop!(data, :geometry_shader)))
    else
        error("Failed to handle geometry shader - should be a String or Collection of paths, but is $(typeof(data[:geometry_shader][])).")
    end

    push!(sources, "util.vert", "lighting.frag", "fragment_output.frag")

    shader_injections = pop!(data, :shader_injections)
    get!(shader_injections, "shading", light_calc(shading))
    get!(shader_injections, "MAX_LIGHTS", "#define MAX_LIGHTS $(screen.config.max_lights)")
    get!(shader_injections, "MAX_LIGHT_PARAMETERS", "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)")
    get!(shader_injections, "buffers", output_buffers(screen, to_value(transparency)))
    get!(shader_injections, "buffer_writes", output_buffer_writes(screen, to_value(transparency)))

    @gen_defaults! data begin
        shader = GLVisualizeShader(screen, sources..., view = shader_injections)
    end

    return assemble_shader(data)
end
