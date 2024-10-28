function init_color!(data, plot)
    # TODO: This switches between GLBuffer and Texture
    # # Exception for intensity, to make it possible to handle intensity with a
    # # different length compared to position. Intensities will be interpolated in that case
    # data[:intensity] = intensity_convert(intensity, position)

    # Colormapping
    if plot.computed[:color] isa Union{Real, AbstractVector{<: Real}} # do colormapping
        interp = plot.computed[:color_mapping_type] === Makie.continuous ? :linear : :nearest
        @gen_defaults! data begin
            intensity       = plot.computed[:color_scaled] => GLBuffer
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

function update_clip_planes!(robj, plot)
    if any(in(plot.updated_outputs[]), (:space, :clip_planes))
        if Makie.is_data_space(plot.computed[:space])
            robj[:num_clip_planes] = 0
            robj[:clip_planes] .= Ref(Vec4f(0, 0, 0, -1e9))
        else
            planes = plot.computed[:clip_planes]
            robj[:num_clip_planes] = N = min(length(planes), 8)
            for i in 1:min(N, 8)
                robj[:clip_planes][i] = Makie.gl_plane_format(planes[i])
            end
            for i in min(N, 8)+1:8
                robj[:clip_planes][i] = Vec4f(0, 0, 0, -1e9)
            end
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
    foreach(k -> get!(data, k, Vec3f(0)), (:eyeposition, :view_direction, :lookat))
    get!(data, :resolution, Vec2f(0))

    push!(plot.updated_outputs[], :camera)
    return
end

set_existing!(robj, value, key) = haskey(robj.uniforms, key) && (robj[key] = value)

function update_camera!(robj, screen, scene, plot, target_markerspace = false)
    cam = scene.camera
    needs_update = in(plot.updated_outputs[])

    if :camera in plot.updated_outputs[]
        set_existing!(robj, Mat4f(cam.pixel_space[]),    :pixel_space)
        set_existing!(robj, Vec3f(cam.eyeposition[]),    :eyeposition)
        set_existing!(robj, Vec3f(cam.view_direction[]), :view_direction)
        set_existing!(robj, Vec3f(cam.upvector[]),       :upvector)
    end

    # If we have markerspace we usually project from
    #       space  ->  markerspace  ->  clip        with
    #         preprojection   projectionview
    # otherwise projectionview goes from space -> clip directly
    space_name = target_markerspace ? (:markerspace) : (:space)
    if any(needs_update, (space_name, :camera))
        _space = plot.computed[space_name]
        set_existing!(robj, is_data_space(_space) ? Mat4f(cam.view[]) : Mat4f(I),   :view)
        set_existing!(robj, Mat4f(Makie.space_to_clip(cam, _space, false)),         :projection)
        set_existing!(robj, Mat4f(Makie.space_to_clip(cam, _space, true)),          :projectionview)
    end

    if target_markerspace && any(needs_update, (:space, :markerspace, :camera))
        preprojection = Mat4f(
            Makie.clip_to_space(cam, plot.computed[:markerspace]) *
            Makie.space_to_clip(cam, plot.computed[:space]))
        set_existing!(robj, preprojection, :preprojection)
    end

    if any(needs_update, (:camera, :px_per_unit))
        set_existing!(robj, Vec2f(screen.px_per_unit[] * scene.camera.resolution[]), :resolution)
    end

    # f32c can change model
    if any(needs_update, (:model, :f32c)) && haskey(robj.uniforms, :world_normalmatrix)
        i3 = Vec(1,2,3)
        robj[:world_normalmatrix] = Mat4f(transpose(inv(robj[:model][i3, i3])))
    end

    if any(needs_update, (:camera, :model, :f32c)) && haskey(robj.uniforms, :view_normalmatrix)
        cam = scene.camera
        robj[:view_normalmatrix]  = Mat4f(transpose(inv(cam.view[i3, i3] * robj[:model][i3, i3])))
    end

    return
end

function init_generics!(data, plot)
    data[:fxaa]         = get(plot.computed, :fxaa, false)
    data[:ssao]         = get(plot.computed, :ssao, false)
    data[:transparency] = get(plot.computed, :transparency, false)
    data[:overdraw]     = get(plot.computed, :overdraw, false)
    data[:px_per_unit]  = 1f0
    data[:depth_shift]  = get(plot.computed, :depth_shift, 0f0)
    return
end

function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::Scatter))
    # TODO: skipped fastpixel

    @assert !haskey(screen.cache, objectid(plot))


    # TODO: make these obsolete
    # Set up additional triggers

    # TODO: Is this even dynamic?
    on(screen.px_per_unit) do ppu
        push!(plot.updated_outputs[], :px_per_unit)
        notify(plot.updated_inputs)
        return
    end
    # f32c depend on projectionview so it doesn't need an explicit trigger (right?)
    if scene.float32convert !== nothing
        on(scene.float32convert.scaling) do _
            push!(plot.updated_outputs[], :f32c)
            notify(plot.updated_inputs)
            return
        end
    end


    # Note: For initializing data via update routine (one time)
    push!(plot.updated_outputs[], :position)
    push!(plot.updated_outputs[], :marker)

    data = Dict{Symbol, Any}()

    begin # cached_robj pre
        # TODO: lighting

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

    begin # draw_atomic
        if plot.computed[:marker] isa FastPixel
            # TODO: implement
        else
            Dim = length(eltype(plot.converted[1][]))
            N = length(plot.converted[1][])
            @gen_defaults! data begin
                position        = Vector{Point{Dim, Float32}}(undef, N) => GLBuffer
                len             = 0 # should match length of position
                distancefield   = get(plot.computed, :distancefield, nothing)
                shape           = Cint(Makie.marker_to_sdf_shape(plot.computed[:marker]))
            end

            atlas = gl_texture_atlas()
            if (data[:distancefield] === nothing) && (data[:shape] === Cint(DISTANCEFIELD))
                data[:distancefield] = get_texture!(atlas)
            end
        end
    end

    begin # draw_scatter()
        rot = vec2quaternion(get(plot.computed, :rotation, Vec4f(0, 0, 0, 1)))

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
            marker_offset   = Vec3f(0) => GLBuffer # Note: currently unused for Scatter
            scale           = Vec2f(0) => GLBuffer
            rotation        = rot => GLBuffer
            image           = nothing => Texture
            indices         = to_index_buffer(plot.computed[:depthsorting] ? UInt32[] : 0)
        end

        init_clip_planes!(data, plot)
        init_color!(data, plot)
        init_camera!(data, scene, plot)
        init_generics!(data, plot)

        @gen_defaults! data begin
            quad_offset     = Vec2f(0) => GLBuffer

            glow_color      = plot.computed[:glowcolor] => GLBuffer
            stroke_color    = plot.computed[:strokecolor] => GLBuffer
            stroke_width    = 0f0
            glow_width      = 0f0
            uv_offset_width = ifelse(plot.computed[:marker] isa Vector, Vec4f[], Vec4f(0)) => GLBuffer

            # rotation and billboard don't go along
            billboard       = (plot.computed[:rotation] isa Billboard) || (rotation == Vec4f(0,0,0,1))
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

        robj = assemble_shader(data)
    end

    on(plot, plot.updated_inputs) do _

        # Makie Update
        Makie.resolve_updates!(plot)

        @info "Triggered with $(plot.updated_outputs[])"

        if isempty(plot.updated_outputs[]) || !isopen(screen)
            return
        else
            screen.requires_update = true
        end

        update_robj!(screen, robj, scene, plot)

        empty!(plot.updated_outputs[])

        return
    end


    notify(plot.updated_inputs)

    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)

    # screen.requires_update = true
    return robj
end

function update_robj!(screen::Screen, robj::RenderObject, scene::Scene, plot::Scatter)
    # Backend Update
    needs_update = in(plot.updated_outputs[])
    atlas = gl_texture_atlas()
    font = get(plot.computed, :font, Makie.defaultfont())

    if any(needs_update, (:f32c, :model))
        # TODO: without Observables
        f32c, model = Makie._patch_model(scene.float32convert, plot.computed[:model]::Mat4d)
        # TODO: This should be rare so we want to cache it
        # maybe do this in resolve? But CairoMakie doesn't need it...
        plot.computed[:f32c] = f32c
        robj[:model] = model
    end

    # Camera update - relies on up-to-date model
    update_camera!(robj, screen, scene, plot, true)

    if any(needs_update, (:f32c, :model, :transform_func, :position))
        positions = apply_transform_and_f32_conversion(
            plot.computed[:f32c], Makie.transform_func(plot), plot.computed[:model]::Mat4d,
            plot.converted[1][], plot.computed[:space]::Symbol
        )
        haskey(robj.uniforms, :len) && (robj[:len] = length(positions))
        update!(robj.vertexarray.buffers["position"], positions)
    end

    # Handle indices
    if get(plot.computed, :depthsorting, false) && any(needs_update, (:f32c, :model, :transform_func, :position, :camera))
        T = Mat4f(robj[:projectionview] * robj[:preprojection] * robj[:model])
        depth_vals = map(robj.vertexarray.buffers["position"]::Vector) do p  # TODO: does this have CPU data?
            p4d::Point4f = T * to_ndim(Point4f, to_ndim(Point3f, p, 0f0), 1f0)
            return p4d[3] / p4d[4]
        end
        indices = UInt32.(sortperm(depth_vals, rev = true) .- 1)
        update!(robj.vertexarray.indices, indices)
    else # this only sets an int, basically free?
        robj.vertexarray.indices = length(robj.vertexarray.buffers["position"])
    end

    if any(needs_update, (:marker, :markersize, :marker_offset))
        scale = Makie.rescale_marker(
            atlas, plot.computed[:marker], font, plot.computed[:markersize])
        quad_offset = Makie.offset_marker(
            atlas, plot.computed[:marker], font, plot.computed[:markersize],
            plot.computed[:marker_offset])

        for (k, v) in ((:scale, scale), (:quad_offset, quad_offset))
            if haskey(robj.uniforms, k)
                robj.uniforms[k] = v
            elseif haskey(robj.vertexarray.buffers, string(k))
                update!(robj.vertexarray.buffers[string(k)], v)
            else
                error("Did not find $k")
            end
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

    # TODO: Don't break stuff :(
    if isnothing(plot.computed[:distancefield])
        delete!(plot.updated_outputs[], :distancefield)
    end

    for key in plot.updated_outputs[]
        glkey = to_glvisualize_key(key)
        val = plot.computed[key]

        if key == :rotation
            # TODO: Don't make this an observable and also can we just skip this?
            val = to_value(vec2quaternion(val))
        end

        # Could also check `val isa AbstractArray` + whitelist buffers

        # Specials
        if key == :marker
            shape = Cint(Makie.marker_to_sdf_shape(val))
            if shape == 0 && !is_all_equal_scale(plot.computed[:markersize])
                robj[:shape] = Cint(5) # circle -> ellipse
            else
                robj[:shape] = shape
            end

            if plot.computed[:uv_offset_width] == Vec4f(0)
                robj[:uv_offset_width] = Makie.primitive_uv_offset_width(atlas, val, font)
            end

        elseif key == :visible
            robj.visible = val::Bool

        elseif key == :overdraw
            robj.prerenderfunction.overdraw[] = val::Bool

        # TODO: Don't let Vec4f(0) pass down here
        elseif key == :uv_offset_width
            if plot.computed[:uv_offset_width] != Vec4f(0)
                robj[:uv_offset_width] = plot.computed[:uv_offset_width]
            end

        # Handle vertex buffers
        elseif haskey(robj.vertexarray.buffers, string(glkey))
            if robj.vertexarray.buffers[string(glkey)] isa GLBuffer
                update!(robj.vertexarray.buffers[string(glkey)], val)
            else
                robj.vertexarray.buffers[string(glkey)] = val
            end

        # Handle uniforms
        elseif haskey(robj.uniforms, glkey)
            # TODO: Should this force matching types (E.g. mutable struct Uniform{T}; x::T; end wrapper?)
            if robj[glkey] isa GPUArray
                update!(robj[glkey], val)
            else
                robj[glkey] = GLAbstraction.gl_convert(val)
            end

        # TODO: colorrange should be colorrange_scaled
        # has been tested as color -> color, but not color_scaled -> intensity
        elseif (key == :color_scaled) && haskey(robj.vertexarray.buffers, "intensity")
            update!(robj.vertexarray.buffers["intensity"], val)

        else
            # printstyled("Discarded backend update $key -> $glkey. (does not exist)\n", color = :light_black)
        end
    end
end

render_asap(screen::Screen, N::Integer) = render_asap(() -> nothing, screen, N)
function render_asap(f::Function, screen::Screen, N::Integer)
    screen.close_after_renderloop = false
    stop_renderloop!(screen)
    yield()
    GLFW.SwapInterval(0)

    for _ in 1:N
        pollevents(screen, Makie.PausedRenderTick)
        f()
        render_frame(screen)
        GLFW.SwapBuffers(to_native(screen))
        GC.safepoint()
    end

    screen.close_after_renderloop = true
    start_renderloop!(screen)
end