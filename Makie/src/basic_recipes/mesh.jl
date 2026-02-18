function plot!(p::Mesh{<:Tuple{<:GeometryBasics.MetaMesh}})
    # Pass through MetaMesh to draw_atomic without splitting into submeshes.
    # Backends handle material assignment directly (e.g. RayMakie uses per-face
    # material indices from the MetaMesh view ranges).
    return p
end
