
help_arguments(x) = ""

function help_arguments(x::Type{Scatter})
    """

    """
end

help(io = STDOUT, other_args) = nothing

help(func, io = STDOUT) = ...

help(iofunc) = ...
help(func) = help(STDOUT, func)


help(func) = help(STDOUT, func)

function help(io::IO, func::Function)

end

file_io = open("function_docs.md", "w")

for func in all_plot_funcs
    help(file_io, func)
end

function help_attributes(io, func)
end

function help(func::Function)
    """
    # Arguments
    lines accepts the following arguments:
    $(help_arguments(lines))

    # Keyword arguments

    lines accepts the following keyword arguments:
    $(help_kwargs(lines))

    # You can use lines in the following way:

    @query_database [lines]

    """
end



help(x::Function) = help(AbstractPlot{Symbol(x)})

function help(x::AbstractPlot{:lines})
    md"""
    Line plots are great
    """
end


function help(io, plot; concise = true, verbose = true)
    println(io, "help for: $plot")
    if verbose
        println(io, "$plot accepts the following attributes")
        println(io, ...)
    end

end


help_kwargs(typ, key::Symbol) = help_kwargs(STDOUT, typ, key)
help_kwargs(io, typ, key::Symbol) = println(io, ...)


help_kwargs(lines)

function help_kwargs(typ)
    io = IOBuffer()
    for key in attribute_dict
        help_kwargs(io, typ, key)
    end
    String(take!(io))
end


function help_kwargs(::Type{T}) where T <: Scatter
    dict = default_theme(nothing, T)
    io = IOBuffer()
    for (key, default_value) in dict
        if haskey(attribute_help, key)
            println(io, attribute_help[key])
        end
        println(io, "   ", key, " with the default: ", default_value)
    end
    String(take!(io))
end
