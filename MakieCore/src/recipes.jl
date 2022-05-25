not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

to_func_name(x::Symbol) = Symbol(lowercase(string(x)))
# Fallback for PlotObject ...
# Will get overloaded by recipe Macro
plotsym(x) = :plot

plotkey(plot::PlotObject) where T <: AbstractPlot = Symbol(lowercase(string(plot.type)))

"""
     default_plot_signatures(funcname, funcname!, PlotType)
Creates all the different overloads for `funcname` that need to be supported for the plotting frontend!
Since we add all these signatures to different functions, we make it reusable with this function.
The `Core.@__doc__` macro transfers the docstring given to the Recipe into the functions.
"""
function default_plot_signatures(funcname, funcname!, PlotType)
    quote
        Core.@__doc__ function ($funcname)(args...; kw...)
            attributes = Dict{Symbol, Any}(kw)
            P = $(PlotType)
            figlike, plot_kw, plot_args = create_figurelike(P, attributes, args...)
            plot = PlotObject(P, Any[plot_args...], plot_kw)
            plot!(figlike, plot)
            return figurelike_return(figlike, plot)
        end

        Core.@__doc__ function ($funcname!)(args...; kw...)
            attributes = Dict{Symbol, Any}(kw)
            P = $(PlotType)
            figlike, plot_kw, plot_args = create_figurelike!(P, attributes, args...)
            plot = PlotObject(P, Any[plot_args...], plot_kw)
            plot!(figlike, plot)
            return figurelike_return!(figlike, plot)
        end

        function ($funcname!)(scene::AbstractScene, args...; kw...)
            P = $(PlotType)
            plot = PlotObject(P, Any[args...], Dict{Symbol, Any}(kw))
            plot!(scene, plot)
            return plot
        end

        function ($funcname!)(obj::PlotObject, args...; kw...)
            attributes = Dict{Symbol, Any}(kw)
            plot = PlotObject($(PlotType), Any[args...], attributes)
            plot!(obj, plot)
            return plot
        end
    end
end

"""
Each argument can be named for a certain plot type `P`. Falls back to `arg1`, `arg2`, etc.
"""
function argument_names(plot::P) where {P<:AbstractPlot}
    argument_names(plot.type, length(plot.converted))
end

function argument_names(::Type{<:AbstractPlot}, num_args::Integer)
    # this is called in the indexing function, so let's be a bit efficient
    ntuple(i -> Symbol("arg$i"), num_args)
end

# Since we can use PlotObject like a scene in some circumstances, we define this alias
theme(x::SceneLike, args...) = theme(x.parent, args...)
theme(x::AbstractScene) = x.theme
theme(x::AbstractScene, key) = deepcopy(x.theme[key])
theme(x::AbstractPlot, key) = deepcopy(x.attributes[key])

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
            plot_color => :red
        )
    end

This macro expands to several things. Firstly a type definition:

    const MyPlot{ArgTypes} = PlotObject{myplot, ArgTypes}

The type parameter of `PlotObject` contains the function instead of e.g. a
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
            plot_color => :red
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
        struct $(PlotType) <: AbstractPlot; end
        $(PlotType)(args...; kw...) = PlotObject($PlotType, Any[args...], Dict{Symbol, Any}(kw))
        $(MakieCore).plotsym(::Type{<:$(PlotType)}) = $(QuoteNode(Tsym))
        $(default_plot_signatures(funcname, funcname!, PlotType))
        $(MakieCore).default_theme(scene, ::$(PlotType)) = $(esc(theme_func))(scene)

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

"""
    `plottype(plot_args...)`

Any custom argument combination that has a preferred way to be plotted should overload this.
e.g.:
```julia
    # make plot(rand(5, 5, 5)) plot as a volume
    plottype(x::Array{<: AbstractFloat, 3}) = Volume
```
"""
plottype(@nospecialize(plot_args...)) = Scatter
plottype(::Type{P}, @nospecialize(plot_args...)) where P <: AbstractPlot = P


function figurelike_return end
function figurelike_return! end

function create_figurelike end
function create_figurelike! end

function plot(args...; kw...)
    P = plottype(args...)
    attributes = Dict{Symbol, Any}(kw)
    figlike, plot_kw, plot_args = create_figurelike(P, attributes, args...)
    plot = PlotObject(P, Any[plot_args...], plot_kw)
    plot!(figlike, plot)
    return figurelike_return(figlike, plot)
end

function plot!(args...; kw...)
    P = plottype(args...)
    attributes = Dict{Symbol, Any}(kw)
    figlike, plot_kw, plot_args = create_figurelike!(P, attributes, args...)
    plot = PlotObject(P, Any[plot_args...], plot_kw)
    plot!(figlike, plot)
    return figurelike_return!(figlike, plot)
end
