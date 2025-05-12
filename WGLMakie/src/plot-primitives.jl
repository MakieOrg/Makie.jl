using Makie: register_computation!

js_plot_type(plot::Makie.AbstractPlot) = "Mesh"
js_plot_type(plot::Union{Scatter, Makie.Text}) = "Scatter"
js_plot_type(plot::Union{Lines, LineSegments}) = "Lines"

function serialize_three(scene::Scene, plot::Makie.ComputePlots)

    mesh = create_shader(scene, plot)

    mesh[:plot_type] = js_plot_type(plot)
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = plot.visible[]
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.args[1][:wgl_update_obs][]

    mesh[:overdraw] = plot.overdraw[]
    mesh[:transparency] = plot.transparency[]
    mesh[:space] = plot.space[]

    if haskey(plot, :markerspace)
        mesh[:markerspace] = plot.markerspace[]
        mesh[:cam_space] = plot.markerspace[]
    else
        mesh[:cam_space] = plot.space[]
    end

    mesh[:uniforms][:clip_planes] = serialize_three([Vec4f(0, 0, 0, -1e9) for _ in 1:8])
    mesh[:uniforms][:num_clip_planes] = serialize_three(0)

    return mesh
end

function backend_colors!(attr, color_name=:scaled_color)
    if !haskey(attr, :interpolate)
        Makie.add_input!(attr, :interpolate, false)
    end
    register_computation!(attr, [color_name, :interpolate], [:uniform_color, :pattern]) do (color, interpolate), changed, last
        filter = interpolate ? :linear : :nearest
        if color isa AbstractMatrix || color isa AbstractArray{<: Any, 3}
            # TODO, don't construct a sampler every time
            return (Sampler(color, minfilter=filter), false)
        elseif color isa Union{Real, Colorant}
            return (color, false)
        elseif color isa Makie.AbstractPattern
            color isa Makie.AbstractPattern
            img = Makie.to_image(color)
            sampler = Sampler(img; x_repeat = :repeat, minfilter=filter)
            return (sampler, true)
        else
            # Not a uniform color
            return (false, false)
        end
    end
    register_computation!(attr, [color_name], [:vertex_color]) do (color,), changed, last
        color isa AbstractVector ? (Buffer(color),) : (false,)
    end

    register_computation!(attr, [:alpha_colormap, :scaled_colorrange, :color_mapping_type], [:uniform_colormap, :uniform_colorrange]) do (cmap, crange, ctype), changed, last
        isnothing(crange) && return (false, false)
        cmap_minfilter = ctype === Makie.continuous ? :linear : :nearest
        cmap_changed = changed.alpha_colormap || changed.color_mapping_type
        cmap_s = cmap_changed ? Sampler(cmap, minfilter=cmap_minfilter) : nothing
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
    set!(:pattern)
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
    for (name, value) in pairs(args)
        if changed[name]
            _val = if value isa Sampler
                [Int32[size(value[].data)...], serialize_three(value.data)]
            else
                serialize_three(value)
            end
            push!(new_values, [name, _val])
        end
    end
    return new_values
end

function create_wgl_renderobject(callback, attr, inputs)
    register_computation!(attr, inputs, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        if isnothing(last)
            program = callback(args)
            return (program, Observable{Any}([]))
        else
            update_values!(last.wgl_update_obs, Bonito.LargeUpdate(plot_updates(args, changed)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
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

function assemble_particle_robj!(attr, data)
    data[:positions_transformed_f32c] = attr.positions_transformed_f32c
    handle_color!(data, attr)
    handle_color_getter!(data)

    data[:rotation] = get(()-> attr.text_rotation, attr, :rotation)
    data[:f32c_scale] = attr.f32c_scale

    # Uniforms will be set in JavaScript
    data[:model_f32c] = attr.model_f32c
    data[:px_per_unit] = 0f0
    data[:picking] = false
    data[:object_id] = UInt32(0)

    data[:depth_shift] = attr.depth_shift
    data[:transform_marker] = attr.transform_marker

    per_instance_keys = Set([
        :positions_transformed_f32c, :rotation, :quad_offset, :quad_scale, :vertex_color,
        :intensity, :sdf_uv, :strokecolor, :marker_offset
    ])

    per_instance = filter(data) do (k, v)
        return k in per_instance_keys && !(Makie.isscalar(v))
    end

    filter!(data) do (k, v)
        return !(k in per_instance_keys && !(Makie.isscalar(v)))
    end

    return per_instance, data
end

const SCATTER_INPUTS = [
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
    :atlas,
    :markerspace,

    :visible,
    :transform_marker,
    :f32c_scale,
    :model_f32c,
    :marker_offset,
    :glyph_data
]

function scatter_program(attr)
    dfield = attr.sdf_marker_shape === Cint(Makie.DISTANCEFIELD)
    atlas = attr.atlas
    distancefield = dfield ? NoDataTextureAtlas(size(atlas.data)) : false
    data = Dict(
        :resolution => Vec2f(0),
        :preprojection => Mat4f(I),
        :atlas_texture_size => Float32(size(atlas.data, 2)),
        :billboard => get(()-> attr.text_rotation, attr, :rotation) isa Billboard,
        :distancefield => distancefield,

        :marker_offset => attr.marker_offset,
        # Optional if glyph_data is provided
        :sdf_uv => get(attr, :sdf_uv, Vec4f[]),
        :quad_scale => get(attr, :quad_scale, Vec2f[]),
        :quad_offset => get(attr, :quad_offset, Vec2f[]),
        :sdf_marker_shape => get(attr, :sdf_marker_shape, Vec2f[]),

        :strokewidth => attr.strokewidth,
        :strokecolor => get(()-> attr.text_strokecolor, attr, :strokecolor),
        :glowwidth => attr.glowwidth,
        :glowcolor => attr.glowcolor,
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
    attr = plot.args[1]
    Makie.all_marker_computations!(attr)
    register_computation!(attr, [:sdf_marker_shape, :marker, :font], [:glyph_data]) do (shape, markers, fonts), changed, last
        shape != 3 && return nothing
        data = get_scatter_data(scene, markers, fonts)
        dict = Dict(:atlas_updates => data)
        return (dict,)
    end
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    backend_colors!(attr)
    return create_wgl_renderobject(scatter_program, attr, SCATTER_INPUTS)
end

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

function register_text_computation!(attr, scene)
    register_computation!(attr, [:glyphindices, :text_blocks, :text_scales], [:glyph_scales]) do (glyphs, text_blocks, fontsize), changed, last
        return (Makie.map_per_glyph(glyphs, text_blocks, Vec2f, Makie.to_2d_scale(fontsize)),)
    end

    register_computation!(attr, [:glyphindices, :font_per_char, :glyph_scales], [:glyph_data]) do (glyphs,fonts,glyph_scales), changed, last
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
    # TODO: color processing incorrect, processed per-glyphcollection/global
    #       colors instead of per glyph
    attr = plot.args[1]
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    backend_colors!(attr, :text_color)
    register_text_computation!(attr, scene)
    inputs = [
        :positions_transformed_f32c,

        :vertex_color, :uniform_color, :uniform_colormap, :uniform_colorrange, :nan_color, :highclip_color, :lowclip_color, :pattern,
        :strokewidth, :glowwidth, :glowcolor,

        :text_rotation, :text_strokecolor, # TODO: do these even work per glyph?
        :marker_offset, :sdf_marker_shape, :glyph_data,
        # :quad_scale, :quad_offset, :sdf_uv,
        :depth_shift, :atlas, :markerspace,

        :visible, :transform_marker, :f32c_scale, :model_f32c
    ]
    return create_wgl_renderobject(scatter_program, attr, inputs)
end


function meshscatter_program(args)
    instance = args.marker
    data = Dict{Symbol, Any}(
        :diffuse => args.diffuse,
        :specular => args.specular,
        :shininess => args.shininess,
        :pattern => false,
        :uniform_color => false,
        :uv_transform => Mat3f(I),
        :PICKING_INDEX_FROM_UV => false,
        :shading => args.shading == false || args.shading != NoShading,
        :backlight => args.backlight,
        :interpolate_in_fragment_shader => false,
        :markersize => args.markersize,
        :f32c_scale => args.f32c_scale,
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
    attr = plot.args[1]
    # generate_clip_planes!(attr, scene)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))
    Makie.add_computation!(attr, scene, Val(:uv_transform_packing), :pattern_uv_transform)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    Makie.register_world_normalmatrix!(attr)
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    backend_colors!(attr)
    inputs = [
        # Special
        :space,
        :uniform_colormap, :uniform_color, :uniform_colorrange, :vertex_color,
        :packed_uv_transform, :pattern,
        :positions_transformed_f32c, :markersize, :rotation, :f32c_scale,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :fetch_pixel, :model_f32c,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :transform_marker, :marker, :shading, :depth_shift
    ]
    return create_wgl_renderobject(meshscatter_program, attr, inputs)
end


function add_uv_mesh!(attr)
    if !haskey(attr, :positions)
        register_computation!(attr, [:data_limits], [:positions]) do (rect,), changed, last
            return (decompose(Point2f, Rect2f(rect)),)
        end
        Makie.register_position_transforms!(attr)
    end
    # These are constant so we just add them as inputs
    rect = Rect2f(0, 0, 1, 1)
    if !haskey(attr, :faces)
        Makie.add_input!(attr, :faces, decompose(GLTriangleFace, rect))
        Makie.add_input!(attr, :texturecoordinates, decompose_uv(rect))
        Makie.add_input!(attr, :normals, nothing)
        for name in [:diffuse, :specular]
            Makie.add_input!(attr, name, Vec3f(0))
        end

        Makie.add_input!(attr, :shininess, 0f0)
        Makie.add_input!(attr, :backlight, 0f0)
        Makie.add_input!(attr, :shading, false)
        Makie.add_input!(attr, :pattern_uv_transform, Mat3f(I))
    end
end

to_3x3(mat::Mat{3, 3}) = mat
function to_3x3(mat::Mat{2, 3})::Mat{3, 3}
    return Mat3f(mat[1, 1], mat[1, 2], 0, mat[2, 1], mat[2, 2], 0, 0, 0, 1)
end

function mesh_program(attr)
    i = Vec(1, 2, 3)
    uv_transform = to_3x3(attr.pattern_uv_transform)
    shading = attr.shading isa Bool ? attr.shading : attr.shading != NoShading
    data = Dict(

        :shading => shading,
        :diffuse => attr.diffuse,
        :specular => attr.specular,
        :shininess => attr.shininess,
        :backlight => attr.backlight,

        :model => Mat4f(attr.model_f32c),
        :PICKING_INDEX_FROM_UV => true,
        :uv_transform => Mat3f(I),
        :depth_shift => attr.depth_shift,
        :normalmatrix => attr.world_normalmatrix,
        :interpolate_in_fragment_shader => true
    )

    handle_color!(data, attr)
    # id + picking gets filled in JS, needs to be here to emit the correct shader uniforms
    data[:picking] = false
    data[:object_id] = UInt32(0)

    uniforms = filter(x-> !(x[2] isa Buffer), data)
    buffers = filter(x-> x[2] isa Buffer, data)

    if !isnothing(attr.normals)
        buffers[:normal] = attr.normals
    else
        uniforms[:normal] = Vec3f(0)
    end
    if !isnothing(attr.texturecoordinates)
        buffers[:uv] = attr.texturecoordinates
    else
        uniforms[:uv] = Vec2f(0)
    end
    buffers[:positions_transformed_f32c] = attr.positions_transformed_f32c
    buffers[:faces] = attr.faces

    return create_shader(buffers, uniforms, lasset("mesh.vert"), lasset("mesh.frag"))
end

function create_shader(::Scene, plot::Union{Heatmap, Image})
    attr = plot.args[1]
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
        :pattern_uv_transform, :fetch_pixel, :shading,
        :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
    ]
    return create_wgl_renderobject(mesh_program, attr, inputs)
end

function create_shader(scene::Scene, plot::Makie.Mesh)
    attr = plot.args[1]
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform); colorname = :mesh_color)
    backend_colors!(attr)
    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :uniform_colormap, :uniform_color, :vertex_color, :uniform_colorrange, :pattern,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :pattern_uv_transform, :fetch_pixel, :shading, :color_mapping_type,
        :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
    ]
    return create_wgl_renderobject(mesh_program, attr, inputs)
end

# This adjusts uvs (compared to decompose_uv) so texture sampling starts at
# the center of a texture pixel rather than the edge, fixing
# https://github.com/MakieOrg/Makie.jl/pull/2598#discussion_r1152552196
function _surface_uvs(nx, ny)
    if (nx, ny) == (2, 2)
        return Vec2f[(0,1), (1,1), (1,0), (0,0)]
    else
        f = Vec2f(1 / nx, 1 / ny)
        return [f .* Vec2f(0.5 + i, 0.5 + j) for j in ny-1:-1:0 for i in 0:nx-1]
    end
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


function surface2mesh_computation!(attr)
    register_computation!(attr, [:x, :y, :z], [:positions]) do (x, y, z), changed, last
        return (Makie.matrix_grid(identity, x, y, z),)
    end
    Makie.register_position_transforms!(attr)
    register_computation!(attr, [:z], [:_faces, :texturecoordinates, :z_size]) do (z,), changed, last
        last_size = isnothing(last) ? size(z) : last.z_size
        new_size = size(z)
        !isnothing(last) && last_size == new_size && return nothing
        rect = Tessellation(Rect2(0f0, 0f0, 1f0, 1f0), new_size)
        faces = fast_faces(new_size)
        return (faces, _surface_uvs(new_size...), new_size)
    end
    register_computation!(attr, [:_faces, :positions_transformed_f32c], [:faces]) do (fs, ps), changed, last
        return (filter(f -> !any(i -> (i > length(ps)) || isnan(ps[i]), f), fs),)
    end
    register_computation!(attr, [:positions_transformed_f32c, :faces, :invert_normals], [:normals]) do (ps, fs, invert_normals), changed, last
        # TODO only recalculate normals if changed
        ns = Makie.nan_aware_normals(ps, fs)
        return (invert_normals ? -ns : ns,)
    end
end

function create_shader(scene::Scene, plot::Surface)
    attr = plot.args[1]
    # Makie.add_computation!(attr, scene, Val(:surface_transform))
    surface2mesh_computation!(attr)
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))
    backend_colors!(attr)
    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :uniform_colormap, :uniform_color, :vertex_color, :uniform_colorrange, :pattern,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :pattern_uv_transform, :fetch_pixel, :shading, :color_mapping_type,
        :depth_shift, :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
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
        :object_id => UInt32(0)
    )
    handle_color!(uniforms, attr)
    return create_shader(box, uniforms, lasset("volume.vert"), lasset("volume.frag"))
end

function create_shader(scene::Scene, plot::Volume)
    attr = plot.args[1]

    Makie.add_computation!(attr, scene, Val(:uniform_model)) # bit different from voxel_model
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
        :uniform_model,
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

    attributes = Dict{Symbol,Any}(
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

    uniforms[:num_clip_planes] = 0
    uniforms[:clip_planes] = [Vec4f(0, 0, 0, -1e9) for _ in 1:8]
    return Dict(
        :plot_type => "Lines",
        :visible => Observable(attr.visible),
        :is_segments => !islines,
        :cam_space => attr.space,
        :uniforms => serialize_uniforms(uniforms),
        :attributes => attributes,
        :transparency => attr.transparency,
        :overdraw => false, # TODO
        :zvalue => 0,
    )
end

using Makie.ComputePipeline

function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    attr = plot.args[1]

    Makie.add_computation!(attr, :uniform_pattern, :uniform_pattern_length)
    backend_colors!(attr)

    islines = plot isa Lines

    inputs = [
        :positions_transformed_f32c,
        :line_color, :uniform_colormap, :uniform_colorrange, :color_mapping_type, :lowclip_color, :highclip_color, :nan_color,
        :linecap, :uniform_linewidth, :uniform_pattern, :uniform_pattern_length,
        :space, :scene_origin, :model_f32c, :depth_shift, :transparency, :visible,
    ]

    register_computation!(attr, [:uniform_color, :vertex_color], [:line_color]) do (uc, vc), changed, last
        return vc == false ? (uc,) : (vc,)
    end
    if islines
        Makie.add_computation!(attr, :gl_miter_limit)
        push!(inputs, :joinstyle, :gl_miter_limit)
    end
    dict = create_wgl_renderobject(args-> create_lines_data(islines, args), attr, inputs)
    dict[:uuid] = js_uuid(plot)
    dict[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    dict[:updater] = attr[:wgl_update_obs][]
    return dict
end
