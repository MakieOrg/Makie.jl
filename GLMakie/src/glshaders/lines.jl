function sumlengths(points)
    T = eltype(points[1])
    result = zeros(T, length(points))
    for i=1:length(points)
        i0 = max(i-1,1)
        p1, p2 = points[i0], points[i]
        if !(any(map(isnan, p1)) || any(map(isnan, p2)))
            result[i] = result[i0] + norm(p1-p2)
        else
            result[i] = result[i0]
        end
    end
    result
end

intensity_convert(intensity, verts) = intensity
function intensity_convert(intensity::VecOrSignal{T}, verts) where T
    if length(to_value(intensity)) == length(to_value(verts))
        GLBuffer(intensity)
    else
        Texture(intensity)
    end
end
function intensity_convert_tex(intensity::VecOrSignal{T}, verts) where T
    if length(to_value(intensity)) == length(to_value(verts))
        TextureBuffer(intensity)
    else
        Texture(intensity)
    end
end
#TODO NaNMath.min/max?
dist(a, b) = abs(a-b)
mindist(x, a, b) = min(dist(a, x), dist(b, x))
function gappy(x, ps)
    n = length(ps)
    x <= first(ps) && return first(ps) - x
    for j=1:(n-1)
        p0 = ps[j]
        p1 = ps[min(j+1, n)]
        if p0 <= x && p1 >= x
            return mindist(x, p0, p1) * (isodd(j) ? 1 : -1)
        end
    end
    return last(ps) - x
end
function ticks(points, resolution)
    Float16[gappy(x, points) for x = range(first(points), stop=last(points), length=resolution)]
end

@nospecialize
function draw_lines(screen, position::Union{VectorTypes{T}, MatTypes{T}}, data::Dict) where T<:Point
    p_vec = if isa(position, GPUArray)
        position
    else
        const_lift(vec, position)
    end

    @gen_defaults! data begin
        total_length::Int32 = const_lift(x-> Int32(length(x)), position)
        vertex              = p_vec => GLBuffer
        intensity           = nothing
        color_map           = nothing => Texture
        color_norm          = nothing
        color               = (color_map == nothing ? default(RGBA, s) : nothing) => GLBuffer
        thickness::Float32  = 2f0
        linecap             = 0
        linecap_length::Float32 = thickness
        pattern             = nothing
        fxaa                = false
        # Duplicate the vertex indices on the ends of the line, as our geometry
        # shader in `layout(lines_adjacency)` mode requires each rendered
        # segment to have neighbouring vertices.
        indices             = const_lift(p_vec) do p
            len0 = length(p) - 1
            return isempty(p) ? Cuint[] : Cuint[0; 0:len0; len0]
        end => to_index_buffer
        transparency = false
        shader              = GLVisualizeShader(
            screen,
            "fragment_output.frag", "util.vert", "lines.vert", "lines.geom", "lines.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        gl_primitive        = GL_LINE_STRIP_ADJACENCY
        valid_vertex        = const_lift(p_vec) do points
            map(p-> Float32(all(isfinite, p)), points)
        end => GLBuffer
    end
    if pattern !== nothing
        if !isa(pattern, Texture)
            if !isa(pattern, Vector)
                error("Pattern needs to be a Vector of floats. Found: $(typeof(pattern))")
            end
            tex = GLAbstraction.Texture(ticks(pattern, 100), x_repeat = :repeat)
            data[:pattern] = tex
        end
        @gen_defaults! data begin
            pattern_length = Float32(last(pattern))
            lastlen   = const_lift(sumlengths, p_vec) => GLBuffer
            maxlength = const_lift(last, lastlen)
        end
    end
    data[:intensity] = intensity_convert(intensity, vertex)
    return assemble_shader(data)
end

function draw_linesegments(screen, positions::VectorTypes{T}, data::Dict) where T <: Point
    @gen_defaults! data begin
        vertex              = positions => GLBuffer
        color               = default(RGBA, s, 1) => GLBuffer
        color_map           = nothing => Texture
        color_norm          = nothing
        thickness           = 2f0 => GLBuffer
        shape               = RECTANGLE
        pattern             = nothing
        fxaa                = false
        indices             = const_lift(length, positions) => to_index_buffer
        # TODO update boundingbox
        transparency = false
        shader              = GLVisualizeShader(
            screen,
            "fragment_output.frag", "util.vert", "line_segment.vert", "line_segment.geom", "lines.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        gl_primitive = GL_LINES
    end
    if !isa(pattern, Texture) && pattern != nothing
        if !isa(pattern, Vector)
            error("Pattern needs to be a Vector of floats")
        end
        tex = GLAbstraction.Texture(ticks(pattern, 100), x_repeat = :repeat)
        data[:pattern] = tex
        data[:pattern_length] = Float32(last(pattern))
    end
    return assemble_shader(data)
end
@specialize
