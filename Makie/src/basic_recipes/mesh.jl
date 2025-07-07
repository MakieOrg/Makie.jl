function plot!(p::Mesh{<:Tuple{<:GeometryBasics.MetaMesh}})
    metamesh = p[1][]
    meshes = GeometryBasics.split_mesh(metamesh.mesh)

    if !haskey(metamesh, :material_names) || !haskey(metamesh, :materials)
        @error "The given mesh has no :material_names or :materials. Drawing without material information."
        for (i, m) in enumerate(meshes)
            mesh!(p, Attributes(p), m, color = i, colorrange = (1, length(meshes)))
        end
        return p
    end

    names = metamesh[:material_names]

    for (name, m) in zip(names, meshes)
        overwrites = Dict{Symbol, Any}()
        material = metamesh[:materials][name]

        # TODO: Add ambient multiplier
        # attr[:ambient]   = get(material, "ambient", p.attributes[:ambient])
        for key in ["diffuse", "specular", "shininess"]
            if haskey(material, key)
                overwrites[Symbol(key)] = material[key]
            end
        end

        if haskey(material, "diffuse map")
            try
                x = material["diffuse map"]
                tex = if haskey(x, "image")
                    x["image"]
                elseif haskey(x, "filename")
                    if isfile(x["filename"])
                        FileIO.load(x["filename"])
                    else
                        # try to match filename
                        path, filename = splitdir(x["filename"])
                        files = readdir(path)
                        idx = findfirst(f -> lowercase(f) == lowercase(filename), files)
                        if idx === nothing
                            @error "Failed to load texture from material $name - File $filename not found in $path."
                            fill(RGB{N0f8}(1, 0, 1), (1, 1))
                        else
                            FileIO.load(joinpath(path, files[idx]))
                        end
                    end
                else
                    fill(RGB{N0f8}(1, 0, 1), (1, 1))
                end
                repeat = get(x, "clamp", false) ? (:clamp_to_edge) : (:repeat)

                overwrites[:color] = ShaderAbstractions.Sampler(
                    tex;
                    x_repeat = repeat, mipmap = true,
                    minfilter = :linear_mipmap_linear, magfilter = :linear
                )

                scale = Vec2f(get(x, "scale", Vec2f(1)))
                trans = Vec2f(get(x, "offset", Vec2f(0)))
                overwrites[:uv_transform] = ((trans, scale), :mesh)
            catch e
                @error "Failed to load texture from material $name: " exception = e
            end

            # What should we do if no texture is given?
            # Should we assume diffuse carries color information if no texture is given?
        elseif haskey(material, "diffuse")
            overwrites[:color] = RGBAf(1, 1, 1, 1)
        else
            # use Makie default?
        end

        mesh!(p, Attributes(p), m; overwrites...)
    end

    return p
end
