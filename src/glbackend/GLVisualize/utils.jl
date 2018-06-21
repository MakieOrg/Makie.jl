"""
Determines if of Image Type
"""
function isa_image(x::Type{T}) where T<:Matrix
    eltype(T) <: Union{Colorant, Colors.Fractional}
end
isa_image(x::Matrix) = isa_image(typeof(x))

isa_image(x) = false

# Splits a dictionary in two dicts, via a condition
function Base.split(condition::Function, associative::Associative)
    A = similar(associative)
    B = similar(associative)
    for (key, value) in associative
        if condition(key, value)
            A[key] = value
        else
            B[key] = value
        end
    end
    A, B
end



function assemble_shader(data)
    default_bb = Signal(centered(AABB))
    bb  = get(data, :boundingbox, default_bb)
    if bb == nothing || isa(bb, Signal{Void})
        bb = default_bb
    end
    robj = RenderObject(data, bb)
    Composition(robj)
end

function y_partition_abs(area, amount)
    a = round(Int, amount)
    p = const_lift(area) do r
        (
            SimpleRectangle{Int}(0, 0, r.w, a),
            SimpleRectangle{Int}(0, a, r.w, r.h - a)
        )
    end
    return map(first, p), map(last, p)
end
function x_partition_abs(area, amount)
    a = round(Int, amount)
    p = const_lift(area) do r
        (
            SimpleRectangle{Int}(0, 0, a, r.h),
            SimpleRectangle{Int}(a, 0, r.w - a, r.h)
        )
    end
    return map(first, p), map(last, p)
end

function y_partition(area, percent)
    amount = percent / 100.0
    p = const_lift(area) do r
        (
            SimpleRectangle{Int}(0, 0, r.w, round(Int, r.h*amount)),
            SimpleRectangle{Int}(0, round(Int, r.h*amount), r.w, round(Int, r.h*(1-amount)))
        )
    end
    return map(first, p), map(last, p)
end
function x_partition(area, percent)
    amount = percent / 100.0
    p = const_lift(area) do r
        (
            SimpleRectangle{Int}(0, 0, round(Int, r.w*amount), r.h ),
            SimpleRectangle{Int}(round(Int, r.w*amount), 0, round(Int, r.w*(1-amount)), r.h)
        )
    end
    return map(first, p), map(last, p)
end


glboundingbox(mini, maxi) = AABB{Float32}(Vec3f0(mini), Vec3f0(maxi)-Vec3f0(mini))
function default_boundingbox(main, model)
    main == nothing && return Signal(AABB{Float32}(Vec3f0(0), Vec3f0(1)))
    const_lift(*, model, AABB{Float32}(main))
end
AABB(a::GPUArray) = AABB{Float32}(gpu_data(a))
AABB{T}(a::GPUArray) where {T} = AABB{T}(gpu_data(a))




points2f0(positions::Vector{T}, range::Range) where {T} = Point2f0[Point2f0(range[i], positions[i]) for i=1:length(range)]

extrema2f0(x::Array{T,N}) where {T<:Intensity,N} = Vec2f0(extrema(reinterpret(Float32,x)))
extrema2f0(x::Array{T,N}) where {T,N} = Vec2f0(extrema(x))
extrema2f0(x::GPUArray) = extrema2f0(gpu_data(x))
function extrema2f0(x::Array{T,N}) where {T<:Vec,N}
    _norm = map(norm, x)
    Vec2f0(minimum(_norm), maximum(_norm))
end

function mix_linearly(a::C, b::C, s) where C<:Colorant
    RGBA{Float32}((1-s)*comp1(a)+s*comp1(b), (1-s)*comp2(a)+s*comp2(b), (1-s)*comp3(a)+s*comp3(b), (1-s)*alpha(a)+s*alpha(b))
end

color_lookup(cmap, value, mi, ma) = color_lookup(cmap, value, (mi, ma))
function color_lookup(cmap, value, color_norm)
    mi,ma = color_norm
    scaled = clamp((value-mi)/(ma-mi), 0, 1)
    index = scaled * (length(cmap)-1)
    i_a, i_b = floor(Int, index)+1, ceil(Int, index)+1
    mix_linearly(cmap[i_a], cmap[i_b], scaled)
end


"""
Converts index arrays to the OpenGL equivalent.
"""
to_index_buffer(x::Buffer) = x
to_index_buffer(x::TOrSignal{Int}) = x
to_index_buffer(x::VecOrSignal{UnitRange{Int}}) = x
to_index_buffer(x::TOrSignal{UnitRange{Int}}) = x
"""
For integers, we transform it to 0 based indices
"""
to_index_buffer(x::Vector{I}) where {I<:Integer} = indexbuffer(map(i-> Cuint(i-1), x))
function to_index_buffer(x::Signal{Vector{I}}) where I<:Integer
    x = map(x-> Cuint[i-1 for i=x], x)
    gpu_mem = Buffer(value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    preserve(const_lift(update!, gpu_mem, x))
    gpu_mem
end
"""
If already GLuint, we assume its 0 based (bad heuristic, should better be solved with some Index type)
"""
to_index_buffer(x::Vector{I}) where {I<:GLuint} = indexbuffer(x)
function to_index_buffer(x::Signal{Vector{I}}) where I<:GLuint
    gpu_mem = Buffer(value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    preserve(const_lift(update!, gpu_mem, x))
    gpu_mem
end
function to_index_buffer(x::Signal{Vector{I}}) where I <: Face{2, GLIndex}
    gpu_mem = Buffer(value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    preserve(const_lift(update!, gpu_mem, x))
    gpu_mem
end
to_index_buffer(x) = error(
    "Not a valid index type: $(typeof(x)).
    Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them"
)

"""
Creates a moving average and discards values to close together.
If discarded return (false, p), if smoothed, (true, smoothed_p).
"""
function moving_average(p, cutoff,  history, n = 5)
    if length(history) > 0
        if norm(p - history[end]) < cutoff
            return false, p # don't keep point
        end
    end
    if length(history) == 5
        # maybe better to just keep a current index
        history[1:5] = circshift(view(history, 1:5), -1)
        history[end] = p
    else
        push!(history, p)
    end
    true, sum(history) ./ length(history)# smooth
end

function layoutlinspace(n::Integer)
    if n == 1
        1:1
    else
        linspace(1/n, 1, n)
    end
end
xlayout(x::Int) = zip(layoutlinspace(x), Iterators.repeated(""))
function xlayout(x::AbstractVector{T}) where T <: AbstractFloat
    zip(x, Iterators.repeated(""))
end

function xlayout(x::AbstractVector)
    zip(layoutlinspace(length(x)), x)
end
function ylayout(x::AbstractVector)
    zip(layoutlinspace(length(x)), x)
end
function ylayout(x::AbstractVector{T}) where T <: Tuple
    sizes = map(first, x)
    values = map(last, x)
    zip(sizes, values)
end
function IRect(x, y , w, h)
    SimpleRectangle(
        round(Int, x),
        round(Int, y),
        round(Int, w),
        round(Int, h),
    )
end

function layout_rect(area, lastw, lasth, w, h)
    wp = widths(area)
    xmin = wp[1] * lastw
    ymin = wp[2] * lasth
    xmax = wp[1] * w
    ymax = wp[2] * h
    xmax = max(xmin, xmax)
    xmin = min(xmin, xmax)
    ymax = max(ymin, ymax)
    ymin = min(ymin, ymax)
    IRect(xmin, ymin, xmax - xmin, ymax - ymin)
end
