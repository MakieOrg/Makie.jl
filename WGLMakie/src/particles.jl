
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
    :inspector_label, :axis_cyclerr, :dim_conversions, :material, :clip_planes
    # TODO add model here since we generally need to apply patch_model?
])

function create_shader(scene::Scene, plot::MeshScatter)
    # Potentially per instance attributes
    per_instance_keys = (:rotation, :markersize, :intensity)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(v[]))
    end

    f32c, model = Makie.patch_model(plot)
    per_instance[:offset] = apply_transform_and_f32_conversion(plot, f32c, plot[1])

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

    # TODO: allow passing Mat{2, 3, Float32} (and nothing)
    uv_transform = map(plot, plot[:uv_transform]) do x
        M = convert_attribute(x, Key{:uv_transform}(), Key{:meshscatter}())
        # why transpose?
        T = Mat3f(0,1,0, 1,0,0, 0,0,1)
        if M === nothing
            return T
        elseif M isa Mat
            return T * Mat3f(M[1], M[2], 0, M[3], M[4], 0, M[5], M[6], 1)
        elseif M isa Vector
            return [T * Mat3f(m[1], m[2], 0, m[3], m[4], 0, m[5], m[6], 1) for m in M]
        end
    end

    if to_value(uv_transform) isa Vector
        per_instance[:uv_transform] = Buffer(uv_transform)
    else
        uniform_dict[:uv_transform] = uv_transform
    end

    handle_color!(plot, uniform_dict, per_instance)
    # handle_color_getter!(uniform_dict, per_instance)
    instance = convert_attribute(plot.marker[], key"marker"(), key"meshscatter"())
    uniform_dict[:interpolate_in_fragment_shader] = get(plot, :interpolate_in_fragment_shader, false)
    uniform_dict[:transform_marker] = get(plot, :transform_marker, false)

    # See GLMakie/drawing_primtives.jl
    if isnothing(scene.float32convert)
        uniform_dict[:f32c_scale] = Vec3f(1)
    else
        uniform_dict[:f32c_scale] = map(plot, f32c, scene.float32convert.scaling, plot.transform_marker) do new_f32c, old_f32c, transform_marker
            return Vec3f(transform_marker ? new_f32c.scale : old_f32c.scale)
        end
    end

    if haskey(uniform_dict, :color) && haskey(per_instance, :color)
        to_value(uniform_dict[:color]) isa Bool && delete!(uniform_dict, :color)
        to_value(per_instance[:color]) isa Bool && delete!(per_instance, :color)
    end

    if !hasproperty(instance, :uv)
        uniform_dict[:uv] = Vec2f(0)
    end
    if !hasproperty(instance, :normal)
        uniform_dict[:normal] = Vec3f(0)
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
    get!(uniform_dict, :PICKING_INDEX_FROM_UV, false)

    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    uniform_dict[:picking] = false
    uniform_dict[:object_id] = UInt32(0)
    uniform_dict[:shading] = map(x -> x != NoShading, plot.shading)

    uniform_dict[:model] = model
    program = InstancedProgram(WebGL(), lasset("particles.vert"), lasset("mesh.frag"),
                            instance, VertexArray(; per_instance...), uniform_dict)
    return program, nothing
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
    per_instance_keys = (:pos, :rotation, :markersize, :color, :intensity,
                         :uv_offset_width, :quad_offset, :marker_offset)
    uniform_dict = Dict{Symbol,Any}()
    uniform_dict[:image] = false
    marker = nothing
    atlas = Makie.get_texture_atlas()
    if haskey(attributes, :marker)
        font = map(Makie.to_font, pop!(attributes, :font))
        marker = lift(plot, attributes[:marker]) do marker
            marker isa Makie.FastPixel && return Rect # FastPixel not supported, but same as Rect just slower
            marker isa AbstractMatrix{<:Colorant} && return to_color(marker)
            return Makie.to_spritemarker(marker)
        end

        markersize = lift(Makie.to_2d_scale, plot, attributes[:markersize])
        msize, offset = Makie.marker_attributes(atlas, marker, markersize, font, plot)
        attributes[:markersize] = msize
        attributes[:quad_offset] = offset
        attributes[:uv_offset_width] = Makie.primitive_uv_offset_width(atlas, marker, font)

        if to_value(marker) isa AbstractMatrix
            uniform_dict[:image] = Sampler(lift(el32convert, plot, marker))
        end
    end

    per_instance = filter(attributes) do (k, v)
        return k in per_instance_keys && !(isscalar(to_value(v)))
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
        atlas = Makie.get_texture_atlas()
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

    # TODO, bring back in observable refactor
    # _, arr = first(per_instance)
    # if any(v-> length(arr) != length(v), values(per_instance))
    #     lens = [k => length(v) for (k, v) in per_instance]
    #     error("Not all have the same length: $(lens)")
    # end
    program = InstancedProgram(WebGL(), lasset("sprites.vert"), lasset("sprites.frag"),
                            instance, VertexArray(; per_instance...), uniform_dict)
    return program
end

function get_scatter_data(scene::Scene, markers, fonts)
    tracker = get_atlas_tracker(Makie.root(scene))
    atlas = Makie.get_texture_atlas()
    _, new_glyphs = Makie.get_glyph_data(atlas, tracker, markers, fonts)
    return new_glyphs
end

function get_glyph_data(scene::Scene, glyphs, fonts)
    tracker = get_atlas_tracker(Makie.root(scene))
    atlas = Makie.get_texture_atlas()
    glyph_hashes, new_glyphs = Makie.get_glyph_data(atlas, tracker, glyphs, fonts)
    return glyph_hashes, new_glyphs
end

function create_shader(scene::Scene, plot::Scatter)
    # Potentially per instance attributes
    # create new dict so we don't automatically convert to observables
    # Which is the case for Dict{Symbol, Observable}
    attributes = Dict{Symbol, Any}()
    for (k, v) in plot.attributes.attributes
        attributes[k] = v
    end
    space = get(attributes, :space, :data)
    attributes[:preprojection] = Mat4f(I) # calculate this in JS
    f32c, model = Makie.patch_model(plot)
    attributes[:pos] = apply_transform_and_f32_conversion(plot, f32c, plot[1], space)

    Makie.add_f32c_scale!(attributes, scene, plot, f32c)

    attributes[:billboard] = lift(rot -> isa(rot, Billboard), plot, plot.rotation)
    attributes[:model] = model
    attributes[:depth_shift] = get(plot, :depth_shift, Observable(0f0))

    delete!(attributes, :uv_offset_width)
    filter!(kv -> !(kv[2] isa Function), attributes)
    program = scatter_shader(scene, attributes, plot)
    if program.program.uniforms[:shape_type][] == 3
        glyph_data = lift(plot, plot.marker, plot.font) do marker, font
            f = Makie.to_font(font)
            data = get_scatter_data(scene, to_spritemarker(marker), f)
            return Dict("atlas_updates" => data)
        end
        additional = Dict(:glyph_data => glyph_data)
    else
        additional = nothing
    end
    return program, additional
end

value_or_first(x::AbstractArray) = first(x)
value_or_first(x::StaticVector) = x
value_or_first(x::Mat) = x
value_or_first(x) = x


const SCENE_ATLASES = Dict{Session, Set{UInt32}}()

function get_atlas_tracker(scene::Scene)
    for (s, _) in SCENE_ATLASES
        Bonito.isclosed(s) && delete!(SCENE_ATLASES, s)
    end
    screen = Makie.getscreen(scene, WGLMakie)
    if isnothing(screen.session)
        @warn "No session found, returning empty atlas tracker"
        # TODO, it's not entirely clear in which case this can happen,
        # which is why we don't just error, but just assume there isn't anything tracked
        return Set{UInt32}()
    end
    session = Bonito.root_session(screen.session)
    if haskey(SCENE_ATLASES, session)
        return SCENE_ATLASES[session]
    else
        atlas = Set{UInt32}()
        SCENE_ATLASES[session] = atlas
        return atlas
    end
end

function get_from_collection(glyphcollection::AbstractArray, name::Symbol, Typ)
    result = Typ[]
    for g in glyphcollection
        arr = getfield(g, name)
        if arr isa Vector
            append!(result, arr)
        else
            _arr = arr.sv
            if _arr isa Vector
                append!(result, _arr)
            else
                append!(result, (_arr for i in 1:length(g.glyphs)))
            end
        end
    end
    return result
end

expand_to_collection(::AbstractVector, vec::StaticVector) = vec
expand_to_collection(::Union{AbstractVector, Makie.GlyphCollection}, vec::Union{StaticVector, AbstractVector}) = vec
expand_to_collection(::Makie.GlyphCollection, arraylike) = arraylike
function expand_to_collection(glyphcollection::AbstractVector, arraylike::AbstractVector)
    if length(glyphcollection) !== length(arraylike)
        error("Length of glyphcollection and arraylike don't match")
    end

    return [arraylike[i] for (i, gc) in enumerate(glyphcollection) for _ in 1:length(gc.glyphs)]
end

function create_shader(scene::Scene, plot::Makie.Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})
    glyphcollection = plot[1]
    f32c, model = Makie.patch_model(plot)
    pos = apply_transform_and_f32_conversion(plot, f32c, plot.position)

    # Extract, so they only change when the extracted values change
    glyph_input = lift(plot, glyphcollection; ignore_equal_values=true) do gc
        glyphs = get_from_collection(gc, :glyphs, UInt64)
        fonts = get_from_collection(gc, :fonts, Makie.NativeFont)
        scales = get_from_collection(gc, :scales, Vec2f)
        return (glyphs, fonts), scales
    end

    marker_offset = lift(plot, glyphcollection, plot.offset; ignore_equal_values=true) do gc, offset
        origins = get_from_collection(gc, :origins, Point3f)
        offsets = expand_to_collection(gc, Makie.to_2d_scale(offset))
        return map(((i,o),)-> Vec3f(Vec3f(o) .+ to_ndim(Vec3f, Makie.sv_getindex(offsets, i), 0f9)), enumerate(origins))
    end
    all_glyph_data = lift(plot, glyph_input; ignore_equal_values=true) do args
        data = get_glyph_data(scene, args[1]...)
        return Dict(
            :glyph_hashes => data[1],
            :atlas_updates => data[2],
            :scales => serialize_three(args[2])
        )
    end

    uniform_color = lift(plot, glyphcollection; ignore_equal_values=true) do gc
        get_from_collection(gc, :colors, RGBAf)
    end

    uniform_rotation = lift(plot, glyphcollection; ignore_equal_values=true) do gc
        get_from_collection(gc, :rotations, Quaternionf)
    end

    glyph_lengths = lift(glyphcollection) do gc
        if gc isa AbstractArray
            return [length(g.glyphs) for g in gc]
        else
            return length(gc.glyphs)
        end
    end

    positions = lift(plot, glyph_lengths, pos; ignore_equal_values=true) do lengths, positions
        _pos = lengths isa Vector ? positions : [positions] # assuming they match?
        return [to_ndim(Point3f, p, 0) for (p, len) in zip(_pos, lengths) for _ in 1:len]
    end

    plot_attributes = copy(plot.attributes)
    plot_attributes.attributes[:calculated_colors] = uniform_color

    uniforms = Dict(
        :model => model,
        :shape_type => Observable(Cint(3)),
        :rotation => uniform_rotation,
        :pos => positions,

        # will be set in JS from glyph_data
        :marker_offset => marker_offset,
        :quad_offset => Vec2f[],
        :markersize => Vec2f[],
        :uv_offset_width => Vec4f[],

        :preprojection => Mat4f(I),
        :transform_marker => get(plot.attributes, :transform_marker, Observable(true)),
        :billboard => Observable(false),
        :depth_shift => get(plot, :depth_shift, Observable(0f0)),
        :glowwidth => plot.glowwidth,
        :glowcolor => plot.glowcolor,
    )

    Makie.add_f32c_scale!(uniforms, scene, plot, f32c)
    additional = Dict(:glyph_data => all_glyph_data)
    return scatter_shader(scene, uniforms, plot_attributes), additional
end
