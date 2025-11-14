function argument_docs(::Type{LineSegments})
    ldocs = argument_docs(PointBased())
    pairs = "* `pairs`: An `AbstractVector{Tuple{<:VecTypes, <:VecTypes}}` representing
        pairs of points to be connected."


    items = Markdown.parse(pairs).content[1].items
    append!(ldocs.content[1].items, items)
    return ldocs
end



################################################################################
### convert_arguments method collection
################################################################################

function collect_applicable_conversion_methods(plot_type)
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
    methods = collect_applicable_conversion_methods(PlotType)
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
    str *= "\nNote that these methods are automatically collected. Some may not \
    be applicable based on their return type or due to a more specialized method \
    existing and some may not be listed due to being called by another method recursively."
    return Markdown.parse(str)
end



"""
    format_argument_signature(::Type{PT}) where {PT<:Plot}

Returns a formatted string showing the argument signature with types for a plot type.
For example: "positions::AbstractVector{<:Union{Point2, Point3}}"
Returns nothing if type information is not available.
"""
function format_argument_signature(::Type{PT}) where {PT<:Plot}
    # Get argument names
    arg_names = argument_names(PT, 10)
    isempty(arg_names) && return nothing

    # Get target types - try plot-specific first, then trait-based
    arg_types = types_for_plot_arguments(PT)
    if isnothing(arg_types)
        CT = conversion_trait(PT)
        arg_types = types_for_plot_arguments(CT)
    end
    isnothing(arg_types) && return nothing

    # arg_types is a Tuple type, extract the parameter types
    type_params = arg_types.parameters

    # Match names with types
    if length(arg_names) != length(type_params)
        # Mismatch - just return nothing for now
        return nothing
    end

    # Format as "name::Type"
    parts = String[]
    for (name, typ) in zip(arg_names, type_params)
        # Simplify type representation
        type_str = string(typ)
        # Skip overly complex type signatures (more than 200 characters per argument)
        if length(type_str) > 200
            return nothing
        end
        # Clean up Union{A, B} to be more readable
        type_str = replace(type_str, r"Union\{([^}]+)\}" => s"Union{\1}")
        push!(parts, "$name::$type_str")
    end

    return join(parts, ", ")
end

function argument_docs_md(Pt)
    arg_docs = argument_docs(Pt)
    sig = format_argument_signature(Pt)
    result = arg_docs.content
    if !isnothing(sig)
        header = Markdown.parse("**Conversion target:** `$sig`")
        pushfirst!(result, header)
    end
    pushfirst!(result, Markdown.parse("## Arguments"))
    return Markdown.MD(result)
end
