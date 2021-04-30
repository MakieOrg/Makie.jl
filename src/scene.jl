mutable struct Scene
    # Scene Graph attributes
    parent::Union{Nothing,Scene}
    children::Vector{Scene}
    plots::Vector{AbstractPlot}
    # link to backend
    current_screens::Vector{AbstractScreen}

    # Transformation attributes
    screen_area::Rect2D{Int}
    camera::Camera
    camera_controls::Base.RefValue{Any}
    transformation::Transformation

    # Drawing attributes
    clear_background::Bool
    backgroundcolor::RGBAf0
end

GeometryBasics.widths(scene::Scene) = widths(scene.screen_area)

function Scene(w::Int, h::Int)
    return Scene(
        nothing,
        Scene[],
        AbstractPlot[],
        AbstractScreen[],
        IRect2D(0, 0, w, h),
        Camera(),
        Base.RefValue{Any}(),
        Transformation(),
        true,
        RGBAf0(1, 1, 1, 1),
    )
end

function Base.push!(scene::Scene, plot::AbstractPlot)
    plot.camera.screen_area[] = scene.screen_area
    plot.parent = scene
    push!(scene.plots, plot)
    return plot
end
