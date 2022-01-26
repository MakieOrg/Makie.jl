
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
                         :transparency, :marker, :lightposition, :cycle, :label])

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
        uniform_dict[:uv] = Vec2f(0)
    end

    uniform_dict[:depth_shift] = get(plot, :depth_shift, Observable(0f0))
    uniform_dict[:backlight] = plot.backlight
    get!(uniform_dict, :ambient, Vec3f(1))

    return InstancedProgram(WebGL(), lasset("particles.vert"), lasset("particles.frag"),
                            instance, VertexArray(; per_instance...); uniform_dict...)
end

@enum Shape CIRCLE RECTANGLE ROUNDED_RECTANGLE DISTANCEFIELD TRIANGLE

primitive_shape(::Union{String,Char,Vector{Char}}) = Cint(DISTANCEFIELD)
primitive_shape(x::X) where {X} = Cint(primitive_shape(X))
primitive_shape(::Type{<:Circle}) = Cint(CIRCLE)
primitive_shape(::Type{<:Rect2}) = Cint(RECTANGLE)
primitive_shape(::Type{T}) where {T} = error("Type $(T) not supported")
primitive_shape(x::Shape) = Cint(x)

function char_scale_factor(char, font)
    # uv * size(ta.data) / Makie.PIXELSIZE_IN_ATLAS[] is the padded glyph size
    # normalized to the size the glyph was generated as.
    ta = Makie.get_texture_atlas()
    lbrt = glyph_uv_width!(ta, char, font)
    width = Vec(lbrt[3] - lbrt[1], lbrt[4] - lbrt[2])
    width * Vec2f(size(ta.data)) / Makie.PIXELSIZE_IN_ATLAS[]
end

# This works the same for x being widths and offsets
rescale_glyph(char::Char, font, x) = x * char_scale_factor(char, font)
function rescale_glyph(char::Char, font, xs::Vector)
    f = char_scale_factor(char, font)
    map(xs -> f * x, xs)
end
function rescale_glyph(str::String, font, x)
    [x * char_scale_factor(char, font) for char in collect(str)]
end
function rescale_glyph(str::String, font, xs::Vector)
    map((char, x) -> x * char_scale_factor(char, font), collect(str), xs)
end

using Makie: to_spritemarker

function scatter_shader(scene::Scene, attributes)
    # Potentially per instance attributes
    per_instance_keys = (:offset, :rotations, :markersize, :color, :intensity,
                         :uv_offset_width, :marker_offset)
    uniform_dict = Dict{Symbol,Any}()

    if haskey(attributes, :marker) && attributes[:marker][] isa Union{Char, Vector{Char},String}
        font = get(attributes, :font, Observable(Makie.defaultfont()))
        attributes[:markersize] = map(rescale_glyph, attributes[:marker], font, attributes[:markersize])
        attributes[:marker_offset] = map(rescale_glyph, attributes[:marker], font, attributes[:marker_offset])
    end

    if haskey(attributes, :marker) && attributes[:marker][] isa Union{Vector{Char},String}
        x = pop!(attributes, :marker)
        attributes[:uv_offset_width] = lift(x -> Makie.glyph_uv_width!.(collect(x)), x)
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
                Vec4f(0)
            end
        end
    end

    space = get(uniforms, :markerspace, Observable(SceneSpace))
    uniform_dict[:use_pixel_marker] = map(space) do space
        return space == Pixel
    end
    handle_color!(uniform_dict, per_instance)

    instance = uv_mesh(Rect2(-0.5f0, -0.5f0, 1f0, 1f0))
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
    attributes[:depth_shift] = get(plot, :depth_shift, Observable(0f0))

    delete!(attributes, :uv_offset_width)
    return scatter_shader(scene, attributes)
end

value_or_first(x::AbstractArray) = first(x)
value_or_first(x::StaticArray) = x
value_or_first(x) = x

function create_shader(scene::Scene, plot::Makie.Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})
    glyphcollection = plot[1]
    res = map(x->Vec2f(widths(x)), pixelarea(scene))
    projview = scene.camera.projectionview
    transfunc =  Makie.transform_func_obs(scene)
    pos = plot.position
    space = plot.space
    offset = plot.offset

    # TODO: This is a hack before we get better updating of plot objects and attributes going.
    # Here we only update the glyphs when the glyphcollection changes, if it's a singular glyphcollection.
    # The if statement will be compiled away depending on the parameter of Text.
    # This means that updates of a text vector and a separate position vector will still not work if only the text
    # vector is triggered, but basically all internal objects use the vector of tuples version, and that triggers
    # both glyphcollection and position, so it still works
    if glyphcollection[] isa Makie.GlyphCollection
        # here we use the glyph collection observable directly
        gcollection = glyphcollection
    else
        # and here we wrap it into another observable
        # so it doesn't trigger dimension mismatches
        # the actual, new value gets then taken in the below lift with to_value
        gcollection = Observable(glyphcollection)
    end

    glyph_data = lift(pos, gcollection, space, projview, res, offset, transfunc) do pos, gc, args...
        Makie.preprojected_glyph_arrays(pos, to_value(gc), args...)
    end
    # unpack values from the one signal:
    positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
        lift(getindex, glyph_data, i)
    end

    uniform_color = lift(glyphcollection) do gc
        if gc isa AbstractArray
            reduce(vcat, (Makie.collect_vector(g.colors, length(g.glyphs)) for g in gc),
                init = RGBAf[])
        else
            Makie.collect_vector(gc.colors, length(gc.glyphs))
        end
    end

    uniform_rotation = lift(glyphcollection) do gc
        if gc isa AbstractArray
            reduce(vcat, (Makie.collect_vector(g.rotations, length(g.glyphs)) for g in gc),
                init = Quaternionf[])
        else
            Makie.collect_vector(gc.rotations, length(gc.glyphs))
        end
    end

    uniforms = Dict(
        :model => plot.model,
        :shape_type => Observable(Cint(3)),
        :color => uniform_color,
        :rotations => uniform_rotation,
        :markersize => scale,
        :markerspace => Observable(Pixel),
        :marker_offset => offset,
        :offset => positions,
        :uv_offset_width => uv_offset_width,
        :transform_marker => Observable(false),
        :billboard => Observable(false),
        :pixelspace => getfield(scene.camera, :pixel_space),
        :depth_shift => get(plot, :depth_shift, Observable(0f0))
    )

    return scatter_shader(scene, uniforms)
end
