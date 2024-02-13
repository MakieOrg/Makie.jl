###########################################
# v0.20 deprecations:
##
Base.@deprecate_binding DiscreteSurface CellGrid true
Base.@deprecate_binding ContinuousSurface VertexGrid true

function Base.getproperty(scene::Scene, field::Symbol)
    if field === :px_area
        @warn "`.px_area` got renamed to `.viewport`, and means the area the scene maps to in device independent units, not pixels. Note, `size(scene) == widths(scene.viewport[])`"
        return scene.viewport
    end
    return getfield(scene, field)
end

@deprecate pixelarea viewport true
Base.@deprecate_binding Combined Plot true
