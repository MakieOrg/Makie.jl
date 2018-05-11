
const Vecf0{N} = Vec{N, Float32}
const Pointf0{N} = Point{N, Float32}
export Vecf0, Pointf0

gpuvec(x) = GPUVector(GLBuffer(x))


function to_world(point::T, cam) where T <: StaticVector
    x = to_world(
        point,
         inv(Reactive.value(cam.view)) * inv(Reactive.value(cam.projection)),
        T(widths(Reactive.value(cam.window_size)))
    )
    Point2f0(x[1], x[2])
end
function to_world(
        p::StaticVector{N, T},
        prj_view_inv::Mat4,
        cam_res::StaticVector
    ) where {N, T}
    VT = typeof(p)
    clip_space = ((VT(p) ./ VT(cam_res)) .* T(2)) .- T(1)
    pix_space = Vec{4, T}(
        clip_space[1],
        clip_space[2],
        T(0), GLAbstraction.w_component(p)
    )
    ws = prj_view_inv * pix_space
    ws ./ ws[4]
end

function qrotation(axis::StaticVector{N, T}, theta) where {N, T <: Real}
    if length(axis) != 3
        error("Must be a 3-vector")
    end
    u = normalize(axis)
    thetaT = convert(eltype(u), theta)
    s = sin(thetaT / T(2))
    x = Vec4f0(s * u[1], s * u[2], s * u[3], cos(thetaT / T(2)))
    # qnormalize(x)
end

qabs(q) = sqrt(dot(q, q))

function qnormalize(q)
    q ./ qabs(q)
end

function qmul(quat::StaticVector{4}, vec::StaticVector{2})
    x3 = qmul(quat, Vec(vec[1], vec[2], 0))
    StaticArrays.similar_type(vec, StaticArrays.Size(2,))(x3[1], x3[2])
end

function qmul(quat::StaticVector{4}, vec::StaticVector{3})
    num = quat[1] * 2f0;
    num2 = quat[2] * 2f0;
    num3 = quat[3] * 2f0;
    num4 = quat[1] * num;
    num5 = quat[2] * num2;
    num6 = quat[3] * num3;
    num7 = quat[1] * num2;
    num8 = quat[1] * num3;
    num9 = quat[2] * num3;
    num10 = quat[4] * num;
    num11 = quat[4] * num2;
    num12 = quat[4] * num3;
    return Point3f0(
        (1f0 - (num5 + num6)) * vec[1] + (num7 - num12) * vec[2] + (num8 + num11) * vec[3],
        (num7 + num12) * vec[1] + (1f0 - (num4 + num6)) * vec[2] + (num9 - num10) * vec[3],
        (num8 - num11) * vec[1] + (num9 + num10) * vec[2] + (1f0 - (num4 + num5)) * vec[3]
    )
end
qconj(q) = Vec4f0(-q[1], -q[2], -q[3], q[4])

function qmul(q::StaticVector{4}, w::StaticVector{4})
    Vec4f0(
        q[4] * w[1] + q[1] * w[4] + q[2] * w[3] - q[3] * w[2],
        q[4] * w[2] - q[1] * w[3] + q[2] * w[4] + q[3] * w[1],
        q[4] * w[3] + q[1] * w[2] - q[2] * w[1] + q[3] * w[4],
        q[4] * w[4] - q[1] * w[1] - q[2] * w[2] - q[3] * w[3],
    )
end


is_unitrange(x) = (false, 0:0)
is_unitrange(x::Range) = (true, x)
function is_unitrange(x::AbstractVector)
    length(x) < 2 && return false, 0:0
    diff = x[2] - x[1]
    length(x) < 3 && return true, x[1]:x[2]
    last = x[3]
    for elem in drop(x, 3)
        diff2 = elem - last
        diff2 != diff && return false, 0:0
    end
    return true, range(first(x), diff, length(x))
end

function ngrid(x::AbstractVector, y::AbstractVector)
    xgrid = [Float32(x[i]) for i = 1:length(x), j = 1:length(y)]
    ygrid = [Float32(y[j]) for i = 1:length(x), j = 1:length(y)]
    xgrid, ygrid
end

function nan_extrema(array)
    mini, maxi = (Inf, -Inf)
    for elem in array
        isnan(elem) && continue
        mini = min(mini, elem)
        maxi = max(maxi, elem)
    end
    Vec2f0(mini, maxi)
end


function drawbrush(scene)
    brush = to_node(Point2f0[])
    waspressed_t_lastpos = Ref((false, time(), Point2f0(0)))
    cam = scene[:screen].cameras[:orthographic_pixel]
    Makie.to_world(Point2f0(0,0), cam)
    lift_node(scene, :mouseposition) do mp
        if ispressed(scene, Makie.Mouse.left)
            waspressed, t, lastpos = waspressed_t_lastpos[]
            append!(brush, [Makie.to_world(Point2f0(mp), cam)])
            if !waspressed
                waspressed_t_lastpos[] = (true, time(), mp)
            else
                waspressed_t_lastpos[] = (true, t, mp)
            end
        else
            waspressed_t_lastpos[] = (false, 0, Point2f0(0))
        end
        return
    end
end


"""
usage @exctract scene (a, b, c, d)
"""
macro extract(scene, args)
    if args.head != :tuple
        error("Usage: args need to be a tuple. Found: $args")
    end
    expr = Expr(:block)
    for elem in args.args
        push!(expr.args, :($(esc(elem)) = $(esc(scene))[$(QuoteNode(elem))]))
    end
    push!(expr.args, esc(args))
    expr
end

"""
    @get_attribute scene (a, b, c, d)

This will extract attribute `a`, `b`, `c`, `d` from `scene` and apply the correct attribute
conversions + will extract the value if it's a signal.
It will make those attributes available as variables and return them as a tuple.
So the above is equal to:
will become:
```example
begin
    a = get_attribute(scene, :a)
    b = get_attribute(scene, :b)
    c = get_attribute(scene, :c)
    (a, b, c)
end
```
"""
macro get_attribute(scene, args)
    if args.head != :tuple
        error("Usage: args need to be a tuple. Found: $args")
    end
    expr = Expr(:block)
    for elem in args.args
        push!(expr.args, :($(esc(elem)) = get_attribute($(esc(scene)), $(QuoteNode(elem)))))
    end
    push!(expr.args, esc(args))
    expr
end

"""
usage @extractvals scene (a, b, c, d)
will become:
```example
begin
    a = value(scene[:a])
    b = value(scene[:b])
    c = value(scene[:c])
    (a, b, c)
end
```
"""
macro extractvals(scene, args)
    if args.head != :tuple
        error("Usage: args need to be a tuple. Found: $args")
    end
    expr = Expr(:block)
    for elem in args.args
        push!(expr.args, :($(esc(elem)) = value($(esc(scene))[$(QuoteNode(elem))])))
    end
    push!(expr.args, esc(args)) # return the tuple
    expr
end

"""
usage @extractvals struct (a, b, c)
will become:
```example
    begin
        a = value(type.a)
        b = value(type.b)
        c = value(type.c)
        (a, b, c)
    end
```
"""
macro getfields(val, keys)
    if keys.head != :tuple
        error("Needs to be @getfields typ (field1, field2, ...). Found: @getfields $val $keys")
    end
    valsym = gensym(:tmp)

    result = Expr(:block, :($valsym = $(esc(val))))
    for key in keys.args
        push!(result.args, :($(esc(key)) = value(getfield($valsym, $(QuoteNode(key))))))
    end
    push!(result.args, esc(keys))
    result
end


function Base.in(point::StaticVector{N}, rectangle::HyperRectangle{N}) where N
    mini, maxi = minimum(rectangle), maximum(rectangle)
    for i = 1:N
        point[i] in (mini[i]..maxi[i]) || return false
    end
    return true
end



bs_length(x::VecTypes) = 1 # these are our rules, and for what we do, Vecs are usually scalars
bs_length(x::AbstractArray) = length(x)
bs_length(x::AbstractString) = length(x)
bs_length(x) = 1

bs_getindex(x::VecTypes, i) = x # these are our rules, and for what we do, Vecs are usually scalars
bs_getindex(x::AbstractArray, i) = x[i]
bs_getindex(x::AbstractString, i) = x[i]
bs_getindex(x, i) = x

"""
Like broadcast but for foreach. Doesn't care about shape and treats Tuples && StaticVectors as scalars.
"""
function broadcast_foreach(f, args...)
    lengths = bs_length.(args)
    maxlen = maximum(lengths)
    # all non scalars should have same length
    if any(x-> !(x in (1, maxlen)), lengths)
        error("All non scalars need same length, Found lengths for each argument: $lengths, $(typeof.(args))")
    end
    for i in 1:maxlen
        f(bs_getindex.(args, i)...)
    end
    return
end


function from_dict(::Type{T}, dict) where T
    T(map(fieldnames(T)) do name
        signal_convert(fieldtype(T, name), dict[name])
    end...)
end


function interpolated_getindex(cmap::AbstractArray, value::AbstractFloat, norm = (0.0, 1.0))
    cmin, cmax = norm
    i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0)
    i1len = (i01 * (length(cmap) - 1)) + 1
    down = floor(Int, i1len)
    up = ceil(Int, i1len)
    interp_val = up - i1len
    downc, upc = cmap[down], cmap[up]
    (downc * (1.0 - interp_val)) + (upc * interp_val)
end

function to_image(image::AbstractMatrix{<: AbstractFloat}, colormap::AbstractVector{<: Colorant}, colorrange)
    interpolated_getindex.((value(colormap),), image, (value(colorrange),))
end

same_length_array(array, value) = repeated(value, length(array))
same_length_array(array, value::Font) = repeated(value, length(array))
function same_length_array(arr, value::Vector)
    if length(arr) != length(value)
        error("Array lengths do not match. Found: $(length(arr)) of $(eltype(arr)) but $(length(value)) $(eltype(value))")
    end
    value
end
same_length_array(arr, value, key) = same_length_array(arr, convert_attribute(value, key))



function to_ndim(T::Type{<: VecTypes{N, ET}}, vec::VecTypes{N2}, fillval) where {N, ET, N2}
    T(ntuple(Val{N}) do i
        i > N2 && return ET(fillval)
        @inbounds return vec[i]
    end)
end

dim3(x) = ntuple(i-> x, Val{3})
dim3(x::NTuple{3, Any}) = x

dim2(x) = ntuple(i-> x, Val{2})
dim2(x::NTuple{2, Any}) = x


to_range(x) = linspace(minimum(x), maximum(x), 4)
to_range(x::VecTypes{2}) = optimal_ticks_and_labels((x[1], x[2]))
function to_range(x::AbstractVector)
    if length(x) <= 5
        x
    else
        linspace(minimum(x), maximum(x), 5)
    end
end


function close2square(n::Real)
    # a cannot be greater than the square root of n
    # b cannot be smaller than the square root of n
    # we get the maximum allowed value of a
    amax = floor(Int, sqrt(n));
    if 0 == rem(n, amax)
        # special case where n is a square number
        return (amax, div(n, amax))
    end
    # Get its prime factors of n
    primeFactors  = factor(n);
    # Start with a factor 1 in the list of candidates for a
    candidates = [1]
    for (f, _) in primeFactors
        # Add new candidates which are obtained by multiplying
        # existing candidates with the new prime factor f
        # Set union ensures that duplicate candidates are removed
        candidates = union(candidates, f .* candidates)
        # throw out candidates which are larger than amax
        filter!(x-> x <= amax, candidates)
    end
    # Take the largest factor in the list d
    (candidates[end], div(n, candidates[end]))
end
