not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

to_func_name(x::Symbol) = Symbol(lowercase(string(x)))
# Fallback for Plot ...
# Will get overloaded by recipe Macro
plotsym(x) = :plot

function func2string(func::F) where F <: Function
    string(F.name.mt.name)
end

plotfunc(::Plot{F}) where F = F
plotfunc(::Type{<: AbstractPlot{Func}}) where Func = Func
plotfunc(::T) where T <: AbstractPlot = plotfunc(T)
function plotfunc(f::Function)
    if endswith(string(nameof(f)), "!")
        name = Symbol(string(nameof(f))[begin:end-1])
        return getproperty(parentmodule(f), name)
    else
        return f
    end
end

function plotfunc!(x)
    F = plotfunc(x)::Function
    name = Symbol(nameof(F), :!)
    return getproperty(parentmodule(F), name)
end

func2type(x::T) where T = func2type(T)
func2type(x::Type{<: AbstractPlot}) = x
func2type(f::Function) = Plot{plotfunc(f)}

plotkey(::Type{<: AbstractPlot{Typ}}) where Typ = Symbol(lowercase(func2string(Typ)))
plotkey(::T) where T <: AbstractPlot = plotkey(T)
plotkey(::Nothing) = :scatter
plotkey(any) = nothing


argtypes(::T) where {T <: Tuple} = T

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
function argument_names(plot::P) where {P<:AbstractPlot}
    argument_names(P, length(plot.converted))
end

function argument_names(::Type{<:AbstractPlot}, num_args::Integer)
    # this is called in the indexing function, so let's be a bit efficient
    ntuple(i -> Symbol("arg$i"), num_args)
end

# Since we can use Plot like a scene in some circumstances, we define this alias
theme(x::SceneLike, args...) = theme(x.parent, args...)
theme(x::AbstractScene) = x.theme
theme(x::AbstractScene, key; default=nothing) = deepcopy(get(x.theme, key, default))
theme(x::AbstractPlot, key; default=nothing) = deepcopy(get(x.attributes, key, default))

Attributes(x::AbstractPlot) = x.attributes

default_theme(scene, T) = Attributes()

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
        const $(PlotType){$(esc(:ArgType))} = Plot{$funcname,$(esc(:ArgType))}
        $(MakieCore).plotsym(::Type{<:$(PlotType)}) = $(QuoteNode(Tsym))
        Core.@__doc__ ($funcname)(args...; kw...) = _create_plot($funcname, Dict{Symbol, Any}(kw), args...)
        ($funcname!)(args...; kw...) = _create_plot!($funcname, Dict{Symbol, Any}(kw), args...)
        $(MakieCore).default_theme(scene, ::Type{<:$PlotType}) = $(esc(theme_func))(scene)
        export $PlotType, $funcname, $funcname!
    end
    if !isempty(args)
        push!(
            expr.args,
            :(
                $(esc(:($(MakieCore).argument_names)))(::Type{<:$PlotType}, len::Integer) =
                    $args
            ),
        )
    end
    expr
end

function attribute_names end
function documented_attributes end # this can be used for inheriting from other recipes

attribute_names(_) = nothing

Base.@kwdef struct AttributeMetadata
    docstring::Union{Nothing,String}
    default_expr::String # stringified expression, just needed for docs purposes
end

update_metadata(am1::AttributeMetadata, am2::AttributeMetadata) = AttributeMetadata(
    am2.docstring === nothing ? am1.docstring : am2.docstring,
    am2.default_expr # TODO: should it be possible to overwrite only a docstring by not giving a default expr?
)

struct DocumentedAttributes
    d::Dict{Symbol,AttributeMetadata}
    closure::Function
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

            push!(metadata_exprs, quote
                am = AttributeMetadata(; docstring = $docs, default_expr = $(_default_expr_string(default)))
                if haskey(d, $(QuoteNode(sym)))
                    d[$(QuoteNode(sym))] = update_metadata(d[$(QuoteNode(sym))], am)
                else
                    d[$(QuoteNode(sym))] = am
                end
            end)

            if default isa Expr && default.head === :macrocall && default.args[1] === Symbol("@inherit")
                if length(default.args) ∉ (3, 4)
                    error("@inherit works with 1 or 2 arguments, expression was $d")
                end
                if !(default.args[3] isa Symbol)
                    error("Argument 1 of @inherit must be a Symbol, got $(default.args[3])")
                end
                key = default.args[3]
                _default = get(default.args, 4, :(error("Inherited key $($(QuoteNode(key))) not found in theme with no fallback given.")))
                # first check scene theme
                # then default value
                d = :(
                    dict[$(QuoteNode(sym))] = if haskey(thm, $(QuoteNode(key)))
                        to_value(thm[$(QuoteNode(key))]) # only use value of theme entry
                    else
                        $(esc(_default))
                    end
                )
                push!(closure_exprs, d)
            else
                push!(closure_exprs, :(
                    dict[$(QuoteNode(sym))] = $(esc(default))
                ))
            end
        elseif is_mixin_line
            # this intermediate variable is needed to evaluate each mixin only once
            # and is inserted at the start of the final code block
            gsym = gensym("mixin")
            mixin = only(attr.args)
            push!(mixin_exprs, quote
                $gsym = $(esc(mixin))
                if !($gsym isa DocumentedAttributes)
                    error("Mixin was not a DocumentedAttributes but $($gsym)")
                end
            end)

            # the actual runtime values of the mixed in defaults
            # are computed using the closure stored in the DocumentedAttributes
            closure_exp = quote
                # `scene` and `dict` here are defined below where this exp is interpolated into
                merge!(dict, $gsym.closure(scene))
            end
            push!(closure_exprs, closure_exp)

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

    quote
        $(mixin_exprs...)
        d = Dict{Symbol,AttributeMetadata}()
        $(metadata_exprs...)
        closure = function (scene)
            thm = theme(scene)
            dict = Dict{Symbol,Any}()
            $(closure_exprs...)
            return dict
        end
        DocumentedAttributes(d, closure)
    end
end

function is_attribute(T::Type{<:Plot}, sym::Symbol)
    sym in attribute_names(T)
end

function attribute_default_expressions(T::Type{<:Plot})
    Dict(k => v.default_expr for (k, v) in documented_attributes(T).d)
end

function _attribute_docs(T::Type{<:Plot})
    Dict(k => v.docstring for (k, v) in documented_attributes(T).d)
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
    if all(x-> x isa Symbol, all_fields)
        return all_fields, :()
    end
    for field in all_fields
        if  field isa Symbol
            error("All fields need to be typed if one is. Please either type  all fields or none. Found: $(all_fields)")
        end
        push!(names, field.args[1])
        push!(types, field.args[2])
    end
    expr = quote
        MakieCore.types_for_plot_arguments(::Type{<:$(PlotType)}) = Tuple{$(esc.(types)...)}
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
        const $(PlotType){$(esc(:ArgType))} = Plot{$funcname,$(esc(:ArgType))}

        # This weird syntax is so that the output of the macrocall can be escaped because it
        # contains user expressions, without escaping what's passed to the macro because that
        # messes with its transformation logic. Because we escape the whole block with the macro,
        # we don't reference it by symbol but splice in the macro itself into the AST
        # with `var"@DocumentedAttributes"`
        const $attr_placeholder = $(
            esc(Expr(:macrocall, var"@DocumentedAttributes", LineNumberNode(@__LINE__), attrblock))
        )

        $(MakieCore).documented_attributes(::Type{<:$(PlotType)}) = $attr_placeholder

        $(MakieCore).plotsym(::Type{<:$(PlotType)}) = $(QuoteNode(Tsym))
        function ($funcname)(args...; kw...)
            kwdict = Dict{Symbol, Any}(kw)
            _create_plot($funcname, kwdict, args...)
        end
        function ($funcname!)(args...; kw...)
            kwdict = Dict{Symbol, Any}(kw)
             _create_plot!($funcname, kwdict, args...)
        end

        function $(MakieCore).attribute_names(T::Type{<:$(PlotType)})
            keys(documented_attributes(T).d)
        end

        function $(MakieCore).default_theme(scene, T::Type{<:$(PlotType)})
            Attributes(documented_attributes(T).closure(scene))
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
                $(esc(:($(MakieCore).argument_names)))(::Type{<:$PlotType}, len::Integer) =
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
  if x.head === :macrocall && length(x.args) >= 2
    Expr(x.head, x.args[1], nothing, filter(x->!isline(x), x.args[3:end])...)
  else
    Expr(x.head, filter(x->!isline(x), x.args)...)
  end
end

_default_expr_string(x) = string(rmlines(x))
_default_expr_string(x::String) = repr(x)

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

    (docs = docs, symbol = attr_symbol, type = type, default = default)
end

function make_default_theme_expr(attrs, scenesym::Symbol)

    exprs = map(attrs) do a

        d = a.default
        if d isa Expr && d.head === :macrocall && d.args[1] == Symbol("@inherit")
            if length(d.args) != 4
                error("@inherit works with exactly 2 arguments, expression was $d")
            end
            if !(d.args[3] isa QuoteNode)
                error("Argument 1 of @inherit must be a :symbol, got $(d.args[3])")
            end
            key, default = d.args[3:4]
            # first check scene theme
            # then default value
            d = quote
                if haskey(thm, $key)
                    to_value(thm[$key]) # only use value of theme entry
                else
                    $default
                end
            end
        end

        :(attr[$(QuoteNode(a.symbol))] = $d)
    end

    quote
        thm = theme($scenesym)
        attr = Attributes()
        $(exprs...)
        attr
    end
end

function expand_mixins(attrblock::Expr)
    Expr(:block, mapreduce(expand_mixin, vcat, attrblock.args)...)
end

expand_mixin(x) = x
function expand_mixin(e::Expr)
    if e.head === :macrocall && e.args[1] === Symbol("@mixin")
        if length(e.args) != 3 && e.args[2] isa LineNumberNode && e.args[3] isa Symbol
            error("Invalid mixin, needs to be of the format `@mixin some_mixin`, got $e")
        end
        mixin_ex = getproperty(MakieCore, e.args[3])()::Expr
        if (mixin_ex.head !== :block)
            error("Expected mixin to be a block expression (such as generated by `quote`)")
        end
        return mixin_ex.args
    else
        e
    end
end

"""
    Plot(args::Vararg{<:DataType,N})

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
function Plot(args::Vararg{DataType,N}) where {N}
    Plot{plot, <:Tuple{args...}}
end

function Plot(::Type{T}) where {T}
    Plot{plot, <:Tuple{T}}
end

function Plot(::Type{T1}, ::Type{T2}) where {T1,T2}
    Plot{plot, <:Tuple{T1,T2}}
end

"""
    `plottype(plot_args...)`

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
    plottype::Type
    attributes::Set{Symbol}
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
        aggregated_width = (sum(widths) + (ncols-1) * gapsize)
        if aggregated_width > cols
            ncols = max(1, ncols-1)
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
            print(io, ' ' ^ remaining)
        end
        println(io)
    end

    return
end

function Base.showerror(io::IO, i::InvalidAttributeError)
    n = length(i.attributes)
    print(io, "Invalid attribute$(n > 1 ? "s" : "") ")
    for (j, att) in enumerate(i.attributes)
        j > 1 && print(io, j == length(i.attributes) ? " and " : ", ")
        printstyled(io, att; color = :red, bold = true)
    end
    print(io, " for plot type ")
    printstyled(io, i.plottype; color = :blue, bold = true)
    println(io, ".")
    nameset = sort(string.(collect(attribute_names(i.plottype))))
    println(io)
    println(io, "The available plot attributes for $(i.plottype) are:")
    println(io)
    print_columns(io, nameset; cols = displaysize(stderr)[2], rows_first = true)
    allowlist = attribute_name_allowlist()
    println(io)
    println(io)
    println(io, "Generic attributes are:")
    println(io)
    print_columns(io, sort([string(a) for a in allowlist]); cols = displaysize(stderr)[2], rows_first = true)
    println(io)
end

function attribute_name_allowlist()
    return (:xautolimits, :yautolimits, :zautolimits, :label, :rasterize, :model, :transformation,
            :dim_conversions, :cycle, :clip_planes)
end

function validate_attribute_keys(plot::P) where {P<:Plot}
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
