# TODO to be deleted once text is moved!

function handle_old_color!(plot, uniforms; permute_tex=true)
    color = plot.calculated_colors
    minfilter = to_value(get(plot, :interpolate, true)) ? :linear : :nearest

    convert_texture(x) = permute_tex ? lift(permutedims, plot, x) : x

    if color[] isa Colorant
        uniforms[:uniform_color] = color
    elseif color[] isa ShaderAbstractions.Sampler
        uniforms[:uniform_color] = to_value(color)
    elseif color[] isa AbstractVector
        uniforms[:vertex_color] = Buffer(color)
    elseif color[] isa Makie.AbstractPattern
        uniforms[:pattern] = true
        img = convert_texture(map(Makie.to_image, plot, color))
        uniforms[:uniform_color] = Sampler(img; x_repeat = :repeat, minfilter=minfilter)
        # different default with Patterns (no swapping and flipping of axes)
        # also includes px to uv coordinate transform so we can use linear
        # interpolation (no jitter) and related pattern to (0,0,0) in world space
        scene = Makie.parent_scene(plot)
        uniforms[:uv_transform] = map(plot,
                plot.attributes[:uv_transform], scene.camera.projectionview,
                scene.camera.resolution, plot.model, color # TODO float32convert
            ) do uvt, pv, res, model, pattern
            return Makie.pattern_uv_transform(uvt, pv * model, res, pattern, true)
        end
    elseif color[] isa Union{AbstractMatrix, AbstractArray{<: Any, 3}}
        uniforms[:uniform_color] = Sampler(convert_texture(color); minfilter=minfilter)
    elseif color[] isa Makie.ColorMapping
        if color[].color_scaled[] isa AbstractVector
            uniforms[:vertex_color] = Buffer(color[].color_scaled)
        else
            color_scaled = convert_texture(color[].color_scaled)
            uniforms[:uniform_color] = Sampler(color_scaled; minfilter=minfilter)
        end
        cm_minfilter = color[].color_mapping_type[] === Makie.continuous ? :linear : :nearest
        uniforms[:uniform_colormap] = Sampler(color[].colormap, minfilter = cm_minfilter)
        uniforms[:uniform_colorrange] = color[].colorrange_scaled
        uniforms[:highclip_color] = Makie.highclip(color[])
        uniforms[:lowclip_color] = Makie.lowclip(color[])
        uniforms[:nan_color] = color[].nan_color
    else
        error("Color type not supported: $(typeof(color[]))")
    end
    get!(uniforms, :vertex_color, false)
    get!(uniforms, :uniform_color, false)
    get!(uniforms, :uniform_colormap, false)
    get!(uniforms, :uniform_colorrange, false)
    get!(uniforms, :pattern, false)
    get!(uniforms, :highclip_color, RGBAf(0, 0, 0, 0))
    get!(uniforms, :lowclip_color, RGBAf(0, 0, 0, 0))
    get!(uniforms, :nan_color, RGBAf(0, 0, 0, 0))
    return
end

function handle_color_getter!(uniform_dict)
    vertex_color = uniform_dict[:vertex_color]
    if vertex_color isa AbstractArray{<:Real}
        uniform_dict[:vertex_color_getter] = """
            vec4 get_vertex_color(){
                vec2 norm = get_uniform_colorrange();
                float cmin = norm.x;
                float cmax = norm.y;
                float value = vertex_color;
                if (value <= cmax && value >= cmin) {
                    // in value range, continue!
                } else if (value < cmin) {
                    return get_lowclip_color();
                } else if (value > cmax) {
                    return get_highclip_color();
                } else {
                    // isnan is broken (of course) -.-
                    // so if outside value range and not smaller/bigger min/max we assume NaN
                    return get_nan_color();
                }
                float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
                // 1/0 corresponds to the corner of the colormap, so to properly interpolate
                // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
                float stepsize = 1.0 / float(textureSize(uniform_colormap, 0));
                i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
                return texture(uniform_colormap, vec2(i01, 0.0));
            }
        """
    end
    return
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
Base.size(x::NoDataTextureAtlas) = x.dims
Base.show(io::IO, ::NoDataTextureAtlas) = print(io, "NoDataTextureAtlas()")

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
    all_keys = [
        :positions_transformed_f32c,
        :vertex_color,
        :uniform_color,
        :uniform_colormap,
        :uniform_colorrange,
        :nan_color,
        :highclip_color,
        :lowclip_color,
        :pattern,

        :rotation,
        :quad_scale,
        :quad_offset,
        :sdf_uv,
        :sdf_marker_shape,
        :image,
        :strokewidth,
        :strokecolor,
        :glowwidth,
        :glowcolor,
        :depth_shift,
        :atlas_1024_32,
        :markerspace,
        :visible,
        :transform_marker,
        :f32c_scale,
        :uv_offset_width,
        :markersize,
        :marker_offset,
        :model_f32c,
        :preprojection,
        :billboard
    ]
    per_instance_keys = [:positions_transformed_f32c, :rotation, :quad_scale, :vertex_color, :intensity,
                         :uv_offset_width, :quad_scale, :quad_offset, :marker_offset, :sdf_uv]
    data = Dict{Symbol,Any}()
    marker = nothing
    atlas = wgl_texture_atlas()
    if haskey(attributes, :marker)
        font =  attributes.font[]
        marker = lift(plot, attributes[:marker]) do marker
            marker isa Makie.FastPixel && return Rect # FastPixel not supported, but same as Rect just slower
            marker isa AbstractMatrix{<:Colorant} && return to_color(marker)
            return Makie.to_spritemarker(marker)
        end

        markersize = lift(Makie.to_2d_scale, plot, attributes[:markersize])

        msize, offset = Makie.marker_attributes(atlas, marker, markersize, font, plot)
        data[:markersize] = msize
        data[:quad_offset] = offset
        data[:uv_offset_width] = Makie.primitive_uv_offset_width(atlas, marker, font)
        if to_value(marker) isa AbstractMatrix
            data[:uniform_color] = Sampler(lift(el32convert, plot, marker))
        end
    end
    for key in all_keys
        if haskey(attributes, key)
            data[key] = attributes[key]
        end
    end
    handle_old_color!(plot, data)
    handle_color_getter!(data)

    per_instance = filter(data) do (k, v)
        _v = to_value(v)
        return k in per_instance_keys && (!(Makie.isscalar(_v)) || _v isa Buffer)
    end

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, plot))
    end

    uniform_dict = filter(data) do (k, v)
        return !haskey(per_instance, k)
    end

    color_keys = Set([:uniform_color, :uniform_colormap, :highclip_color, :lowclip_color, :nan_color, :colorrange, :colorscale,
                      :calculated_colors])

    for (k, v) in uniform_dict
        k in IGNORE_KEYS && continue
        k in color_keys && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end
    if !isnothing(marker)
        get!(uniform_dict, :sdf_marker_shape) do
            return lift(plot, marker; ignore_equal_values=true) do marker
                return Cint(Makie.marker_to_sdf_shape(to_spritemarker(marker)))
            end
        end
    end

    if uniform_dict[:sdf_marker_shape][] == 3
        atlas = wgl_texture_atlas()
        uniform_dict[:distancefield] = NoDataTextureAtlas(size(atlas.data))
        uniform_dict[:atlas_texture_size] = Float32(size(atlas.data, 1)) # Texture must be quadratic
    else
        uniform_dict[:atlas_texture_size] = 0f0
        uniform_dict[:distancefield] = Observable(false)
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
    _, arr = first(per_instance)
    if any(v-> length(arr) != length(v), values(per_instance))
        lens = [k => length(v) for (k, v) in per_instance]
        error("Not all have the same length: $(lens)")
    end
    return InstancedProgram(WebGL(), lasset("sprites.vert"), lasset("sprites.frag"),
                            instance, VertexArray(; per_instance...), uniform_dict)
end

const IGNORE_KEYS = Set([
    :shading, :overdraw, :distancefield, :space, :markerspace, :fxaa,
    :visible, :transformation, :alpha, :linewidth, :transparency, :marker,
    :light_direction, :light_color,
    :cycle, :label, :inspector_clear, :inspector_hover,
    :inspector_label, :axis_cyclerr, :dim_conversions, :material, :clip_planes
    # TODO add model here since we generally need to apply patch_model?
])

value_or_first(x::AbstractArray) = first(x)
value_or_first(x::StaticVector) = x
value_or_first(x::Mat) = x
value_or_first(x) = x

function create_shader(scene::Scene, plot::Makie.Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})
    glyphcollection = plot[1]
    f32c, model = Makie.patch_model(plot)
    pos = apply_transform_and_f32_conversion(plot, f32c, plot.position)
    offset = plot.offset

    atlas = wgl_texture_atlas()
    glyph_data = lift(plot, pos, glyphcollection, offset; ignore_equal_values=true) do pos, gc, offset
        Makie.text_quads(atlas, pos, to_value(gc), offset)
    end

    # unpack values from the one signal:
    positions, char_offset, quad_offset, uv_offset_width, scale = map((1, 2, 3, 4, 5)) do i
        return lift(getindex, plot, glyph_data, i; ignore_equal_values=true)
    end

    uniform_color = lift(plot, glyphcollection; ignore_equal_values=true) do gc
        if gc isa AbstractArray
            reduce(vcat, (Makie.collect_vector(g.colors, length(g.glyphs)) for g in gc);
                    init=RGBAf[])
        else
            gc.colors.sv
        end
    end
    uniform_rotation = lift(plot, glyphcollection; ignore_equal_values=true) do gc
        if gc isa AbstractArray
            reduce(vcat, (Makie.collect_vector(g.rotations, length(g.glyphs)) for g in gc);
                    init=Quaternionf[])
        else
            gc.rotations.sv
        end
    end

    plot_attributes = copy(plot.attributes)
    plot_attributes.attributes[:calculated_colors] = uniform_color
    uniforms = Dict(
        :model_f32c => model,
        :sdf_marker_shape => Observable(Cint(3)),
        :rotation => uniform_rotation,
        :positions_transformed_f32c => positions,
        :marker_offset => char_offset,
        :quad_offset => quad_offset,
        :quad_scale => scale,
        :preprojection => Mat4f(I),
        :sdf_uv => uv_offset_width,
        :transform_marker => get(plot.attributes, :transform_marker, Observable(true)),
        :billboard => Observable(false),
        :depth_shift => get(plot, :depth_shift, Observable(0f0)),
        :glowwidth => plot.glowwidth,
        :glowcolor => plot.glowcolor,
    )

    Makie.add_f32c_scale!(uniforms, scene, plot, f32c)

    return scatter_shader(scene, uniforms, plot_attributes)
end
