GridLayout(scene::Scene, args...; kwargs...) = GridLayout(args...; bbox = lift(x -> BBox(x), pixelarea(scene)), parentscene = scene, kwargs...)
