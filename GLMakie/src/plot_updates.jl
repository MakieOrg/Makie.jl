# Notes:
# - Handling FastPixel here feels pretty messy, shoudl extract
#   - generally, different shader = different primitive plot type?
# - image marker feels like something for Makie to handle, maybe?

# LOC:
# this: ~500
# equivalent before:
#   65 draw_atomic
#   12 handle_view
#   90 cached_robj w/o lighting
#   55 connect_camera + get_space
#   20 handle_intensities
#   20 draw_pixel_scatter
#   10 draw_scatter (image)
#   30 draw_scatter (images)
#   75 draw_scatter (general)
#    5 intensity_convert
# ----------------------
#  382

################################################################################
### Generics
################################################################################

function init_color!(data, plot)
    # Colormapping
    if plot.computed[:color] isa Union{Real, AbstractVector{<: Real}} # do colormapping
        interp = plot.computed[:color_mapping_type] === Makie.continuous ? :linear : :nearest
        # Allow missmatch between length of value colors and positions
        if length(plot.converted[1][]) == length(plot.computed[:color_scaled])
            data[:intensity] = GLBuffer(plot.computed[:color_scaled])
        else
            data[:intensity] = Texture(plot.computed[:color_scaled])
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

function update_clip_planes!(robj, plot)
    if any(in(plot.updated_outputs[]), (:space, :clip_planes))
        if !Makie.is_data_space(plot.computed[:space])
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
        data[:image] = marker
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

    begin # draw_scatter()
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

        init_generics!(data, plot, screen)
        init_camera!(data, scene, plot)
        init_clip_planes!(data, plot)
        init_color!(data, plot)
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

        robj = assemble_shader(data)
    end

    # We could try pulling out some "constants"
    HAS_IMAGE = get(robj.uniforms, :image, nothing) !== nothing
    ISFASTPIXEL = plot.computed[:marker] isa FastPixel
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

        # intersect!(plot.updated_outputs[], APPLICABLE_NAMES)

        # @info "Triggered with $(plot.updated_outputs[])"

        if isempty(plot.updated_outputs[]) || !isopen(screen) || (robj.id == 0) ||
                any(buffer -> buffer.id == 0, values(robj.vertexarray.buffers))
            return
        else
            update_robj!(screen, robj, scene, plot)
            empty!(plot.updated_outputs[])
            screen.requires_update = true
        end

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