using Makie: register_computation!

# Javascript Plot type (there are only three right now)
js_plot_type(plot::Makie.AbstractPlot) = "Mesh"
js_plot_type(plot::Union{Scatter, Makie.Text}) = "Scatter"
js_plot_type(plot::Union{Lines, LineSegments}) = "Lines"

function serialize_three(scene::Scene, plot::Makie.PrimitivePlotTypes)
    mesh = create_shader(scene, plot)

    mesh[:plot_type] = js_plot_type(plot)
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = plot.visible[]
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.attributes[:wgl_update_obs][]

    mesh[:overdraw] = plot.overdraw[]
    mesh[:transparency] = plot.transparency[]
    mesh[:zvalue] = Makie.zvalue2d(plot)
    mesh[:space] = plot.space[]

    if haskey(plot, :markerspace)
        mesh[:markerspace] = plot.markerspace[]
        mesh[:cam_space] = plot.markerspace[]
    else
        mesh[:cam_space] = plot.space[]
    end

    mesh[:uniforms][:uniform_clip_planes] = serialize_three(plot.uniform_clip_planes[])
    mesh[:uniforms][:uniform_num_clip_planes] = serialize_three(plot.uniform_num_clip_planes[])

    return mesh
end

function backend_colors!(attr, color_name = :scaled_color)
    # TODO: Shouldn't this be guaranteed?
    if !haskey(attr, :interpolate)
        Makie.add_input!(attr, :interpolate, false)
    end
    register_computation!(attr, [color_name, :interpolate, :fetch_pixel], [:uniform_color, :pattern]) do (color, interpolate, is_pattern), changed, last
        filter = interpolate ? :linear : :nearest
        if color isa Sampler
            return (color, is_pattern)
        elseif color isa AbstractMatrix || color isa AbstractArray{<:Any, 3}
            # TODO, don't construct a sampler every time
            return (Sampler(color, minfilter = filter), false)
        elseif color isa Union{Real, Colorant}
            return (color, false)
        else
            # Not a uniform color
            return (false, false)
        end
    end

    register_computation!(attr, [color_name], [:vertex_color]) do (color,), changed, last
        color isa Real && return (color,)
        return color isa AbstractVector ? (color,) : (false,)
    end

    return register_computation!(attr, [:alpha_colormap, :scaled_colorrange, :color_mapping_type], [:uniform_colormap, :uniform_colorrange]) do (cmap, crange, ctype), changed, last
        isnothing(crange) && return (false, false)
        cmap_minfilter = ctype === Makie.continuous ? :linear : :nearest
        cmap_changed = changed.alpha_colormap || changed.color_mapping_type
        cmap_s = cmap_changed ? Sampler(cmap, minfilter = cmap_minfilter) : nothing
        return (cmap_s, Vec2f(crange))
    end
end

function handle_color!(data, attr)
    set!(x) = haskey(attr, x) && (data[x] = attr[x])
    set!(:vertex_color)
    set!(:uniform_color)
    set!(:uniform_colormap)
    set!(:uniform_colorrange)
    set!(:highclip_color)
    set!(:lowclip_color)
    set!(:nan_color)
    return set!(:pattern)
end

function update_values!(updater, values::Bonito.LargeUpdate)
    isempty(values.data) && return
    updater[] = values
    return
end

function update_values!(updater, values)
    isempty(values) && return
    updater[] = values
    return
end

function plot_updates(args, changed)
    new_values = []
    # we currently dont handle update of these in JS
    disallowed = (:space, :markerspace)
    for (name, value) in pairs(args)
        if changed[name] && !isnothing(value) && !(name in disallowed)
            _val = if value isa Sampler
                [Int32[size(value.data)...], serialize_three(value.data)]
            else
                # Check if value is an array with all identical elements
                if Makie.is_vector_attribute(value) && length(value) > 1 && all(x -> x == value[1], value)
                    # Use compressed format for arrays with identical elements
                    Dict("value" => serialize_three(value[1]), "length" => length(value))
                else
                    serialize_three(value)
                end
            end
            push!(new_values, [name, _val])
        end
    end
    return new_values
end

function create_wgl_renderobject(callback, attr, inputs)
    # default case
    haskey(attr, :uniform_clip_planes) || Makie.add_computation!(attr, Val(:uniform_clip_planes))

    register_computation!(attr, inputs, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        if isnothing(last)
            program = callback(args)
            return (program, Observable{Any}([]))
        else
            updates = plot_updates(args, changed)
            last.wgl_renderobject[:visible] = args.visible
            update_values!(last.wgl_update_obs, Bonito.LargeUpdate(updates))
            return nothing
        end
    end
    return attr[:wgl_renderobject][]
end

function add_primitive_shading!(scene::Scene, attr)
    scene_shading = Makie.get_shading_mode(scene)
    return map!(attr, :shading, :primitive_shading) do shading
        s = (shading ? scene_shading : shading)
        shading = s isa Bool ? s : (s !== NoShading)
        return shading
    end
end

function handle_color_getter!(uniform_dict)
    vertex_color = uniform_dict[:vertex_color]
    if vertex_color isa Union{Real, AbstractArray{<:Real}} && !(vertex_color isa Bool)
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

function assemble_particle_robj!(attr, data)
    data[:positions_transformed_f32c] = attr.positions_transformed_f32c
    handle_color!(data, attr)
    handle_color_getter!(data)

    data[:converted_rotation] = attr.converted_rotation
    data[:f32c_scale] = attr.f32c_scale

    # Uniforms will be set in JavaScript
    data[:model_f32c] = attr.model_f32c
    data[:px_per_unit] = 0.0f0
    data[:picking] = false
    data[:object_id] = UInt32(0)

    data[:depth_shift] = attr.depth_shift
    data[:transform_marker] = attr.transform_marker
    per_instance_keys = Set(
        [
            :positions_transformed_f32c, :converted_rotation, :quad_offset, :quad_scale, :vertex_color,
            :intensity, :sdf_uv, :converted_strokecolor, :marker_offset, :markersize,
        ]
    )

    per_instance = filter(data) do (k, v)
        return k in per_instance_keys && !(Makie.isscalar(v))
    end

    filter!(data) do (k, v)
        return !(k in per_instance_keys && !(Makie.isscalar(v)))
    end

    return per_instance, data
end


function scatter_program(attr)
    dfield = attr.sdf_marker_shape === Cint(Makie.DISTANCEFIELD)
    atlas = attr.atlas
    distancefield = dfield ? NoDataTextureAtlas(size(atlas.data)) : false
    data = Dict(
        :resolution => Vec2f(0),
        :preprojection => Mat4f(I),
        :atlas_texture_size => Float32(size(atlas.data, 2)),
        :billboard => get(attr, :billboard, false),
        :distancefield => distancefield,

        :marker_offset => attr.marker_offset,
        # Optional if glyph_data is provided
        :sdf_uv => get(attr, :sdf_uv, Vec4f[]),
        :quad_scale => get(attr, :quad_scale, Vec2f[]),
        :quad_offset => get(attr, :quad_offset, Vec2f[]),
        :sdf_marker_shape => get(attr, :sdf_marker_shape, Vec2f[]),

        :strokewidth => attr.strokewidth,
        :converted_strokecolor => attr.converted_strokecolor,
        :glowwidth => attr.glowwidth,
        :glowcolor => attr.glowcolor,
        :pattern => get(attr, :pattern, false),
    )

    per_instance, uniforms = assemble_particle_robj!(attr, data)
    instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1.0f0, 1.0f0))

    data = create_instanced_shader(
        per_instance, instance, uniforms,
        lasset("sprites.vert"),
        lasset("sprites.frag")
    )

    if haskey(attr, :glyph_data)
        data[:glyph_data] = attr.glyph_data
    end
    return data
end

function create_shader(scene::Scene, plot::Scatter)
    attr = plot.attributes
    markersym = :marker
    if attr[:marker][] isa FastPixel
        # TODO, can we do this more elegantly?
        map!(attr, :marker, :fast_pixel_marker) do marker
            return Rect
        end
        markersym = :fast_pixel_marker
    end
    Makie.all_marker_computations!(attr, markersym)
    register_computation!(attr, [:sdf_marker_shape, :marker, :font], [:glyph_data]) do (shape, markers, fonts), changed, last
        shape != 3 && return nothing
        data = get_scatter_data(scene, markers, fonts)
        dict = Dict(:atlas_updates => data)
        return (dict,)
    end

    map!(attr, [:marker, :scaled_color], :scatter_color) do marker, color
        if marker isa AbstractMatrix
            return to_color(marker)
        else
            return color
        end
    end
    # For image markers (should this be a plot attribute?)
    Makie.add_constant!(attr, :interpolate, true)

    # ComputePipeline.alias!(attr, :rotation, :converted_rotation)
    ComputePipeline.alias!(attr, :strokecolor, :converted_strokecolor)

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    backend_colors!(attr, :scatter_color)
    inputs = [
        :positions_transformed_f32c,

        :vertex_color, :uniform_color, :uniform_colormap,
        :uniform_colorrange, :nan_color, :highclip_color,
        :lowclip_color, :pattern,

        :converted_rotation, :billboard, :quad_scale,
        :quad_offset, :sdf_uv, :sdf_marker_shape, :image,
        :strokewidth, :converted_strokecolor, :glowwidth,
        :glowcolor, :depth_shift, :atlas,
        :markerspace, :visible, :transform_marker, :f32c_scale,
        :model_f32c, :marker_offset, :glyph_data,
        :uniform_clip_planes, :uniform_num_clip_planes,
    ]
    return create_wgl_renderobject(scatter_program, attr, inputs)
end

const SCENE_ATLASES = Dict{Session, Set{UInt32}}()
const SCENE_ATLAS_LOCK = ReentrantLock()

function get_atlas_tracker(f, scene::Scene)
    return lock(SCENE_ATLAS_LOCK) do
        for (s, _) in SCENE_ATLASES
            Bonito.isclosed(s) && delete!(SCENE_ATLASES, s)
        end
        screen = Makie.getscreen(scene, WGLMakie)
        if isnothing(screen) || isnothing(screen.session)
            @warn "No session found, returning empty atlas tracker"
            # TODO, it's not entirely clear in which case this can happen,
            # which is why we don't just error, but just assume there isn't anything tracked
            return f(Set{UInt32}())
        end
        session = Bonito.root_session(screen.session)
        if haskey(SCENE_ATLASES, session)
            return f(SCENE_ATLASES[session])
        else
            atlas = Set{UInt32}()
            SCENE_ATLASES[session] = atlas
            return f(atlas)
        end
    end
end

function get_scatter_data(scene::Scene, markers, fonts)
    return get_atlas_tracker(Makie.root(scene)) do tracker
        atlas = Makie.get_texture_atlas()
        _, new_glyphs = Makie.get_glyph_data(atlas, tracker, markers, fonts)
        return new_glyphs
    end
end

function get_glyph_data(scene::Scene, glyphs, fonts)
    return get_atlas_tracker(Makie.root(scene)) do tracker
        atlas = Makie.get_texture_atlas()
        glyph_hashes, new_glyphs = Makie.get_glyph_data(atlas, tracker, glyphs, fonts)
        return glyph_hashes, new_glyphs
    end
end

function register_text_computation!(attr, scene)
    map!(attr, [:text_blocks, :text_scales], :glyph_scales) do text_blocks, fontsize
        return Makie.map_per_glyph(text_blocks, Vec2f, Makie.to_2d_scale(fontsize))
    end
    return register_computation!(attr, [:glyphindices, :font_per_char, :glyph_scales], [:glyph_data]) do (glyphs, fonts, glyph_scales), changed, last
        hashes, updates = get_glyph_data(scene, glyphs, fonts)
        dict = Dict(
            :glyph_hashes => hashes,
            :atlas_updates => updates,
            :scales => serialize_three(glyph_scales)
        )
        return (dict,)
    end
end

function create_shader(scene::Scene, plot::Makie.Text)
    # billboard for text causes glyph to not align correctly, should always be false
    attr = plot.attributes
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    backend_colors!(attr, :text_color)
    register_text_computation!(attr, scene)

    ComputePipeline.alias!(attr, :text_rotation, :converted_rotation)
    ComputePipeline.alias!(attr, :text_strokecolor, :converted_strokecolor)
    inputs = [
        :positions_transformed_f32c,

        :vertex_color, :uniform_color, :uniform_colormap, :uniform_colorrange,
        :nan_color, :highclip_color, :lowclip_color, :pattern,
        :strokewidth, :glowwidth, :glowcolor,

        :converted_rotation, :converted_strokecolor,
        :marker_offset, :sdf_marker_shape, :glyph_data,
        # :quad_scale, :quad_offset, :sdf_uv,
        :depth_shift, :atlas, :markerspace,

        :visible, :transform_marker, :f32c_scale, :model_f32c,
        :uniform_clip_planes, :uniform_num_clip_planes,
    ]
    return create_wgl_renderobject(scatter_program, attr, inputs)
end


to_3x3(mat::Mat{3, 3}) = mat
to_3x3(M::Mat{2, 3}) = Mat3f(M[1], M[2], 0, M[3], M[4], 0, M[5], M[6], 1)
to_3x3(xs::Vector{Vec2f}) = Sampler(xs) # already has appropriate format

function meshscatter_program(args)
    instance = Dict(
        :vertex_position => args.vertex_position,
        :faces => args.faces,
        :normal => args.normal,
    )
    if !isnothing(args.uv)
        instance[:uv] = args.uv
    end
    data = Dict{Symbol, Any}(
        :diffuse => args.diffuse,
        :specular => args.specular,
        :shininess => args.shininess,
        :pattern => false,
        :uniform_color => false,
        :wgl_uv_transform => args.wgl_uv_transform,
        :PICKING_INDEX_FROM_UV => false,
        :shading => args.primitive_shading,
        :backlight => args.backlight,
        :interpolate_in_fragment_shader => false,
        :markersize => args.markersize,
        :f32c_scale => args.f32c_scale,
        # Note: uv needs to be generated via register_computation! to allow updates
        :uv => Vec2f(0),
    )
    per_instance, uniforms = assemble_particle_robj!(args, data)
    return create_instanced_shader(
        per_instance, instance, uniforms,
        lasset("particles.vert"),
        lasset("mesh.frag")
    )
end


function create_shader(scene::Scene, plot::MeshScatter)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:disassemble_mesh), :marker)
    Makie.add_computation!(attr, scene, Val(:uv_transform_packing))
    map!(to_3x3, attr, :packed_uv_transform, :wgl_uv_transform)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    Makie.register_world_normalmatrix!(attr)
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    backend_colors!(attr)
    add_primitive_shading!(scene, attr)
    ComputePipeline.alias!(attr, :rotation, :converted_rotation)

    inputs = [
        :vertex_position, :faces, :normal, :uv, # marker mesh
        :uniform_colormap, :uniform_color, :uniform_colorrange, :vertex_color,
        :wgl_uv_transform, :pattern,
        :positions_transformed_f32c, :markersize, :converted_rotation, :f32c_scale,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :fetch_pixel, :model_f32c,
        :space,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :transform_marker, :primitive_shading, :depth_shift,
        :uniform_clip_planes, :uniform_num_clip_planes, :visible,
    ]
    return create_wgl_renderobject(meshscatter_program, attr, inputs)
end

# TODO, speed up GeometryBasics
function fast_uv(nvertices)
    xrange, yrange = LinRange.((0, 1), (1, 0), nvertices)
    return [Vec2f(x, y) for y in yrange for x in xrange]
end
xy_convert(x::Makie.EndPoints, n) = LinRange(x..., n + 1)
xy_convert(x::AbstractArray, n) = x

import Makie: EndPoints

function add_uv_mesh!(attr)
    if !haskey(attr, :positions)
        register_computation!(
            attr, [:data_limits, :x, :y, :image, :transform_func],
            [:faces, :texturecoordinates, :wgl_positions]
        ) do (rect, x, y, z, t), changed, last

            if x isa EndPoints && y isa EndPoints && Makie.is_identity_transform(t)
                init = isnothing(last) # these are constant after init
                faces = init ? decompose(GLTriangleFace, Rect2f(rect)) : nothing
                uv = init ? decompose_uv(Rect2f(rect)) : nothing
                return (faces, uv, decompose(Point2d, Rect2d(rect)))
            else
                px = WGLMakie.xy_convert(x, size(z, 1))
                py = WGLMakie.xy_convert(y, size(z, 2))
                grid_ps = Makie.matrix_grid(px, py, zeros(length(px), length(py)))
                res = (length(px), length(py))
                faces = WGLMakie.fast_faces(res)
                uv = WGLMakie.fast_uv(res)
                return (faces, uv, grid_ps)
            end
        end
        Makie.register_position_transforms!(attr, input_name = :wgl_positions, transformed_name = :positions_transformed)
    else
        _rect = Rect2f(0, 0, 1, 1)
        add_constant!(attr, :faces, decompose(GLTriangleFace, _rect))
        add_constant!(attr, :texturecoordinates, decompose_uv(_rect))
    end

    if !haskey(attr, :normals)
        Makie.add_constants!(
            attr, normals = nothing, primitive_shading = false,
            diffuse = Vec3f(0), specular = Vec3f(0), shininess = 0.0f0, backlight = 0.0f0
        )
    end
    return if !haskey(attr, :wgl_uv_transform)
        Makie.add_constant!(attr, :wgl_uv_transform, Makie.uv_transform(:flip_y))
    end
end

function mesh_program(attr)

    data = Dict(
        :shading => attr.primitive_shading,
        :diffuse => attr.diffuse,
        :specular => attr.specular,
        :shininess => attr.shininess,
        :backlight => attr.backlight,

        :model_f32c => attr.model_f32c,
        :PICKING_INDEX_FROM_UV => true,
        :wgl_uv_transform => attr.wgl_uv_transform,
        :depth_shift => attr.depth_shift,
        :world_normalmatrix => attr.world_normalmatrix,
        :interpolate_in_fragment_shader => true
    )

    handle_color!(data, attr)
    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    data[:picking] = false
    data[:object_id] = UInt32(0)
    is_vertex((_, x)) = begin
        (x isa AbstractVector) && !Makie.is_scalar_attribute(x) && (length(x) == length(attr.positions_transformed_f32c))
    end
    uniforms = filter(!is_vertex, data)
    buffers = filter(is_vertex, data)
    if !isnothing(attr.normals)
        buffers[:normals] = attr.normals
    else
        uniforms[:normals] = Vec3f(0)
    end
    if !isnothing(attr.texturecoordinates)
        buffers[:texturecoordinates] = attr.texturecoordinates
    else
        uniforms[:texturecoordinates] = Vec2f(0)
    end
    buffers[:positions_transformed_f32c] = attr.positions_transformed_f32c
    buffers[:faces] = attr.faces

    return create_shader(buffers, uniforms, lasset("mesh.vert"), lasset("mesh.frag"))
end

function create_shader(::Scene, plot::Union{Heatmap, Image})
    attr = plot.attributes
    if plot isa Image
        map!(to_3x3, attr, :uv_transform, :wgl_uv_transform)
    end
    add_uv_mesh!(attr)
    backend_colors!(attr)
    Makie.register_world_normalmatrix!(attr)

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :uniform_colormap, :uniform_color, :vertex_color, :uniform_colorrange, :color_mapping_type, :pattern, :interpolate,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :wgl_uv_transform, :fetch_pixel, :primitive_shading,
        :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
        :uniform_clip_planes, :uniform_num_clip_planes, :visible,
    ]
    return create_wgl_renderobject(mesh_program, attr, inputs)
end

function create_shader(scene::Scene, plot::Makie.Mesh)
    attr = plot.attributes
    Makie.register_world_normalmatrix!(attr)
    map!(to_3x3, attr, :pattern_uv_transform, :wgl_uv_transform)
    backend_colors!(attr)
    add_primitive_shading!(scene, attr)
    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :uniform_colormap, :uniform_color, :vertex_color, :uniform_colorrange, :pattern,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :wgl_uv_transform, :fetch_pixel, :primitive_shading, :color_mapping_type,
        :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
        :uniform_clip_planes, :uniform_num_clip_planes, :visible,
    ]
    return create_wgl_renderobject(mesh_program, attr, inputs)
end


# TODO, speed up GeometryBasics
function fast_faces(nvertices)
    w, h = nvertices
    idx = LinearIndices(nvertices)
    nfaces = 2 * (w - 1) * (h - 1)
    faces = Vector{GLTriangleFace}(undef, nfaces)
    face_idx = 1
    @inbounds for i in 1:(w - 1)
        for j in 1:(h - 1)
            a, b, c, d = idx[i, j], idx[i + 1, j], idx[i + 1, j + 1], idx[i, j + 1]
            faces[face_idx] = GLTriangleFace(a, b, c)
            face_idx += 1
            faces[face_idx] = GLTriangleFace(a, c, d)
            face_idx += 1
        end
    end
    return faces
end

function create_shader(scene::Scene, plot::Surface)
    attr = plot.attributes
    Makie.add_computation!(attr, Val(:surface_as_mesh))
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))
    backend_colors!(attr)

    map!(attr, [:pattern_uv_transform, :z, :pattern], :wgl_uv_transform) do uvt, zs, is_pattern
        is_pattern && return to_3x3(uvt) # no rescaling, just shifting
        # Rescale and shift uvs so that vertices map to pixel centers in the texture
        # if the texture size and grid size match (i.e. no explicit `color = tex`)
        s = size(zs)
        scale = Vec2f((s .- 1) ./ s)
        trans = Vec2f(0.5 ./ s)
        # order matters, e.g. for :rotr90
        return to_3x3(uvt) * Makie.uv_transform(trans, scale)
    end
    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    add_primitive_shading!(scene, attr)
    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :uniform_colormap, :uniform_color, :vertex_color, :uniform_colorrange, :pattern,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :wgl_uv_transform, :fetch_pixel, :primitive_shading, :color_mapping_type,
        :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
        :uniform_clip_planes, :uniform_num_clip_planes, :visible,
    ]
    return create_wgl_renderobject(mesh_program, attr, inputs)
end

function create_volume_shader(attr)
    box = GeometryBasics.mesh(Rect3f(Vec3f(0), Vec3f(1)))
    uniforms = Dict{Symbol, Any}(
        :modelinv => attr.modelinv,
        :isovalue => attr.isovalue,
        :isorange => attr.isorange,
        :absorption => attr.absorption,
        :algorithm => attr.algorithm,
        :diffuse => attr.diffuse,
        :specular => attr.specular,
        :shininess => attr.shininess,
        :model => attr.uniform_model,
        :depth_shift => attr.depth_shift,

        # these get filled in later by serialization, but we need them
        # as dummy values here, so that the correct uniforms are emitted
        :eyeposition => Vec3f(1),
        :picking => false,
        :object_id => UInt32(0),
    )
    handle_color!(uniforms, attr)
    return create_shader(box, uniforms, lasset("volume.vert"), lasset("volume.frag"))
end

function create_shader(scene::Scene, plot::Volume)
    attr = plot.attributes

    Makie.add_computation!(attr, scene, Val(:uniform_model)) # bit different from voxel_model
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :uniform_model)

    # TODO: reuse in clip planes
    register_computation!(attr, [:uniform_model], [:modelinv]) do (model,), changed, cached
        return (Mat4f(inv(model)),)
    end
    backend_colors!(attr)
    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :vertex_color, :uniform_color, :uniform_colormap, :uniform_colorrange, :pattern,
        :modelinv, :algorithm, :absorption, :isovalue, :isorange,
        :diffuse, :specular, :shininess, :backlight, :depth_shift,
        :lowclip_color, :highclip_color, :nan_color,
        :uniform_model, :uniform_num_clip_planes, :uniform_clip_planes, :visible,
    ]
    return create_wgl_renderobject(create_volume_shader, attr, inputs)
end


function create_lines_data(islines, attr)
    uniforms = Dict(
        :model_f32c => attr.model_f32c,
        :depth_shift => attr.depth_shift,
        :picking => false,
        :linecap => attr.linecap,
        :scene_origin => attr.scene_origin,
    )

    if islines
        uniforms[:joinstyle] = attr.joinstyle
        uniforms[:miter_limit] = attr.gl_miter_limit
    end

    uniforms[:uniform_pattern] = attr.uniform_pattern
    uniforms[:uniform_pattern_length] = attr.uniform_pattern_length

    handle_color!(uniforms, attr)

    attributes = Dict{Symbol, Any}(
        :positions_transformed_f32c => serialize_buffer_attribute(attr.positions_transformed_f32c),
    )

    for name in [:line_color, :uniform_linewidth]
        vals = attr[name]
        if Makie.is_scalar_attribute(vals)
            uniforms[name] = vals
        else
            attributes[name] = serialize_buffer_attribute(vals)
        end
    end

    return Dict(
        :plot_type => "Lines",
        :visible => attr.visible,
        :is_segments => !islines,
        :cam_space => attr.space,
        :uniforms => serialize_uniforms(uniforms),
        :attributes => attributes,
        :transparency => attr.transparency,
    )
end

using Makie.ComputePipeline

function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    attr = plot.attributes

    Makie.add_computation!(attr, :uniform_pattern, :uniform_pattern_length)
    backend_colors!(attr)

    islines = plot isa Lines

    Makie.add_computation!(attr, Val(:uniform_clip_planes), :clip)

    inputs = [
        :positions_transformed_f32c,
        :line_color, :uniform_colormap, :uniform_colorrange, :color_mapping_type, :lowclip_color, :highclip_color, :nan_color,
        :linecap, :uniform_linewidth, :uniform_pattern, :uniform_pattern_length,
        :space, :scene_origin, :model_f32c, :depth_shift, :transparency, :visible,
        :uniform_clip_planes, :uniform_num_clip_planes,
    ]

    map!(attr, [:uniform_color, :vertex_color], :line_color) do uc, vc
        return vc == false ? uc : vc
    end
    if islines
        Makie.add_computation!(attr, :gl_miter_limit)
        push!(inputs, :joinstyle, :gl_miter_limit)
    end
    dict = create_wgl_renderobject(args -> create_lines_data(islines, args), attr, inputs)
    dict[:uuid] = js_uuid(plot)
    dict[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    dict[:updater] = attr[:wgl_update_obs][]
    dict[:uniforms][:uniform_clip_planes] = serialize_three(plot.uniform_clip_planes[])
    dict[:uniforms][:uniform_num_clip_planes] = serialize_three(plot.uniform_num_clip_planes[])
    dict[:overdraw] = plot.overdraw[]
    dict[:zvalue] = Makie.zvalue2d(plot)
    return dict
end
