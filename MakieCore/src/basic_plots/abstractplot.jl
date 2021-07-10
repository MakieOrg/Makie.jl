
function update!(scatter::AbstractPlot, values::Dict{Symbol})
    # scatter.basics.on_update[] = values
end

function Base.setproperty!(scatter::T, field::Symbol, value::Any) where T <: AbstractPlot
    converted = convert_attribute(scatter, value, Key(field))
    FT = fieldtype(T, field)
    if !(converted isa FT)
        error("Attribute $(field) couldn't be converted to required type. Converted type $(typeof(converted)). Required type: $(FT)")
    end
    setfield!(scatter, field, converted)
    update!(scatter, Dict(field => converted))
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
