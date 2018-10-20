to_func_name(x::Symbol) = string(x) |> lowercase |> Symbol



"""
     default_plot_signatures(funcname, PlotType)
Creates all the different overloads for `funcname` that need to be supported for the plotting frontend!
Since we add all these signatures to different functions, we make it reusable with this function
"""
function default_plot_signatures(funcname, funcname!, PlotType)
    quote
        """
            $($(funcname))(args...; attributes...)

        Command works on plot args 1:N and accepts keyword arguments to style the plot. Creates a new scene!
        """
        ($funcname)(args...; attributes...) = plot!(Scene(), $PlotType, Attributes(attributes), args...)

        """
            $($(funcname!))(args...; attributes...)

        Command works on plot args 1:N and accepts keyword arguments to style the plot. Adds new plot to `current_scene()`
        """
        ($funcname!)(args...; attributes...) = plot!(current_scene(), $PlotType, Attributes(attributes), args...)


        """
            $($(funcname!))(scene::SceneLike, args...; attributes...)

        Command works on plot args 1:N and accepts keyword arguments to style the plot. Adds new plot to `scene`!
        """
        ($funcname!)(scene::SceneLike, args...; attributes...) = plot!(scene, $PlotType, Attributes(attributes), args...)

        """
            $($(funcname))(attributes::Attributes, args...; attributes...)

        Like $($(funcname))(args...; attributes...) but accepts a theme as first argument. Creates a new scene!
        """
        ($funcname)(attributes::Attributes, args...; kw_attributes...) = plot!(Scene(), $PlotType, merge!(Attributes(kw_attributes), attributes), args...)

        """
            $($(funcname!))(attributes::Attributes, args...; attributes...)

        Like $($(funcname!))(args...; attributes...) but accepts a theme as first argument. Adds new plot to `current_scene()`!
        """
        ($funcname!)(attributes::Attributes, args...; kw_attributes...) = plot!(current_scene(), $PlotType, merge!(Attributes(kw_attributes), attributes), args...)

        """
            $($(funcname!))(attributes::Attributes, args...; attributes...)

        Like $($(funcname!))(scene, args...; attributes...) but accepts a theme as second argument. Adds new plot to `scene`!
        """
        ($funcname!)(scene::SceneLike, attributes::Attributes, args...; kw_attributes...) = plot!(scene, $PlotType, merge!(Attributes(kw_attributes), attributes), args...)
    end
end


"""

# type recipe are really simple and just overload the argument conversion pipeline.
convert_arguments(P::Type{<:AbstractPlot}, x::MyType) = convert_arguments(P, rand(10, 10))
# only apply this for a certain plot type:
convert_arguments(P::Type{<:Scatter}, x::MyType) = convert_arguments(P, rand(10, 10))
# optionally define the plotting type, when someone just says plot(x::MyType)
# - will fall back to whatever the standard plot type for what you return from argument_convert is!
plottype(::MyType) = Surface

# full recipes:

# (x, y, z) && themes are optional
@recipe(MyPlot, x, y, z) do scene
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
macro recipe(theme_func, Tsym::Symbol, args::Symbol...)
    funcname_sym = to_func_name(Tsym)
    funcname! = esc(Symbol("$(funcname_sym)!"))
    PlotType = esc(Tsym)
    funcname = esc(funcname_sym)
    expr = quote
        $(funcname)() = not_implemented_for($funcname)
        if !@isdefined($(Tsym))# make this work with interactive usage
            const $(PlotType){$(esc(:ArgType))} = Combined{$funcname, $(esc(:ArgType))}
        end
        Base.show(io::IO, ::Type{<: $PlotType}) = print(io, $(string(Tsym)), "{...}")
        $(default_plot_signatures(funcname, funcname!, PlotType))
        Base.@__doc__($funcname)
        AbstractPlotting.default_theme(scene, ::Type{<: $PlotType}) = $(esc(theme_func))(scene)
        export $PlotType, $funcname, $funcname!
    end
    if !isempty(args)
        push!(expr.args, :($(esc(:argument_names))(::Type{<: $PlotType}, len::Integer) = $args))
    end
    expr
end


macro atomic(theme_func, Tsym::Symbol)
    funcname_sym = to_func_name(Tsym)
    funcname! = esc(Symbol("$(funcname_sym)!"))
    PlotType = esc(Tsym)
    funcname = esc(funcname_sym)
    quote
        $(funcname)() = not_implemented_for($funcname)
        Base.@__doc__($funcname)
        const $PlotType{$(esc(:ArgType))} = Atomic{$funcname, $(esc(:ArgType))}
        Base.show(io::IO, ::Type{<: $PlotType}) = print(io, $(string(Tsym)), "{...}")
        $(default_plot_signatures(funcname, funcname!, PlotType))
        AbstractPlotting.default_theme(scene, ::Type{<: $PlotType}) = $theme_func(scene)
        export $PlotType, $funcname, $funcname!
    end
end
