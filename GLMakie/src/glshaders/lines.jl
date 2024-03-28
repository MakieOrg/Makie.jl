function sumlengths(points, resolution)
    # normalize w component if availabke
    f(p::VecTypes{4}) = p[Vec(1, 2)] / p[4]
    f(p::VecTypes) = p[Vec(1, 2)]

    invalid(p::VecTypes{4}) = p[4] <= 1e-6
    invalid(p::VecTypes) = false

    T = eltype(eltype(typeof(points)))
    result = zeros(T, length(points))
    for i in eachindex(points)
        i0 = max(i-1, 1)
        p1, p2 = points[i0], points[i]
        if any(map(isnan, p1)) || any(map(isnan, p2)) || invalid(p1) || invalid(p2)
            result[i] = 0f0
        else
            result[i] = result[i0] + 0.5 * norm(resolution .* (f(p1) - f(p2)))
        end
    end
    result
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
function draw_lines(screen, position::Union{VectorTypes{T}, MatTypes{T}}, data::Dict) where T<:Point
    p_vec = if isa(position, GPUArray)
        position
    else
        const_lift(vec, position)
    end

    color_type = gl_color_type_annotation(data[:color])
    resolution = data[:resolution]

    @gen_defaults! data begin
        total_length::Int32 = const_lift(x-> Int32(length(x)), position)
        vertex              = p_vec => GLBuffer
        color               = nothing => GLBuffer
        color_map           = nothing => Texture
        color_norm          = nothing
        thickness           = 2f0 => GLBuffer
        pattern             = nothing
        pattern_sections    = pattern => Texture
        fxaa                = false
        # Duplicate the vertex indices on the ends of the line, as our geometry
        # shader in `layout(lines_adjacency)` mode requires each rendered
        # segment to have neighbouring vertices.
        indices             = const_lift(p_vec) do p
            len0 = length(p) - 1
            return isempty(p) ? Cuint[] : Cuint[0; 0:len0; len0]
        end => to_index_buffer
        transparency = false
        fast         = false
        shader              = GLVisualizeShader(
            screen,
            "fragment_output.frag", "lines.vert", "lines.geom", "lines.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency)),
                "define_fast_path" => to_value(fast) ? "#define FAST_PATH" : "",
                "stripped_color_type" => color_type
            )
        )
        gl_primitive        = GL_LINE_STRIP_ADJACENCY
        valid_vertex        = const_lift(p_vec) do points
            map(p-> Float32(all(isfinite, p)), points)
        end => GLBuffer
        lastlen             = const_lift(sumlengths, p_vec, resolution) => GLBuffer
        pattern_length      = 1f0 # we divide by pattern_length a lot.
        debug               = false
    end
    if to_value(pattern) !== nothing
        if !isa(pattern, Texture)
            if !isa(to_value(pattern), Vector)
                error("Pattern needs to be a Vector of floats. Found: $(typeof(pattern))")
            end
            tex = GLAbstraction.Texture(lift(Makie.linestyle_to_sdf, pattern); x_repeat=:repeat)
            data[:pattern] = tex
        end
        data[:pattern_length] = lift(pt -> Float32(last(pt) - first(pt)), pattern)
    end

    return assemble_shader(data)
end

function draw_linesegments(screen, positions::VectorTypes{T}, data::Dict) where T <: Point
    color_type = gl_color_type_annotation(data[:color])

    @gen_defaults! data begin
        vertex              = positions => GLBuffer
        color               = nothing => GLBuffer
        color_map           = nothing => Texture
        color_norm          = nothing
        thickness           = 2f0 => GLBuffer
        shape               = RECTANGLE
        pattern             = nothing
        fxaa                = false
        fast                = false
        indices             = const_lift(length, positions) => to_index_buffer
        # TODO update boundingbox
        transparency        = false
        shader              = GLVisualizeShader(
            screen,
            "fragment_output.frag", "line_segment.vert", "line_segment.geom",
            "lines.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency)),
                "stripped_color_type" => color_type
            )
        )
        gl_primitive        = GL_LINES
        pattern_length      = 1f0
        debug               = false
    end
    if !isa(pattern, Texture) && to_value(pattern) !== nothing
        if !isa(to_value(pattern), Vector)
            error("Pattern needs to be a Vector of floats. Found: $(typeof(pattern))")
        end
        tex = GLAbstraction.Texture(lift(Makie.linestyle_to_sdf, pattern); x_repeat=:repeat)
        data[:pattern] = tex
        data[:pattern_length] = lift(pt -> Float32(last(pt) - first(pt)), pattern)
    end
    robj = assemble_shader(data)
    return robj
end
@specialize
