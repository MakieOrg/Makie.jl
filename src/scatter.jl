
mutable struct Scatter{N}
    positions::Vector{Point{N, Float32}}
    color::TorVector{RGBAf0}
    marker::TorVector{<: Union{Symbol, Char, Type{Circle}}}
    markersize::TorVector{Union{Float32, Vec{N, Float32}}}
    markeroffset::TorVector{Vec{N, Float32}}
    strokecolor::TorVector{RGBAf0}
    strokewidth::TorVector{Float32}
    markerspace::Space
    transform_marker::Bool
    on_update::Observable{Dict{Symbol, Any}}
    on_event::Observable{Tuple{Symbol, Any}}
    camera::Camera
    transformation::Transformation
end

optional_fields(T::Type{Scatter}) = keys(defaults(T))

function defaults(::Type{Scatter})
    return (
        color = :black,
        marker = :circle,
        markersize = 10f0,
        markeroffset = Vec2f0(0),
        strokecolor = :white,
        strokewidth = 1f0,
        markerspace = Pixel,
        transform_marker = false
    )
end

function Scatter(positions; kw...)
    sdefaults = defaults(Scatter)
    pos = convert_arguments(Scatter, positions)
    fields = map(optional_fields(Scatter)) do name
        value = get(kw, name, getfield(sdefaults, name))
        return convert_attribute(Scatter, Key(name), value)
    end
    on_update = Observable{Dict{Symbol, Any}}()
    on_event = Observable{Tuple{Symbol, Any}}()
    camera = Camera()
    transformation = Transformation()
    return Scatter(pos, fields..., on_update, on_event, camera, transformation)
end

function update!(scatter::Scatter, values::Dict{Symbol})
    scatter.on_update[] = values
end

function Base.setproperty!(scatter::Scatter, field::Symbol, value::Any)
    converted = if field === :positions
        convert_arguments(Scatter, value)
    else
        convert_attribute(Scatter, Key(field), value)
    end
    setfield!(scatter, field, converted)
    update!(scatter, Dict(field => converted))
end
