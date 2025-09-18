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
### Trait based Argument Docstrings
################################################################################

"""
    argument_docs(::ConversionTrait)

Returns a string documenting the most common arguments associated with a
conversion trait so that the documentation can be reused over multiple recipes.
May refer to `conversion_docs(PlotType)` for more information.

Sample:
\"\"\"
## Arguments (trait_type):
- `option1`: ...
- `option2`: ...
\"\"\"
"""
argument_docs

argument_docs(::PointBased; item = "") = """
## Arguments (`PointBased()`)
- `position`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` \
corresponding to `(x, y)` or `(x, y, z)` positions.
- `x, y[, z]`: Positions given per dimension. Can be `Real` to define \
a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to \
define multiple. Using `ClosedInterval` requires at least one dimension to be \
given as an array. `z` can also be given as a `AbstractMatrix` which will cause \
`x` and `y` to be interpreted per matrix axis.
- `y`: Defaults `x` positions to `eachindex(y)`.
$item
See `conversion_docs(PlotType)` for a full list of applicable conversion methods.
"""

argument_docs(::VertexGrid; arg3 = "z", title_info = "") = """
## Arguments ($title_info`VertexGrid()`)
- `$arg3`: Defines $arg3 values for vertices of a grid using an `AbstractMatrix{<:Real}`.
- `x, y`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or \
`Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between \
which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex \
positions directly for the respective dimension. An `AbstractMatrix{<:Real}` \
allows grid positions to be defined per vertex, i.e. in a non-repeating fashion. \
If `x` and `y` are omitted they default to `axes(data, dim)`.

See `conversion_docs(PlotType)` for a full list of applicable conversion methods.
"""

argument_docs(::CellGrid) = """
## Arguments (`CellGrid()`)
- `data`: Defines data values for cells of a grid using an `AbstractMatrix{<:Real}`.
- `x, y`: Defines the positions of grid cells. A `ClosedInterval{<:Real}` or \
`Tuple{<:Real, <:Real}` is interpreted as the outer edges of the grid, between \
which cells are spaced regularly. An `AbstractVector{<:Real}` defines cell positions \
directly for the respective dimension. This define either `size(data, dim)` cell \
centers or `size(data, dim) + 1` cell edges. These are allowed to be spaced \
irregularly. If `x` and `y` are omitted they default to `axes(data, dim)`.

See `conversion_docs(PlotType)` for a full list of applicable conversion methods.
"""

argument_docs(::ImageLike) = """
## Arguments (`ImageLike()`)
- `image`: An `AbstractMatrix{<:Colorant}` defining the colors of an image, or \
an `AbstractMatrix{<:Real}` defining colors through colormapping.
- `x, y`: Defines the boundary of the image rectangle. Can be a `Tuple{<:Real, <:Real}` \
or `ClosedInterval{<:Real}`. Defaults to `0 .. size(z, 1)` and `0 .. size(z, 2)` respectively.

See `conversion_docs(PlotType)` for a full list of applicable conversion methods.
"""

argument_docs(::VolumeLike; arg4 = "volume_data", title_info = "") = """
## Arguments ($title_info`VolumeLike()`)
- `$arg4`: An `AbstractArray{<:Real, 3}` defining volume data.
- `x, y, z`: Defines the boundary of a 3D rectangle with a `Tuple{<:Real, <:Real}` \
or `ClosedInterval{<:Real}`. If omitted `x`, `y` and `z` default to `0 .. size(volume)`.

See `conversion_docs(PlotType)` for a full list of applicable conversion methods.
"""


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

function conversion_docs(PlotType)
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

    CT = conversion_trait(PlotType)
    conversion_trait_str = if CT isa NoConversion
        ""
    else
        " and its conversion trait $CT"
    end

    str = "Conversion applicable to $(PlotType)$(conversion_trait_str):\n" * join(output, '\n')
    return Markdown.parse(str)
end