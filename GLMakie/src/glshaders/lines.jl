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
    @gen_defaults! data begin
        vertex = Point3f[] => GLBuffer
        color = nothing => GLBuffer
        color_map = nothing => Texture
        color_norm = nothing
        thickness = 2.0f0 => GLBuffer
        pattern = nothing => Texture
        # Duplicate the vertex indices on the ends of the line, as our geometry
        # shader in `layout(lines_adjacency)` mode requires each rendered
        # segment to have neighbouring vertices.
        indices = Cuint[] => to_index_buffer
        fast = false
        gl_primitive = GL_LINE_STRIP_ADJACENCY
        valid_vertex = Float32[] => GLBuffer
        lastlen = Float32[] => GLBuffer
        pattern_length = 1.0f0 # we divide by pattern_length a lot.
        debug = false
        px_per_unit = 1.0f0
    end
    return RenderObject(screen.glscreen, data)
end

function default_shader(screen, robj, plot::Lines, param)
    color_type = gl_color_type_annotation(plot[:scaled_color][])
    shader = GLVisualizeShader(
        screen,
        "fragment_output.frag", "lines.vert", "lines.geom", "lines.frag",
        view = Dict(
            "define_fast_path" => Bool(robj[:fast]) ? "#define FAST_PATH" : "",
            "stripped_color_type" => color_type,
            param...,
        )
    )
    return shader
end

function draw_linesegments(screen, positions::VectorTypes{T}, data::Dict) where {T <: Point}
    @gen_defaults! data begin
        vertex = Point3f[] => GLBuffer
        color = nothing => GLBuffer
        color_map = nothing => Texture
        color_norm = nothing
        thickness = 2.0f0 => GLBuffer
        shape = RECTANGLE
        pattern = nothing => Texture
        indices = 0 => to_index_buffer
        gl_primitive = GL_LINES
        pattern_length = 1.0f0
        debug = false
        px_per_unit = 1.0f0
    end
    robj = RenderObject(screen.glscreen, data)
    return robj
end

function default_shader(screen, robj, plot::LineSegments, param)
    color_type = gl_color_type_annotation(plot[:scaled_color][])
    shader = GLVisualizeShader(
        screen,
        "fragment_output.frag", "line_segment.vert", "line_segment.geom",
        "lines.frag",
        view = Dict(
            "stripped_color_type" => color_type,
            param...
        )
    )
    return shader
end

@specialize
