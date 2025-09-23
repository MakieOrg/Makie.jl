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
    "`positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}`
    corresponding to `(x, y)` or `(x, y, z)` positions.",
    "`xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define
    a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to
    define multiple. Using `ClosedInterval` requires at least one dimension to be
    given as an array. `zs` can also be given as a `AbstractMatrix` which will cause
    `xs` and `ys` to be interpreted per matrix axis.",
    "`ys`: Defaults `xs` positions to `eachindex(ys)`."
]

argument_docs_title(::Val{:PointBased2D}, title_note) = argument_docs_title(Val{:PointBased}(), title_note)
argument_docs_items(::Val{:PointBased2D}) = [
    "`positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}`
    corresponding to `(x, y)` positions.",
    "`xs, ys`: Positions given per dimension. Can be `Real` to define
    a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to
    define multiple. Using `ClosedInterval` requires at least one dimension to be
    given as an array. If omitted, `xs` defaults to `eachindex(ys)`."
]

argument_docs_items(::Val{:VertexGrid}; arg3 = "zs") = [
    "`$arg3`: Defines $arg3 values for vertices of a grid using an `AbstractMatrix{<:Real}`.",
    "`xs, ys`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or
    `Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between
    which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex
    positions directly for the respective dimension. An `AbstractMatrix{<:Real}`
    allows grid positions to be defined per vertex, i.e. in a non-repeating fashion.
    If `xs` and `ys` are omitted they default to `axes(data, dim)`."
]

argument_docs_items(::Val{:CellGrid}) = [
    "`data`: Defines data values for cells of a grid using an `AbstractMatrix{<:Real}`."
    "`xs, ys`: Defines the positions of grid cells. A `ClosedInterval{<:Real}` or
    `Tuple{<:Real, <:Real}` is interpreted as the outer edges of the grid, between
    which cells are spaced regularly. An `AbstractVector{<:Real}` defines cell positions
    directly for the respective dimension. This define either `size(data, dim)` cell
    centers or `size(data, dim) + 1` cell edges. These are allowed to be spaced
    irregularly. If `xs` and `ys` are omitted they default to `axes(data, dim)`."
]

argument_docs_items(::Val{:ImageLike}) = [
    "`image`: An `AbstractMatrix{<:Colorant}` defining the colors of an image, or
    an `AbstractMatrix{<:Real}` defining colors through colormapping.",
    "`x, y`: Defines the boundary of the image rectangle. Can be a
    `Tuple{<:Real, <:Real}` or `ClosedInterval{<:Real}`. Defaults to
    `0 .. size(image, 1)` and `0 .. size(image, 2)` respectively."
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
        "`pairs`: An `AbstractVector{Tuple{<:VecTypes, <:VecTypes}}` representing
        pairs of points to be connected."
    )
end

argument_docs_items(::Val{:SampleBased}) = [
    "`ys`: An `AbstractVector{<:Real} defining samples."
    "`xs`: An `AbstractVector{<:Real} defining the x positions and grouping
    of `ys`. This can typically be reinterpreted as y positions by adjusting the
    `orientation` or `direction` attribute. (x, y) pairs with the same x value
    are considered part of the same group, category or sample."
]

################################################################################
### convert_arguments method collection
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