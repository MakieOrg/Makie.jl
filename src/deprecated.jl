function register_backend!(backend)
    @warn("`register_backend!` is an internal deprecated function, which shouldn't be used outside Makie.
    if you must really use this function, it's now `set_active_backend!(::Module)")
end

function backend_display(args...)
    @warn("`backend_display` is an internal deprecated function, which shouldn't be used outside Makie.
    if you must really use this function, it's now just `display(::Backend.Screen, figlike)`")
end

@deprecate DiscreteSurface CellGrid true
@deprecate ContinuousSurface VertexGrid true


function Base.getproperty(scene::Scene, field::Symbol)
    if field === :px_area
        @warn "`.px_area` got renamed to `.viewport`, and means the area the scene maps to in device indepentent units, not pixels. Note, `size(scene) == widths(scene.viewport[])`"
        return scene.area
    end
    return getfield(scene, field)
end

@deprecate pixelarea viewport true
