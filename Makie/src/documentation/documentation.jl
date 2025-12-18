"""
    help(plot[, name::Symbol; extended = false])

When given a `plot` type or function, this will print the docstring of the plot
much like `?plot`.

When given a `name` the function will look for an attribute of that name and
print information about it. This is equivalent to `?Plot.name` in Julia 1.12.2
and beyond.
"""
function help(plot::Type{T}, args...) where {T <: AbstractPlot}
    buffer = IOBuffer()
    _help(buffer, plot, args...)
    return Markdown.parse(String(take!(buffer)))
end

function help(plot::Function, args...)
    buffer = IOBuffer()
    _help(buffer, to_plot_type(plot), args...)
    return Markdown.parse(String(take!(buffer)))
end

function _help(io::IO, plot::Type{T}) where {T <: AbstractPlot}
    println(io, Base.doc(to_plot_func(plot)))
    return
end

function _help(io::IO, plot::Type{T}, name::Symbol) where {T <: AbstractPlot}
    println(io, field_docs(plot, name))
    return
end

# ==========================================================
# Supporting functions for the help functions

"""
    to_plot_func(plot)

Returns the plot function of a given plot type (or function).
"""
to_plot_func(Typ::Type{<:AbstractPlot{F}}) where {F} = F
to_plot_func(func::Function) = func


"""
    to_plot_type(plot)

Returns the plot type of a given plot function (or type).
"""
to_plot_type(func::Function) = Plot{func}
to_plot_type(Typ::Type{T}) where {T <: AbstractPlot} = Typ
