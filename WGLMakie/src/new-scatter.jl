using Makie: register_computation!

function serialize_three(scene::Scene, plot::Makie.ComputePlots)
    program = create_shader(scene, plot)
    mesh = serialize_three(plot, program)
    mesh[:plot_type] = "Mesh"
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = Observable(plot.visible[])
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.args[1][:wgl_update_obs][]

    mesh[:overdraw] = Observable(plot.overdraw[])
    mesh[:transparency] = Observable(plot.transparency[])

    mesh[:space] = Observable(plot.space[])
    if haskey(plot, :markerspace)
        mesh[:markerspace] = Observable(plot.markerspace[])
        mesh[:cam_space] = plot.markerspace[]
    else
        mesh[:cam_space] = plot.space[]
    end

    mesh[:uniforms][:clip_planes] = serialize_three([Vec4f(0, 0, 0, -1e9) for _ in 1:8])
    mesh[:uniforms][:num_clip_planes] = serialize_three(0)

    delete!(mesh, :uniform_updater)
    return mesh
end

function backend_colors!(attr, input_name = :scaled_color)
    register_computation!(attr, [input_name, :interpolate], [:uniform_color, :pattern]) do (color, interpolate), changed, last
        filter = interpolate ? :linear : :nearest
        if color isa AbstractMatrix
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
    register_computation!(attr, [input_name], [:vertex_color]) do (color,), changed, last
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
    data[:vertex_color] = attr.vertex_color
    data[:uniform_color] = attr.uniform_color
    data[:pattern] = attr.pattern
    data[:uniform_colorrange] = attr.uniform_colorrange
    data[:uniform_colormap] = attr.uniform_colormap
    data[:highclip_color] = attr.highclip_color
    data[:lowclip_color] = attr.lowclip_color
    data[:nan_color] = attr.nan_color
end

function plot_updates(args, changed, name_map)
    new_values = []
    for (name, value) in pairs(args)
        if changed[name]
            name = get(name_map, name, name)
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


function assemble_particle_robj!(attr, data)
    if haskey(attr, :gl_position)
        data[:positions_transformed_f32c] = attr.gl_position
    else
        data[:positions_transformed_f32c] = attr.positions_transformed_f32c
    end
    handle_color!(data, attr)
    handle_color_getter!(data)

    data[:rotation] = haskey(attr, :gl_rotation) ? attr.gl_rotation : attr.rotation
    data[:f32c_scale] = attr.f32c_scale

    # Camera will be set in JS
    data[:model] = Mat4f(I)
    data[:px_per_unit] = 0f0
    data[:picking] = false
    data[:object_id] = UInt32(0)

    data[:depth_shift] = attr.depth_shift
    data[:transform_marker] = attr.transform_marker


    per_instance_keys = (
        :positions_transformed_f32c, :rotation, :markersize, :vertex_color, :intensity, :uv_offset_width, :quad_offset, :marker_offset
    )

    per_instance = filter(data) do (k, v)
        return k in per_instance_keys && !(Makie.isscalar(v))
    end

    filter!(data) do (k, v)
        return !(k in per_instance_keys && !(Makie.isscalar(v)))
    end
    _, arr = first(per_instance)
    if any(v -> length(arr) != length(v), values(per_instance))
        lens = [k => length(v) for (k, v) in per_instance]
        error("Not all have the same length: $(lens)")
    end

    return VertexArray(; per_instance...), data
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
    :atlas_1024_32,
    :markerspace,

    :visible,
    :transform_marker,
    :f32c_scale,
    :marker_offset,
]

default(::Type{<: Colorant}) = RGBAf(0,0,0,0)
default(::Type{<: VecTypes}) = Vec4f(0)
default(::Type{T}) where {T <: Real} = T(0)
to_scalar(x::Vector{T}) where {T} = isempty(x) ? default(T) : first(x)
to_scalar(x::VecTypes) = x
to_scalar(x) = x

function scatter_program(attr, changed, last)
    replace = Dict(
        :quad_scale => :markersize,
        :sdf_uv => :uv_offset_width,
        :sdf_marker_shape => :shape_type,
        :model_f32c => :model,
        # for text, which remaps these from per glyphcollection or global to per glyph
        :gl_rotation => :rotation,
        :gl_stroke_color => :strokecolor,
        :gl_position => :positions_transformed_f32c,
        # TODO: switching between different sizes breaks derived attributes, so
        #       the atlas should probably be shared between WGLMakie and GLMakie
        # text uses :atlas because of this atm
        :atlas => :atlas_1024_32,
    )
    if isnothing(last)
        dfield = attr.sdf_marker_shape === Cint(Makie.DISTANCEFIELD)
        atlas = haskey(attr, :atlas) ? attr.atlas : attr.atlas_1024_32
        distancefield = dfield ? NoDataTextureAtlas(size(atlas.data)) : false
        data = Dict(
            :marker_offset => attr.marker_offset,
            :markersize => attr.quad_scale,
            :quad_offset => attr.quad_offset,
            :uv_offset_width => attr.sdf_uv,
            :shape_type => attr.sdf_marker_shape,
            :distancefield => distancefield,
            :resolution => Vec2f(0),
            :preprojection => Mat4f(I),
            :billboard => true, # attr.rotation isa Billboard, # TODO: fix billboard detection
            :atlas_texture_size => Float32(size(atlas.data, 2)),
            :shape_type => attr.sdf_marker_shape,
            # TODO: WGLMakie doesn't support per-element stroke
            :strokewidth => to_scalar(attr.strokewidth),
            :strokecolor => to_scalar(haskey(attr, :gl_stroke_color) ? attr.gl_stroke_color : attr.strokecolor),
            :glowwidth => attr.glowwidth,
            :glowcolor => attr.glowcolor,
        )
        per_instance, uniforms = assemble_particle_robj!(attr, data)
        instance = uv_mesh(Rect2f(-0.5f0, -0.5f0, 1.0f0, 1.0f0))
        program = InstancedProgram(
            WebGL(),
            lasset("sprites.vert"),
            lasset("sprites.frag"),
            instance,
            per_instance,
            uniforms,
        )
        return (program, Observable([]))
    else
        updater = last[2]
        update_values!(updater, plot_updates(attr, changed, replace))
        return nothing
    end
end

function create_shader(scene::Scene, plot::Scatter)
    attr = plot.args[1]
    Makie.all_marker_computations!(attr, 1024, 32)
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    backend_colors!(attr)
    register_computation!(scatter_program, attr, SCATTER_INPUTS, [:wgl_scatter_renderobject, :wgl_update_obs])
    on(attr.onchange) do _
        attr[:wgl_scatter_renderobject][]
        return nothing
    end
    return attr[:wgl_scatter_renderobject][]
end

function meshscatter_program(args, changed, last)
    r = Dict(
        :model_f32c => :model,
    )
    if isnothing(last)
        instance = args.marker
        data = Dict{Symbol, Any}(
            :ambient => Vec3f(0.5),
            :diffuse => args.diffuse,
            :specular => args.specular,
            :shininess => args.shininess,
            :pattern => false,
            :uniform_color => false,
            :uv_transform => Mat3f(I),
            :light_direction => Vec3f(1),
            :light_color => Vec3f(1),
            :PICKING_INDEX_FROM_UV => false,
            :shading => args.shading == false || args.shading != NoShading,
            :backlight => args.backlight,
            :interpolate_in_fragment_shader => false,
            :markersize => args.markersize,
            :f32c_scale => args.f32c_scale,
            :uv => Vec2f(0)
        )

        per_instance, uniforms = assemble_particle_robj!(args, data)
        program = InstancedProgram(
            WebGL(), lasset("particles.vert"), lasset("mesh.frag"),
            instance, per_instance, uniforms
        )
        return (program, Observable([]))
    else
        updater = last[2]
        update_values!(updater, plot_updates(args, changed, r))
        return nothing
    end
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
    register_computation!(meshscatter_program, attr, inputs, [:wgl_renderobject, :wgl_update_obs])
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
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
    register_computation!(attr, inputs, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict()
        if isnothing(last)
            program = mesh_program(args)
            return (program, Observable{Any}([]))
        else
            updater = last[2]
            update_values!(updater, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
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
        :ambient => Vec3f(1),
        :light_direction => Vec3f(1),
        :light_color => Vec3f(1),

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
    vbo = VertexArray(; positions_transformed_f32c=attr.positions_transformed_f32c, faces=attr.faces, buffers...)
    return Program(WebGL(), lasset("mesh.vert"), lasset("mesh.frag"), vbo, uniforms)
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
    register_computation!(attr, inputs, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict()
        if isnothing(last)
            program = mesh_program(args)
            return (program, Observable{Any}([]))
        else
            update_values!(last.wgl_update_obs, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
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
        return (decompose(QuadFace{Int}, rect), _surface_uvs(new_size...), new_size)
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
    register_computation!(attr, inputs, [:wgl_renderobject, :wgl_update_obs]) do args, changed, last
        r = Dict()
        if isnothing(last)
            program = mesh_program(args)
            return (program, Observable{Any}([]))
        else
            updater = last.wgl_update_obs
            update_values!(updater, Bonito.LargeUpdate(plot_updates(args, changed, r)))
            return nothing
        end
    end
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return nothing
    end
    return attr[:wgl_renderobject][]
end

################################


function create_shader(scene::Scene, plot::Makie.Text)
    # TODO: color processing incorrect, processed per-glyphcollection/global
    #       colors instead of per glyph
    attr = plot.args[1]
    Makie.register_quad_computations!(attr, 1024, 32)
    haskey(attr, :interpolate) || Makie.add_input!(attr, :interpolate, false)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    backend_colors!(attr, :gl_color)
    inputs = [
        :gl_position,
        :vertex_color, :uniform_color, :uniform_colormap, :uniform_colorrange, :nan_color, :highclip_color, :lowclip_color, :pattern,
        :gl_rotation, :gl_stroke_color, # TODO: do these even work per glyph?
        :quad_scale, :quad_offset, :sdf_uv, :sdf_marker_shape, :marker_offset,
        :strokewidth, :glowwidth, :glowcolor,
        :depth_shift, :atlas, :markerspace,
        :visible, :transform_marker, :f32c_scale,
    ]
    register_computation!(scatter_program, attr, inputs, [:wgl_scatter_renderobject, :wgl_update_obs])
    on(attr.onchange) do _
        attr[:wgl_scatter_renderobject][]
        return nothing
    end
    return attr[:wgl_scatter_renderobject][]
end