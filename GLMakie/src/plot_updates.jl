#=
cached_robj!() does:
- excludes          -> skipped by white-listing
- update tracking   -> set in update call
- key name convert  -> explicit
- convert_attribute -> semi automatic, mostly in update call
- patch_model       -> update call
- clip_planes       -> init_clip_planes, update_clip_planes
- handle_intensities -> init_color
- connect_camera    -> init_camera, update_camera
- shading           -> TODO
- SSAO              -> init_generics
=#

################################################################################
### Generics
################################################################################

function init_color!(data, plot, allow_intensity_texture = true)
    #=
    Requirements:
    Scatter: intensity can be texture
    Lines:   intensity can't be texture, can be value, renamed to color
    =#

    # Colormapping
    if plot.computed[:color] isa Union{Real, AbstractVector{<: Real}} # do colormapping
        interp = plot.computed[:color_mapping_type] === Makie.continuous ? :linear : :nearest
        intensity = plot.computed[:color_scaled]
        # Allow missmatch between length of value colors and positions
        if allow_intensity_texture && (length(plot.converted[1][]) != length(intensity))
            data[:intensity] = Texture(intensity)
        elseif !allow_intensity_texture && (to_value(plot.color) isa Real) # TODO: maybe don't generate Vector?
            data[:intensity] = first(intensity)
        else
            data[:intensity] = GLBuffer(intensity)
        end
        @gen_defaults! data begin
            color_map       = Texture(plot.computed[:colormap], minfilter = interp)
            color_norm      = plot.computed[:colorrange_scaled]
            color           = nothing
        end
    else # direct colors
        @gen_defaults! data begin
            intensity       = nothing
            color_map       = nothing
            color_norm      = nothing
            color           = plot.computed[:color] => GLBuffer
        end
    end

    @gen_defaults! data begin
        lowclip         = get(plot.computed, :lowclip,   RGBAf(0,1,0,1))
        highclip        = get(plot.computed, :highclip,  RGBAf(0,1,1,1))
        nan_color       = get(plot.computed, :nan_color, RGBAf(1,0,1,1))
    end

    return
end

function init_clip_planes!(data, plot)
    @gen_defaults! data begin
        num_clip_planes = 0
        clip_planes     = fill(Vec4f(0,0,0,-1e9), 8)
    end
    push!(plot.updated_outputs[], :clip_planes) # trigger later updates
    return
end

function update_clip_planes!(robj::RenderObject, plot::Plot, target_space::Symbol = :world, private_count::Bool = false)
    if any(in(plot.updated_outputs[]), (:space, :clip_planes)) ||
            ((target_space == :clip) && (:camera in plot.updated_outputs[]))

        if !Makie.is_data_space(plot.computed[:space])
            N = 0
            robj[:clip_planes] .= Ref(Vec4f(0, 0, 0, -1e9))
        else
            planes = plot.computed[:clip_planes]
            if target_space == :clip
                scene = Makie.parent_scene(plot)
                planes = Makie.to_clip_space(scene.camera.projectionview[], planes)
            end
            N = min(length(planes), 8)
            for i in 1:min(N, 8)
                robj[:clip_planes][i] = Makie.gl_plane_format(planes[i])
            end
            for i in min(N, 8)+1:8
                robj[:clip_planes][i] = Vec4f(0, 0, 0, -1e9)
            end
        end
        if private_count
            robj[:_num_clip_planes] = N
        else
            robj[:num_clip_planes] = N
        end
    end
    delete!(plot.updated_outputs[], :clip_planes)
    return
end

function init_camera!(data, scene, plot)
    # TODO: Better solution
    onany(plot, scene.camera.projectionview, scene.camera.resolution) do _, __
        push!(plot.updated_outputs[], :camera)
        notify(plot.updated_inputs)
        return
    end

    # RenderObject constructor will cleanup unused ones
    # Initializing update will set appropriate values
    mat_keys = (:pixel_space, :view, :projection, :projectionview, :preprojection, :model)
    foreach(k -> get!(data, k, Mat4f(I)), mat_keys)
    foreach(k -> get!(data, k, Mat3f(I)), (:normal_matrix, :view_normalmatrix))
    foreach(k -> get!(data, k, Vec3f(0)), (:eyeposition, :view_direction, :lookat, :upvector))
    get!(data, :resolution, Vec2f(0))

    push!(plot.updated_outputs[], :camera)
    return
end

function update_camera!(robj, screen, scene, plot, target_markerspace = false)
    cam = scene.camera
    needs_update = in(plot.updated_outputs[])

    if :camera in plot.updated_outputs[]
        haskey(robj, :pixel_space)     && (robj[:pixel_space] = Mat4f(cam.pixel_space[]))
        haskey(robj, :eyeposition)     && (robj[:eyeposition] = Vec3f(cam.eyeposition[]))
        haskey(robj, :view_direction)  && (robj[:view_direction] = Vec3f(cam.view_direction[]))
        haskey(robj, :upvector)        && (robj[:upvector] = Vec3f(cam.upvector[]))
    end

    # If we have markerspace we usually project from
    #       space  ->  markerspace  ->  clip        with
    #         preprojection   projectionview
    # otherwise projectionview goes from space -> clip directly
    space_name = target_markerspace ? (:markerspace) : (:space)
    if any(needs_update, (space_name, :camera))
        _space = plot.computed[space_name]
        haskey(robj, :view)             && (robj[:view] = is_data_space(_space) ? Mat4f(cam.view[]) : Mat4f(I))
        haskey(robj, :projection)       && (robj[:projection] = Mat4f(Makie.space_to_clip(cam, _space, false)))
        haskey(robj, :projectionview)   && (robj[:projectionview] = Mat4f(Makie.space_to_clip(cam, _space, true)))
    end

    if target_markerspace && any(needs_update, (:space, :markerspace, :camera)) && haskey(robj, :preprojection)
        robj[:preprojection] = Mat4f(
            Makie.clip_to_space(cam, plot.computed[:markerspace]) *
            Makie.space_to_clip(cam, plot.computed[:space]))
    end

    if needs_update(:px_per_unit) && haskey(robj, :px_per_unit)
        robj[:px_per_unit] = screen.px_per_unit[]
    end
    if any(needs_update, (:camera, :px_per_unit)) && haskey(robj, :resolution)
        robj[:resolution] = Vec2f(screen.px_per_unit[] * scene.camera.resolution[])
    end

    # f32c can change model
    if any(needs_update, (:model, :f32c)) && haskey(robj, :world_normalmatrix)
        i3 = Vec(1,2,3)
        robj[:world_normalmatrix] = Mat4f(transpose(inv(robj[:model][i3, i3])))
    end

    if any(needs_update, (:camera, :model, :f32c)) && haskey(robj, :view_normalmatrix)
        cam = scene.camera
        robj[:view_normalmatrix]  = Mat4f(transpose(inv(cam.view[i3, i3] * robj[:model][i3, i3])))
    end

    return
end

function init_generics!(data, plot, screen)
    data[:fxaa]         = get(plot.computed, :fxaa, false)
    data[:ssao]         = get(plot.computed, :ssao, false)
    data[:transparency] = get(plot.computed, :transparency, false)
    data[:overdraw]     = get(plot.computed, :overdraw, false)
    data[:px_per_unit]  = screen.px_per_unit[]
    data[:depth_shift]  = get(plot.computed, :depth_shift, 0f0)
    return
end

function new_cached_robj!(
        setup_func, screen::Screen, scene::Scene, @nospecialize(plot::Plot);
        allow_intensity_texture::Bool = true
    )
    @assert !haskey(screen.cache, objectid(plot))

    # TODO: make these obsolete
    # Set up additional triggers

    # TODO: Is this even dynamic?
    on(screen.px_per_unit) do _
        push!(plot.updated_outputs[], :px_per_unit)
        notify(plot.updated_inputs)
        return
    end
    # TODO: maybe want ignores for e.g. volume?
    # f32c depend on projectionview so it doesn't need an explicit trigger (right?)
    if scene.float32convert !== nothing
        on(scene.float32convert.scaling) do _
            push!(plot.updated_outputs[], :f32c)
            notify(plot.updated_inputs)
            return
        end
    end

    # Make sure plot attributes are as up-to-date as possible. They can be
    # outdated from this:
    # p = plot!(...)       <-- triggers resolve
    # p.something = ...    <-- does not until robj is created
    Makie.resolve_updates!(plot)

    data = Dict{Symbol, Any}()

    # TODO: lighting
    begin # cached_robj pre
        # TODO: this should be resolve_updates! job
        # # TODO: remove depwarn & conversion after some time
        # if haskey(gl_attributes, :shading) && to_value(gl_attributes[:shading]) isa Bool
        #     @warn "`shading::Bool` is deprecated. Use `shading = NoShading` instead of false and `shading = FastShading` or `shading = MultiLightShading` instead of true."
        #     gl_attributes[:shading] = ifelse(gl_attributes[:shading][], FastShading, NoShading)
        # elseif haskey(gl_attributes, :shading) && gl_attributes[:shading] isa Observable
        #     gl_attributes[:shading] = gl_attributes[:shading][]
        # end

        # shading = to_value(get(gl_attributes, :shading, NoShading))

        # if shading == FastShading
        #     dirlight = Makie.get_directional_light(scene)
        #     if !isnothing(dirlight)
        #         gl_attributes[:light_direction] = if dirlight.camera_relative
        #             map(gl_attributes[:view], dirlight.direction) do view, dir
        #                 return  normalize(inv(view[Vec(1,2,3), Vec(1,2,3)]) * dir)
        #             end
        #         else
        #             map(normalize, dirlight.direction)
        #         end

        #         gl_attributes[:light_color] = dirlight.color
        #     else
        #         gl_attributes[:light_direction] = Observable(Vec3f(0))
        #         gl_attributes[:light_color] = Observable(RGBf(0,0,0))
        #     end

        #     ambientlight = Makie.get_ambient_light(scene)
        #     if !isnothing(ambientlight)
        #         gl_attributes[:ambient] = ambientlight.color
        #     else
        #         gl_attributes[:ambient] = Observable(RGBf(0,0,0))
        #     end
        # elseif shading == MultiLightShading
        #     handle_lights(gl_attributes, screen, scene.lights)
        # end
    end

    init_generics!(data, plot, screen)
    init_camera!(data, scene, plot)
    init_clip_planes!(data, plot) # TODO: differences between plots (world space, model space, skipped)
    init_color!(data, plot, allow_intensity_texture)

    setup_func(data)

    robj = assemble_shader(data)

    # TODO: We could pre-filter updated_outputs to skip more backend updates
    #       With all the renames this will probably take some time to get right though
    # APPLICABLE_NAMES = union!(
    #     Set([:camera, :px_per_unit, :f32c, :transform_func, :color_scaled, :marker,
    #         :visible, :colorrange_scaled, :glowwidth, :glowcolor, :strokewidth,
    #         :strokecolor, :colormap, :transform_marker]),
    #     keys(robj.uniforms), Symbol.(keys(robj.vertexarray.buffers))
    # )

    on(plot, plot.updated_inputs) do _
        # Makie Update
        Makie.resolve_updates!(plot)

        # Update of things the backend caches in plot.updated_outputs
        update_plot_cache!(plot, robj)

        # TODO: possible optimization
        # intersect!(plot.updated_outputs[], APPLICABLE_NAMES)

        # @info "Triggered with $(plot.updated_outputs[])"

        # nothing to do, screen closed, robj dead -> no update
        if isempty(plot.updated_outputs[]) || !isopen(screen) || (robj.id == 0) ||
                any(buffer -> buffer.id == 0, values(robj.vertexarray.buffers))
            return
        else
            # Update of values in the render object
            update_robj!(screen, robj, scene, plot)
            empty!(plot.updated_outputs[])
            screen.requires_update = true
        end

        return
    end

    # trigger update pipeline once to intialize robj
    notify(plot.updated_inputs)

    # could also go back to get(screen.cache, objectid(plot)) do ... end
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)

    return robj
end

################################################################################
### Scatter specifics
################################################################################

function init_scatter_marker!(data, plot, screen)
    # Image packing
    marker = plot.computed[:marker]
    if marker isa VectorTypes{<: Matrix{<: Colorant}}
        # TODO: extract this to Makie side as a SpriteSheet generator
        # TODO: make this dynamic
        images = map(el32convert, marker)
        isempty(images) && error("Can not display empty vector of images as primitive")
        sizes = map(size, images)
        if !all(x-> x == sizes[1], sizes) # if differently sized
            # create texture atlas
            maxdims = sum(map(Vec{2, Int}, sizes))
            rectangles = map(x -> Rect2(0, 0, x...), sizes)
            rpack = RectanglePacker(Rect2(0, 0, maxdims...))
            uv_coordinates = [push!(rpack, rect).area for rect in rectangles]
            max_xy = mapreduce(maximum, (a,b) -> max.(a, b), uv_coordinates)
            texture_atlas = Texture(eltype(images[1]), (max_xy...,))
            for (area, img) in zip(uv_coordinates, images)
                texture_atlas[area] = img # transfer to texture atlas
            end
            data[:uv_offset_width] = map(uv_coordinates) do uv
                m = max_xy .- 1
                mini = reverse((minimum(uv)) ./ m)
                maxi = reverse((maximum(uv) .- 1) ./ m)
                return Vec4f(mini..., maxi...)
            end
            images = texture_atlas
        else
            data[:uv_offset_width] = Vec4f(0,0,1,1)
        end
        data[:image] = images # we don't want this to be overwritten by user
        @gen_defaults! data begin
            shape = RECTANGLE
        end

    # single image
    elseif marker isa Matrix{<: Colorant}
        @gen_defaults! data begin
            image = marker => Texture
            scale = lift(x-> Vec2f(size(x)), p[1])
            offset = Vec2f(0)
            uv_offset_width = Vec4f(0,0,1,1)
        end

    # TODO: FastPixel
    elseif marker isa FastPixel
        if !isnothing(get(data, :intensity, nothing))
            data[:color] = pop!(data, :intensity)
        end
        # to_keep = Set([:color_map, :color, :color_norm, :px_per_unit, :scale, :model,
        #                  :projectionview, :projection, :view, :visible, :resolution, :transparency])
        # filter!(gl_attributes) do (k, v,)
        #     return (k in to_keep)
        # end
        data[:markerspace] = Int32(0)
        push!(plot.updated_outputs[], :markerspace)
        data[:marker_shape] = plot.computed[:marker].marker_type

        data[:shader] = GLVisualizeShader(
            screen,
            "fragment_output.frag", "dots.vert", "dots.frag",
            view = Dict(
                "buffers" => output_buffers(screen, plot.computed[:transparency]),
                "buffer_writes" => output_buffer_writes(screen, plot.computed[:transparency])
            )
        )
        data[:prerender] = ()-> glEnable(GL_VERTEX_PROGRAM_POINT_SIZE)

    # shape or Signed Distance field
    else
        shape = Makie.marker_to_sdf_shape(plot.computed[:marker])
        data[:shape] = Cint(shape)
        data[:distancefield] = get(plot.computed, :distancefield, nothing)
        if (data[:distancefield] === nothing) && (shape === DISTANCEFIELD)
            atlas = gl_texture_atlas()
            data[:distancefield] = get_texture!(atlas)
        end
    end
    return
end

function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::Scatter))

    # Note: For initializing data via update routine (one time)
    push!(plot.updated_outputs[], :position)
    push!(plot.updated_outputs[], :marker)

    return new_cached_robj!(screen, scene, plot) do data
        Dim = length(eltype(plot.converted[1][]))
        N = length(plot.converted[1][])

        # TODO: infer type (Vector vs value), set data with initial resolve run
        atlas = gl_texture_atlas()
        font = get(plot.computed, :font, Makie.defaultfont())
        @assert !isa(font, Observable) # should be the case...
        data[:scale] = Makie.rescale_marker(
            atlas, plot.computed[:marker], font, plot.computed[:markersize])

        data[:quad_offset] = Makie.offset_marker(
            atlas, plot.computed[:marker], font, plot.computed[:markersize],
            plot.computed[:marker_offset])

        @gen_defaults! data begin
            position        = Vector{Point{Dim, Float32}}(undef, N) => GLBuffer
            len             = 0 # should match length of position
            marker_offset   = Vec3f(0) => GLBuffer # Note: currently unused for Scatter
            scale           = Vec2f(0) => GLBuffer
            rotation        = plot.computed[:rotation] => GLBuffer
            indices         = to_index_buffer(plot.computed[:depthsorting] ? UInt32[] : 0)
        end

        init_scatter_marker!(data, plot, screen)

        @gen_defaults! data begin
            image           = nothing => Texture
            quad_offset     = Vec2f(0) => GLBuffer

            glow_color      = plot.computed[:glowcolor] => GLBuffer
            stroke_color    = plot.computed[:strokecolor] => GLBuffer
            stroke_width    = 0f0
            glow_width      = 0f0
            uv_offset_width = ifelse(plot.computed[:marker] isa Vector, Vector{Vec4f}(undef, N), Vec4f(0)) => GLBuffer

            # rotation and billboard don't go along
            billboard       = (plot[:rotation][] isa Billboard) || (rotation == Vec4f(0,0,0,1))
            distancefield    = nothing => Texture
            shader           = GLVisualizeShader(
                screen,
                "fragment_output.frag", "util.vert", "sprites.geom",
                "sprites.vert", "distance_shape.frag",
                view = Dict(
                    "position_calc" => position_calc(position, nothing, nothing, nothing, GLBuffer),
                    "buffers" => output_buffers(screen, data[:transparency]),
                    "buffer_writes" => output_buffer_writes(screen, data[:transparency])
                )
            )
            scale_primitive = true
            gl_primitive = GL_POINTS
        end

        return
    end
end

function update_plot_cache!(@nospecialize(plot::Scatter), @nospecialize(robj::RenderObject))
    # TODO: technically constants
    HAS_IMAGE = get(robj.uniforms, :image, nothing) !== nothing
    ISFASTPIXEL = plot.computed[:marker] isa FastPixel

    # More convenient as extension to resolve_updates!()
    # But other backends may not need these or do these slightly different
    # (e.g. smaller texture atlas for WGLMakie, different handling of markersize etc in CairoMakie)
    # Note marker_size should probably split from this
    if any(in(plot.updated_outputs[]), (:marker_offset, :marker, :markersize))
        atlas = gl_texture_atlas()
        font = get(plot.computed, :font, Makie.defaultfont())
        plot.computed[:scale] = Makie.rescale_marker(
            atlas, plot.computed[:marker], font, plot.computed[:markersize])
        plot.computed[:quad_offset] = Makie.offset_marker(
            atlas, plot.computed[:marker], font, plot.computed[:markersize],
            plot.computed[:marker_offset])
        push!(plot.updated_outputs[], :scale, :quad_offset)
    end

    if (plot[:uv_offset_width] == Vec4f(0) || in(:marker, plot.updated_outputs[])) &&
            !HAS_IMAGE && !ISFASTPIXEL
        plot.computed[:uv_offset_width] = Makie.primitive_uv_offset_width(atlas, plot.computed[:marker], font)
        push!(plot.updated_outputs[], :uv_offset_width)
    end

    return
end

function update_robj!(screen::Screen, robj::RenderObject, scene::Scene, plot::Scatter)
    # Backend Update
    needs_update = in(plot.updated_outputs[])
    length_changed = false
    isfastpixel = plot.computed[:marker] isa FastPixel
    hasimage = get(robj.uniforms, :image, nothing) !== nothing

    if any(needs_update, (:f32c, :model))
        f32c, model = Makie._patch_model(scene.float32convert, plot.computed[:model]::Mat4d)
        plot.computed[:f32c] = f32c
        robj[:model] = model
    end

    # Camera update - relies on up-to-date model
    update_camera!(robj, screen, scene, plot, !isfastpixel)

    if any(needs_update, (:f32c, :model, :transform_func, :position))
        positions = apply_transform_and_f32_conversion(
            plot.computed[:f32c], Makie.transform_func(plot), plot.computed[:model]::Mat4d,
            plot.converted[1][], plot.computed[:space]::Symbol
        )
        haskey(robj, :len) && (robj[:len] = length(positions))
        update!(robj.vertexarray.buffers["position"], positions)
        if get(plot.computed, :depthsorting, false)
            plot.computed[:backend_positions] = positions
        end
    end

    # Handle indices
    if get(plot.computed, :depthsorting, false) && any(needs_update, (:f32c, :model, :transform_func, :position, :camera))
        T = Mat4f(robj[:projection] * robj[:view] * robj[:preprojection] * robj[:model])
        # TODO: does this have CPU data? Otherwise we should cache this in computed
        depth_vals = map(plot.computed[:backend_positions]::Vector) do p
            p4d::Point4f = T * to_ndim(Point4f, to_ndim(Point3f, p, 0f0), 1f0)
            return p4d[3] / p4d[4]
        end
        indices = UInt32.(sortperm(depth_vals, rev = true) .- 1)
        length_changed = length(indices) != length(robj.vertexarray.indices)
        update!(robj.vertexarray.indices, indices)
    else # this only sets an int, basically free?
        length_changed = length(robj.vertexarray.buffers["position"]) != robj.vertexarray.indices
        robj.vertexarray.indices = length(robj.vertexarray.buffers["position"])
    end

    if needs_update(:color_scaled) || length_changed
        if haskey(robj.vertexarray.buffers, "intensity")
            update!(robj.vertexarray.buffers["intensity"], plot.computed[:color_scaled])
        elseif haskey(robj, :intensity)
            update!(robj[:intensity], plot.computed[:color_scaled])
        end
    end

    update_clip_planes!(robj, plot)

    # Clean up things we've already handled (and must not handle again)
    delete!(plot.updated_outputs[], :position)
    delete!(plot.updated_outputs[], :model)
    delete!(plot.updated_outputs[], :markersize)
    delete!(plot.updated_outputs[], :marker_offset)

    # And that don't exist in computed
    delete!(plot.updated_outputs[], :camera)
    delete!(plot.updated_outputs[], :px_per_unit)

    # special restrictions
    (isfastpixel || hasimage) && delete!(plot.updated_outputs[], :uv_offset_width)
    delete!(plot.updated_outputs[], :colorrange) # replaced by colorrange_scaled

    # TODO: Don't break stuff :(
    isnothing(plot.computed[:distancefield]) && delete!(plot.updated_outputs[], :distancefield)

    for key in plot.updated_outputs[]
        glkey = to_glvisualize_key(key)
        val = plot.computed[key]

        # Specials
        if key == :marker
            if isfastpixel
                robj[:marker_shape] = gl_convert(val.marker_type)
            else
                shape = Cint(Makie.marker_to_sdf_shape(val))
                if shape == 0 && !is_all_equal_scale(plot.computed[:markersize])
                    robj[:shape] = Cint(5) # circle -> ellipse
                else
                    robj[:shape] = shape
                end
            end

        elseif key == :visible
            robj.visible = val::Bool

        # NOT FastPixel
        elseif (key == :overdraw) && !isfastpixel
            robj.prerenderfunction.overdraw[] = val::Bool

        # ONLY FastPixel
        elseif (key == :markerspace) && isfastpixel
            if val == :pixel;       robj[:markerspace] = gl_convert(Int32(0))
            elseif val == :data;    robj[:markerspace] = gl_convert(Int32(1))
            else                    error("Unsupported markerspace for FastPixel marker: $val")
            end

        # TODO: do we even need unscaled colorrange for anything?
        elseif key == :colorrange_scaled
            robj[:color_norm] = gl_convert(val)

        # Handle vertex buffers
        elseif haskey(robj.vertexarray.buffers, string(glkey))
            if robj.vertexarray.buffers[string(glkey)] isa GLBuffer
                update!(robj.vertexarray.buffers[string(glkey)], val)
            else
                robj.vertexarray.buffers[string(glkey)] = val
            end

        # Handle uniforms
        elseif haskey(robj, glkey)
            # TODO: Should this force matching types (E.g. mutable struct Uniform{T}; x::T; end wrapper?)
            if robj[glkey] isa GPUArray
                update!(robj[glkey], val)
            else
                robj[glkey] = GLAbstraction.gl_convert(val)
            end

        else
            # printstyled("Discarded backend update $key -> $glkey. (does not exist)\n", color = :light_black)
        end
    end
end


################################################################################
### Lines
################################################################################

function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::Lines))
    robj = new_cached_robj!(screen, scene, plot, allow_intensity_texture = false) do gl_attributes

        # Trigger updates for...
        union!(plot.updated_outputs[], (:position,))
        union!(plot.updated_outputs[], keys(plot.computed))

        has_linestyle = !isnothing(plot.computed[:linestyle])
        Dim = has_linestyle ? 4 : length(eltype(plot.converted[1][]))
        N = length(plot.converted[1][])
        transparency = plot.computed[:transparency]

        # Nonstandard stuff
        if get(gl_attributes, :intensity, nothing) !== nothing
            gl_attributes[:color] = pop!(gl_attributes, :intensity)
            color_type = "float"
        else
            color_type = "vec4" # because alpha gets added
        end
        gl_attributes[:num_clip_planes] = 0 # TODO: Don't update num, do update clip_planes

        @gen_defaults! gl_attributes begin
            # Definitely
            vertex       = Vector{Point{Dim, Float32}}(undef, N) => GLBuffer
            indices      = to_index_buffer(UInt32[])
            valid_vertex = Vector{Float32}(undef, N) => GLBuffer # Why Float32?
            thickness    = plot.computed[:linewidth] => GLBuffer
            lastlen      = Vector{Float32}(undef, N) => GLBuffer
            total_length = Int32(0)

            miter_limit = Float32(cos(pi - plot.computed[:miter_limit]))
            joinstyle   = 0
            linecap     = 0
            pattern_length = 1f0
            scene_origin = Vec2f(screen.px_per_unit[] * origin(scene.viewport[]))

            shader      = GLVisualizeShader(
                screen,
                "fragment_output.frag", "lines.vert", "lines.geom", "lines.frag",
                view = Dict(
                    "buffers" => output_buffers(screen, transparency),
                    "buffer_writes" => output_buffer_writes(screen, transparency),
                    "define_fast_path" => has_linestyle ? "" : "#define FAST_PATH",
                    "stripped_color_type" => color_type
                )
            )
            gl_primitive = GL_LINE_STRIP_ADJACENCY
            debug        = false
        end

        # only needed for :repeat setting in Texture...
        if has_linestyle
            gl_attributes[:pattern] = GLAbstraction.Texture([0f0], x_repeat = :repeat)
        else
            gl_attributes[:pattern] = nothing
        end

        # GLBuffers need persitent Julia arrays backing them (no temp arrays)
        # Or is that just printing?
        plot.computed[:backend_vertex] = Point{Dim, Float32}[]
        plot.computed[:backend_indices] = Cuint[]
        plot.computed[:backend_valid_vertex] = Float32[]
        plot.computed[:backend_lastlen] = Float32[]

        return gl_attributes
    end

    return robj
end

# generate_indices with slight modifications
# TODO: probably cache indices and valid in computed to avoid allocations?
function calculate_indices!(plot, ps::AbstractVector{PT} = plot.converted[1][]) where {PT <: VecTypes}
    valid = resize!(plot.computed[:backend_valid_vertex], length(ps)) # Why Float32?
    indices = sizehint!(plot.computed[:backend_indices], length(ps)+2)

    # This loop identifies sections of line points A B C D E F bounded by
    # the start/end of the list ps or by NaN and generates indices for them:
    # if A == F (loop):      E A B C D E F B 0
    # if A != F (no loop):   0 A B C D E F 0
    # where 0 is NaN
    # It marks vertices as invalid (0) if they are NaN, valid (1) if they
    # are part of a continuous line section, or as ghost edges (2) used to
    # cleanly close a loop. The shader detects successive vertices with
    # 1-2-0 and 0-2-1 validity to avoid drawing ghost segments (E-A from
    # 0-E-A-B and F-B from E-F-B-0 which would duplicate E-F and A-B)

    last_start_pos = PT(NaN)
    last_start_idx = -1

    for (i, p) in enumerate(ps)
        not_nan = isfinite(p)
        valid[i] = not_nan

        if not_nan
            if last_start_idx == -1
                # place nan before section of line vertices
                # (or duplicate ps[1])
                push!(indices, max(1, i-1))
                last_start_idx = length(indices) + 1
                last_start_pos = p
            end
            # add line vertex
            push!(indices, i)

        # case loop (loop index set, loop contains at least 3 segments, start == end)
        elseif (last_start_idx != -1) && (length(indices) - last_start_idx > 2) &&
                (ps[max(1, i-1)] ≈ last_start_pos)

            # add ghost vertices before an after the loop to cleanly connect line
            indices[last_start_idx-1] = max(1, i-2)
            push!(indices, indices[last_start_idx+1], i)
            # mark the ghost vertices
            valid[i-2] = 2
            valid[indices[last_start_idx+1]] = 2
            # not in loop anymore
            last_start_idx = -1

        # non-looping line end
        elseif (last_start_idx != -1) # effective "last index not NaN"
            push!(indices, i)
            last_start_idx = -1
        # else: we don't need to push repeated NaNs
        end
    end

    # treat ps[end+1] as NaN to correctly finish the line
    if (last_start_idx != -1) && (length(indices) - last_start_idx > 2) &&
            (ps[end] ≈ last_start_pos)

        indices[last_start_idx-1] = length(ps) - 1
        push!(indices, indices[last_start_idx+1])
        valid[end-1] = 2
        valid[indices[last_start_idx+1]] = 2
    elseif last_start_idx != -1
        push!(indices, length(ps))
    end

    indices .-= Cuint(1)

    return indices, valid
end

update_plot_cache!(@nospecialize(::Lines), @nospecialize(::RenderObject)) = nothing

function update_robj!(screen::Screen, robj::RenderObject, scene::Scene, plot::Lines)
    # Backend Update
    needs_update = in(plot.updated_outputs[])

    if any(needs_update, (:f32c, :model))
        f32c, model = Makie._patch_model(scene.float32convert, plot.computed[:model]::Mat4d)
        plot.computed[:f32c] = f32c
        robj[:model] = model
    end

    # Camera update - relies on up-to-date model
    update_camera!(robj, screen, scene, plot)

    # TODO: camera includes resolution, but is that enough here?
    if any(needs_update, (:px_per_unit, :camera))
        robj[:scene_origin] = Vec2f(screen.px_per_unit[] * origin(scene.viewport[]))
    end

    if isnothing(plot.computed[:linestyle]) &&
            any(needs_update, (:f32c, :model, :transform_func, :position))

        # TODO: patch_model, camera only relevant here

        plot.computed[:backend_vertex] = apply_transform_and_f32_conversion(
            plot.computed[:f32c], Makie.transform_func(plot), plot.computed[:model]::Mat4d,
            plot.converted[1][], plot.computed[:space]::Symbol
        )
        update!(robj.vertexarray.buffers["vertex"], plot.computed[:backend_vertex])

    elseif !isnothing(plot.computed[:linestyle]) &&
            any(needs_update, (:f32c, :model, :transform_func, :camera, :position))

        space = plot.computed[:space]::Symbol
        tf = Makie.transform_func(plot)
        transform = Makie.space_to_clip(scene.camera, space, true) *
            Makie.f32_convert_matrix(scene.float32convert, space) *
            plot.computed[:model]

        resize!(plot.computed[:backend_vertex], length(plot.converted[1][]))
        map!(plot.computed[:backend_vertex], plot.converted[1][]) do pos
            transformed = apply_transform(tf, pos, space)
            p4d = to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
            return Point4f(transform * p4d)
        end

        update!(robj.vertexarray.buffers["vertex"], plot.computed[:backend_vertex])

        # TODO: avoid replacing
        # lastlen is only needed for patterned lines
        plot.computed[:backend_lastlen] = sumlengths(plot.computed[:backend_vertex], scene.camera.resolution[])
        update!(robj.vertexarray.buffers["lastlen"], plot.computed[:backend_lastlen])
    end

    # Thsi shouldn't care about projections etc...
    if needs_update(:position)
        calculate_indices!(plot) # TODO: maybe move to update_plot_cache!()
        update!(robj.vertexarray.indices, plot.computed[:backend_indices])
        robj[:total_length] = Int32(length(plot.computed[:backend_indices]) - 2)
        update!(robj.vertexarray.buffers["valid_vertex"], plot.computed[:backend_valid_vertex])
    end

    update_clip_planes!(robj, plot, :clip, true)

    # TODO: maybe change this?
    # Needs to be handled separately because color and color_scaled can exist simulaneously atm
    if needs_update(:color_scaled) && !isnothing(plot.computed[:color_scaled])
        if haskey(robj.vertexarray.buffers, "color")
            update!(robj.vertexarray.buffers["color"], plot.computed[:color_scaled])
            delete!(plot.updated_outputs[], :color)
        elseif haskey(robj.uniforms, :color)
            robj[:color] = GLAbstraction.gl_convert(plot.computed[:color_scaled])
            delete!(plot.updated_outputs[], :color)
        end
    end

    # Clean up things we've already handled (and must not handle again)
    delete!(plot.updated_outputs[], :position)
    delete!(plot.updated_outputs[], :model)
    delete!(plot.updated_outputs[], :color_scaled)
    # And that don't exist in computed
    delete!(plot.updated_outputs[], :camera)
    delete!(plot.updated_outputs[], :px_per_unit)

    # special restrictions
    delete!(plot.updated_outputs[], :colorrange) # replaced by colorrange_scaled

    for key in plot.updated_outputs[]
        glkey = to_glvisualize_key(key)
        val = plot.computed[key]

        # Specials
        if (glkey == :linestyle) && (val !== nothing)
            sdf = Makie.linestyle_to_sdf(val)
            update!(robj[:pattern], sdf)
            robj[:pattern_length] = Float32(last(val) - first(val))

        elseif (glkey == :miter_limit)
            robj[:miter_limit] = Float32(cos(pi - val))

        # TODO: v- all the other branches could probably be generic?
        #          earlier branches can overwrite if needed
        elseif glkey == :visible
            robj.visible = val::Bool

        # NOT FastPixel
        elseif glkey == :overdraw
            robj.prerenderfunction.overdraw[] = val::Bool

        # TODO: do we even need unscaled colorrange for anything?
        elseif glkey == :colorrange_scaled
            robj[:color_norm] = gl_convert(val)

        # Handle vertex buffers
        elseif haskey(robj.vertexarray.buffers, string(glkey))
            if robj.vertexarray.buffers[string(glkey)] isa GLBuffer
                update!(robj.vertexarray.buffers[string(glkey)], val)
            else
                robj.vertexarray.buffers[string(glkey)] = val
            end

        # Handle uniforms
        elseif haskey(robj, glkey)
            # TODO: Should this force matching types (E.g. mutable struct Uniform{T}; x::T; end wrapper?)
            if robj[glkey] isa GPUArray
                update!(robj[glkey], val)
            else
                robj[glkey] = GLAbstraction.gl_convert(val)
            end

        else
            # printstyled("Discarded backend update $key -> $glkey. (does not exist)\n", color = :light_black)
        end
    end
end