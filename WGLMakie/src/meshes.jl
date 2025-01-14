function vertexbuffer(x, f32c, transform_func, model, space)
    pos = decompose(Point, x)
    transformed = apply_transform_and_f32_conversion(f32c, transform_func, model, pos, space)
    return transformed
end

function vertexbuffer(x::Observable, @nospecialize(plot), f32c::Observable)
    return Buffer(lift(vertexbuffer, plot, x, f32c, transform_func_obs(plot), plot.model, plot.space))
end

facebuffer(x) = faces(x)
facebuffer(x::AbstractArray{<:GLTriangleFace}) = x
facebuffer(x::Observable) = Buffer(lift(facebuffer, x))

function converted_attribute(plot::AbstractPlot, key::Symbol)
    return lift(plot, plot[key]) do value
        return convert_attribute(value, Key{key}(), Key{plotkey(plot)}())
    end
end

function handle_color!(plot, uniforms, buffers, uniform_color_name = :uniform_color; permute_tex=true)
    color = plot.calculated_colors
    minfilter = to_value(get(plot, :interpolate, true)) ? :linear : :nearest

    convert_texture(x) = permute_tex ? lift(permutedims, plot, x) : x

    if color[] isa Colorant
        uniforms[uniform_color_name] = color
    elseif color[] isa ShaderAbstractions.Sampler
        uniforms[uniform_color_name] = to_value(color)
    elseif color[] isa AbstractVector
        buffers[:color] = Buffer(color)
    elseif color[] isa Makie.AbstractPattern
        uniforms[:pattern] = true
        uniforms[uniform_color_name] = Sampler(convert_texture(color); minfilter=minfilter)
    elseif color[] isa AbstractMatrix
        uniforms[uniform_color_name] = Sampler(convert_texture(color); minfilter=minfilter)
    elseif color[] isa Makie.ColorMapping
        if color[].color_scaled[] isa AbstractVector
            buffers[:color] = Buffer(color[].color_scaled)
        else
            color_scaled = convert_texture(color[].color_scaled)
            uniforms[uniform_color_name] = Sampler(color_scaled; minfilter=minfilter)
        end
        uniforms[:colormap] = Sampler(color[].colormap)
        uniforms[:colorrange] = color[].colorrange_scaled
        uniforms[:highclip] = Makie.highclip(color[])
        uniforms[:lowclip] = Makie.lowclip(color[])
        uniforms[:nan_color] = color[].nan_color
    end
    get!(uniforms, :color, false)
    get!(uniforms, uniform_color_name, false)
    get!(uniforms, :colormap, false)
    get!(uniforms, :colorrange, false)
    get!(uniforms, :pattern, false)
    get!(uniforms, :highclip, RGBAf(0, 0, 0, 0))
    get!(uniforms, :lowclip, RGBAf(0, 0, 0, 0))
    get!(uniforms, :nan_color, RGBAf(0, 0, 0, 0))
    return
end

lift_or(f, p, x) = f(x)
lift_or(f, @nospecialize(p), x::Observable) = lift(f, p, x)

function draw_mesh(mscene::Scene, per_vertex, plot, uniforms; permute_tex=true)
    filter!(kv -> !(kv[2] isa Function), uniforms)
    handle_color!(plot, uniforms, per_vertex; permute_tex=permute_tex)

    get!(uniforms, :ambient, Vec3f(1))
    get!(uniforms, :light_direction, Vec3f(1))
    get!(uniforms, :light_color, Vec3f(1))

    uniforms[:interpolate_in_fragment_shader] = get(plot, :interpolate_in_fragment_shader, true)

    get!(uniforms, :shading, to_value(get(plot, :shading, NoShading)) != NoShading)

    uniforms[:normalmatrix] = map(uniforms[:model]) do m
        i = Vec(1, 2, 3)
        return Mat3f(transpose(inv(m[i, i])))
    end


    for key in (:diffuse, :specular, :shininess, :backlight, :depth_shift)
        if !haskey(uniforms, key)
            uniforms[key] = lift_or(x -> convert_attribute(x, Key{key}()), plot, plot[key])
        end
    end
    if haskey(uniforms, :color) && haskey(per_vertex, :color)
        to_value(uniforms[:color]) isa Bool && delete!(uniforms, :color)
        to_value(per_vertex[:color]) isa Bool && delete!(per_vertex, :color)
    end

    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniforms[:picking] = false
    uniforms[:object_id] = UInt32(0)
    get!(uniforms, :PICKING_INDEX_FROM_UV, false)
    pos = pop!(per_vertex, :positions)
    faces = pop!(per_vertex, :faces)
    mesh = GeometryBasics.Mesh(pos, faces; per_vertex...)
    return Program(WebGL(), lasset("mesh.vert"), lasset("mesh.frag"), mesh, uniforms)
end

function create_shader(scene::Scene, plot::Makie.Mesh)
    # Potentially per instance attributes
    mesh_signal = plot[1]
    get_attribute(mesh, key) = lift(x -> getproperty(x, key), plot, mesh)
    data = GeometryBasics.vertex_attributes(mesh_signal[])

    uniforms = Dict{Symbol,Any}()
    attributes = Dict{Symbol,Any}()

    uniforms[:interpolate_in_fragment_shader] = get(plot, :interpolate_in_fragment_shader, true)

    for (key, default) in (:uv => Vec2f(0), :normal => Vec3f(0))
        if haskey(data, key)
            attributes[key] = Buffer(get_attribute(mesh_signal, key))
        else
            uniforms[key] = Observable(default)
        end
    end

    # TODO: allow passing Mat{2, 3, Float32} (and nothing)
    uniforms[:uv_transform] = map(plot, plot[:uv_transform]) do x
        M = convert_attribute(x, Key{:uv_transform}(), Key{:mesh}())
        if M === nothing
            return Mat3f(I)
        else
            return Mat3f(M[1], M[2], 0, M[3], M[4], 0, M[5], M[6], 1)
        end
    end

    faces = facebuffer(mesh_signal)
    f32c, model = Makie.patch_model(plot)
    uniforms[:model] = model
    positions = vertexbuffer(mesh_signal, plot, f32c)
    attributes[:faces] = faces
    attributes[:positions] = positions

    return draw_mesh(scene, attributes, plot, uniforms; permute_tex=false)
end
