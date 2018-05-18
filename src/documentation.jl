# TODO: figure out where to put the below
"""
# General function signatures and usage
`func` are the function names, e.g. `lines`, `scatter`, `surface`, etc.

# creates a new plot + scene object
`func(args...; kw_args...)`

# creates a new plot as a subscene of a scene object
`func(scene::SceneLike, args...; kw_args...)`

# adds a plot in-place to the current_scene()
`func!(args...; kw_args...)`

# adds a plot in-place to the current_scene() as a subscene
`func!(scene::SceneLike, args...; kw_args...)`

# `[]` means an optional argument. `Attributes` is a Dictionary file of attributes:
`func[!]([scene], kw_args::Attributes, args...)`

"""


to_func(::Type{T}) where T <: Makie.AbstractPlot = string("Makie.",lowercase(split(string(T),"Makie.")[2]))
to_type(::Func) where Func <: Function = Type(string("Makie.",titlecase(split(string(Func),"Makie.")[2])))

# choose one to redirect
help(::Type{T}) where {T = help(to_func(T))}
#help(::Func) where Func = help(to_type(T))

# choose one to implement the functionality
function help(f::Function)
    Typ = to_type(f)
    help_arguments(f)
    help_attributes(Typ) #TODO: need to convert type to Makie.AbstractPlot, otherwise this fails
end

function help(Typ::Type{T}) where T <: Makie.AbstractPlot
    f = to_func(Typ)
    help_arguments(f) #TODO: need to convert type to Function, otherwise this fails
    help_attributes(Typ)
end

"""
    help(func)

Welcome to Makie.

For help on a specific function's arguments, type `help_arguments(function_name)`.
For help on a specific function's attributes, type `help_attributes(function_name)`.
"""
function help(func::Function)
    # TODO: this doesn't work 100% yet. help_attributes accepts a Type,
    # e.g. Makie.Scatter, whereas help_signatures accepts a Function,
    # e.g. Makie.scatter?

    """
    # Arguments
    $(func) has the following function signatures (arguments):
    $(help_arguments(func))

    # Keyword arguments
    $(func) accepts the following attrbutes (keyword arguments):
    $(help_attributes(func))

    # You can use $(func) in the following way:
    @query_database [$(func)]
    """
end


"""
    help_signatures(func)

Returns a list of signatures for function `func`.
"""
function help_arguments(x::Function)
    # hard-coded for now, per Simon
    io = IOBuffer()

    println(io, "$x accepts:")
    println(io, "(Vector, Vector)")
    println(io, "(Vector, Vector, Vector)")
    println(io, "(Matrix)")
    str = String(take!(io))
    println(str)
end


"""
    help_attributes(func)

Returns a list of attributes for function `func`.
The attributes returned extend those attribues found in the `default_theme`.

Use the optional keyword argument `extended` (default = `false`) to show
in addition the default values of each attribute.
"""
function help_attributes(func::Type{T}; extended = false) where T <: Makie.AbstractPlot # TODO: Not sure if this is a good way to generalize for any function
    # TODO: calling it a func, but it's really a type? e.g. Makie.Scatter
    # TODO: implement error-catching

    # get list of attributes from function (using Scatter as an example)
    # this is a symbolic dictionary, with symbols as the keys
    attributes = Makie.default_theme(nothing, func)

    # get list of default attributes to filter out
    # and show only the attributes that are not default attributes
    filter_keys = collect(keys(Makie.default_theme(nothing)))

    io = IOBuffer()

    # increase verbosity if extended kwarg is on
    if extended
        println("Available attributes for ", func, " are: \n")
        for (attribute, value) in attributes
            if !(attribute in filter_keys)
                println(io, "  ", attribute, ", with the default value: ", Makie.value(value))
            end
        end
    else
        println("Available attributes for ", func, " are: \n")
        for (attribute, value) in attributes
            if !(attribute in filter_keys)
                println(io, "  ", attribute)
            end
        end
    end
    str = String(take!(io))
    println(str)
end
