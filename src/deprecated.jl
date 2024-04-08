###########################################
# v0.20 deprecations:
##
Base.@deprecate_binding DiscreteSurface CellGrid true
Base.@deprecate_binding ContinuousSurface VertexGrid true

@deprecate pixelarea viewport true
Base.@deprecate_binding Combined Plot true
