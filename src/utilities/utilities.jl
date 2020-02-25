"""
    interpolated_getindex(cmap::AbstractArray, value::AbstractFloat, norm = (0.0, 1.0))

Like getindex, but accepts values between 0..1 and interpolates those to the full range.
You can use `norm`, to change the range of 0..1 to whatever you want.

"""
function interpolated_getindex(cmap::AbstractArray{T}, value::AbstractFloat, norm = (0.0, 1.0)) where T
    cmin, cmax = norm
    i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0)
    i1len = (i01 * (length(cmap) - 1)) + 1
    down = floor(Int, i1len)
    up = ceil(Int, i1len)
    down == up && return cmap[down]
    interp_val = i1len - down
    downc, upc = cmap[down], cmap[up]
    convert(T, (downc * (1.0 - interp_val)) + (upc * interp_val))
end

function to_image(image::AbstractMatrix{<: AbstractFloat}, colormap::AbstractVector{<: Colorant}, colorrange)
    interpolated_getindex.((to_value(colormap),), image, (to_value(colorrange),))
end

"""
    resample(A::AbstractVector, len::Integer)
Resample a vector with linear interpolation to have length `len`
"""
function resample(A::AbstractVector, len::Integer)
    length(A) == len && return A
    interpolated_getindex.((A,), range(0.0, stop=1.0, length=len))
end

"""
    resampled_colors(attributes::Attributes, levels::Integer)

Resample the color attribute from `attributes`. Resamples `:colormap` if present,
or repeats `:color`.
"""
function resampled_colors(attributes, levels::Integer)
    cols = if haskey(attributes, :color)
        c = get_attribute(attributes, :color)
        c isa AbstractVector ? resample(c, levels) : repeated(c, levels)
    else
        c = get_attribute(attributes, :colormap)
        resample(c, levels)
    end
end


"""
Like `get!(f, dict, key)` but also calls `f` and replaces `key` when the corresponding
value is nothing
"""
function replace_automatic!(f, dict, key)
    haskey(dict, key) || return (dict[key] = f())
    val = dict[key]
    to_value(val) == automatic && return (dict[key] = f())
    val
end

is_unitrange(x) = (false, 0:0)
is_unitrange(x::AbstractRange) = (true, x)
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

function extract_expr(extract_func, dictlike, args)
    if args.head != :tuple
        error("Usage: args need to be a tuple. Found: $args")
    end
    expr = Expr(:block)
    for elem in args.args
        push!(expr.args, :($(esc(elem)) = $(extract_func)($(esc(dictlike)), $(QuoteNode(elem)))))
    end
    push!(expr.args, esc(args))
    expr
end

"""
usage @exctract scene (a, b, c, d)
"""
macro extract(scene, args)
    extract_expr(getindex, scene, args)
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
    extract_expr(get_attribute, scene, args)
end

@inline getindex_value(x::Union{Dict, Attributes, AbstractPlot}, key::Symbol) = to_value(x[key])
@inline getindex_value(x, key::Symbol) = to_value(getfield(x, key))

"""
usage @extractvalue scene (a, b, c, d)
will become:
```example
begin
    a = to_value(scene[:a])
    b = to_value(scene[:b])
    c = to_value(scene[:c])
    (a, b, c)
end
```
"""
macro extractvalue(scene, args)
    extract_expr(getindex_value, scene, args)
end

bs_length(x::NativeFont) = 1 # these are our rules, and for what we do, Vecs are usually scalars
bs_length(x::VecTypes) = 1 # these are our rules, and for what we do, Vecs are usually scalars
bs_length(x::AbstractArray) = length(x)
bs_length(x::AbstractString) = length(x)
bs_length(x) = 1

bs_getindex(x::NativeFont, i) = x # these are our rules, and for what we do, Vecs are usually scalars
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
    if any(x-> !(x in (0, 1, maxlen)), lengths)
        error("All non scalars need same length, Found lengths for each argument: $lengths, $(typeof.(args))")
    end
    for i in 1:maxlen
        f(bs_getindex.(args, i)...)
    end
    return
end

"""
    from_dict(::Type{T}, dict)
Creates the type `T` from the fields in dict.
Automatically converts to the correct node types.
"""
function from_dict(::Type{T}, dict) where T
    T(map(fieldnames(T)) do name
        convert(fieldtype(T, name), dict[name])
    end...)
end

same_length_array(array, value::NativeFont) = repeated(value, length(array))
same_length_array(array, value) = repeated(value, length(array))
function same_length_array(arr, value::Vector)
    if length(arr) != length(value)
        error("Array lengths do not match. Found: $(length(arr)) of $(eltype(arr)) but $(length(value)) $(eltype(value))")
    end
    value
end
same_length_array(arr, value, key) = same_length_array(arr, convert_attribute(value, key))

function to_ndim(T::Type{<: VecTypes{N, ET}}, vec::VecTypes{N2}, fillval) where {N, ET, N2}
    T(ntuple(Val(N)) do i
        i > N2 && return ET(fillval)
        @inbounds return vec[i]
    end)
end

dim3(x) = ntuple(i-> x, Val(3))
dim3(x::NTuple{3, Any}) = x

dim2(x) = ntuple(i-> x, Val(2))
dim2(x::NTuple{2, Any}) = x

lerp(a::T, b::T, val::AbstractFloat) where {T} = (a .+ (val * (b .- a)))

function merge_attributes!(input::Attributes, theme::Attributes)
    for (key, value) in theme
        if !haskey(input, key)
            input[key] = copy(value)
        else
            current_value = input[key]
            if value isa Attributes && current_value isa Attributes
                # if nested attribute, we merge recursively
                merge_attributes!(current_value, value)
            elseif value isa Attributes || current_value isa Attributes
                error("""
                Type missmatch while merging plot attributes with theme for key: $(key).
                Found $(value) in theme, while attributes contains: $(current_value)
                """)
            else
                # we're good! input already has a value, can ignore theme
            end
        end
    end
    return input
end

function merged_get!(defaults::Function, key, scene, input::Vector{Any})
    return merged_get!(defaults, key, scene, Attributes(input))
end

function merged_get!(defaults::Function, key, scene::SceneLike, input::Attributes)
    d = defaults()
    if haskey(theme(scene), key)
        # we need to merge theme(scene) with the defaults, because it might be an incomplete theme
        # TODO have a mark that says "theme uncomplete" and only then get the defaults
        merge!(d, to_value(theme(scene, key)))
    end
    return merge!(input, d)
end

struct Key{K} end
macro key_str(arg)
    :(Key{$(QuoteNode(Symbol(arg)))})
end
Base.broadcastable(x::Key) = (x,)

to_vector(x::AbstractVector, len, T) = convert(Vector{T}, x)
function to_vector(x::AbstractArray, len, T)
    if length(x) in size(x) # assert that just one dim != 1
        to_vector(vec(x), len, T)
    else
        error("Can't convert to a Vector. Please supply a range/vector/interval")
    end
end
function to_vector(x::ClosedInterval, len, T)
    a, b = T.(extrema(x))
    range(a, stop=b, length=len)
end




"""
Returns (N1, N2) with `N1 x N2 == n`. N2 might become 1
"""
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

"""
A colorsampler maps numnber values from a certain range to values of a colormap
```
x = ColorSampler(colormap, (0.0, 1.0))
x[0.5] # returns color at half point of colormap
```
"""
struct ColorSampler{Data <: AbstractArray}
    colormap::Data
    color_range::Tuple{Float64, Float64}
end

function Base.getindex(cs::ColorSampler, value::Number)
    return interpolated_getindex(cs.colormap, value, cs.color_range)
end
