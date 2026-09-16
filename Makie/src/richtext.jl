struct RichText
    type::Symbol
    children::Vector{Union{RichText, String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText, String}[children...]
        return new(type, cs, Dict(kwargs))
    end
end

Base.:(==)(a::RichText, b::RichText) = a.type == b.type && a.children == b.children && a.attributes == b.attributes

Base.hash(a::RichText, b::UInt) = hash(a.type, hash(a.children, hash(a.attributes, b)))

function Base.print(io::IO, r::RichText)
    return foreach(child -> print(io, child), r.children)
end

function Base.String(r::RichText)
    return sprint(print, r)
end

function Base.show(io::IO, ::MIME"text/plain", r::RichText)
    return print(io, "RichText: \"$(String(r))\"")
end

"""
    rich(args...; kwargs...)

Create a `RichText` object containing all elements in `args`.
"""
rich(args...; kwargs...) = RichText(:span, args...; kwargs...)
"""
    subscript(args...; kwargs...)

Create a `RichText` object representing a superscript containing all elements in `args`.
"""
subscript(args...; kwargs...) = RichText(:sub, args...; kwargs...)
"""
    superscript(args...; kwargs...)

Create a `RichText` object representing a superscript containing all elements in `args`.
"""
superscript(args...; kwargs...) = RichText(:sup, args...; kwargs...)
"""
    subsup(subscript, superscript; kwargs...)

Create a `RichText` object representing a right subscript/superscript combination,
where both scripts are left-aligned against the preceding text.
"""
subsup(args...; kwargs...) = RichText(:subsup, args...; kwargs...)
"""
    left_subsup(subscript, superscript; kwargs...)

Create a `RichText` object representing a left subscript/superscript combination,
where both scripts are right-aligned against the following text.
"""
left_subsup(args...; kwargs...) = RichText(:leftsubsup, args...; kwargs...)

Base.:*(x::RichText, y::AbstractString) = rich(x, y)
Base.:*(x::AbstractString, y::RichText) = rich(x, y)
Base.:*(x::RichText, y::RichText) = rich(x, y)

export rich, subscript, superscript, subsup, left_subsup
