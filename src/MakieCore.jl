module MakieCore


using Observables
# Solution 1: strictly type fields
const TorVector{T} = Union{Vector{T}, T}

mutable struct Scatter{N}
    positions::Vector{Point{N, Float32}}
    color::Union{TorVector{RGBAf0}, Sampler}
    marker::Union{Nothing, TorVector{<: Union{Symbol, Char}}}
    markersize::Union{Nothing, TorVector{Union{Float32, Vec{N, Float32}}}}
    strokecolor::Union{Nothing, TorVector{RGBAf0}}
    strokewidth::Union{Nothing, TorVector{Float32}}
    markerspace::Space
    on_update::Observable{Dict{Symbol, Any}}
end

function defaults(::Type{Scatter})
    return (
        color = :black,
        marker = :circle,
        markersize = 10,
        strokecolor = :white,
        strokewidth = 1,
        markerspace = :Pixel,
    )
end

optional_fields(T::Type{Scatter}) = keys(defaults(T))

function Scatter(positions; kw...)
    pos = convert_arguments(Scatter, positions)
    on_update = Observable{Dict{Symbol, Any}}()
    fields = map(optional_fields(Scatter)) do name
        if haskey(kw, name)
            return convert_attribute(Scatter, name, getproperty(kw, name))
        else
            return nothing
        end
    end
    scatter = Scatter(pos, fields..., on_update)
    on(on_update) do updates
        for (k, v) in updates
            converted = convert_attribute(Scatter, k, v)
            setfield!(scatter, k, converted)
        end
    end
    return scatter
end

function update!(scatter::Scatter, values::Dict{Symbol})
    scatter.on_update[] = values
end

function Base.setproperty!(scatter::Scatter, field::Symbol, value::Any)
    if field === :color
        converted = to_color(scatter, value)
        setfield!(scatter, field, converted)
        update!(scatter, Dict(field => converted))
    end
end
# Very simple solution, but writing them out like that can get complicated
# would infer unions for s.color
# annyoing to type out types, and duplicates convert method types
# Would nicely document possible types


# Solution 2: type parameters + getproperty overload
mutable struct Scatter{T1, T2}
    positions::T1
    color::T2
    ...
end
to_color(::Scatter, x::Colorant)::RGBAf0
to_color(::Scatter, x::AbstractVector{<:Colorant})::Vector{RGBAf0}

function Base.getproperty(s::Scatter, sym::Symbol)
    if sym === :color
        return to_color(s, s.color)
    else
        ...
    end
end
function Base.setproperty!(scatter::Scatter, field::Symbol, value::Any)
    if field === :color
        converted = to_color(scatter, value)
        setfield!(scatter, field, converted)
        update!(scatter, Dict(field => converted))
    end
end

# could infer exact type on field access, but would introduce many type parameters
# which could be hard on the compiler - and when printing the type
# doesn't as easily document itself as solution 1, but if well documented it should work as well.

# Solution 3: just use Any + getproperty overload
mutable struct Scatter
    positions::Any
    color::Any
    ...
end

function Base.getproperty(s::Scatter, sym::Symbol)
    if sym === :color
        return to_color(s, s.color)
    else
        ...
    end
end

# Maybe least compilation for functions passing through the object
# would infer unions for s.color ( Union{TorVector{RGBAf0}, Sampler})
# easier to read than solution 2, but same documentation caveat


end
