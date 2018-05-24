to_func_name(x::Symbol) = string(x) |> lowercase |> Symbol

"""

# type recipe are really simple and just overload the argument conversion pipeline.
argument_convert(x::MyType) = (rand(10, 10),)
# only apply this for a certain plot type:
argument_convert(::Type{<: Scatter}, x::MyType) = (rand(10, 10),)
# optionally define the plotting type, when someone just says plot(x::MyType)
# - will fall back to whatever the standard plot type for what you return from argument_convert is!
plottype(::MyType) = Surface

# full recipes:

# (x, y, z) && themes are optional
@recipe(myplot, x, y, z) do scene
    Theme(
        plot_color => :red
    )
end
# this macro defines the following:

const Myplot{ArgTypes} = Combined{myplot, ArgTypes}
# the type parameter contains the function instead of e.g. a symbol. This way
# the mapping from Myplot to myplot is safer and simpler.
# Downside, we always need a function. Would there be rejection against that?

# all the signatures to make it nice to use:
myplot(args...; kw_args...) = ...
myplot!(scene, args...; kw_args...) = ...
myplot(kw_args::Dict, args...) = ...
myplot!(scene, kw_args::Dict, args...) = ...
#etc (not 100% settled what signatures there will be)

# the next one is optional, but it will allow to say plot_object[:x] to fetch the first argument
# from the call `plot_object = myplot(rand(10), rand(10), rand(10))`.
# If you leave out the (x, y, z)
# in the recipe macro, it will default to plot_object[1] (always works), and plot_object[:arg1]
argument_names(::Type{<: MyPlot}) = (:x, :y, :z)

# this function will insert the theme into any scene that plots Myplot.
function default_theme(scene, ::Myplot)
    Theme(
        plot_color => :red
    )
end
#-----------------------------
# Implement the recipe
function plot!(plot::MyPlot)
    # normal plotting code, building up on any previously defined recipes
    # or atomic plotting operations, and adds it to the combined `plot`:
    lines!(plot, rand(10), color = plot[:plot_color])
    plot!(plot, plot[:x], plot[:y])
    plot
end

# Add specialization
const MyVolume = MyPlot{Tuple{ArgTypes <: AbstractArray{<: AbstractFloat, 3}}}
argument_names(::Type{<: MyVolume}) = (:volume,) # again, optional
function plot!(plot::MyVolume)
    # plot a volume with a colormap going from fully transparent to plot_color
    volume!(plot, plot[:volume], colormap = :transparent => plot[:plot_color])
    plot
end
"""
macro recipe(theme_func, T::Symbol, args::Symbol...)
    funcname = to_func_name(T)
    funcname! = esc(Symbol("$(funcname)!"))
    T = esc(T)
    funcname = esc(funcname)
    expr = quote
        $funcname() = not_implemented_for($funcname)
        const $(T){$(esc(:ArgType))} = Combined{$funcname, $(esc(:ArgType))}
        $funcname(args...; attributes...) = plot($T, args...; attributes...)
        $funcname!(scene::SceneLike, args...; attributes...) = plot!(scene, $T, args...; attributes...)
        $funcname(attributes::Attributes, args...) = plot($T, attributes, args...)
        $funcname!(scene::SceneLike, attributes::Attributes, args...) = plot!(scene, $T, attributes, args...)
        $funcname!(attributes::Attributes, args...) = plot!(current_scene(), $T, attributes, args...)
        $funcname!(args...; kw_args...) = plot!(current_scene(), $T, Attributes(kw_args), args...)

        Base.@__doc__($funcname)
        $(esc(:default_theme))(scene::SceneLike, ::Type{<: $T}) = $theme_func(scene)

        export $T, $funcname, $funcname!
    end
    if isempty(args)
        quoted_args = map(QuoteNode, args)
        push!(expr.args, :($(esc(:argument_names))(::Type{<: $T}) = $quoted_args))
    end
    expr
end


macro atomic(theme_func, T::Symbol)
    funcname = to_func_name(T)
    funcname! = esc(Symbol("$(funcname)!"))
    T = esc(T)
    funcname = esc(funcname)
    quote
        $funcname() = not_implemented_for($funcname)
        Base.@__doc__($funcname)
        const $T{$(esc(:ArgType))} = Atomic{$funcname, $(esc(:ArgType))}

        $funcname(args...; attributes...) = plot($T, args...; attributes...)
        $funcname!(scene::SceneLike, args...; attributes...) = plot!(scene, $T, args...; attributes...)
        $funcname(attributes::Attributes, args...) = plot($T, attributes, args...)
        $funcname!(scene::SceneLike, attributes::Attributes, args...) = plot!(scene, $T, attributes, args...)

        $funcname!(attributes::Attributes, args...) = plot!(current_scene(), $T, attributes, args...)
        $funcname!(args...; kw_args...) = plot!(current_scene(), $T, Attributes(kw_args), args...)

        $(esc(:default_theme))(scene::SceneLike, ::Type{<: $T}) = $theme_func(scene)

        export $T, $funcname, $funcname!
    end
end
