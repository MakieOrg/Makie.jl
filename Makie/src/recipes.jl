not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

to_func_name(x::Symbol) = Symbol(lowercase(string(x)))
# Fallback for Plot ...
# Will get overloaded by recipe Macro
plotsym(x) = :plot

func2string(func::Function) = string(nameof(func))

plotfunc(::Plot{F}) where {F} = F
plotfunc(::Type{<:AbstractPlot{Func}}) where {Func} = Func
plotfunc(::T) where {T <: AbstractPlot} = plotfunc(T)
function plotfunc(f::Function)
    if endswith(string(nameof(f)), "!")
        name = Symbol(string(nameof(f))[begin:(end - 1)])
        return getproperty(parentmodule(f), name)
    else
        return f
    end
end

symbol_to_plot(x::Symbol) = symbol_to_plot(Val(x))
function symbol_to_plot(::Val{Sym}) where {Sym}
    return nothing
end


function plotfunc!(x)
    F = plotfunc(x)::Function
    name = Symbol(nameof(F), :!)
    return getproperty(parentmodule(F), name)
end

func2type(x::T) where {T} = func2type(T)
func2type(x::Type{<:AbstractPlot}) = x
func2type(f::Function) = Plot{plotfunc(f)}

@generated plotkey(::Type{<:AbstractPlot{Typ}}) where {Typ} = QuoteNode(Symbol(lowercase(func2string(Typ))))
plotkey(::T) where {T <: AbstractPlot} = plotkey(T)
plotkey(::Nothing) = :scatter
plotkey(any) = nothing


function create_axis_like end
function create_axis_like! end
function figurelike_return end
function figurelike_return! end

function _create_plot end
function _create_plot! end


plot(args...; kw...) = _create_plot(plot, Dict{Symbol, Any}(kw), args...)
plot!(args...; kw...) = _create_plot!(plot, Dict{Symbol, Any}(kw), args...)

"""
Each argument can be named for a certain plot type `P`. Falls back to `arg1`, `arg2`, etc.
"""
function argument_names(plot::P) where {P <: AbstractPlot}
    return argument_names(P, length(plot.converted[]))
end

function argument_names(::Type{<:AbstractPlot}, num_args::Integer)
    # this is called in the indexing function, so let's be a bit efficient
    return ntuple(i -> Symbol("converted_$i"), num_args)
end

# Since we can use Plot like a scene in some circumstances, we define this alias
theme(x::SceneLike, args...) = theme(x.parent, args...)
theme(x::AbstractScene) = x.theme
theme(x::AbstractScene, key; default = nothing) = deepcopy(get(x.theme, key, default))
theme(x::AbstractPlot, key; default = nothing) = deepcopy(get(x.attributes, key, default))

Attributes(x::AbstractPlot) = x.attributes

function default_theme end

"""
# Plot Recipes in `Makie`

There's two types of recipes. *Type recipes* define a simple mapping from a
user defined type to an existing plot type. *Full recipes* can customize the
theme and define a custom plotting function.

## Type recipes

Type recipe are really simple and just overload the argument conversion
pipeline. This can be done for all plot types or for a subset of plot types:

    # All plot types
    convert_arguments(P::Type{<:AbstractPlot}, x::MyType) = convert_arguments(P, rand(10, 10))
    # Only for scatter plots
    convert_arguments(P::Type{<:Scatter}, x::MyType) = convert_arguments(P, rand(10, 10))

Optionally you may define the default plot type so that `plot(x::MyType)` will
use this:

    plottype(::MyType) = Surface

## Full recipes with the `@recipe` macro

A full recipe for `MyPlot` comes in two parts. First is the plot type name,
arguments and theme definition which are defined using the `@recipe` macro.
Second is a custom `plot!` for `MyPlot`, implemented in terms of the atomic
plotting functions.

We use an example to show how this works:

    # arguments (x, y, z) && theme are optional
    @recipe(MyPlot, x, y, z) do scene
        Attributes(
            plot_color = :red
        )
    end

This macro expands to several things. Firstly a type definition:

    const MyPlot{ArgTypes} = Plot{myplot, ArgTypes}

The type parameter of `Plot` contains the function instead of e.g. a
symbol. This way the mapping from `MyPlot` to `myplot` is safer and simpler.
(The downside is we always need a function `myplot` - TODO: is this a problem?)

The following signatures are defined to make `MyPlot` nice to use:

    myplot(args...; kw_args...) = ...
    myplot!(scene, args...; kw_args...) = ...
    myplot(kw_args::Dict, args...) = ...
    myplot!(scene, kw_args::Dict, args...) = ...
    #etc (not 100% settled what signatures there will be)

A specialization of `argument_names` is emitted if you have an argument list
`(x,y,z)` provided to the recipe macro:

    argument_names(::Type{<: MyPlot}) = (:x, :y, :z)

This is optional but it will allow the use of `plot_object[:x]` to
fetch the first argument from the call
`plot_object = myplot(rand(10), rand(10), rand(10))`, for example.
Alternatively you can always fetch the `i`th argument using `plot_object[i]`,
and if you leave out the `(x,y,z)`, the default version of `argument_names`
will provide `plot_object[:arg1]` etc.

The theme given in the body of the `@recipe` invocation is inserted into a
specialization of `default_theme` which inserts the theme into any scene that
plots `MyPlot`:

    function default_theme(scene, ::MyPlot)
        Attributes(
            plot_color = :red
        )
    end

As the second part of defining `MyPlot`, you should implement the actual
plotting of the `MyPlot` object by specializing `plot!`:

    function plot!(plot::MyPlot)
        # normal plotting code, building on any previously defined recipes
        # or atomic plotting operations, and adding to the combined `plot`:
        lines!(plot, rand(10), color = plot[:plot_color])
        plot!(plot, plot[:x], plot[:y])
        plot
    end

It's possible to add specializations here, depending on the argument *types*
supplied to `myplot`. For example, to specialize the behavior of `myplot(a)`
when `a` is a 3D array of floating point numbers:

    const MyVolume = MyPlot{Tuple{<:AbstractArray{<: AbstractFloat, 3}}}
    argument_names(::Type{<: MyVolume}) = (:volume,) # again, optional
    function plot!(plot::MyVolume)
        # plot a volume with a colormap going from fully transparent to plot_color
        volume!(plot, plot[:volume], colormap = :transparent => plot[:plot_color])
        plot
    end

The docstring given to the recipe will be transferred to the functions it generates.

"""
macro recipe(theme_func, Tsym::Symbol, args::Symbol...)
    funcname_sym = to_func_name(Tsym)
    funcname! = esc(Symbol("$(funcname_sym)!"))
    PlotType = esc(Tsym)
    funcname = esc(funcname_sym)
    expr = quote
        $(funcname)() = not_implemented_for($funcname)
        const $(PlotType){$(esc(:ArgType))} = Plot{$funcname, $(esc(:ArgType))}
        $(Makie).plotsym(::Type{<:$(PlotType)}) = $(QuoteNode(Tsym))
        Core.@__doc__ ($funcname)(args...; kw...) = _create_plot($funcname, Dict{Symbol, Any}(kw), args...)
        ($funcname!)(args...; kw...) = _create_plot!($funcname, Dict{Symbol, Any}(kw), args...)
        $(Makie).default_theme(scene, ::Type{<:$PlotType}) = $(esc(theme_func))(scene)
        $(Makie).symbol_to_plot(::Val{$(QuoteNode(Tsym))}) = $PlotType
        export $PlotType, $funcname, $funcname!
    end
    if !isempty(args)
        push!(
            expr.args,
            :(
                $(esc(:($(Makie).argument_names)))(::Type{<:$PlotType}, len::Integer) =
                    $args
            ),
        )
    end
    return expr
end

function attribute_names end
function documented_attributes end # this can be used for inheriting from other recipes

attribute_names(_) = nothing

Base.@kwdef struct AttributeMetadata
    docstring::Union{Nothing, String}
    default_value::Any
    default_expr::String # stringified expression, just needed for docs purposes
end

update_metadata(am1::AttributeMetadata, am2::AttributeMetadata) = AttributeMetadata(
    am2.docstring === nothing ? am1.docstring : am2.docstring,
    am2.default_value,
    am2.default_expr # TODO: should it be possible to overwrite only a docstring by not giving a default expr?
)

struct DocumentedAttributes
    d::Dict{Symbol, AttributeMetadata}
end

struct Inherit
    key::Symbol
    fallback::Any
end

function lookup_default(meta::AttributeMetadata, theme)
    default = meta.default_value
    if default isa Inherit
        if haskey(theme, default.key)
            to_value(theme[default.key]) # only use value of theme entry
        else
            if isnothing(default.fallback)
                error("Inherited key $(default.key) not found in theme with no fallback given.")
            else
                return default.fallback
            end
        end
    else
        return default
    end
end

function get_default_expr(default)
    if default isa Expr && default.head === :macrocall && default.args[1] === Symbol("@inherit")
        if length(default.args) ∉ (3, 4)
            error("@inherit works with 1 or 2 arguments, expression was $default")
        end
        if !(default.args[3] isa Symbol)
            error("Argument 1 of @inherit must be a Symbol, got $(default.args[3])")
        end
        key = default.args[3]
        _default = get(default.args, 4, :(nothing))
        # first check scene theme
        # then default value
        return :($(Makie.Inherit)($(QuoteNode(key)), $(esc(_default))))
    else
        return esc(default)
    end
end

macro DocumentedAttributes(expr::Expr)
    if !(expr isa Expr && expr.head === :block)
        throw(ArgumentError("Argument is not a begin end block"))
    end

    metadata_exprs = []
    closure_exprs = []
    mixin_exprs = Expr[]

    for arg in expr.args
        arg isa LineNumberNode && continue

        has_docs = arg isa Expr && arg.head === :macrocall && arg.args[1] isa GlobalRef

        if has_docs
            docs = arg.args[3]
            attr = arg.args[4]
        else
            docs = nothing
            attr = arg
        end

        is_attr_line = attr isa Expr && attr.head === :(=) && length(attr.args) == 2
        is_mixin_line = attr isa Expr && attr.head === :(...) && length(attr.args) == 1
        if !(is_attr_line || is_mixin_line)
            error("$attr is neither a valid attribute line like `x = default_value` nor a mixin line like `some_mixin...`")
        end

        if is_attr_line
            sym = attr.args[1]
            default = attr.args[2]
            if !(sym isa Symbol)
                error("$sym should be a symbol")
            end
            qsym = QuoteNode(sym)
            metadata = quote
                am = AttributeMetadata(;
                    docstring = $docs,
                    default_value = $(get_default_expr(default)),
                    default_expr = $(default_expr_string(default))
                )
                if haskey(d, $(qsym))
                    d[$(qsym)] = update_metadata(d[$(qsym)], am)
                else
                    d[$(qsym)] = am
                end
            end
            push!(metadata_exprs, metadata)
        elseif is_mixin_line
            # this intermediate variable is needed to evaluate each mixin only once
            # and is inserted at the start of the final code block
            gsym = gensym("mixin")
            mixin = only(attr.args)
            push!(
                mixin_exprs, quote
                    $gsym = $(esc(mixin))
                    if !($gsym isa DocumentedAttributes)
                        error("Mixin was not a DocumentedAttributes but $($gsym)")
                    end
                end
            )

            # docstrings and default expressions of the mixed in
            # DocumentedAttributes are inserted
            metadata_exp = quote
                for (key, value) in $gsym.d
                    if haskey(d, key)
                        error("Mixin `$($(QuoteNode(mixin)))` had the key :$key which already existed. It's not allowed for mixins to overwrite keys to avoid accidental overwrites. Drop those keys from the mixin first.")
                    end
                    d[key] = value
                end
            end
            push!(metadata_exprs, metadata_exp)
        else
            error("Unreachable")
        end
    end

    return quote
        $(mixin_exprs...)
        d = Dict{Symbol, AttributeMetadata}()
        $(metadata_exprs...)
        DocumentedAttributes(d)
    end
end

function is_attribute(T::Type{<:Plot}, sym::Symbol)
    return sym in attribute_names(T)
end

function attribute_default_expressions(T::Type{<:Plot})
    return Dict(k => v.default_expr for (k, v) in documented_attributes(T).d)
end

function _attribute_docs(T::Type{<:Plot})
    return Dict(k => v.docstring for (k, v) in documented_attributes(T).d)
end


function create_args_type_expr(PlotType, args::Nothing)
    return [], :()
end
function create_args_type_expr(PlotType, args)
    if Meta.isexpr(args, :tuple)
        all_fields = args.args
    else
        throw(ArgumentError("Recipe arguments need to be a tuple of the form (name::OptionalType, name,). Found: $(args)"))
    end
    if any(x -> !(Meta.isexpr(x, :(::)) || x isa Symbol), all_fields)
        throw(ArgumentError("All fields need to be of type `name::Type` or `name`. Found: $(all_fields)"))
    end
    types = []; names = Symbol[]
    if all(x -> x isa Symbol, all_fields)
        return all_fields, :()
    end
    for field in all_fields
        if field isa Symbol
            error("All fields need to be typed if one is. Please either type  all fields or none. Found: $(all_fields)")
        end
        push!(names, field.args[1])
        push!(types, field.args[2])
    end
    expr = quote
        Makie.types_for_plot_arguments(::Type{<:$(PlotType)}) = Tuple{$(esc.(types)...)}
    end
    return names, expr
end

macro recipe(Tsym::Symbol, attrblock)
    return create_recipe_expr(Tsym, nothing, attrblock)
end

macro recipe(Tsym::Symbol, args, attrblock)
    return create_recipe_expr(Tsym, args, attrblock)
end

function types_for_plot_arguments end

documented_attributes(_) = nothing

function attribute_names(T::Type{<:Plot})
    attr = documented_attributes(T)
    isnothing(attr) && return nothing
    return keys(attr.d)
end


function plot_attributes(scene, T)
    plot_attr = Makie.documented_attributes(T)
    if isnothing(plot_attr)
        return merge(default_theme(scene, T), default_theme(T))
    else
        return plot_attr.d
    end
end

function lookup_default(::Type{T}, scene, attribute::Symbol) where {T <: Plot}
    thm = theme(scene)
    metas = plot_attributes(scene, T)
    psym = plotsym(T)
    if haskey(thm, psym)
        overwrite = thm[psym]
        if haskey(overwrite, attribute)
            return to_value(overwrite[attribute])
        end
    end
    if haskey(metas, attribute)
        return lookup_default(metas[attribute], thm)
    else
        return nothing
    end
end

function default_theme(scene, T::Type{<:Plot})
    metas = documented_attributes(T)
    attr = Attributes()
    isnothing(metas) && return attr
    thm = theme(scene)
    _attr = attr.attributes
    for (k, meta) in metas.d
        _attr[k] = lookup_default(meta, thm)
    end
    return attr
end

function extract_docstring(str)
    if VERSION >= v"1.11" && str isa Base.Docs.DocStr
        return only(str.text::Core.SimpleVector)
    else
        return str
    end
end

function create_recipe_expr(Tsym, args, attrblock)
    funcname_sym = to_func_name(Tsym)
    funcname!_sym = Symbol("$(funcname_sym)!")
    funcname! = esc(funcname!_sym)
    PlotType = esc(Tsym)
    funcname = esc(funcname_sym)

    syms, arg_type_func = create_args_type_expr(PlotType, args)
    if !(attrblock isa Expr && attrblock.head === :block)
        throw(ArgumentError("Last argument is not a begin end block"))
    end
    # attrblock = expand_mixins(attrblock)
    # attrs = [extract_attribute_metadata(arg) for arg in attrblock.args if !(arg isa LineNumberNode)]

    docs_placeholder = gensym()
    attr_placeholder = gensym()

    q = quote
        # This part is as far as I know the only way to modify the docstring on top of the
        # recipe, so that we can offer the convenience of automatic augmented docstrings
        # but combine them with the simplicity of using a normal docstring.
        # The trick is to mark some variable (in this case a gensymmed placeholder) with the
        # Core.@__doc__ macro, which causes this variable to get assigned the docstring on top
        # of the @recipe invocation. From there, it can then be retrieved, modified, and later
        # attached to plotting function by using @doc again. We also delete the binding to the
        # temporary variable so no unnecessary docstrings stay in place.
        Core.@__doc__ $(esc(docs_placeholder)) = nothing
        binding = Docs.Binding(@__MODULE__, $(QuoteNode(docs_placeholder)))
        user_docstring = if haskey(Docs.meta(@__MODULE__), binding)
            _docstring = extract_docstring(@doc($docs_placeholder))
            delete!(Docs.meta(@__MODULE__), binding)
            _docstring
        else
            "No docstring defined.\n"
        end


        $(funcname)() = not_implemented_for($funcname)
        const $(PlotType){$(esc(:ArgType))} = Plot{$funcname, $(esc(:ArgType))}

        # This weird syntax is so that the output of the macrocall can be escaped because it
        # contains user expressions, without escaping what's passed to the macro because that
        # messes with its transformation logic. Because we escape the whole block with the macro,
        # we don't reference it by symbol but splice in the macro itself into the AST
        # with `var"@DocumentedAttributes"`
        const $attr_placeholder = $(
            esc(Expr(:macrocall, var"@DocumentedAttributes", LineNumberNode(@__LINE__), attrblock))
        )

        $(Makie).documented_attributes(::Type{<:$(PlotType)}) = $attr_placeholder

        $(Makie).plotsym(::Type{<:$(PlotType)}) = $(QuoteNode(Tsym))
        $(Makie).symbol_to_plot(::Val{$(QuoteNode(Tsym))}) = $PlotType

        function ($funcname)(args...; kw...)
            kwdict = Dict{Symbol, Any}(kw)
            return _create_plot($funcname, kwdict, args...)
        end
        function ($funcname!)(args...; kw...)
            kwdict = Dict{Symbol, Any}(kw)
            return _create_plot!($funcname, kwdict, args...)
        end

        $(arg_type_func)

        docstring_modified = make_recipe_docstring($PlotType, $(QuoteNode(Tsym)), $(QuoteNode(funcname_sym)), user_docstring)
        @doc docstring_modified $funcname_sym
        @doc "`$($(string(Tsym)))` is the plot type associated with plotting function `$($(string(funcname_sym)))`. Check the docstring for `$($(string(funcname_sym)))` for further information." $Tsym
        @doc "`$($(string(funcname!_sym)))` is the mutating variant of plotting function `$($(string(funcname_sym)))`. Check the docstring for `$($(string(funcname_sym)))` for further information." $funcname!_sym
        export $PlotType, $funcname, $funcname!
    end

    if !isempty(syms)
        push!(
            q.args,
            :(
                $(esc(:($(Makie).argument_names)))(::Type{<:$PlotType}, len::Integer) =
                    ($(QuoteNode.(syms)...),)
            ),
        )
    end

    return q
end


function make_recipe_docstring(P::Type{<:Plot}, Tsym, funcname_sym, docstring)
    io = IOBuffer()

    attr_docstrings = _attribute_docs(P)

    print(io, docstring)

    println(io, "## Plot type")
    println(io, "The plot type alias for the `$funcname_sym` function is `$Tsym`.")

    println(io, "## Attributes")
    println(io)

    names = sort(collect(attribute_names(P)))
    exprdict = attribute_default_expressions(P)
    for name in names
        default = exprdict[name]
        print(io, "**`", name, "`** = ", " `", default, "`  — ")
        println(io, something(attr_docstrings[name], "*No docs available.*"))
        println(io)
    end

    return String(take!(io))
end

# from MacroTools
isline(ex) = (ex isa Expr && ex.head === :line) || isa(ex, LineNumberNode)
rmlines(x) = x
function rmlines(x::Expr)
    # Do not strip the first argument to a macrocall, which is
    # required.
    return if x.head === :macrocall && length(x.args) >= 2
        Expr(x.head, x.args[1], nothing, filter(x -> !isline(x), x.args[3:end])...)
    else
        Expr(x.head, filter(x -> !isline(x), x.args)...)
    end
end

default_expr_string(x) = string(rmlines(x))
default_expr_string(x::String) = repr(x)

function extract_attribute_metadata(arg)
    has_docs = arg isa Expr && arg.head === :macrocall && arg.args[1] isa GlobalRef

    if has_docs
        docs = arg.args[3]
        attr = arg.args[4]
    else
        docs = nothing
        attr = arg
    end

    if !(attr isa Expr && attr.head === :(=) && length(attr.args) == 2)
        error("$attr is not a valid attribute line like :x[::Type] = default_value")
    end
    left = attr.args[1]
    default = attr.args[2]
    if left isa Symbol
        attr_symbol = left
        type = Any
    else
        if !(left isa Expr && left.head === :(::) && length(left.args) == 2)
            error("$left is not a Symbol or an expression such as x::Type")
        end
        attr_symbol = left.args[1]::Symbol
        type = left.args[2]
    end

    return (docs = docs, symbol = attr_symbol, type = type, default = default)
end

function expand_mixins(attrblock::Expr)
    return Expr(:block, mapreduce(expand_mixin, vcat, attrblock.args)...)
end

expand_mixin(x) = x
function expand_mixin(e::Expr)
    if e.head === :macrocall && e.args[1] === Symbol("@mixin")
        if length(e.args) != 3 && e.args[2] isa LineNumberNode && e.args[3] isa Symbol
            error("Invalid mixin, needs to be of the format `@mixin some_mixin`, got $e")
        end
        mixin_ex = getproperty(Makie, e.args[3])()::Expr
        if (mixin_ex.head !== :block)
            error("Expected mixin to be a block expression (such as generated by `quote`)")
        end
        return mixin_ex.args
    else
        e
    end
end

"""
    Plot(args::Vararg{DataType,N})

Returns the Plot type that represents the signature of `args`.
Example:

```julia
Plot(Vector{Point2f}) == Plot{plot, Tuple{<:Vector{Point2f}}}
```
This can be used to more conveniently create recipes for `plot(mytype)` without the recipe macro:

```julia
struct MyType ... end

function Makie.plot!(plot::Plot(MyType))
    ...
end

plot(MyType(...))
```
"""
function Plot(args::Vararg{DataType, N}) where {N}
    return Plot{plot, <:Tuple{args...}}
end

function Plot(::Type{T}) where {T}
    return Plot{plot, <:Tuple{T}}
end

function Plot(::Type{T1}, ::Type{T2}) where {T1, T2}
    return Plot{plot, <:Tuple{T1, T2}}
end

"""
    plottype(plot_args...)

Any custom argument combination that has a preferred way to be plotted should overload this.
e.g.:
```julia
    # make plot(rand(5, 5, 5)) plot as a volume
    plottype(x::Array{<: AbstractFloat, 3}) = Volume
```
"""
plottype(plot_args...) = Plot{plot} # default to dispatch to type recipes!

# plot types can overload this to throw errors or show warnings when deprecated attributes are used.
# this is easier than if every plot type added manual checks in its `plot!` methods
deprecated_attributes(_) = ()

struct InvalidAttributeError <: Exception
    type::Type
    object_name::String # Generic name like plot, block
    attributes::Set{Symbol}
end
function InvalidAttributeError(::Type{PT}, attributes::Set{Symbol}) where {PT <: Plot}
    return InvalidAttributeError(PT, "plot", attributes)
end

function print_columns(io::IO, v::Vector{String}; gapsize = 2, rows_first = true, cols = displaysize(io)[2])

    lens = length.(v) # for unicode ligatures etc this won't work, but we don't use those for attribute names
    function col_widths(ncols; rows_first)
        max_widths = zeros(Int, ncols)
        for (i, len) in enumerate(lens)
            nrows = ceil(Int, length(v) / ncols)
            j = rows_first ? fld1(i, nrows) : mod1(i, ncols)
            max_widths[j] = max(max_widths[j], len)
        end
        return max_widths
    end
    ncols = 1
    while true
        widths = col_widths(ncols; rows_first)
        aggregated_width = (sum(widths) + (ncols - 1) * gapsize)
        if aggregated_width > cols
            ncols = max(1, ncols - 1)
            break
        end
        ncols += 1
    end
    widths = col_widths(ncols; rows_first)

    nrows = ceil(Int, length(v) / ncols)

    for irow in 1:nrows
        for icol in 1:ncols
            idx = rows_first ? (icol - 1) * nrows + irow : (irow - 1) * ncols + icol
            if idx <= length(v)
                print(io, v[idx])
                remaining = widths[icol] - lens[idx]
            else
                remaining = widths[icol]
            end
            remaining += !(icol == ncols) * gapsize
            print(io, ' '^remaining)
        end
        println(io)
    end

    return
end

function _levenshtein_matrix(s1, s2)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L648
    a, b = collect(s1), collect(s2)
    m, n = length(a), length(b)
    d = Matrix{Int}(undef, m + 1, n + 1)
    d[1:(m + 1), 1] = 0:m
    d[1, 1:(n + 1)] = 0:n
    for i in 1:m
        for j in 1:n
            d[i + 1, j + 1] = min(d[i, j + 1] + 1, d[i + 1, j] + 1, d[i, j] + (a[i] != b[j]))
        end
    end
    return d
end
function _levenshtein(s1, s2)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L648
    d = _levenshtein_matrix(s1, s2)
    return d[end]
end
function _fuzzyscore(needle, haystack)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L631
    score = 0.0
    is, acro = _bestmatch(needle, haystack)
    score += (acro ? 2 : 1) * length(is)                # Matched characters
    score -= 2(length(needle) - length(is))             # Missing characters
    !acro && (score -= _avgdistance(is) / 10)             # Contiguous
    return !isempty(is) && (score -= sum(is) / length(is) / 100)   # Closer to beginning
end
function _matchinds(needle, haystack; acronym::Bool = false)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L602
    chars = collect(needle)
    is = Int[]
    lastc = '\0'
    for (i, char) in enumerate(haystack)
        while !isempty(chars) && isspace(first(chars))
            popfirst!(chars)
        end
        isempty(chars) && break
        if lowercase(char) == lowercase(chars[1]) && (!acronym || !isletter(lastc))
            push!(is, i)
            popfirst!(chars)
        end
        lastc = char
    end
    return is
end
function _longer(x, y)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L621
    return length(x) ≥ length(y) ? (x, true) : (y, false)
end
function _bestmatch(needle, haystack)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L623
    return _longer(
        _matchinds(needle, haystack, acronym = true),
        _matchinds(needle, haystack)
    )
end
function _avgdistance(xs)
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L627
    return isempty(xs) ? 0 : (xs[end] - xs[1] - length(xs) + 1) / length(xs)
end
function _levsort(search::String, candidates::Vector{String})
    # https://github.com/JuliaLang/julia/blob/6f3fdf7b36250fb95f512a2b927ad2518c07d2b5/stdlib/REPL/src/docview.jl#L666
    scores = map(candidates) do cand
        lev = Float64(_levenshtein(search, cand))
        fuz = -_fuzzyscore(search, cand)
        return (lev, -fuz)
    end
    candidates = candidates[sortperm(scores)]
    valid = _levenshtein(search, candidates[1]) < 3 # is the first close enough?
    return candidates[1], valid # Only return one suggestion per search
end
function find_nearby_attributes(attributes, candidates)
    d = Vector{Tuple{String, Bool}}(undef, length(attributes))
    any_close = false
    for (i, attr) in enumerate(attributes)
        candidate, valid = _levsort(String(attr), candidates)
        any_close = any_close || valid
        d[i] = (candidate, valid)
    end
    return d, any_close
end

function textdiff(X::String, Y::String)
    d = _levenshtein_matrix(X, Y)
    a, b = collect(X), collect(Y)
    m, n = length(a), length(b)

    # Backtrack to print the differences with style
    i, j = m, n
    results = Vector{Tuple{Char, Symbol}}()

    while i > 0 || j > 0
        if i > 0 && j > 0 && a[i] == b[j]
            # Characters match, print normally
            push!(results, (b[j], :normal))
            i -= 1
            j -= 1
        elseif i > 0 && j > 0 && d[i + 1, j + 1] == d[i, j] + 1
            # Substitution (different characters between `X` and `Y`)
            push!(results, (b[j], :orange))  # Highlighting the new character. Not showing the old one
            i -= 1
            j -= 1
        elseif j > 0 && d[i + 1, j + 1] == d[i + 1, j] + 1
            # Insertion in `Y` (character in `Y` but not in `X`)
            push!(results, (b[j], :red))  # Highlighting the added character
            j -= 1
        elseif i > 0 && d[i + 1, j + 1] == d[i, j + 1] + 1
            # Deletion in `X` (character in `X` but not in `Y`)
            i -= 1  # Just move the index for X. Not showing the deletion here.
        end
    end

    reverse!(results)
    io = IOBuffer()
    cio = IOContext(io, :color => true)

    for (char, clr) in results
        if clr == :normal
            print(io, char)
        else
            printstyled(cio, char; color = :blue, bold = true) # Ignoring different color choices here
        end
    end

    return String(take!(io))
end

function Base.showerror(io::IO, err::InvalidAttributeError)
    n = length(err.attributes)
    print(io, "Invalid attribute$(n > 1 ? "s" : "") ")
    for (j, att) in enumerate(err.attributes)
        j > 1 && print(io, j == length(err.attributes) ? " and " : ", ")
        printstyled(io, att; color = :red, bold = true)
    end
    print(io, " for $(err.object_name) type ")
    printstyled(io, err.type; color = :blue, bold = true)
    println(io, ".")
    nameset = sort(string.(collect(attribute_names(err.type))))
    attrs = string.(collect(err.attributes))
    possible_cands, any_close = find_nearby_attributes(attrs, nameset)
    any_close && println(io)
    if any_close && length(possible_cands) == 1
        print(io, "Did you mean ", textdiff(attrs[1], possible_cands[1][1]), "?")
        println(io)
    elseif any_close
        print(io, "Did you mean:")
        for (id, (passed, (suggestion, close))) in enumerate(zip(attrs, possible_cands))
            close || continue
            any_next = any(x -> x[2], view(possible_cands, (id + 1):length(possible_cands)))
            if (id == length(err.attributes)) || (id < length(err.attributes) && !any_next)
                print(io, " and")
            end
            print(io, " ", textdiff(passed, suggestion))
            if id < length(err.attributes) && any_next
                print(io, ",")
            end
        end
        println(io, "?")
        println(io)
    end
    println(io)
    println(io, "The available $(err.object_name) attributes for $(err.type) are:")
    println(io)
    print_columns(io, nameset; cols = displaysize(stderr)[2], rows_first = true)
    if err.type isa Plot
        allowlist = attribute_name_allowlist()
        println(io)
        println(io)
        println(io, "Generic attributes are:")
        println(io)
        print_columns(io, sort([string(a) for a in allowlist]); cols = displaysize(stderr)[2], rows_first = true)
    end
    return println(io)
end

function attribute_name_allowlist()
    return (
        :xautolimits, :yautolimits, :zautolimits, :label, :rasterize, :model, :transformation,
        :dim_conversions, :cycle, :clip_planes,
    )
end

function validate_attribute_keys(plot::P) where {P <: Plot}
    nameset = attribute_names(P)
    nameset === nothing && return
    allowlist = attribute_name_allowlist()
    deprecations = deprecated_attributes(P)::Tuple{Vararg{NamedTuple{(:attribute, :message, :error), Tuple{Symbol, String, Bool}}}}
    kw = plot.kw
    unknown = setdiff(keys(kw), nameset, allowlist, first.(deprecations))
    if !isempty(unknown)
        throw(InvalidAttributeError(P, unknown))
    end
    for (deprecated, message, should_error) in deprecations
        if haskey(kw, deprecated)
            full_message = "Keyword `$deprecated` is deprecated for plot type $P. $message"
            if should_error
                throw(ArgumentError(full_message))
            else
                @warn full_message
            end
        end
    end
    return
end
