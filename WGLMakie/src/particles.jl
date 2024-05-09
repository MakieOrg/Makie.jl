
function handle_color_getter!(uniform_dict, per_instance)
    if haskey(uniform_dict, :color) && haskey(per_instance, :color)
        to_value(uniform_dict[:color]) isa Bool && delete!(uniform_dict, :color)
        to_value(per_instance[:color]) isa Bool && delete!(per_instance, :color)
    end
    color = haskey(uniform_dict, :color) ? to_value(uniform_dict[:color]) : to_value(per_instance[:color])
    if color isa AbstractArray{<:Real}
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
    return
end

const IGNORE_KEYS = Set([
    :shading, :overdraw, :distancefield, :space, :markerspace, :fxaa,
    :visible, :transformation, :alpha, :linewidth, :transparency, :marker,
    :light_direction, :light_color,
    :cycle, :label, :inspector_clear, :inspector_hover,
    :inspector_label, :axis_cyclerr, :dim_conversions, :material
    # TODO add model here since we generally need to apply patch_model?
])

function create_shader(scene::Scene, plot::MeshScatter)
    # Potentially per instance attributes
    per_instance_keys = (:rotation, :markersize, :intensity)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end

    per_instance[:offset] = apply_transform_and_f32_conversion(scene, plot, plot[1])

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, plot))
    end

    uniforms = filter(plot.attributes.attributes) do (k, v)
        return (!haskey(per_instance, k)) && isscalar(v[])
    end

    uniform_dict = Dict{Symbol,Any}()
    color_keys = Set([:color, :colormap, :highclip, :lowclip, :nan_color, :colorrange, :colorscale, :calculated_colors])
    for (k, v) in uniforms
        k in IGNORE_KEYS && continue
        k in color_keys && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end

    handle_color!(plot, uniform_dict, per_instance, :color)
    handle_color_getter!(uniform_dict, per_instance)
    instance = convert_attribute(plot.marker[], key"marker"(), key"meshscatter"())

    if !hasproperty(instance, :uv)
        uniform_dict[:uv] = Vec2f(0)
    end

    uniform_dict[:depth_shift] = get(plot, :depth_shift, Observable(0f0))
    uniform_dict[:backlight] = plot.backlight

    # Make sure these exist
    get!(uniform_dict, :ambient, Vec3f(0.1))
    get!(uniform_dict, :diffuse, Vec3f(0.9))
    get!(uniform_dict, :specular, Vec3f(0.3))
    get!(uniform_dict, :shininess, 8f0)
    get!(uniform_dict, :light_direction, Vec3f(1))
    get!(uniform_dict, :light_color, Vec3f(1))

    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniform_dict[:picking] = false
    uniform_dict[:object_id] = UInt32(0)
    uniform_dict[:shading] = map(x -> x != NoShading, plot.shading)

    uniform_dict[:model] = map(Makie.patch_model, f32_conversion_obs(plot), plot.model)

    return InstancedProgram(WebGL(), lasset("particles.vert"), lasset("particles.frag"),
                            instance, VertexArray(; per_instance...), uniform_dict)
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

function scatter_shader(scene::Scene, attributes, plot)
    # Potentially per instance attributes
    per_instance_keys = (:pos, :rotation, :markersize, :color, :intensity,
                         :uv_offset_width, :quad_offset, :marker_offset)
    uniform_dict = Dict{Symbol,Any}()
    uniform_dict[:image] = false
    marker = nothing
    atlas = wgl_texture_atlas()
    if haskey(attributes, :marker)
        font = get(attributes, :font, Observable(Makie.defaultfont()))
        marker = lift(plot, attributes[:marker]) do marker
            marker isa Makie.FastPixel && return Rect # FastPixel not supported, but same as Rect just slower
            return Makie.to_spritemarker(marker)
        end

        markersize = lift(Makie.to_2d_scale, plot, attributes[:markersize])

        msize, offset = Makie.marker_attributes(atlas, marker, markersize, font, attributes[:quad_offset], plot)
        attributes[:markersize] = msize
        attributes[:quad_offset] = offset
        attributes[:uv_offset_width] = Makie.primitive_uv_offset_width(atlas, marker, font)
        if to_value(marker) isa AbstractMatrix
            uniform_dict[:image] = Sampler(lift(el32convert, plot, marker))
        end
    end

    per_instance = filter(attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, plot))
    end

    uniforms = filter(attributes) do (k, v)
        return !haskey(per_instance, k)
    end

    color_keys = Set([:color, :colormap, :highclip, :lowclip, :nan_color, :colorrange, :colorscale,
                      :calculated_colors])

    for (k, v) in uniforms
        k in IGNORE_KEYS && continue
        k in color_keys && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end

    if !isnothing(marker)
        get!(uniform_dict, :shape_type) do
            return lift(plot, marker; ignore_equal_values=true) do marker
                return Cint(Makie.marker_to_sdf_shape(to_spritemarker(marker)))
            end
        end
    end

    if uniform_dict[:shape_type][] == 3
        atlas = wgl_texture_atlas()
        uniform_dict[:distancefield] = NoDataTextureAtlas(size(atlas.data))
        uniform_dict[:atlas_texture_size] = Float32(size(atlas.data, 1)) # Texture must be quadratic
    else
        uniform_dict[:atlas_texture_size] = 0f0
        uniform_dict[:distancefield] = Observable(false)
    end

    handle_color!(plot, uniform_dict, per_instance, :color)
    handle_color_getter!(uniform_dict, per_instance)

    if haskey(uniform_dict, :color) && haskey(per_instance, :color)
        to_value(uniform_dict[:color]) isa Bool && delete!(uniform_dict, :color)
        to_value(per_instance[:color]) isa Bool && delete!(per_instance, :color)
    end

    instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1f0, 1f0))
    # Don't send obs, since it's overwritten in JS to be updated by the camera
    uniform_dict[:resolution] = to_value(scene.camera.resolution)
    uniform_dict[:px_per_unit] = 1f0

    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniform_dict[:picking] = false
    uniform_dict[:object_id] = UInt32(0)

    # Make sure these exist
    get!(uniform_dict, :strokewidth, 0f0)
    get!(uniform_dict, :strokecolor, RGBAf(0, 0, 0, 0))
    get!(uniform_dict, :glowwidth, 0f0)
    get!(uniform_dict, :glowcolor, RGBAf(0, 0, 0, 0))

    return InstancedProgram(WebGL(), lasset("sprites.vert"), lasset("sprites.frag"),
                            instance, VertexArray(; per_instance...), uniform_dict)
end

function create_shader(scene::Scene, plot::Scatter)
    # Potentially per instance attributes
    attributes = copy(plot.attributes.attributes)
    space = get(attributes, :space, :data)
    attributes[:preprojection] = Mat4f(I) # calculate this in JS
    attributes[:pos] = apply_transform_and_f32_conversion(scene, plot, plot[1], space)

    quad_offset = get(attributes, :marker_offset, Observable(Vec2f(0)))
    attributes[:marker_offset] = Vec3f(0)
    attributes[:quad_offset] = quad_offset
    attributes[:billboard] = lift(rot -> isa(rot, Billboard), plot, plot.rotation)
    attributes[:model] = map(Makie.patch_model, f32_conversion_obs(plot), plot.model)
    attributes[:depth_shift] = get(plot, :depth_shift, Observable(0f0))

    delete!(attributes, :uv_offset_width)
    filter!(kv -> !(kv[2] isa Function), attributes)
    return scatter_shader(scene, attributes, plot)
end

value_or_first(x::AbstractArray) = first(x)
value_or_first(x::StaticVector) = x
value_or_first(x::Mat) = x
value_or_first(x) = x

function create_shader(scene::Scene, plot::Makie.Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})
    glyphcollection = plot[1]
    f32c = f32_conversion_obs(plot)
    transfunc = transform_func_obs(plot)
    pos = plot.position
    space = plot.space
    offset = plot.offset

    atlas = wgl_texture_atlas()
    glyph_data = lift(plot, pos, glyphcollection, offset, f32c, transfunc, space; ignore_equal_values=true) do pos, gc, offset, f32c, transfunc, space
        Makie.text_quads(atlas, pos, to_value(gc), offset, f32c, transfunc, space)
    end

    # unpack values from the one signal:
    positions, char_offset, quad_offset, uv_offset_width, scale = map((1, 2, 3, 4, 5)) do i
        return lift(getindex, plot, glyph_data, i)
    end

    uniform_color = lift(plot, glyphcollection) do gc
        if gc isa AbstractArray
            reduce(vcat, (Makie.collect_vector(g.colors, length(g.glyphs)) for g in gc),
                init = RGBAf[])
        else
            Makie.collect_vector(gc.colors, length(gc.glyphs))
        end
    end

    uniform_rotation = lift(plot, glyphcollection) do gc
        if gc isa AbstractArray
            reduce(vcat, (Makie.collect_vector(g.rotations, length(g.glyphs)) for g in gc),
                init = Quaternionf[])
        else
            Makie.collect_vector(gc.rotations, length(gc.glyphs))
        end
    end

    plot_attributes = copy(plot.attributes)
    plot_attributes.attributes[:calculated_colors] = uniform_color
    uniforms = Dict(
        :model => map(Makie.patch_model, f32_conversion_obs(plot), plot.model),
        :shape_type => Observable(Cint(3)),
        :rotation => uniform_rotation,
        :pos => positions,
        :marker_offset => char_offset,
        :quad_offset => quad_offset,
        :markersize => scale,
        :preprojection => Mat4f(I),
        :uv_offset_width => uv_offset_width,
        :transform_marker => get(plot.attributes, :transform_marker, Observable(true)),
        :billboard => Observable(false),
        :depth_shift => get(plot, :depth_shift, Observable(0f0))
    )

    return scatter_shader(scene, uniforms, plot_attributes)
end
