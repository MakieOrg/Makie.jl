function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::Scatter))
    # TODO: skipped fastpixel
    # TODO: all the auto-converts... for maybe textures

    # WHITELIST = Set([
    #     :model, :transform_func, # TODO: add value in computed, tracking
    #     :colormap, :lowclip, :highclip, :nan_color, :color, :colorrange, 
    #     :glowwidth, :glowcolor, :strokecolor, :strokewidth,  
    #     :depthsorting, :distancefield, :rotation,
    #     :marker, :marker_offset, :markersize, :transform_marker, :uv_offset_width,
    #     :space, :markerspace, 
    #     :ssao, :fxaa, :overdraw, :visible, :depth_shift, :clip_planes, :transparency, 
    # ])
    
    # TODO: maybe on plot init?
    # Prepare - force all computed to get calculated
    union!(plot.updated_inputs[], keys(plot.attributes))
    Makie.resolve_updates!(plot) # make sure we have computed values to set defaults



    # TODO: make these obsolete
    # Set up additional triggers
    onany(plot, scene.camera.projectionview, scene.camera.resolution) do _, __
        push!(plot.updated_outputs[], :camera)
    end
    # TODO: Is this even dynamic?
    on(ppu -> push!(plot.updated_outputs[], :ppu), screen.px_per_unit)
    # f32c depend on projectionview so it doesn't need an explicit trigger (right?)
    if scene.float32convert !== nothing
        on(_ -> push!(plot.updated_outputs[], :f32c), scene.float32convert.scaling)
    end


    # Note: For initializing data via update routine (one time)
    push!(plot.updated_outputs[], :position)
    push!(plot.updated_outputs[], :marker)
    push!(plot.updated_outputs[], :camera)
    
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
            # TODO
        else
            Dim = length(eltype(plot.converted[1][]))
            @gen_defaults! data begin
                position        = Point{Dim, Float32}[] => GLBuffer
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
        rot = vec2quaternion(get(data, :rotation, Vec4f(0, 0, 0, 1)))

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
            num_clip_planes = 0
            clip_planes     = fill(Vec4f(0,0,0,-1e9), 8)
        end

        # Colormapping
        if plot.computed[:color] isa Union{Real, Vector{<: Real}} # do colormapping
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
            quad_offset     = Vec2f(0) => GLBuffer

            lowclip         = get(plot.computed, :lowclip, Vec3f(0))
            highclip        = get(plot.computed, :highclip, Vec3f(0))
            nan_color       = get(plot.computed, :nan_color, Vec3f(0))

            glow_color      = plot.computed[:glowcolor] => GLBuffer
            stroke_color    = plot.computed[:strokecolor] => GLBuffer
            stroke_width    = 0f0
            glow_width      = 0f0
            uv_offset_width = ifelse(plot.computed[:marker] isa Vector, Vec4f[], Vec4f(0)) => GLBuffer

            # rotation and billboard don't go along
            billboard       = (plot.computed[:rotation] isa Billboard) || (rotation == Vec4f(0,0,0,1))

            distancefield    = nothing => Texture
            fxaa             = false
            ssao             = false
            transparency     = false
            px_per_unit      = 1f0
            depth_shift      = 0f0
            shader           = GLVisualizeShader(
                screen,
                "fragment_output.frag", "util.vert", "sprites.geom",
                "sprites.vert", "distance_shape.frag",
                view = Dict(
                    "position_calc" => position_calc(position, nothing, nothing, nothing, GLBuffer),
                    "buffers" => output_buffers(screen, to_value(transparency)),
                    "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
                )
            )
            scale_primitive = true
            gl_primitive = GL_POINTS
        end

        # TODO:
        # # Exception for intensity, to make it possible to handle intensity with a
        # # different length compared to position. Intensities will be interpolated in that case
        # data[:intensity] = intensity_convert(intensity, position)

        robj = assemble_shader(data)
    end

    on(plot, plot.updated_inputs) do _

        # Makie Update
        Makie.resolve_updates!(plot)
        
        if isempty(plot.updated_outputs[])
            return
        else
            screen.requires_update = true
        end

        # Backend Update
        needs_update = in(plot.updated_outputs[])
        atlas = gl_texture_atlas()
        font = get(plot.computed, :font, Makie.defaultfont())

        # Camera
        if needs_update(:camera)
            cam = scene.camera
            space = plot.computed[:space]
            markerspace = plot.computed[:markerspace]

            # robj[:pixel_space]    = Mat4f(cam.pixel_space[])
            # robj[:eyeposition]    = Vec3f(cam.eyeposition[])
            robj[:view]           = is_data_space(markerspace) ? Mat4f(cam.view[]) : Mat4f(I)
            robj[:projection]     = Mat4f(Makie.space_to_clip(cam, markerspace, false))
            # robj[:projectionview] = Mat4f(Makie.space_to_clip(cam, markerspace, true))
            
            robj[:preprojection]  = Mat4f(Makie.clip_to_space(cam, markerspace) * Makie.space_to_clip(cam, space))
        end

        # TODO: too much fragmentation?
        if any(needs_update, (:camera, :px_per_unit))
            robj[:resolution] = Vec2f(screen.px_per_unit[] * scene.camera.resolution[])
        end

        if any(needs_update, (:f32c, :model))
            # TODO: without Observables
            f32c, model = Makie._patch_model(scene.float32convert, plot.computed[:model])
            # TODO: This should be rare so we want to cache it
            # maybe do this in resolve? But CairoMakie doesn't need it...
            plot.computed[:f32c] = f32c
            robj[:model] = model
            
            # i3 = Vec(1,2,3)
            # robj[:world_normalmatrix] = Mat4f(transpose(inv(plot.computed[:model][i3, i3])))
        end
        
        # if any(needs_update, (:camera, :model, :f32c)) # because f32c can influence model
            # cam = scene.camera
            # robj[:view_normalmatrix]  = Mat4f(transpose(inv(cam.view[i3, i3] * robj[:model][i3, i3])))
        # end

        changed_length = false
        if any(needs_update, (:f32c, :model, :transform_func, :position))
            positions = apply_transform_and_f32_conversion(
                plot.computed[:f32c], Makie.transform_func(plot), plot.computed[:model], 
                plot.converted[1][], plot.computed[:space]
            )
            changed_length = length(positions) != length(robj.vertexarray.buffers["position"])
            robj[:len] = length(positions)
            update!(robj.vertexarray.buffers["position"], positions)
        end

        # Handle indices
        if get(plot.computed, :depthsorting, false) && any(needs_update, (:f32c, :model, :transform_func, :position, :camera))
            T = Mat4f(robj[:projectionview] * robj[:preprojection] * robj[:model])
            depth_vals = map(robj.vertexarray.buffers["position"]) do p  # TODO: does this have CPU data?
                p4d = T * to_ndim(Point4f, to_ndim(Point3f, p, 0f0), 1f0)
                p4d[3] / p4d[4]
            end
            indices = UInt32.(sortperm(depth_vals, rev = true) .- 1)
            update!(robj.vertexarray.indices, indices)
        elseif changed_length
            robj.vertexarray.indices = length(positions)
        end

        if any(needs_update, (:marker, :makersize, :marker_offset))
            robj[:scale] = Makie.rescale_marker(
                atlas, plot.computed[:marker], font, plot.computed[:markersize])

            robj[:quad_offset] = Makie.offset_marker(
                atlas, plot.computed[:marker], font, plot.computed[:markersize], 
                plot.computed[:marker_offset])
        end

        if any(needs_update, (:space, :clip_planes))
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

        # Clean up things we've already handled (and must not handle again)
        delete!(plot.updated_outputs[], :position)
        delete!(plot.updated_outputs[], :model)
        delete!(plot.updated_outputs[], :markersize)
        delete!(plot.updated_outputs[], :marker_offset)
        delete!(plot.updated_outputs[], :clip_planes)
        
        # And that don't exist in computed
        delete!(plot.updated_outputs[], :camera)

        # TODO: Don't break stuff :(
        if isnothing(plot.computed[:distancefield])
            delete!(plot.updated_outputs[], :distancefield)
        end

        for key in plot.updated_outputs[]
            glkey = to_glvisualize_key(key)
            val = plot.computed[key]
            
            # Could also check `val isa AbstractArray` + whitelist buffers

            # Specials
            if key == :marker
                shape = Cint(Makie.marker_to_sdf_shape(val))
                if shape == 0 && !is_all_equal_scale(robj[:scale]) # Note: scale set already
                    robj[:shape] = Cint(5) # circle -> ellipse
                else
                    robj[:shape] = shape
                end

                if plot.computed[:uv_offset_width] == Vec4f(0)
                    robj[:uv_offset_width] = Makie.primitive_uv_offset_width(atlas, val, font)
                end

            elseif key == :visible
                robj.visible = val

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
                if val isa Union{Real, StaticVector, Mat, Colorant, Nothing, Quaternion}
                    robj[glkey] = GLAbstraction.gl_convert(val)
                else
                    update!(robj[glkey], val)
                end
            else
                printstyled("Discarded backend update $key -> $glkey. (does not exist)\n", color = :light_black)
            end
        end

        empty!(plot.updated_outputs[])

        return
    end

    
    notify(plot.updated_inputs)
    
    screen.cache2plot[robj.id] = plot
    push!(screen, scene, robj)
    
    # screen.requires_update = true
    return robj
end