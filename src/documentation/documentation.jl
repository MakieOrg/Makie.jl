# ==========================================================
# Help functions
# help function defaults to STDOUT output when io is not specified
"""
    help(func[; extended = false])

Welcome to the main help function of `Makie.jl` / `Makie.jl`.

For help on a specific function's arguments, type `help_arguments(function_name)`.

For help on a specific function's attributes, type `help_attributes(plot_Type)`.

Use the optional `extended = true` keyword argument to see more details.
"""
help(func; kw_args...) = help(stdout, func; kw_args...) #defaults to STDOUT

function help(io::IO, input::Type{T}; extended = false) where T <: AbstractPlot
    buffer = IOBuffer()
    _help(buffer, input; extended = extended)
    Markdown.parse(String(take!(buffer)))
end

function help(io::IO, input::Function; extended = false)
    buffer = IOBuffer()
    _help(buffer, to_type(input); extended = extended)
    Markdown.parse(String(take!(buffer)))
end

# Internal help functions
function _help(io::IO, input::Type{T}; extended = false) where T <: AbstractPlot
    func = to_func(input)
    str = to_string(input)

    # Print docstrings
    println(io, Base.doc(func))

    # Arguments
    help_arguments(io, func)
    if extended
        println(io, "Please refer to [`convert_arguments`](@ref) to find the full list of accepted arguments\n")
    end

    # Keyword arguments
    help_attributes(io, input; extended = extended)
    if extended
        println(io, "You can see usage examples of `$func` by running:\n")
        println(io, "`example_database($func)`\n")
    end
end

function _help(io::IO, input::Function; extended = false)
    _help(io, to_type(input); extended = extended)
end
"""
    help_arguments([io], func)

Returns a list of signatures for function `func`.
"""
help_arguments(x) = help_arguments(stdout, x)
# Other help functions

function help_arguments(io::IO, x::Function)
    @warn("argument help isn't currently implemented correctly")
    #TODO: will need to parse what arguments from convert_arguments apply to x
    println(io, "`$x` has the following function signatures: \n")
    println(io, "```")
    println(io, "  ", "(Vector, Vector)")
    println(io, "  ", "(Vector, Vector, Vector)")
    println(io, "  ", "(Matrix)")
    println(io, "```")
end

"""
    help_attributes([io], Union{PlotType, PlotFunction}; extended = false)

Returns a list of attributes for the plot type `Typ`.
The attributes returned extend those attributes found in the `default_theme`.

Use the optional keyword argument `extended` (default = `false`) to show
in addition the default values of each attribute.
usage:
```julia
>help_attributes(scatter)
    alpha
    color
    colormap
    colorrange
    distancefield
    glowcolor
    glowwidth
    linewidth
    marker
    marker_offset
    markersize
    overdraw
    rotations
    strokecolor
    strokewidth
    transform_marker
    transparency
    uv_offset_width
    visible
```
"""
help_attributes(x; kw...) = help_attributes(stdout, x; kw...)

function help_attributes(io::IO, Typ::Type{T}; extended = false) where T <: AbstractPlot
    # get and sort list of attributes from function (using Scatter as an example)
    # this is a symbolic dictionary, with symbols as the keys
    attributes = default_theme(nothing, Typ)

    # manually filter out some attributes
    filter_keys = Symbol.([:fxaa, :model, :transformation])

    # count the character length of the longest key
    longest = 0
    allkeys = sort(collect(keys(attributes)))
    for k in allkeys
        currentlength = length(string(k))
        if currentlength > longest
            longest = currentlength
        end
    end
    extra_padding = 2

    # increase verbosity if extended kwarg is on
    if extended
        println(io, "Available attributes and their defaults for `$Typ` are: \n")
    else
        println(io, "Available attributes for `$Typ` are: \n")
    end
    println(io, "```")
    if extended
        for attribute in allkeys
            value = attributes[attribute]
            if !(attribute in filter_keys)
                padding = longest - length(string(attribute)) + extra_padding
                print(io, "  ", attribute, " "^padding)
                show(io, isnothing(Makie.to_value(value)) ? "nothing" : to_value(value))
                print(io, "\n")
            end
        end
    else
        for attribute in allkeys
            value = attributes[attribute]
            if !(attribute in filter_keys)
                println(io, "  ", attribute)
            end
        end
    end
    println(io, "```")
end

function help_attributes(io::IO, func::Function; extended = false)
    help_attributes(io, to_type(func); extended = extended)
end

function help_attributes(io::IO, Typ::Type{T}; extended = false) where T <: Axis3D
    if extended
        println(io, "OldAxis attributes and their defaults for `$Typ` are: \n")
    else
        println(io, "OldAxis attributes for `$Typ` are: \n")
    end
    attributes = default_theme(nothing, Typ)
    println(io, "```")
    print_rec(io, attributes, 1; extended = extended)
    println(io, "```")
end

# ==========================================================
# Supporting functions for the help functions
"""
    to_func(Typ)

Maps the input of a Type name to its cooresponding function.
"""
function to_func(Typ::Type{<: AbstractPlot{F}}) where F
    F
end

to_func(func::Function) = func


"""
    to_type(func)

Maps the input of a function name to its cooresponding Type.
"""
to_type(func::Function) = Combined{func}

to_type(Typ::Type{T}) where T <: AbstractPlot = Typ

"""
    to_string(func)

Turns the input of a function name or plot Type into a string.
"""
function to_string(func::Function)
    str = string(typeof(func).name.mt.name)
end

to_string(Typ::Type{T}) where T <: AbstractPlot = to_string(to_func(Typ))
to_string(s::Symbol) = string(s)
to_string(s::String) = s

"""
    print_rec(io::IO, dict, indent::Int = 1[; extended = false])

Traverses a dictionary `dict` and recursively print out its keys and values
in a nicely-indented format.

Use the optional `extended = true` keyword argument to see more details.
"""
function print_rec(io::IO, dict, indent::Int = 1; extended = false)
    for (k, v) in dict
        print(io, " "^(indent*4), k)
        if isa(to_value(v), Makie.Attributes)
            print(io, ": ")
            println(io)
            print_rec(io, v.attributes, indent + 1; extended = extended)
        elseif isa(v, Observable)
            if extended
                print(io, ": ")
                println(io, isnothing(to_value(v)) ? "nothing" : to_value(v))
            else
                println(io)
            end
        else
            println(io, v)
        end
    end
end
