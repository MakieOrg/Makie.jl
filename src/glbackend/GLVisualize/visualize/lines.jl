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
    if length(value(intensity)) == length(value(verts))
        GLBuffer(intensity)
    else
        Texture(intensity)
    end
end
function intensity_convert_tex(intensity::VecOrSignal{T}, verts) where T
    if length(value(intensity)) == length(value(verts))
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


# ambigious signature
function _default(position::VecTypes{<: Point}, s::style"lines", data::Dict)
    line_visualization(position, data)
end
function _default(position::MatTypes{<:Point}, s::style"lines", data::Dict)
    line_visualization(position, data)
end
function line_visualization(position::Union{VecTypes{T}, MatTypes{T}}, data::Dict) where T<:Point
    pv = value(position)
    p_vec = if isa(position, GPUArray)
        position
    else
        const_lift(position) do p
            pvv = vec(p)
            if length(pvv) < 4 # geometryshader doesn't work with less then 4
                return [pvv..., fill(T(NaN), 4-length(pvv))...]
            else
                return pvv
            end
        end
    end

    @gen_defaults! data begin
        dims::Vec{2, Int32} = const_lift(position) do p
            sz = ndims(p) == 1 ? (length(p), 1) : size(p)
            Vec{2, Int32}(sz)
        end
        vertex              = p_vec => GLBuffer
        intensity           = nothing
        color_map           = nothing => Texture
        color_norm          = nothing
        color               = (color_map == nothing ? default(RGBA, s) : nothing) => GLBuffer
        thickness::Float32  = 2f0
        pattern             = nothing
        fxaa                = false
        preferred_camera    = :orthographic_pixel
        indices             = const_lift(length, p_vec) => to_index_buffer
        shader              = GLVisualizeShader("fragment_output.frag", "util.vert", "lines.vert", "lines.geom", "lines.frag")
        gl_primitive        = GL_LINE_STRIP_ADJACENCY
        startend            = const_lift(p_vec) do vec
            l = length(vec)
            map(1:l) do i
                (i == 1 || isnan(vec[max(i-1, 1)])) && return Float32(0) # start
                (i == l || isnan(vec[min(i+1, l)])) && return Float32(1) # end
                Float32(2) # segment
            end
        end => GLBuffer
    end
    if pattern != nothing
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
    data
end

to_points(x::Vector{LineSegment{T}}) where {T} = reinterpret(T, x, (length(x)*2,))

_default(positions::VecTypes{LineSegment{T}}, s::Style, data::Dict) where {T <: Point} =
    _default(const_lift(to_points, positions), style"linesegment"(), data)

function _default(positions::VecTypes{T}, s::style"linesegment", data::Dict) where T <: Point
    @gen_defaults! data begin
        vertex              = positions           => GLBuffer
        color               = default(RGBA, s, 1) => GLBuffer
        thickness           = 2f0                 => GLBuffer
        shape               = RECTANGLE
        pattern             = nothing
        fxaa                = false
        indices             = const_lift(length, positions) => to_index_buffer
        # TODO update boundingbox
        shader              = GLVisualizeShader("fragment_output.frag", "util.vert", "line_segment.vert", "line_segment.geom", "lines.frag")
        gl_primitive        = GL_LINES
    end
    if !isa(pattern, Texture) && pattern != nothing
        if !isa(pattern, Vector)
            error("Pattern needs to be a Vector of floats")
        end
        tex = GLAbstraction.Texture(ticks(pattern, 100), x_repeat = :repeat)
        data[:pattern] = tex
        data[:pattern_length] = Float32(last(pattern))
    end
    data
end

function _default(positions::Vector{T}, range::AbstractRange, s::style"lines", data::Dict) where T <: AbstractFloat
    length(positions) != length(range) && throw(
        DimensionMismatsch("length of $(typeof(positions)) $(length(positions)) and $(typeof(range)) $(length(range)) must match")
    )
    _default(points2f0(positions, range), s, data)
end

function line_indices(array)
    len = length(array)
    result = Array(GLuint, len*2)
    idx = 1
    for i=0:(len-3), j=0:1
        result[idx] = i+j
        idx += 1
    end
    result
    #GLuint[i+j for i=0:(len-3) for j=0:1] # on 0.5
end
"""
Fast, non anti aliased lines
"""
function _default(position::VecTypes{T}, s::style"speedlines", data::Dict) where T <: Point
    @gen_defaults! data begin
        vertex       = position => GLBuffer
        color_map    = nothing  => Vec2f0
        indices      = const_lift(line_indices, position) => to_index_buffer
        color        = (color_map == nothing ? default(RGBA{Float32}, s) : nothing) => GLBuffer
        color_norm   = nothing  => Vec2f0
        intensity    = nothing  => GLBuffer
        shader       = GLVisualizeShader("fragment_output.frag", "dots.vert", "dots.frag")
        gl_primitive = GL_LINES
    end
end
