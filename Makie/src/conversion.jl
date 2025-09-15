"""
    convert_attribute(value, attribute::Key[, plottype::Key])

Convert `value` into a suitable domain for use as `attribute`.

# Example
```jldoctest
julia> using Makie

julia> Makie.convert_attribute(:black, key"color"())
RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0)
```
"""
function convert_attribute end
function used_attributes end

################################################################################
#                              Conversion Traits                               #
################################################################################

abstract type ConversionTrait end

struct NoConversion <: ConversionTrait end

# No conversion by default
conversion_trait(::Type) = NoConversion()
conversion_trait(T::Type, args...) = conversion_trait(T)

"""
    PointBased() <: ConversionTrait

Plots with the `PointBased` trait convert their input data to a
`Vector{Point{D, Float32}}`.
"""
struct PointBased <: ConversionTrait end

argument_docs(::PointBased) = """
## Arguments (`PointBased()`)
- `x`: A `Real`, `AbstractVector{<:Real}` or `ClosedInterval[<:Real]` corresponding to \
x positions. Intervals require another dimension to be given as an `AbstractVector`. \
Defaults to `eachindex(y)` if omitted.
- `y`: A `Real`, `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` corresponding to \
y positions. Intervals require another dimension to be given as an `AbstractVector`.
- `z`: A `Real`, `AbstractVector{<:Real}` or `AbstractMatrix{<:Real}` corresponding to \
z positions. Using a matrix will change `x` and `y` to be interpreted per matrix axis.
- `position`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` \
corresponding to `(x, y)` or `(x, y, z)` positions. Used instead of `x`, `y`, `z` arguments.
- `matrix`: A 2 or 3 by N matrix interpreted to contain N 2 or 3 dimensional positions. \
The matrix can also be transposed, i.e. N by 2 or 3.
- `geometry_primitive`: Coordinates of a `GeometryBasics.GeometryPrimitive` which can \
be decomposed into points. This includes for example `Rect`, `Sphere` and `GeometryBasics.Mesh`.
- `multi_point`: A `GeometryBasics.MultiPoint` or `AbstractVector` thereof, interpreted \
as a collection of positions.
- `line_string`: A `GeometryBasics.LineString`, `GeometryBasics.MultiLineString` or \
`AbstractVector{<:LineString}` interpreted as a collection of positions. The latter \
two will separate line strings by NaN points to disconnect them.
- `polygon`: A `GeometryBasics.Polygon`, `GeometryBasics.MultiPolygon` or \
`AbstractVector{<:Polygon}` disassembled into positions of the exterior and \
interior coordinates. Each polygon, interior and exterior is separated by a NaN \
point. Each exterior and interior is closed, meaning the first point is duplicated \
after the last.
- `bezierpath`: A `Makie.BezierPath` discretized into 2D positions.
"""

"""
    GridBased <: ConversionTrait

GridBased is an abstract conversion trait for data that exists on a grid.

Child types: [`VertexGrid`](@ref), [`CellGrid`](@ref)

See also: [`ImageLike`](@ref)
"""
abstract type GridBased <: ConversionTrait end

"""
    VertexGrid() <: GridBased <: ConversionTrait

Plots with the `VertexGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs)`, or
`(xs::Matrix{Float32}, ys::Matrix{Float32}, zs::Matrix{Float32})` such that
`size(xs) == size(ys) == size(zs)`.

Used for: Surface \\
See also: [`CellGrid`](@ref), [`ImageLike`](@ref)
"""
struct VertexGrid <: GridBased end

"""
    CellGrid() <: GridBased <: ConversionTrait

Plots with the `CellGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs) .+ 1`. After the conversion the x and y
values represent the edges of cells corresponding to z values.

Used for: Heatmap \\
See also: [`VertexGrid`](@ref), [`ImageLike`](@ref)
"""
struct CellGrid <: GridBased end

"""
    ImageLike() <: ConversionTrait

Plots with the `ImageLike` trait convert their input data to
`(xs::Interval, ys::Interval, zs::Matrix{Float32})` where xs and ys mark the
limits of a quad containing zs.

Used for: Image \\
See also: [`CellGrid`](@ref), [`VertexGrid`](@ref)
"""
struct ImageLike <: ConversionTrait end
# Rect2f(xmin, ymin, xmax, ymax)


struct VolumeLike <: ConversionTrait end

function convert_arguments end

convert_arguments(::NoConversion, args...; kw...) = args

get_element_type(::T) where {T} = T
function get_element_type(arr::AbstractArray{T}) where {T}
    if T == Any
        return mapreduce(typeof, promote_type, arr)
    else
        return T
    end
end

types_for_plot_arguments(trait) = nothing
function types_for_plot_arguments(P::Type{<:Plot}, Trait::ConversionTrait)
    p = types_for_plot_arguments(P)
    isnothing(p) || return p
    return types_for_plot_arguments(Trait)
end

function types_for_plot_arguments(::PointBased)
    return Tuple{AbstractVector{<:Union{Point2, Point3}}}
end

should_dim_convert(::Type) = false

"""
    should_dim_convert(::Type{<: Plot}, args)::Bool
    should_dim_convert(eltype::DataType)::Bool

Returns `true` if the plot type should convert its arguments via DimConversions.
Needs to be overloaded for recipes that want to use DimConversions. Also needs
to be overloaded for DimConversions, e.g. for CategoricalConversion:

```julia
    should_dim_convert(::Type{Categorical}) = true
```

`should_dim_convert(::Type{<: Plot}, args)` falls back on checking if
`has_typed_convert(plot_or_trait)` and `should_dim_convert(get_element_type(args))`
 are true. The former is defined as true by `@convert_target`, i.e. when
`convert_arguments_typed` is defined for the given plot type or conversion trait.
The latter marks specific types as convertible.

If a recipe wants to use dim conversions, it should overload this function:
```julia
    should_dim_convert(::Type{<:MyPlotType}, args) = should_dim_convert(get_element_type(args))
``
"""
function should_dim_convert(P, arg)
    isnothing(types_for_plot_arguments(P)) && return false
    return should_dim_convert(get_element_type(arg))
end

################################################################################
### Utilities
################################################################################

function collect_applicable_onversion_methods(plot_type)
    # methodswith does not return applicable methods with abstract types when
    # using a concrete subtype. So we filter ourself...
    methodlist = methods(convert_arguments)
    CT = Makie.conversion_trait(plot_type)

    # Methods with `(..., x::T) where T` have UnionAll's in method.sig
    extract_arg_types(x::UnionAll) = extract_arg_types(x.body)
    extract_arg_types(x::DataType) = x.types

    return filter(methodlist) do method
        # method.sig = Tuple{function_type, arg_types...}
        f, arg_types... = extract_arg_types(method.sig)
        length(arg_types) > 1 || return false
        # plot_type or its trait are the first argument
        is_applicable = plot_type isa arg_types[1] || CT isa arg_types[1]
        # remaining args aren't a catchall foo(x, args...)
        is_applicable &= arg_types[2] !== Vararg{Any}
        return is_applicable
    end
end

function method_docstrings(methodlist)
    # get the module's multidoc
    binding = Docs.Binding(Makie, Symbol(convert_arguments))
    dict = Docs.meta(Makie)
    multidoc = dict[binding]

    function remove_func(sig::UnionAll)
        vars = TypeVar[]
        body = remove_func(sig, vars)
        final_body = Union{map(x -> Tuple{x}, vars)..., body}
        union_type = final_body
        for var in vars
            union_type = UnionAll(var, union_type)
        end
        return union_type
    end

    function remove_func(sig::UnionAll, vars)
        pushfirst!(vars, sig.var)
        return remove_func(sig.body, vars)
    end

    remove_func(sig::DataType, vars = nothing) = Tuple{sig.types[2:end]...}

    # for each module, attempt to get the docstring as markdown
    docstrings = String[]
    for m in methodlist
        # cleanup signature
        sig = remove_func(m.sig)

        if haskey(multidoc.docs, sig)
            push!(docstrings, multidoc.docs[sig].text[1])
        else
            push!(docstrings, "")
        end
    end

    return docstrings
end

function build_conversion_docs(PlotType)
    methods = collect_applicable_onversion_methods(PlotType)
    docstrings = method_docstrings(methods)

    output = map(methods, docstrings) do method, docstring
        func_signature, location = split(string(method), " @ ")
        # remove `convert_argument(first_arg, ` and `) ...`
        # func_signature = replace(func_signature, r"^[^,]+, " => "")
        # func_signature = replace(func_signature, r"\).*" => "")

        if isempty(docstring)
            return "- `$func_signature`"
        else
            # Try to compact docstring
            str = replace(docstring, r"convert_arguments\(.+\).+\n" => "")
            str = replace(str, '\n' => ' ')
            str = replace(str, r"  +" => ' ')
            str = replace(str, r"^ +" => "", r" +$" => "")
            return "- `$func_signature`: $str"
        end
    end

    str = "Conversion applicable to $PlotType:\n" * join(output, '\n')
    return Markdown.parse(str)
end