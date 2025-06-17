function sumlengths(points, resolution)
    # normalize w component if available
    f(p::VecTypes{4}) = p[Vec(1, 2)] / p[4]
    f(p::VecTypes) = p[Vec(1, 2)]

    invalid(p::VecTypes{4}) = p[4] <= 1.0e-6
    invalid(p::VecTypes) = false

    T = eltype(eltype(typeof(points)))
    result = zeros(T, length(points))
    for (i, idx) in enumerate(eachindex(points))
        idx0 = max(idx - 1, 1)
        p1, p2 = points[idx0], points[idx]
        if any(map(isnan, p1)) || any(map(isnan, p2)) || invalid(p1) || invalid(p2)
            result[i] = 0.0f0
        else
            result[i] = result[max(i - 1, 1)] + 0.5 * norm(resolution .* (f(p1) - f(p2)))
        end
    end
    return result
end

# because the "color_type" generated in GLAbstraction also include "uniform"
gl_color_type_annotation(x::Observable) = gl_color_type_annotation(x.val)
gl_color_type_annotation(::Vector{<:Real}) = "float"
gl_color_type_annotation(::Vector{<:Makie.RGB}) = "vec3"
gl_color_type_annotation(::Vector{<:Makie.RGBA}) = "vec4"
gl_color_type_annotation(::Real) = "float"
gl_color_type_annotation(::Makie.RGB) = "vec3"
gl_color_type_annotation(::Makie.RGBA) = "vec4"

@nospecialize
function draw_lines(screen, position::Union{VectorTypes{T}, MatTypes{T}}, data::Dict) where {T <: Point}
    color_type = gl_color_type_annotation(data[:color])

    @gen_defaults! data begin
        vertex = Point3f[] => GLBuffer
        color = nothing => GLBuffer
        color_map = nothing => Texture
        color_norm = nothing
        thickness = 2.0f0 => GLBuffer
        pattern = nothing => Texture
        fxaa = false
        # Duplicate the vertex indices on the ends of the line, as our geometry
        # shader in `layout(lines_adjacency)` mode requires each rendered
        # segment to have neighbouring vertices.
        indices = Cuint[] => to_index_buffer
        transparency = false
        fast = false
        shader = GLVisualizeShader(
            screen,
            "fragment_output.frag", "lines.vert", "lines.geom", "lines.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency)),
                "define_fast_path" => to_value(fast) ? "#define FAST_PATH" : "",
                "stripped_color_type" => color_type
            )
        )
        gl_primitive = GL_LINE_STRIP_ADJACENCY
        valid_vertex = Float32[] => GLBuffer
        lastlen = Float32[] => GLBuffer
        pattern_length = 1.0f0 # we divide by pattern_length a lot.
        debug = false
        px_per_unit = 1.0f0
    end
    return assemble_shader(data)
end

function draw_linesegments(screen, positions::VectorTypes{T}, data::Dict) where {T <: Point}
    color_type = gl_color_type_annotation(data[:color])

    @gen_defaults! data begin
        vertex = Point3f[] => GLBuffer
        color = nothing => GLBuffer
        color_map = nothing => Texture
        color_norm = nothing
        thickness = 2.0f0 => GLBuffer
        shape = RECTANGLE
        pattern = nothing => Texture
        fxaa = false
        indices = 0 => to_index_buffer
        transparency = false
        shader = GLVisualizeShader(
            screen,
            "fragment_output.frag", "line_segment.vert", "line_segment.geom",
            "lines.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency)),
                "stripped_color_type" => color_type
            )
        )
        gl_primitive = GL_LINES
        pattern_length = 1.0f0
        debug = false
        px_per_unit = 1.0f0
    end
    robj = assemble_shader(data)
    return robj
end
@specialize
