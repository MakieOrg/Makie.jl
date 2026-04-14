function plot!(p::Mesh{<:Tuple{<:GeometryBasics.MetaMesh}})
    attr = p.attributes

    # Resolve materials from MetaMesh metadata via register_computation!
    # This makes _resolved_materials available to backends (RayMakie, GLMakie, etc.)
    register_computation!(attr, [:mesh], [:_resolved_materials]) do args, changed, cached
        mm = args.mesh
        inner = mm.mesh

        if hasproperty(inner, :material) && haskey(mm, :material_palette)
            # Per-face path: FaceView{UInt32} indices + Dict{UInt32, Material} palette
            palette = convert_material(mm[:material_palette])
            return ((per_face=true, palette=palette, indices=inner.material),)

        elseif haskey(mm, :view_materials)
            # Per-view path: one material per mesh view
            converted = convert_material(mm[:view_materials])
            return ((per_face=false, view_materials=converted, views=inner.views),)

        elseif haskey(mm, :material_names) && haskey(mm, :materials)
            # Legacy GLTF path (MeshIO compatibility)
            return ((legacy_gltf=true, names=mm[:material_names],
                     materials=mm[:materials], views=inner.views),)
        end

        return (nothing,)
    end

    return p
end
