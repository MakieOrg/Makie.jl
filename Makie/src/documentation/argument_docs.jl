"""
    argument_docs(key, plot_type; kwargs...)

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
function argument_docs(
        key::Symbol;
        additional_items = String[],
        item_kwargs = NamedTuple(),
        items = argument_docs_items(Val(key); item_kwargs...),
        title_note = "",
        title = argument_docs_title(Val(key), title_note),
        ref = "See `conversion_docs(PlotType)` for a full list of applicable conversion methods."
    )
    all_items = vcat(items, additional_items)
    # constructs item list an appends to title
    str = mapreduce((a, b) -> "$a\n$b", all_items, init = title) do item
        item = replace(item, '\n' => ' ')
        item = replace(item, r"  +" => ' ')
        return "- " * item
    end

    if !isempty(ref)
        str = str * "\n\n" * ref
    end

    return str
end

function argument_docs_title(::Val{name}, title_note) where {name}
    return "## Arguments ($title_note`$name()`)"
end

argument_docs_items(::Val{:PointBased}) = [
    "`position`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}`
    corresponding to `(x, y)` or `(x, y, z)` positions.",
    "`x, y[, z]`: Positions given per dimension. Can be `Real` to define
    a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to
    define multiple. Using `ClosedInterval` requires at least one dimension to be
    given as an array. `z` can also be given as a `AbstractMatrix` which will cause
    `x` and `y` to be interpreted per matrix axis.",
    "`y`: Defaults `x` positions to `eachindex(y)`."
]

argument_docs_title(::Val{:PointBased2D}, title_note) = argument_docs_title(Val{:PointBased}(), title_note)
argument_docs_items(::Val{:PointBased2D}) = [
    "`position`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}`
    corresponding to `(x, y)`positions.",
    "`x, y`: Positions given per dimension. Can be `Real` to define
    a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to
    define multiple. Using `ClosedInterval` requires at least one dimension to be
    given as an array. If omitted, `x` defaults to `eachindex(y)`."
]

argument_docs_items(::Val{:VertexGrid}; arg3 = "z") = [
    "`$arg3`: Defines $arg3 values for vertices of a grid using an `AbstractMatrix{<:Real}`.",
    "`x, y`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or
    `Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between
    which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex
    positions directly for the respective dimension. An `AbstractMatrix{<:Real}`
    allows grid positions to be defined per vertex, i.e. in a non-repeating fashion.
    If `x` and `y` are omitted they default to `axes(data, dim)`."
]

argument_docs_items(::Val{:CellGrid}) = [
    "`data`: Defines data values for cells of a grid using an `AbstractMatrix{<:Real}`."
    "`x, y`: Defines the positions of grid cells. A `ClosedInterval{<:Real}` or
    `Tuple{<:Real, <:Real}` is interpreted as the outer edges of the grid, between
    which cells are spaced regularly. An `AbstractVector{<:Real}` defines cell positions
    directly for the respective dimension. This define either `size(data, dim)` cell
    centers or `size(data, dim) + 1` cell edges. These are allowed to be spaced
    irregularly. If `x` and `y` are omitted they default to `axes(data, dim)`."
]

argument_docs_items(::Val{:ImageLike}) = [
    "`image`: An `AbstractMatrix{<:Colorant}` defining the colors of an image, or
    an `AbstractMatrix{<:Real}` defining colors through colormapping.",
    "`x, y`: Defines the boundary of the image rectangle. Can be a `Tuple{<:Real, <:Real}`
    or `ClosedInterval{<:Real}`. Defaults to `0 .. size(z, 1)` and `0 .. size(z, 2)` respectively."
]

argument_docs_items(::Val{:VolumeLike}; arg4 = "volume_data") = [
    "`$arg4`: An `AbstractArray{<:Real, 3}` defining volume data.",
    "`x, y, z`: Defines the boundary of a 3D rectangle with a `Tuple{<:Real, <:Real}`
    or `ClosedInterval{<:Real}`. If omitted `x`, `y` and `z` default to `0 .. size(volume)`."
]

argument_docs_title(::Val{:LineSegments}, title_note) = argument_docs_title(Val{:PointBased}(), title_note)
function argument_docs_items(::Val{:LineSegments})
    return push!(
        argument_docs_items(Val{:PointBased}()),
        "- `pairs`: An `AbstractVector{Tuple{<:VecTypes, <:VecTypes}}` representing
        pairs of points to be connected."
    )
end