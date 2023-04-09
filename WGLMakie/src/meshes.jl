function vertexbuffer(x, trans, space)
    pos = decompose(Point, x)
    return apply_transform(trans,  pos, space)
end

function vertexbuffer(x::Observable, p)
    return Buffer(lift(vertexbuffer, x, transform_func_obs(p), get(p, :space, :data)))
end

facebuffer(x) = faces(x)
facebuffer(x::AbstractArray{<:GLTriangleFace}) = x
facebuffer(x::Observable) = Buffer(lift(facebuffer, x))


function converted_attribute(plot::AbstractPlot, key::Symbol)
    return lift(plot[key]) do value
        return convert_attribute(value, Key{key}(), Key{plotkey(plot)}())
    end
end

function create_shader(scene::Scene, plot::Makie.Mesh)
    # Potentially per instance attributes
    mesh_signal = plot[1]
    mattributes = GeometryBasics.attributes
    get_attribute(mesh, key) = lift(x -> getproperty(x, key), mesh)
    data = mattributes(mesh_signal[])

    uniforms = Dict{Symbol,Any}()
    attributes = Dict{Symbol,Any}()

    uniforms[:interpolate_in_fragment_shader] = get(plot, :interpolate_in_fragment_shader, true)

    for (key, default) in (:uv => Vec2f(0), :normals => Vec3f(0))
        if haskey(data, key)
            attributes[key] = Buffer(get_attribute(mesh_signal, key))
        else
            uniforms[key] = Observable(default)
        end
    end

    if haskey(data, :attributes) && data[:attributes] isa AbstractVector
        attr = get_attribute(mesh_signal, :attributes)
        attr_id = get_attribute(mesh_signal, :attribute_id)
        color = lift((c, id) -> c[Int.(id) .+ 1], attr_id)
        attributes[:color] = Buffer(color)
        uniforms[:uniform_color] = false
    else
        color_signal = converted_attribute(plot, :color)
        if color_signal[] isa Colorant && haskey(data, :color)
            color_signal = get_attribute(mesh_signal, :color)
        end
        color = color_signal[]
        uniforms[:uniform_color] = Observable(false) # this is the default
        colorscale = get(plot, :colorscale, Observable(nothing))

        if color isa AbstractArray
            if eltype(color) <: Number
                uniforms[:colorrange] = apply_scale(colorscale, converted_attribute(plot, :colorrange))
                uniforms[:colormap] = Sampler(converted_attribute(plot, :colormap))
                color = apply_scale(colorscale, color)
            end
            if color isa AbstractVector
                attributes[:color] = Buffer(color) # per vertex colors
            else
                uniforms[:uniform_color] = Sampler(color) # Texture
                uniforms[:color] = false
                if color isa Makie.AbstractPattern
                    uniforms[:pattern] = true
                    # add texture coordinates
                    uv = Buffer(lift(decompose_uv, mesh_signal))
                    delete!(uniforms, :uv)
                    attributes[:uv] = uv
                end
            end
        elseif color isa Colorant && !haskey(attributes, :color)
            uniforms[:uniform_color] = color_signal
        else
            error("Unsupported color type: $(typeof(color))")
        end
    end
    if !haskey(attributes, :color)
        get!(uniforms, :color, false) # make sure we have a color attribute, if not in instance attributes
    end

    uniforms[:shading] = plot.shading

    for key in (:diffuse, :specular, :shininess, :backlight)
        uniforms[key] = lift(x-> convert_attribute(x, Key{key}()), plot[key])
    end

    faces = facebuffer(mesh_signal)
    positions = vertexbuffer(mesh_signal, plot)
    instance = GeometryBasics.Mesh(GeometryBasics.meta(positions; attributes...), faces)

    get!(uniforms, :colorrange, true)
    get!(uniforms, :colormap, true)
    get!(uniforms, :pattern, false)
    get!(uniforms, :model, plot.model)
    get!(uniforms, :lightposition, Vec3f(1))
    get!(uniforms, :ambient, Vec3f(1))

    for key in (:nan_color, :highclip, :lowclip)
        if haskey(plot, key)
            uniforms[key] = converted_attribute(plot, key)
        else
            uniforms[key] = RGBAf(0, 0, 0, 0)
        end
    end

    uniforms[:depth_shift] = get(plot, :depth_shift, Observable(0f0))

    uniforms[:normalmatrix] = map(scene.camera.view, plot.model) do v, m
        i = Vec(1, 2, 3)
        return transpose(inv(v[i, i] * m[i, i]))
    end

    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniforms[:picking] = false
    uniforms[:object_id] = UInt32(0)

    return Program(WebGL(), lasset("mesh.vert"), lasset("mesh.frag"), instance, uniforms)
end
