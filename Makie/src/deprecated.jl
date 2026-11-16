###########################################
# v0.20 deprecations:
##

function DiscreteSurface(args...; kwargs...)
    @warn "Makie.DiscreteSurface() is deprecated, use Makie.CellGrid() instead" maxlog = 1
    return CellGrid(args...; kwargs...)
end

function ContinuousSurface(args...; kwargs...)
    @warn "Makie.ContinuousSurface() is deprecated, use Makie.VertexGrid() instead" maxlog = 1
    return VertexGrid(args...; kwargs...)
end

function Base.getproperty(scene::Scene, field::Symbol)
    if field === :px_area
        @warn "`.px_area` got renamed to `.viewport`, and means the area the scene maps to in device independent units, not pixels. Note, `size(scene) == widths(scene.viewport[])`"
        return scene.viewport
    end
    return getfield(scene, field)
end

@deprecate pixelarea viewport true

function Combined(args...; kwargs...)
    @warn "Makie.Combined() is deprecated, use Makie.Plot() instead" maxlog = 1
    return Plot(args...; kwargs...)
end

# For deprecated (primitive plot) attributes. This si not automatic because a
# deprecated attribute may not use the same conversions as its replacement.
convert_attribute(x, ::key"rotations", p::key"scatter") = convert_attribute(x, Key{:rotation}(), p)
convert_attribute(x, ::key"rotations", p::key"meshscatter") = convert_attribute(x, Key{:rotation}(), p)
convert_attribute(x, ::key"textsize", p::key"text") = convert_attribute(x, Key{:fontsize}(), p)