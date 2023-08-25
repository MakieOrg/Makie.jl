

function to_image(image::AbstractMatrix{<: AbstractFloat}, colormap::AbstractVector{<: Colorant}, colorrange)
    return interpolated_getindex.((to_value(colormap),), image, (to_value(colorrange),))
end

"""
    resample(A::AbstractVector, len::Integer)
Resample a vector with linear interpolation to have length `len`
"""
function resample(A::AbstractVector, len::Integer)
    length(A) == len && return A
    return interpolated_getindex.((A,), range(0.0, stop=1.0, length=len))
end


"""
    resample_cmap(cmap, ncolors::Integer; alpha=1.0)

* cmap: anything that `to_colormap` accepts
* ncolors: number of desired colors
* alpha: additional alpha applied to each color. Can also be an array, matching `colors`, or a tuple giving a start + stop alpha value.
"""
function resample_cmap(cmap, ncolors::Integer; alpha=1.0)
    cols = to_colormap(cmap)
    r = range(0.0, stop=1.0, length=ncolors)
    if alpha isa Tuple{<:Number, <:Number}
        alphas = LinRange(alpha..., ncolors)
    else
        alphas = alpha
    end
    return broadcast(r, alphas) do i, a
        c = interpolated_getindex(cols, i)
        return RGBAf(Colors.color(c), Colors.alpha(c) *  a)
    end
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
    Vec2f(mini, maxi)
end

function extract_expr(extract_func, dictlike, args)
    if args.head !== :tuple
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
usage @extract scene (a, b, c, d)
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
```julia
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

# a few shortcut functions to make attribute conversion easier
function converted_attribute(dict, key, default=nothing)
    if haskey(dict, key)
        return lift(x-> convert_attribute(x, Key{key}()), dict[key])
    else
        return default
    end
end

macro converted_attribute(dictlike, args)
    return extract_expr(converted_attribute, dictlike, args)
end


@inline getindex_value(x::Union{Dict,Attributes,AbstractPlot}, key::Symbol) = to_value(x[key])
@inline getindex_value(x, key::Symbol) = to_value(getfield(x, key))

"""
usage @extractvalue scene (a, b, c, d)
will become:
```julia
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


attr_broadcast_length(x::NativeFont) = 1
attr_broadcast_length(x::VecTypes) = 1 # these are our rules, and for what we do, Vecs are usually scalars
attr_broadcast_length(x::AbstractArray) = length(x)
attr_broadcast_length(x::AbstractPattern) = 1
attr_broadcast_length(x) = 1
attr_broadcast_length(x::ScalarOrVector) = x.sv isa Vector ? length(x.sv) : 1

attr_broadcast_getindex(x::NativeFont, i) = x
attr_broadcast_getindex(x::VecTypes, i) = x # these are our rules, and for what we do, Vecs are usually scalars
attr_broadcast_getindex(x::AbstractArray, i) = x[i]
attr_broadcast_getindex(x::AbstractPattern, i) = x
attr_broadcast_getindex(x, i) = x
attr_broadcast_getindex(x::Ref, i) = x[] # unwrap Refs just like in normal broadcasting, for protecting iterables
attr_broadcast_getindex(x::ScalarOrVector, i) = x.sv isa Vector ? x.sv[i] : x.sv

is_vector_attribute(x::AbstractArray) = true
is_vector_attribute(x::NativeFont) = false
is_vector_attribute(x::Quaternion) = false
is_vector_attribute(x::VecTypes) = false
is_vector_attribute(x) = false

is_scalar_attribute(x) = !is_vector_attribute(x)

"""
    broadcast_foreach(f, args...)

Like broadcast but for foreach. Doesn't care about shape and treats Tuples && StaticVectors as scalars.
This method is meant for broadcasting across attributes that can either have scalar or vector / array form.
An example would be a collection of scatter markers that have different sizes but a single color.
The length of an attribute is determined with `attr_broadcast_length` and elements are accessed with
`attr_broadcast_getindex`.
"""
@generated function broadcast_foreach(f, args...)
    N = length(args)
    quote
        lengths = Base.Cartesian.@ntuple $N i -> attr_broadcast_length(args[i])
        maxlen = maximum(lengths)
        any_wrong_length = Base.Cartesian.@nany $N i -> lengths[i] ∉ (0, 1, maxlen)
        if any_wrong_length
            error("All non scalars need same length, Found lengths for each argument: $lengths, $(map(typeof, args))")
        end
        # skip if there's a zero length element (like an empty annotations collection, etc)
        # this differs from standard broadcasting logic in which all non-scalar shapes have to match
        0 in lengths && return

        for i in 1:maxlen
            Base.Cartesian.@ncall $N f (j -> attr_broadcast_getindex(args[j], i))
        end

        return
    end
end


"""
    from_dict(::Type{T}, dict)
Creates the type `T` from the fields in dict.
Automatically converts to the correct types.
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

function to_ndim(T::Type{<: VecTypes{N,ET}}, vec::VecTypes{N2}, fillval) where {N,ET,N2}
    T(ntuple(Val(N)) do i
        i > N2 && return ET(fillval)
        @inbounds return vec[i]
    end)
end

lerp(a::T, b::T, val::AbstractFloat) where {T} = (a .+ (val * (b .- a)))

function merged_get!(defaults::Function, key, scene, input::Vector{Any})
    return merged_get!(defaults, key, scene, Attributes(input))
end

function merged_get!(defaults::Function, key, scene::SceneLike, input::Attributes)
    d = defaults()
    if haskey(theme(scene), key)
        # we need to merge theme(scene) with the defaults, because it might be an incomplete theme
        # TODO have a mark that says "theme uncomplete" and only then get the defaults
        d = merge!(to_value(theme(scene, key)), d)
    end
    return merge!(input, d)
end

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

# This function was copied from GR.jl,
# written by Josef Heinen.
"""
    peaks([n=49])

Return a nonlinear function on a grid.  Useful for test cases.
"""
function peaks(n=49)
    x = LinRange(-3, 3, n)
    y = LinRange(-3, 3, n)
    3 * (1 .- x').^2 .* exp.(-(x'.^2) .- (y .+ 1).^2) .- 10 * (x' / 5 .- x'.^3 .- y.^5) .* exp.(-x'.^2 .- y.^2) .- 1 / 3 * exp.(-(x' .+ 1).^2 .- y.^2)
end


function attribute_names(PlotType)
    # TODO, have all plot types store their attribute names
    return keys(default_theme(nothing, PlotType))
end

get_dim(x, ind, dim, size) = get_dim(LinRange(extrema(x)..., size[dim]), ind, dim, size)
get_dim(x::AbstractVector, ind, dim, size) = x[Tuple(ind)[dim]]
get_dim(x::AbstractMatrix, ind, dim, size) = x[ind]

"""
    surface_normals(x, y, z)
Normals for a surface defined on the grid xy
"""
function surface_normals(x, y, z)
    function normal(i)
        i1, imax = CartesianIndex(1, 1), CartesianIndex(size(z))
        ci(x, y) = min(max(i + CartesianIndex(x, y), i1), imax)
        of = (ci(-1, -1), ci(1, -1), ci(-1, 1), ci(1, 1))
        function offsets(off)
            s = size(z)
            return Vec3f(get_dim(x, off, 1, s), get_dim(y, off, 2, s), z[off])
        end
        return normalize(mapreduce(offsets, +, init=Vec3f(0), of))
    end
    return vec(map(normal, CartesianIndices(z)))
end

"""
    matrix_grid(f, x::AbstractArray, y::AbstractArray, z::AbstractMatrix)::Vector{Point3f}

Creates points on the grid spanned by x, y, z.
Allows to supply `f`, which gets applied to every point.
"""
function matrix_grid(f, x::AbstractArray, y::AbstractArray, z::AbstractMatrix)
    g = map(CartesianIndices(z)) do i
        return f(Point3f(get_dim(x, i, 1, size(z)), get_dim(y, i, 2, size(z)), z[i]))
    end
    return vec(g)
end

function matrix_grid(f, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    matrix_grid(f, LinRange(extrema(x)..., size(z, 1)), LinRange(extrema(x)..., size(z, 2)), z)
end

function extract_keys(attributes, keys)
    attr = Attributes()
    for key in keys
        attr[key] = attributes[key]
    end
    return attr
end

# Scalar - Vector getindex
sv_getindex(v::Vector, i::Integer) = v[i]
sv_getindex(x, i::Integer) = x
