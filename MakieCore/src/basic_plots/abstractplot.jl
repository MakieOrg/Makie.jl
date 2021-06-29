
optional_fields(T::Type{<: AbstractPlot}) = keys(defaults(T))

function update!(scatter::AbstractPlot, values::Dict{Symbol})
    scatter.basics.on_update[] = values
end

function Base.setproperty!(scatter::T, field::Symbol, value::Any) where T <: AbstractPlot
    converted = if field === :positions
        convert_arguments(T, value)
    else
        convert_attribute(T, Key(field), value)
    end
    setfield!(scatter, field, converted)
    update!(scatter, Dict(field => converted))
end

function from_keywords(::T, kw) where T
    sdefaults = defaults(T)
    return map(optional_fields(T)) do name
        value = get(kw, name, getfield(sdefaults, name))
        return convert_attribute(T, Key(name), value)
    end
end


mutable struct PlotBasics
    on_update::Observable{Dict{Symbol,Any}}
    on_event::Observable{Tuple{Symbol,Any}}
    defaults::Set{Symbol}
    observables::Dict{Symbol, Observable}
    camera::Camera
    transformation::Transformation
end


function PlotBasics()
    return PlotBasics(
        Observable{Dict{Symbol,Any}}(),
        Observable{Tuple{Symbol,Any}}(),
        Set{Symbol}(),
        Dict{Symbol, Observable}(),
        Camera(),
        Transformation(),
    )
end
