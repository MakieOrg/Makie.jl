
function handle_color!(uniform_dict, instance_dict)
    color, udict = if haskey(uniform_dict, :color)
        to_value(uniform_dict[:color]), uniform_dict
    elseif haskey(instance_dict, :color)
        to_value(instance_dict[:color]), instance_dict
    else
        nothing, uniform_dict
    end
    if color isa Colorant ||
              color isa AbstractVector{<:Colorant} ||
              color === nothing
        delete!(uniform_dict, :colormap)
    elseif color isa AbstractArray{<:Real}
        udict[:color] = lift(x -> convert(Vector{Float32}, x), udict[:color])
        # udict[:color] = lift(x -> convert(Vector{Float32}, x), udict[:color])
        uniform_dict[:color_getter] = """
            vec4 get_color(){
                vec2 norm = get_colorrange();
                float normed = (color - norm.x) / (norm.y - norm.x);
                return texture(colormap, vec2(normed, 0));
            }
        """
    end
end

const IGNORE_KEYS = Set([:shading, :overdraw, :rotation, :distancefield, :markerspace,
                         :fxaa, :visible, :transformation, :alpha, :linewidth,
                         :transparency, :marker, :lightposition, :cycle])

function create_shader(scene::Scene, plot::MeshScatter)
    # Potentially per instance attributes
    per_instance_keys = (:rotations, :markersize, :color, :intensity)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end
    per_instance[:offset] = apply_transform(transform_func_obs(plot),  plot[1])

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, plot))
    end

    uniforms = filter(plot.attributes.attributes) do (k, v)
        return (!haskey(per_instance, k)) && isscalar(v[])
    end

    uniform_dict = Dict{Symbol,Any}()
    for (k, v) in uniforms
        k in IGNORE_KEYS && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end

    handle_color!(uniform_dict, per_instance)
    instance = convert_attribute(plot.marker[], key"marker"(), key"meshscatter"())

    if !hasproperty(instance, :uv)
        uniform_dict[:uv] = Vec2f0(0)
    end

    return InstancedProgram(WebGL(), lasset("particles.vert"), lasset("particles.frag"),
                            instance, VertexArray(; per_instance...); uniform_dict...)
end

@enum Shape CIRCLE RECTANGLE ROUNDED_RECTANGLE DISTANCEFIELD TRIANGLE

primitive_shape(::Union{String,Char,Vector{Char}}) = Cint(DISTANCEFIELD)
primitive_shape(x::X) where {X} = Cint(primitive_shape(X))
primitive_shape(::Type{<:Circle}) = Cint(CIRCLE)
primitive_shape(::Type{<:Rect2D}) = Cint(RECTANGLE)
primitive_shape(::Type{T}) where {T} = error("Type $(T) not supported")
primitive_shape(x::Shape) = Cint(x)

using Makie: to_spritemarker

function scatter_shader(scene::Scene, attributes)
    # Potentially per instance attributes
    per_instance_keys = (:offset, :rotations, :markersize, :color, :intensity,
                         :uv_offset_width, :marker_offset)
    uniform_dict = Dict{Symbol,Any}()
    if haskey(attributes, :marker) && attributes[:marker][] isa Union{Vector{Char},String}
        x = pop!(attributes, :marker)
        attributes[:uv_offset_width] = lift(x -> Makie.glyph_uv_width!.(collect(x)),
                                            x)
        uniform_dict[:shape_type] = Cint(3)
    end

    per_instance = filter(attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, nothing))
    end

    uniforms = filter(attributes) do (k, v)
        return !haskey(per_instance, k)
    end

    for (k, v) in uniforms
        k in IGNORE_KEYS && continue
        uniform_dict[k] = lift_convert(k, v, nothing)
    end

    get!(uniform_dict, :shape_type) do
        return lift(x -> primitive_shape(to_spritemarker(x)), attributes[:marker])
    end
    if uniform_dict[:shape_type][] == 3
        atlas = Makie.get_texture_atlas()
        uniform_dict[:distancefield] = Sampler(atlas.data, minfilter=:linear,
                                               magfilter=:linear, anisotropic=16f0)
        uniform_dict[:atlas_texture_size] = Float32(size(atlas.data, 1)) # Texture must be quadratic
    else
        uniform_dict[:atlas_texture_size] = 0f0
        uniform_dict[:distancefield] = Observable(false)
    end

    if !haskey(per_instance, :uv_offset_width)
        get!(uniform_dict, :uv_offset_width) do
            return if haskey(attributes, :marker) &&
                      to_spritemarker(attributes[:marker][]) isa Char
                lift(x -> Makie.glyph_uv_width!(to_spritemarker(x)),
                     attributes[:marker])
            else
                Vec4f0(0)
            end
        end
    end

    space = get(uniforms, :markerspace, Observable(SceneSpace))
    uniform_dict[:use_pixel_marker] = map(space) do space
        return space == Pixel
    end
    handle_color!(uniform_dict, per_instance)

    instance = uv_mesh(Rect2D(-0.5f0, -0.5f0, 1f0, 1f0))
    uniform_dict[:resolution] = scene.camera.resolution
    return InstancedProgram(WebGL(), lasset("simple.vert"), lasset("sprites.frag"),
                            instance, VertexArray(; per_instance...); uniform_dict...)
end

function create_shader(scene::Scene, plot::Scatter)
    # Potentially per instance attributes
    per_instance_keys = (:offset, :rotations, :markersize, :color, :intensity,
                         :marker_offset)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end
    attributes = copy(plot.attributes.attributes)
    attributes[:offset] = apply_transform(transform_func_obs(plot),  plot[1])
    attributes[:billboard] = map(rot -> isa(rot, Billboard), plot.rotations)
    attributes[:pixelspace] = getfield(scene.camera, :pixel_space)
    attributes[:model] = plot.model
    attributes[:markerspace] = plot.markerspace
    delete!(attributes, :uv_offset_width)
    return scatter_shader(scene, attributes)
end

value_or_first(x::AbstractArray) = first(x)
value_or_first(x::StaticArray) = x
value_or_first(x) = x

function create_shader(scene::Scene, plot::Makie.Text)

    string_obs = plot[1]
    liftkeys = (:position, :textsize, :font, :align, :rotation, :model, :justification, :lineheight, :space, :offset)

    args = getindex.(Ref(plot), liftkeys)

    gl_text = lift(string_obs, scene.camera.projectionview, Makie.transform_func_obs(scene), args...) do str, projview, transfunc, pos, tsize, font, align, rotation, model, j, l, space, offset
        # For annotations, only str (x[1]) will get updated, but all others are updated too!
        args = @get_attribute plot (position, textsize, font, align, rotation, offset)
        res = Vec2f0(widths(pixelarea(scene)[]))
        return Makie.preprojected_glyph_arrays(str, pos, plot._glyphlayout[], font, textsize, space, projview, res, offset, transfunc)
    end

    # unpack values from the one signal:
    positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
        lift(getindex, gl_text, i)
    end

    atlas = get_texture_atlas()
    keys = (:color, :rotation)

    signals = map(keys) do key
        return lift(positions, plot[key]) do pos, attr
            str = string_obs[]
            if str isa AbstractVector
                if isempty(str)
                    attr = convert_attribute(value_or_first(attr), Key{key}())
                    return Vector{typeof(attr)}()
                else
                    result = []
                    broadcast_foreach(str, attr) do st, aa
                        for att in attribute_per_char(st, aa)
                            push!(result, convert_attribute(att, Key{key}()))
                        end
                    end
                    # narrow the type from any, this is ugly
                    return identity.(result)
                end
            else
                return Makie.get_attribute(plot, key)
            end
        end
    end
    uniforms = Dict(
        :model => plot.model,
        :shape_type => Observable(Cint(3)),
        :color => signals[1],
        :rotations => signals[2],
        :markersize => scale,
        :markerspace => Observable(Pixel),
        :marker_offset => offset,
        :offset => positions,
        :uv_offset_width => uv_offset_width,
        :transform_marker => Observable(false),
        :billboard => Observable(false),
        :pixelspace => getfield(scene.camera, :pixel_space))

    return scatter_shader(scene, uniforms)
end
