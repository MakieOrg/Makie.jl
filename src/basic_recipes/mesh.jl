function plot!(p::Mesh{<: Tuple{<: GeometryBasics.MetaMesh}})
    metamesh = p[1][]
    meshes = GeometryBasics.split_mesh(metamesh.mesh)
    names = metamesh[:material_names]
    
    for (name, m) in zip(names, meshes)
        attr = Attributes()
        material = metamesh[:materials][name]

        # TODO: Add ambient multiplier
        # attr[:ambient]   = get(material, "ambient", p.attributes[:ambient])
        attr[:diffuse]   = get(material, "diffuse", p.attributes[:diffuse])
        attr[:specular]  = get(material, "specular", p.attributes[:specular])
        attr[:shininess] = get(material, "shininess", p.attributes[:shininess])

        if haskey(material, "diffuse map")
            try 
                x = material["diffuse map"]
                tex = if haskey(x, "image")
                    x["image"]
                elseif haskey(x, "filename")
                    FileIO.load(x["filename"])
                else
                    fill(RGB{N0f8}(1,0,1))
                end
                repeat = get(x, "clamp", false) ? (:clamp_to_edge) : (:repeat)
                
                attr[:color] = ShaderAbstractions.Sampler(tex; 
                    x_repeat = repeat, mipmap = true,
                    minfilter = :linear_mipmap_linear, magfilter = :linear
                )
                
                scale = Vec2f(get(x, "scale", Vec2f(1)))
                trans = Vec2f(get(x, "offset", Vec2f(0)))
                attr[:uv_transform] = ((trans, scale), :mesh)
            catch e
                @error "Failed to load texture from material $name: " exception = e
            end
 
        # What should we do if no texture is given?
        # Should we assume diffuse carries color information if no texture is given?
        elseif haskey(material, "diffuse")
            attr[:color] = RGBAf(1,1,1,1)
        else
            # use Makie default?
        end

        for k in Makie.attribute_names(Makie.Mesh)
            get!(attr, k, p.attributes[k])
        end

        plt = mesh!(p, attr, m)
    end

    return p
end
