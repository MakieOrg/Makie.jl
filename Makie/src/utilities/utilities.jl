function to_image(image::AbstractMatrix{<:AbstractFloat}, colormap::AbstractVector{<:Colorant}, colorrange)
    return interpolated_getindex.((to_value(colormap),), image, (to_value(colorrange),))
end

"""
    resample(A::AbstractVector, len::Integer)
Resample a vector with linear interpolation to have length `len`
"""
function resample(A::AbstractVector, len::Integer)
    length(A) == len && return A
    return interpolated_getindex.((A,), range(0.0, stop = 1.0, length = len))
end


"""
    resample_cmap(cmap, ncolors::Integer; alpha=1.0)

* cmap: anything that `to_colormap` accepts
* ncolors: number of desired colors
* alpha: additional alpha applied to each color. Can also be an array, matching `colors`, or a tuple giving a start + stop alpha value.
"""
function resample_cmap(cmap, ncolors::Integer; alpha = 1.0)
    cols = to_colormap(cmap)
    r = range(0.0, stop = 1.0, length = ncolors)
    if alpha isa Tuple{Number, Number}
        alphas = LinRange(alpha..., ncolors)
    else
        alphas = alpha
    end
    return broadcast(r, alphas) do i, a
        c = interpolated_getindex(cols, i)
        return RGBAf(Colors.color(c), Colors.alpha(c) * a)
    end
end

"""
    default_automatic(a, default)

Returns `default` if `a == automatic` and `a` otherwise.
"""
default_automatic(::Automatic, b) = b
default_automatic(a, b) = a
default_automatic(x, ::Automatic) = throw(MethodError(default_automatic, (x, automatic)))

"""
    default_automatic(default)

Creates a function `x -> default_automatic(x, default)` which returns `x` if it is
not automatic and `default` otherwise.
"""
default_automatic(::Automatic) = throw(MethodError(default_automatic, (automatic)))
default_automatic(default) = x -> default_automatic(x, default)

function replace_automatic!(args...)
    error(
        "`replace_automatic!(f, plot_or_attributes, key)` has been removed. " *
            "Instead of `replace_automatic(() -> default_obs, plot, key)` you can use `map(default_automatic, plot[key], default_obs)` or `map(default_automatic(default_val), plot[key])`. " *
            "Within a compute graph you can use `map!(default_automatic, plot.attributes, [:maybe_automatic, :default], :output)` or `map!(default_automatic(default_val), plot.attributes, :maybe_automatic, :output)`."
    )
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
    xgrid = [Float32(x[i]) for i in 1:length(x), j in 1:length(y)]
    ygrid = [Float32(y[j]) for i in 1:length(x), j in 1:length(y)]
    return xgrid, ygrid
end

function nan_extrema(array)
    mini, maxi = (Inf, -Inf)
    for elem in array
        isnan(elem) && continue
        mini = min(mini, elem)
        maxi = max(maxi, elem)
    end
    return Vec2f(mini, maxi)
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
    return expr
end

"""
    @extract scene (a, b, c, d)

This becomes

```julia
begin
    a = scene[:a]
    b = scene[:b]
    c = scene[:d]
    d = scene[:d]
    (a, b, c, d)
end
```
"""
macro extract(scene, args)
    return extract_expr(getindex, scene, args)
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
    return extract_expr(get_attribute, scene, args)
end

# a few shortcut functions to make attribute conversion easier
function converted_attribute(dict, key, default = nothing)
    if haskey(dict, key)
        return lift(x -> convert_attribute(x, Key{key}()), dict[key])
    else
        return default
    end
end

macro converted_attribute(dictlike, args)
    return extract_expr(converted_attribute, dictlike, args)
end


@inline getindex_value(x::Union{Dict, Attributes, AbstractPlot}, key::Symbol) = to_value(x[key])
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
    return extract_expr(getindex_value, scene, args)
end


attr_broadcast_length(x::NativeFont) = 1
attr_broadcast_length(x::VecTypes) = 1 # these are our rules, and for what we do, Vecs are usually scalars
attr_broadcast_length(x::AbstractVector) = length(x)
attr_broadcast_length(x::AbstractPattern) = 1
attr_broadcast_length(x) = 1
attr_broadcast_length(x::ScalarOrVector) = x.sv isa Vector ? length(x.sv) : 1

attr_broadcast_getindex(x::NativeFont, i) = x
attr_broadcast_getindex(x::VecTypes, i) = x # these are our rules, and for what we do, Vecs are usually scalars
attr_broadcast_getindex(x::AbstractVector, i) = x[i]
attr_broadcast_getindex(x::AbstractArray{T, 0}, i) where {T} = x[1]
attr_broadcast_getindex(x::AbstractPattern, i) = x
attr_broadcast_getindex(x, i) = x
attr_broadcast_getindex(x::Ref, i) = x[] # unwrap Refs just like in normal broadcasting, for protecting iterables
attr_broadcast_getindex(x::ScalarOrVector, i) = x.sv isa Vector ? x.sv[i] : x.sv

is_vector_attribute(x::AbstractVector) = true
is_vector_attribute(x::Base.Generator) = is_vector_attribute(x.iter)
is_vector_attribute(x::NativeFont) = false
is_vector_attribute(x::Quaternion) = false
is_vector_attribute(x::VecTypes) = false
is_vector_attribute(x::ScalarOrVector) = x.sv isa Vector
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
    return quote
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

ref_wrap_scalar_parameter(x) = is_vector_attribute(x) ? x : Ref(x)

"""
    makie_broadcast(f, args...)

Like `broadcast` but treats types that Makie considers scalars as such, e.g.
`VecTypes` (Point, Vec) or Quaternions. `is_vector_attribute` controls how
arguments are considered.
"""
@inline makie_broadcast(f, args...) = broadcast(f, ref_wrap_scalar_parameter.(args)...)


# used for lines in CairoMakie
"""
    broadcast_foreach_index(f, arg, indices, args...)

Like broadcast_foreach but with indexing. The first arg is assumed to already
have indices applied while the remaining ones use the given indices.

Effectively calls:
```
for (raw_idx, idx) in enumerate(indices)
    f(arg[raw_idx], attr_broadcast_getindex(args, idx)...)
end
```
"""
@generated function broadcast_foreach_index(f, indices, args...)
    N = length(args)
    return quote
        lengths = Base.Cartesian.@ntuple $N i -> attr_broadcast_length(args[i])
        maxlen = maximum(lengths)
        any_wrong_length = Base.Cartesian.@nany $N i -> lengths[i] ∉ (0, 1, maxlen)
        if any_wrong_length
            error("All non scalars need same length, Found lengths for each argument: $lengths, $(map(typeof, args))")
        end
        if (maxlen > 1) && (length(last(indices)) > maxlen) # assuming indices sorted
            error("Indices must be in range. Found $(last(indices)) > $maxlen.")
        end
        # skip if there's a zero length element (like an empty annotations collection, etc)
        # this differs from standard broadcasting logic in which all non-scalar shapes have to match
        0 in lengths && return

        for i in indices
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
function from_dict(::Type{T}, dict) where {T}
    return T(
        map(fieldnames(T)) do name
            convert(fieldtype(T, name), dict[name])
        end...
    )
end

same_length_array(array, value::NativeFont) = repeated(value, length(array))
same_length_array(array, value) = repeated(value, length(array))
function same_length_array(arr, value::Vector)
    if length(arr) != length(value)
        error("Array lengths do not match. Found: $(length(arr)) of $(eltype(arr)) but $(length(value)) $(eltype(value))")
    end
    return value
end
same_length_array(arr, value, key) = same_length_array(arr, convert_attribute(value, key))

function to_ndim(T::Type{<:VecTypes{N, ET}}, vec::VecTypes{N2}, fillval) where {N, ET, N2}
    return T(
        ntuple(Val(N)) do i
            i > N2 && return ET(fillval)
            @inbounds return vec[i]
        end
    )
end

lerp(a::T, b::T, val::AbstractFloat) where {T} = (a .+ (val * (b .- a)))

function merged_get!(defaults::Function, key, scene, input::Vector{Any})
    return merged_get!(defaults, key, scene, Attributes(input))
end

function merged_get!(defaults::Function, key, scene::SceneLike, input::Attributes)
    d = defaults()
    if haskey(theme(scene), key)
        # we need to merge theme(scene) with the defaults, because it might be an incomplete theme
        # TODO have a mark that says "theme incomplete" and only then get the defaults
        d = merge!(to_value(theme(scene, key)), d)
    end
    return merge!(input, d)
end

function Base.replace!(target::Attributes, key, scene::SceneLike, overwrite::Attributes)
    if haskey(theme(scene), key)
        _replace!(target, theme(scene, key))
    end
    return _replace!(target, overwrite)
end

function _replace!(target::Attributes, overwrite::Attributes)
    for k in keys(target)
        haskey(overwrite, k) && (target[k] = overwrite[k])
    end
    return
end


to_vector(x::AbstractVector, len, T) = convert(Vector{T}, x)
function to_vector(x::AbstractArray, len, T)
    return if length(x) in size(x) # assert that just one dim != 1
        to_vector(vec(x), len, T)
    else
        error("Can't convert to a Vector. Please supply a range/vector/interval")
    end
end
function to_vector(x::ClosedInterval, len, T)
    a, b = T.(extrema(x))
    return range(a, stop = b, length = len)
end

# This function was copied from GR.jl,
# written by Josef Heinen.
"""
    peaks([n=49])

Return a nonlinear function on a grid.  Useful for test cases.
"""
function peaks(n = 49)
    x = LinRange(-3, 3, n)
    y = LinRange(-3, 3, n)
    return 3 * (1 .- x') .^ 2 .* exp.(-(x' .^ 2) .- (y .+ 1) .^ 2) .- 10 * (x' / 5 .- x' .^ 3 .- y .^ 5) .* exp.(-x' .^ 2 .- y .^ 2) .- 1 / 3 * exp.(-(x' .+ 1) .^ 2 .- y .^ 2)
end


# function attribute_names(PlotType)
#     # TODO, have all plot types store their attribute names
#     return keys(default_theme(nothing, PlotType))
# end

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
        return normalize(mapreduce(offsets, +, init = Vec3f(0), of))
    end
    return vec(map(normal, CartesianIndices(z)))
end


############################################################
#            NaN-aware normal & mesh handling              #
############################################################

"""
    nan_aware_orthogonal_vector(v1, v2, v3) where N

Returns an un-normalized normal vector for the triangle formed by the three input points.
Skips any combination of the inputs for which any point has a NaN component.
"""
function nan_aware_orthogonal_vector(v1, v2, v3)
    (isnan(v1) || isnan(v2) || isnan(v3)) && return zero(v1)
    return Vec3(cross(v2 - v1, v3 - v1))
end

"""
    nan_aware_normals(vertices::AbstractVector{<: Union{Point, PointMeta}}, faces::AbstractVector{F})

Computes the normals of a mesh defined by `vertices` and `faces` (a vector of `GeometryBasics.NgonFace`)
which ignores all contributions from points with `NaN` components.

Equivalent in application to `GeometryBasics.normals`.
"""
function nan_aware_normals(vertices::AbstractVector{<:Point{3, T}}, faces::AbstractVector{F}) where {T, F <: NgonFace}
    normals_result = zeros(Vec3{T}, length(vertices))

    for face in faces
        v1, v2, v3 = vertices[face]
        # we can get away with two edges since faces are planar.
        n = nan_aware_orthogonal_vector(v1, v2, v3)

        for fi in face
            normals_result[fi] = normals_result[fi] + n
        end
    end
    normals_result .= normalize.(normals_result)
    return convert(Vector{Vec3f}, normals_result)
end

function nan_aware_normals(vertices::AbstractVector{<:Point{2, T}}, faces::AbstractVector{F}) where {T, F <: NgonFace}
    return Vec2f.(nan_aware_normals(map(v -> Point3{T}(v..., 0), vertices), faces))
end

function surface2mesh(xs, ys, zs::AbstractMatrix, transform_func = identity)
    # create a `Matrix{Point3}`
    # ps = matrix_grid(identity, xs, ys, zs)
    ps = matrix_grid(p -> apply_transform(transform_func, p), xs, ys, zs)
    # create valid tessellations (triangulations) for the mesh
    # knowing that it is a regular grid makes this simple
    rect = Tessellation(Rect2f(0, 0, 1, 1), size(zs))
    # we use quad faces so that nan handling is consistent
    faces = decompose(QuadFace{Int}, rect)
    # and remove quads that contain a NaN coordinate to avoid drawing triangles
    faces = filter(f -> !any(i -> isnan(ps[i]), f), faces)
    # create the uv (texture) vectors
    # uv = map(x-> Vec2f(1f0 - x[2], 1f0 - x[1]), decompose_uv(rect))
    uv = decompose_uv(rect)
    # return a mesh with known uvs and normals.
    return GeometryBasics.Mesh(ps, faces, uv = uv, normal = nan_aware_normals(ps, faces))
end


############################################################
#         Matrix grid method for surface handling          #
############################################################

"""
    matrix_grid(f, x::AbstractArray, y::AbstractArray, z::AbstractMatrix)::Vector{Point3f}

Creates points on the grid spanned by x, y, z.
Allows to supply `f`, which gets applied to every point.
"""
function matrix_grid(f, x::AbstractArray, y::AbstractArray, z::AbstractMatrix)
    return f(matrix_grid(x, y, z))
end

function matrix_grid(f, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    return matrix_grid(f, LinRange(extrema(x)..., size(z, 1)), LinRange(extrema(y)..., size(z, 2)), z)
end

function matrix_grid(x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    return matrix_grid(LinRange(extrema(x)..., size(z, 1)), LinRange(extrema(y)..., size(z, 2)), z)
end

function matrix_grid(x::AbstractArray, y::AbstractArray, z::AbstractMatrix)
    if size(z) == (2, 2) # untesselated Rect2 is defined in counter-clockwise fashion
        ps = Point3.(x[[1, 2, 2, 1]], y[[1, 1, 2, 2]], z[:])
    else
        ps = [Point3(get_dim(x, i, 1, size(z)), get_dim(y, i, 2, size(z)), z[i]) for i in CartesianIndices(z)]
    end
    return vec(ps)
end

############################################################
#                 Attribute key extraction                 #
############################################################

function extract_keys(attributes, keys)
    attr = Attributes()
    for key in keys
        attr[key] = attributes[key]
    end
    return attr
end

# Scalar - Vector getindex
"""
    sv_getindex(x, index)

Returns `x[i]` if x is a `AbstractArray` and `x` otherwise. `VecTypes` and `Mat`
are treated as values rather than Arrays for this, i.e. they do not get indexed.
"""
sv_getindex(v::AbstractArray, i::Integer) = v[i]
sv_getindex(x, ::Integer) = x
sv_getindex(x::VecTypes, ::Integer) = x
sv_getindex(x::Mat, ::Integer) = x
# for CairoMakie meshscatter we don't want images and patterns to get indexed
sv_getindex(x::AbstractMatrix{<:Colorant}, ::Integer) = x
sv_getindex(x::ShaderAbstractions.Sampler, ::Integer) = x

# TODO: move to GeometryBasics
function corners(rect::Rect2{T}) where {T}
    o = minimum(rect)
    w = widths(rect)
    T0 = zero(T)
    return Point{3, T}[o .+ Vec2{T}(x, y) for x in (T0, w[1]) for y in (T0, w[2])]
end

function corners(rect::Rect3{T}) where {T}
    o = minimum(rect)
    w = widths(rect)
    T0 = zero(T)
    return Point{3, T}[o .+ Vec3{T}(x, y, z) for x in (T0, w[1]) for y in (T0, w[2]) for z in (T0, w[3])]
end

"""
    available_plotting_methods()

Returns an array of all available plotting functions.
"""
function available_plotting_methods()
    meths = []
    for m1 in methods(Makie.default_theme)
        params = m1.sig.parameters
        if length(params) == 3 && params[3] isa UnionAll
            push!(meths, Makie.plotfunc(params[3].var.ub))
        end
    end
    return meths
end

function extract_method_arguments(m::Method)
    tv, decls, file, line = Base.arg_decl_parts(m)
    tnames = map(decls[3:end]) do (n, t)
        return string(n, "::", t)
    end
    return join(tnames, ", ")
end

function available_conversions(PlotType)
    result = []
    for m in methods(convert_arguments, (PlotType, Vararg{Any}))
        push!(result, extract_method_arguments(m))
    end
    for m in methods(convert_arguments, (typeof(Makie.conversion_trait(PlotType)), Vararg{Any}))
        push!(result, extract_method_arguments(m))
    end
    return result
end

mindist(x, a, b) = min(abs(a - x), abs(b - x))
function gappy(x, ps)
    n = length(ps)
    x <= first(ps) && return first(ps) - x
    for j in 1:(n - 1)
        p0 = ps[j]
        p1 = ps[min(j + 1, n)]
        if p0 <= x && p1 >= x
            return mindist(x, p0, p1) * (isodd(j) ? 1 : -1)
        end
    end
    return last(ps) - x
end


# This is used to map a vector of `points` to a signed distance field. The
# points mark transition between "on" and "off" section of the pattern.

# The output should be periodic so the signed distance field value
# representing points[1] should be equal to the one representing points[end].
# => range(..., length = resolution+1)[1:end-1]

# points[end] should still represent the full length of the pattern though,
# so we need rescaling by ((resolution + 1) / resolution)
function linestyle_to_sdf(linestyle::AbstractVector{<:Real}, resolution::Real = 100)
    scaled = ((resolution + 1) / resolution) .* linestyle
    r = range(first(scaled); stop = last(scaled), length = resolution + 1)[1:(end - 1)]
    return Float16[-gappy(x, scaled) for x in r]
end

"""
    shared_attributes(plot::Plot, target::Type{<:Plot})

Extracts all attributes from `plot` that are shared with the `target` plot type.
"""
function shared_attributes(plot::Plot, target::Type{<:Plot}; drop::Vector{Symbol} = Symbol[])
    # TODO: This currently happens for ComputeGraph passthrough already
    valid_attributes = attribute_names(target)
    existing_attributes = keys(plot.attributes.outputs)
    to_drop = setdiff(existing_attributes, valid_attributes)
    # Model is always shared, but should not be shared and therefore dropped
    push!(to_drop, :model)
    union!(to_drop, drop)
    return drop_attributes(plot, to_drop)
end

function drop_attributes(plot::Plot, to_drop::Symbol...)
    return drop_attributes(plot, Set(to_drop))
end

function drop_attributes(plot::Plot, to_drop::Set{Symbol})
    attr = plot.attributes.outputs
    return Attributes([k => v for (k, v) in attr if !(k in to_drop)])
end

isscalar(x::StaticVector) = true
isscalar(x::Mat) = true
isscalar(x::AbstractArray) = false
isscalar(x::Billboard) = isscalar(x.rotation)
isscalar(x::Observable) = isscalar(x[])
isscalar(x) = true

# Stolen from StableTasks.jl
# So we can better test threading
# Putting it here, in case we want to start using it!
function set_task_tid!(task::Task, tid::Integer)
    task.sticky = true
    return ccall(:jl_set_task_tid, Cint, (Any, Cint), task, tid - 1)
end
function spawnat(f, tid)
    task = Task(f)
    set_task_tid!(task, tid)
    schedule(task)
    return task
end
