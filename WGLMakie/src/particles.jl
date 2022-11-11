
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
        uniform_dict[:color_getter] = """
            vec4 get_color(){
                vec2 norm = get_colorrange();
                float cmin = norm.x;
                float cmax = norm.y;
                float value = color;
                if (value <= cmax && value >= cmin) {
                    // in value range, continue!
                } else if (value < cmin) {
                    return get_lowclip();
                } else if (value > cmax) {
                    return get_highclip();
                } else {
                    // isnan is broken (of course) -.-
                    // so if outside value range and not smaller/bigger min/max we assume NaN
                    return get_nan_color();
                }
                float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
                // 1/0 corresponds to the corner of the colormap, so to properly interpolate
                // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
                float stepsize = 1.0 / float(textureSize(colormap, 0));
                i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
                return texture(colormap, vec2(i01, 0.0));
            }
        """
    end
end

const IGNORE_KEYS = Set([
    :shading, :overdraw, :rotation, :distancefield, :space, :markerspace, :fxaa,
    :visible, :transformation, :alpha, :linewidth, :transparency, :marker,
    :lightposition, :cycle, :label, :inspector_clear, :inspector_hover,
    :inspector_label
])

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

    for key in (:nan_color, :highclip, :lowclip)
        if haskey(plot, key)
            uniforms[key] = converted_attribute(plot, key)
        else
            uniforms[key] = RGBAf(0, 0, 0, 0)
        end
    end

    return InstancedProgram(WebGL(), lasset("particles.vert"), lasset("particles.frag"),
                            instance, VertexArray(; per_instance...); uniform_dict...)
end

using Makie: to_spritemarker


"""
    NoDataTextureAtlas(texture_atlas_size)

Optimization to just send the texture atlas one time to JS and then look it up from there in wglmakie.js,
instead of uploading this texture 10x in every plot.
"""
struct NoDataTextureAtlas <: ShaderAbstractions.AbstractSampler{Float16, 2}
    dims::NTuple{2, Int}
end

function serialize_three(fta::NoDataTextureAtlas)
    tex = Dict(:type => "Sampler", :data => "texture_atlas",
               :size => [fta.dims...], :three_format => three_format(Float16),
               :three_type => three_type(Float16),
               :minFilter => three_filter(:linear),
               :magFilter => three_filter(:linear),
               :wrapS => "RepeatWrapping",
               :anisotropy => 16f0)
    tex[:wrapT] = "RepeatWrapping"
    return tex
end


function scatter_shader(scene::Scene, attributes)
    # Potentially per instance attributes
    per_instance_keys = (:pos, :rotations, :markersize, :color, :intensity,
                         :uv_offset_width, :quad_offset, :marker_offset)
    uniform_dict = Dict{Symbol,Any}()
    uniform_dict[:image] = false
    marker = nothing
    if haskey(attributes, :marker)
        font = get(attributes, :font, Observable(Makie.defaultfont()))
        marker = lift(attributes[:marker]) do marker
            marker isa Makie.FastPixel && return Rect # FastPixel not supported, but same as Rect just slower
            return Makie.to_spritemarker(marker)
        end

        markersize = lift(Makie.to_2d_scale, attributes[:markersize])

        msize, offset = Makie.marker_attributes(marker, markersize, font, attributes[:quad_offset])
        attributes[:markersize] = msize
        attributes[:quad_offset] = offset
        attributes[:uv_offset_width] = Makie.primitive_uv_offset_width(marker)
        if to_value(marker) isa AbstractMatrix
            uniform_dict[:image] = Sampler(lift(el32convert, marker))
        end
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
    if !isnothing(marker)
        get!(uniform_dict, :shape_type) do
            return Makie.marker_to_sdf_shape(marker)
        end
    end

    if uniform_dict[:shape_type][] == 3
        atlas = Makie.get_texture_atlas()
        uniform_dict[:distancefield] = NoDataTextureAtlas(size(atlas.data))
        uniform_dict[:atlas_texture_size] = Float32(size(atlas.data, 1)) # Texture must be quadratic
    else
        uniform_dict[:atlas_texture_size] = 0f0
        uniform_dict[:distancefield] = Observable(false)
    end

    handle_color!(uniform_dict, per_instance)

    instance = uv_mesh(Rect2(-0.5f0, -0.5f0, 1f0, 1f0))
    # Don't send obs, since it's overwritten in JS to be updated by the camera
    uniform_dict[:resolution] = scene.camera.resolution[]

    return InstancedProgram(WebGL(), lasset("simple.vert"), lasset("sprites.frag"),
                            instance, VertexArray(; per_instance...); uniform_dict...)
end

function create_shader(scene::Scene, plot::Scatter)
    # Potentially per instance attributes
    per_instance_keys = (:offset, :rotations, :markersize, :color, :intensity,
                         :quad_offset)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end
    attributes = copy(plot.attributes.attributes)
    cam = scene.camera
    attributes[:preprojection] = Mat4f(I) # calculate this in JS
    attributes[:pos] = apply_transform(transform_func_obs(plot),  plot[1])
    quad_offset = get(attributes, :marker_offset, Observable(Vec2f(0)))
    attributes[:marker_offset] = Vec3f(0)
    attributes[:quad_offset] = quad_offset
    attributes[:billboard] = map(rot -> isa(rot, Billboard), plot.rotations)
    attributes[:model] = plot.model
    attributes[:depth_shift] = get(plot, :depth_shift, Observable(0f0))

    delete!(attributes, :uv_offset_width)
    filter!(kv -> !(kv[2] isa Function), attributes)
    return scatter_shader(scene, attributes)
end

value_or_first(x::AbstractArray) = first(x)
value_or_first(x::StaticVector) = x
value_or_first(x::Mat) = x
value_or_first(x) = x

function create_shader(scene::Scene, plot::Makie.Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})
    glyphcollection = plot[1]
    res = map(x->Vec2f(widths(x)), pixelarea(scene))
    projview = scene.camera.projectionview
    transfunc =  Makie.transform_func_obs(scene)
    pos = plot.position
    space = plot.space
    markerspace = plot.markerspace
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

    glyph_data = map(pos, gcollection, offset, transfunc) do pos, gc, offset, transfunc
        Makie.text_quads(pos, to_value(gc), offset, transfunc)
    end

    # unpack values from the one signal:
    positions, char_offset, quad_offset, uv_offset_width, scale = map((1, 2, 3, 4, 5)) do i
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

    cam = scene.camera
    # gl_attributes[:preprojection] = Observable(Mat4f(I))
    preprojection = map(space, markerspace, cam.projectionview, cam.resolution) do s, ms, pv, res
        Makie.clip_to_space(cam, ms) * Makie.space_to_clip(cam, s)
    end

    uniforms = Dict(
        :model => plot.model,
        :shape_type => Observable(Cint(3)),
        :color => uniform_color,
        :rotations => uniform_rotation,
        :pos => positions,
        :marker_offset => char_offset,
        :quad_offset => quad_offset,
        :markersize => scale,
        :preprojection => preprojection,
        :uv_offset_width => uv_offset_width,
        :transform_marker => get(plot.attributes, :transform_marker, Observable(true)),
        :billboard => Observable(false),
        :depth_shift => get(plot, :depth_shift, Observable(0f0))
    )

    return scatter_shader(scene, uniforms)
end
