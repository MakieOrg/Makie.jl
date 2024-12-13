using Makie: transform_func_obs, apply_transform
using Makie: attribute_per_char, FastPixel, el32convert, Pixel
using Makie: convert_arguments
using Makie: apply_transform_and_f32_conversion, f32_conversion_obs

function handle_lights(attr::Dict, screen::Screen, lights::Vector{Makie.AbstractLight})
    @inline function push_inplace!(trg, idx, src)
        for i in eachindex(src)
            trg[idx + i] = src[i]
        end
        return idx + length(src)
    end

    MAX_LIGHTS = screen.config.max_lights
    MAX_PARAMS = screen.config.max_light_parameters

    # Every light has a type and a color. Therefore we have these as independent
    # uniforms with a max length of MAX_LIGHTS.
    # Other parameters like position, direction, etc differe between light types.
    # To avoid wasting a bunch of memory we squash all of them into one vector of
    # size MAX_PARAMS.
    attr[:N_lights]         = Observable(0)
    attr[:light_types]      = Observable(sizehint!(Int32[], MAX_LIGHTS))
    attr[:light_colors]     = Observable(sizehint!(RGBf[], MAX_LIGHTS))
    attr[:light_parameters] = Observable(sizehint!(Float32[], MAX_PARAMS))

    on(screen.render_tick, priority = -1000) do _
        # derive number of lights from available lights. Both MAX_LIGHTS and
        # MAX_PARAMS are considered for this.
        n_lights = 0
        n_params = 0
        for light in lights
            delta = 0
            if light isa PointLight
                delta = 5 # 3 position + 2 attenuation
            elseif light isa DirectionalLight
                delta = 3 # 3 direction
            elseif light isa SpotLight
                delta = 8 # 3 position + 3 direction + 2 angles
            elseif light isa RectLight
                delta = 12 # 3 position + 2x 3 rect basis vectors + 3 direction
            end
            if n_params + delta > MAX_PARAMS || n_lights == MAX_LIGHTS
                if n_params > MAX_PARAMS
                    @warn "Exceeded the maximum number of light parameters ($n_params > $MAX_PARAMS). Skipping lights beyond number $n_lights."
                else
                    @warn "Exceeded the maximum number of lights ($n_lights > $MAX_LIGHTS). Skipping lights beyond number $n_lights."
                end
                break
            end
            n_params += delta
            n_lights += 1
        end

        # Update number of lights
        attr[:N_lights][] = n_lights

        # Update light types
        trg = attr[:light_types][]
        resize!(trg, n_lights)
        map!(i -> Makie.light_type(lights[i]), trg, 1:n_lights)
        notify(attr[:light_types])

        # Update light colors
        trg = attr[:light_colors][]
        resize!(trg, n_lights)
        map!(i -> Makie.light_color(lights[i]), trg, 1:n_lights)
        notify(attr[:light_colors])

        # Update other light parameters
        # This precalculates world space pos/dir -> view/cam space pos/dir
        parameters = attr[:light_parameters][]
        resize!(parameters, n_params)
        idx = 0
        for i in 1:n_lights
            light = lights[i]
            if light isa PointLight
                idx = push_inplace!(parameters, idx, light.position[])
                idx = push_inplace!(parameters, idx, light.attenuation[])
            elseif light isa DirectionalLight
                if light.camera_relative
                    T = inv(attr[:view][][Vec(1,2,3), Vec(1,2,3)])
                    dir = normalize(T * light.direction[])
                else
                    dir = normalize(light.direction[])
                end
                idx = push_inplace!(parameters, idx, dir)
            elseif light isa SpotLight
                idx = push_inplace!(parameters, idx, light.position[])
                idx = push_inplace!(parameters, idx, normalize(light.direction[]))
                idx = push_inplace!(parameters, idx, cos.(light.angles[]))
            elseif light isa RectLight
                idx = push_inplace!(parameters, idx, light.position[])
                idx = push_inplace!(parameters, idx, light.u1[])
                idx = push_inplace!(parameters, idx, light.u2[])
                idx = push_inplace!(parameters, idx, normalize(light.direction[]))
            end
        end
        notify(attr[:light_parameters])

        return Consume(false)
    end

    return attr
end

Makie.el32convert(x::GLAbstraction.Texture) = x

gpuvec(x) = GPUVector(GLBuffer(x))

to_range(x, y) = to_range.((x, y))
to_range(x::ClosedInterval) = (minimum(x), maximum(x))
to_range(x::VecTypes{2}) = x
to_range(x::AbstractRange) = (minimum(x), maximum(x))
to_range(x::AbstractVector) = (minimum(x), maximum(x))

function to_range(x::AbstractArray)
    if length(x) in size(x) # assert that just one dim != 1
        to_range(vec(x))
    else
        error("Can't convert to a range. Please supply a range/vector/interval or a tuple (min, max)")
    end
end

function to_glvisualize_key(k)
    k === :rotations && return :rotation
    k === :markersize && return :scale
    k === :glowwidth && return :glow_width
    k === :glowcolor && return :glow_color
    k === :strokewidth && return :stroke_width
    k === :strokecolor && return :stroke_color
    k === :positions && return :position
    k === :linewidth && return :thickness
    k === :colormap && return :color_map
    k === :colorrange && return :color_norm
    k === :transform_marker && return :scale_primitive
    return k
end

function connect_camera!(plot, gl_attributes, cam, space = gl_attributes[:space])
    # Overwrite these, user defined attributes shouldn't use those!
    gl_attributes[:pixel_space] = lift(Mat4f, plot, cam.pixel_space)
    gl_attributes[:eyeposition] = lift(identity, plot, cam.eyeposition)

    get!(gl_attributes, :view) do
        # get!(cam.calculated_values, Symbol("view_$(space[])")) do
            return lift(plot, cam.view, space) do view, space
                return is_data_space(space) ? Mat4f(view) : Mat4f(I)
            end
        # end
    end

    # for lighting
    get!(gl_attributes, :world_normalmatrix) do
        return lift(plot, gl_attributes[:model]) do m
            i = Vec(1, 2, 3)
            return Mat3f(transpose(inv(m[i, i])))
        end
    end

    # for SSAO
    get!(gl_attributes, :view_normalmatrix) do
        return lift(plot, gl_attributes[:view], gl_attributes[:model]) do v, m
            i = Vec(1, 2, 3)
            return Mat3f(transpose(inv(v[i, i] * m[i, i])))
        end
    end
    get!(gl_attributes, :projection) do
        # return get!(cam.calculated_values, Symbol("projection_$(space[])")) do
            return lift(plot, cam.projection, cam.pixel_space, space) do _, _, space
                return Mat4f(Makie.space_to_clip(cam, space, false))
            end
        # end
    end
    get!(gl_attributes, :projectionview) do
        # get!(cam.calculated_values, Symbol("projectionview_$(space[])")) do
            return lift(plot, cam.projectionview, cam.pixel_space, space) do _, _, space
                return Mat4f(Makie.space_to_clip(cam, space, true))
            end
        # end
    end
    # resolution in real hardware pixels, not scaled pixels/units
    get!(gl_attributes, :resolution) do
        # get!(cam.calculated_values, :resolution) do
            return lift(*, plot, gl_attributes[:px_per_unit], cam.resolution)
        # end
    end

    delete!(gl_attributes, :space)
    delete!(gl_attributes, :markerspace)
    return nothing
end

function handle_intensities!(screen, attributes, plot)
    color = plot.calculated_colors
    if color[] isa Makie.ColorMapping
        onany(plot, color[].color_scaled, color[].colorrange_scaled, color[].colormap, color[].nan_color) do args...
            screen.requires_update = true
        end
        attributes[:intensity] = color[].color_scaled
        interp = color[].color_mapping_type[] === Makie.continuous ? :linear : :nearest
        attributes[:color_map] = Texture(color[].colormap; minfilter=interp)
        attributes[:color_norm] = color[].colorrange_scaled
        attributes[:nan_color] = color[].nan_color
        attributes[:highclip] = Makie.highclip(color[])
        attributes[:lowclip] = Makie.lowclip(color[])
        attributes[:color] = nothing
    else
        attributes[:color] = color
        delete!(attributes, :intensity)
        delete!(attributes, :color_map)
        delete!(attributes, :color_norm)
        delete!(attributes, :colorscale)
    end
    return
end

function get_space(x)
    is_fast_pixel = to_value(get(x, :marker, nothing)) isa FastPixel
    is_fast_pixel && return x.space
    return haskey(x, :markerspace) ? x.markerspace : x.space
end

const EXCLUDE_KEYS = Set([:transformation, :tickranges, :ticklabels, :raw, :SSAO,
                        :lightposition, :material, :axis_cycler,
                        :inspector_label, :inspector_hover, :inspector_clear, :inspectable,
                        :colorrange, :colormap, :colorscale, :highclip, :lowclip, :nan_color,
                        :calculated_colors, :space, :markerspace, :model, :dim_conversions, :material])


function cached_robj!(robj_func, screen, scene, plot::AbstractPlot)
    # poll inside functions to make wait on compile less prominent
    pollevents(screen, Makie.BackendTick)
    robj = get!(screen.cache, objectid(plot)) do

        filtered = filter(plot.attributes) do (k, v)
            return !in(k, EXCLUDE_KEYS)
        end

        # Handle update tracking for render on demand
        track_updates = screen.config.render_on_demand
        if track_updates
            for arg in plot.args
                on(plot, arg) do x
                    screen.requires_update = true
                end
            end
            on(plot, plot.model) do x
                screen.requires_update = true
            end
            on(plot, scene.camera.projectionview) do x
                screen.requires_update = true
            end
        end

        # Pass along attributes
        gl_attributes = Dict{Symbol, Any}(map(filtered) do key_value
            key, value = key_value
            gl_key = to_glvisualize_key(key)
            gl_value = lift_convert(key, value, plot, screen)
            gl_key => gl_value
        end)

        # :f32c should get passed to apply_transform_and_f32_conversion but not
        # make it to uniforms
        gl_attributes[:f32c], gl_attributes[:model] = Makie.patch_model(plot)

        if haskey(plot, :markerspace)
            gl_attributes[:markerspace] = plot.markerspace
        end
        gl_attributes[:space] = plot.space
        gl_attributes[:px_per_unit] = screen.px_per_unit

        # Handle clip planes
        # OpenGL supports up to 8
        clip_planes = pop!(gl_attributes, :clip_planes)
        gl_attributes[:num_clip_planes] = map(plot, clip_planes, gl_attributes[:space]) do planes, space
            return Makie.is_data_space(space) ? min(8, length(planes)) : 0
        end
        gl_attributes[:clip_planes] = map(plot, clip_planes, gl_attributes[:space]) do planes, space
            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            if length(planes) > 8
                @warn("Only up to 8 clip planes are supported. The rest are ignored!", maxlog = 1)
            end

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                output[i] = Makie.gl_plane_format(planes[i])
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e9)
            end
            return output
        end

        handle_intensities!(screen, gl_attributes, plot)
        connect_camera!(plot, gl_attributes, scene.camera, get_space(plot))

        # TODO: remove depwarn & conversion after some time
        if haskey(gl_attributes, :shading) && to_value(gl_attributes[:shading]) isa Bool
            @warn "`shading::Bool` is deprecated. Use `shading = NoShading` instead of false and `shading = FastShading` or `shading = MultiLightShading` instead of true."
            gl_attributes[:shading] = ifelse(gl_attributes[:shading][], FastShading, NoShading)
        elseif haskey(gl_attributes, :shading) && gl_attributes[:shading] isa Observable
            gl_attributes[:shading] = gl_attributes[:shading][]
        end

        shading = to_value(get(gl_attributes, :shading, NoShading))

        if shading == FastShading
            dirlight = Makie.get_directional_light(scene)
            if !isnothing(dirlight)
                gl_attributes[:light_direction] = if dirlight.camera_relative
                    map(gl_attributes[:view], dirlight.direction) do view, dir
                        return  normalize(inv(view[Vec(1,2,3), Vec(1,2,3)]) * dir)
                    end
                else
                    map(normalize, dirlight.direction)
                end

                gl_attributes[:light_color] = dirlight.color
            else
                gl_attributes[:light_direction] = Observable(Vec3f(0))
                gl_attributes[:light_color] = Observable(RGBf(0,0,0))
            end

            ambientlight = Makie.get_ambient_light(scene)
            if !isnothing(ambientlight)
                gl_attributes[:ambient] = ambientlight.color
            else
                gl_attributes[:ambient] = Observable(RGBf(0,0,0))
            end
        elseif shading == MultiLightShading
            handle_lights(gl_attributes, screen, scene.lights)
        end
        robj = robj_func(gl_attributes)

        get!(gl_attributes, :ssao, Observable(false))
        screen.cache2plot[robj.id] = plot
        return robj
    end
    push!(screen, scene, robj)
    return robj
end

function Base.insert!(screen::Screen, scene::Scene, @nospecialize(x::Plot))
    ShaderAbstractions.switch_context!(screen.glscreen)
    add_scene!(screen, scene)
    # poll inside functions to make wait on compile less prominent
    pollevents(screen, Makie.BackendTick)
    if isempty(x.plots) # if no plots inserted, this truly is an atomic
        draw_atomic(screen, scene, x)
    else
        foreach(x.plots) do x
            # poll inside functions to make wait on compile less prominent
            pollevents(screen, Makie.BackendTick)
            insert!(screen, scene, x)
        end
    end
end

index1D(x::SubArray) = parentindices(x)[1]

handle_view(array::AbstractVector, attributes) = array
handle_view(array::Observable, attributes) = array

function handle_view(array::SubArray, attributes)
    A = parent(array)
    indices = index1D(array)
    attributes[:indices] = indices
    return A
end

function handle_view(array::Observable{T}, attributes) where T <: SubArray
    A = lift(parent, array)
    indices = lift(index1D, array)
    attributes[:indices] = indices
    return A
end

function lift_convert(key, value, plot, screen)
    return lift_convert_inner(value, Key{key}(), Key{Makie.plotkey(plot)}(), plot, screen)
end

function lift_convert_inner(value, key, plot_key, plot, screen)
    return lift(plot, value) do value
        screen.requires_update = true
        return convert_attribute(value, key, plot_key)
    end
end

to_vec4(val::RGB) = RGBAf(val, 1.0)
to_vec4(val::RGBA) = RGBAf(val)

pixel2world(scene, msize::Number) = pixel2world(scene, Point2f(msize))[1]

function pixel2world(scene, msize::StaticVector{2})
    # TODO figure out why Vec(x, y) doesn't work correctly
    p0 = Makie.to_world(scene, Point2f(0.0))
    p1 = Makie.to_world(scene, Point2f(msize))
    diff = p1 - p0
    return diff
end

pixel2world(scene, msize::AbstractVector) = pixel2world.(scene, msize)


function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::Union{Scatter, MeshScatter}))
    return cached_robj!(screen, scene, plot) do gl_attributes
        # signals not supported for shading yet
        marker = pop!(gl_attributes, :marker)

        space = plot.space
        positions = handle_view(plot[1], gl_attributes)
        f32c = pop!(gl_attributes, :f32c)
        positions = apply_transform_and_f32_conversion(plot, f32c, positions)
        cam = scene.camera

        if plot isa Scatter
            mspace = plot.markerspace
            gl_attributes[:preprojection] = lift(plot, space, mspace, cam.projectionview,
                                                 cam.resolution) do space, mspace, _, _
                return Mat4f(Makie.clip_to_space(cam, mspace) * Makie.space_to_clip(cam, space))
            end
            # fast pixel does its own setup
            if !(marker[] isa FastPixel)
                gl_attributes[:billboard] = lift(rot -> isa(rot, Billboard), plot, plot.rotation)
                atlas = gl_texture_atlas()
                isnothing(gl_attributes[:distancefield][]) && delete!(gl_attributes, :distancefield)
                shape = lift(m -> Cint(Makie.marker_to_sdf_shape(m)), plot, marker)
                gl_attributes[:shape] = shape
                get!(gl_attributes, :distancefield) do
                    if shape[] === Cint(DISTANCEFIELD)
                        return get_texture!(atlas)
                    else
                        return nothing
                    end
                end
                font = get(gl_attributes, :font, Observable(Makie.defaultfont()))
                gl_attributes[:uv_offset_width][] == Vec4f(0) && delete!(gl_attributes, :uv_offset_width)
                get!(gl_attributes, :uv_offset_width) do
                    return Makie.primitive_uv_offset_width(atlas, marker, font)
                end
                scale, quad_offset = Makie.marker_attributes(atlas, marker, gl_attributes[:scale], font, plot)
                gl_attributes[:scale] = scale
                gl_attributes[:quad_offset] = quad_offset
            end
        end

        if marker[] isa FastPixel
            if haskey(gl_attributes, :intensity)
                gl_attributes[:color] = pop!(gl_attributes, :intensity)
            end
            to_keep = Set([:color_map, :color, :color_norm, :px_per_unit, :scale, :model, :marker_offset,
                             :projectionview, :projection, :view, :visible, :resolution, :transparency])
            filter!(gl_attributes) do (k, v,)
                return (k in to_keep)
            end
            gl_attributes[:markerspace] = lift(plot.markerspace) do space
                space == :pixel && return Int32(0)
                space == :data && return Int32(1)
                return error("Unsupported markerspace for FastPixel marker: $space")
            end
            gl_attributes[:marker_shape] = lift(x -> x.marker_type, plot.marker)
            gl_attributes[:upvector] = lift(x-> Vec3f(normalize(x)), cam.upvector)
            return draw_pixel_scatter(screen, positions, gl_attributes)
        else
            if plot isa MeshScatter
                # If the vertices of the scattered mesh, markersize and (if it applies) model
                # are float32 safe we should be able to just correct for any scaling from
                # float32convert in the shader, after those conversions.
                # We should also be fine as long as rotation = identity (also in model).
                # If neither is the case we would have to combine vertices with positions and
                # transform them to world space (post float32convert) on the CPU. We then can't
                # do instancing anymore, so meshscatter becomes pointless.
                if !isnothing(scene.float32convert)
                    gl_attributes[:f32c_scale] = map(plot, f32c, scene.float32convert.scaling, plot.transform_marker) do new_f32c, old_f32c, transform_marker
                        # we must use new_f32c with transform_marker = true,
                        # because model might be merged into f32c (robj.model = I)
                        # with transform_marker = false we must use the old f32c
                        # as we don't want model to apply
                        return Vec3f(transform_marker ? new_f32c.scale : old_f32c.scale)
                    end
                end

                if haskey(gl_attributes, :color) && to_value(gl_attributes[:color]) isa AbstractMatrix{<: Colorant}
                    gl_attributes[:image] = gl_attributes[:color]
                end
                return draw_mesh_particle(screen, (marker, positions), gl_attributes)
            else
                return draw_scatter(screen, (marker, positions), gl_attributes)
            end
        end
    end
end

function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::Lines))
    return cached_robj!(screen, scene, plot) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        miter_limit = pop!(gl_attributes, :miter_limit)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:miter_limit] = map(x -> Float32(cos(pi - x)), plot, miter_limit)
        positions = handle_view(plot[1], data)
        data[:scene_origin] = map(plot, data[:px_per_unit], scene.viewport) do ppu, viewport
            Vec2f(ppu * origin(viewport))
        end
        space = plot.space

        # Handled manually without using OpenGL clipping
        data[:_num_clip_planes] = pop!(data, :num_clip_planes)
        data[:num_clip_planes] = Observable(0)
        pop!(data, :clip_planes)
        data[:clip_planes] = map(plot, data[:projectionview], plot.clip_planes, space) do pv, planes, space
            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            clip_planes = Makie.to_clip_space(pv, planes)

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                output[i] = Makie.gl_plane_format(clip_planes[i])
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e9)
            end
            return output
        end

        if isnothing(to_value(linestyle))
            data[:pattern] = nothing
            data[:fast] = true

            positions = apply_transform_and_f32_conversion(plot, pop!(data, :f32c), positions)
        else
            data[:pattern] = linestyle
            data[:fast] = false

            # TODO: Skip patch_model() when this branch is used
            pop!(data, :f32c)
            pvm = lift(plot, data[:projectionview], plot.model, f32_conversion_obs(scene), space) do pv, model, f32c, space
                Makie.Mat4d(pv) * Makie.f32_convert_matrix(f32c, space) * model
            end
            transform_func = transform_func_obs(plot)
            positions = lift(plot, transform_func, positions, space, pvm) do f, ps, space, pvm
                transformed = apply_transform(f, ps, space)
                output = Vector{Point4f}(undef, length(transformed))
                for i in eachindex(transformed)
                    output[i] = pvm * to_ndim(Point4d, to_ndim(Point3d, transformed[i], 0.0), 1.0)
                end
                output
            end
        end

        if haskey(data, :intensity)
            data[:color] = pop!(data, :intensity)
        end

        return draw_lines(screen, positions, data)
    end
end

function draw_atomic(screen::Screen, scene::Scene, @nospecialize(plot::LineSegments))
    return cached_robj!(screen, scene, plot) do gl_attributes
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = pop!(data, :linestyle)
        data[:scene_origin] = map(plot, data[:px_per_unit], scene.viewport) do ppu, viewport
            Vec2f(ppu * origin(viewport))
        end

        # Handled manually without using OpenGL clipping
        data[:_num_clip_planes] = pop!(data, :num_clip_planes)
        data[:num_clip_planes] = Observable(0)


        positions = handle_view(plot[1], data)
        positions = apply_transform_and_f32_conversion(plot, pop!(data, :f32c), positions)
        if haskey(data, :intensity)
            data[:color] = pop!(data, :intensity)
        end

        return draw_linesegments(screen, positions, data)
    end
end

function draw_atomic(screen::Screen, scene::Scene,
        plot::Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})
    return cached_robj!(screen, scene, plot) do gl_attributes
        glyphcollection = plot[1]

        pos = apply_transform_and_f32_conversion(plot, pop!(gl_attributes, :f32c), gl_attributes[:position])
        space = plot.space
        markerspace = plot.markerspace
        offset = pop!(gl_attributes, :offset, Vec2f(0))
        atlas = gl_texture_atlas()

        # calculate quad metrics
        glyph_data = lift(plot, pos, glyphcollection, offset) do pos, gc, offset
            return Makie.text_quads(atlas, pos, to_value(gc), offset)
        end

        # unpack values from the one signal:
        positions, char_offset, quad_offset, uv_offset_width, scale = map((1, 2, 3, 4, 5)) do i
            lift(getindex, plot, glyph_data, i)
        end


        filter!(gl_attributes) do (k, v)
            # These are liftkeys without model
            !(k in (
                :position, :space, :markerspace, :font,
                :fontsize, :rotation, :justification
            )) # space,
        end

        gl_attributes[:color] = lift(plot, glyphcollection) do gc
            if gc isa AbstractArray
                reduce(vcat, (Makie.collect_vector(g.colors, length(g.glyphs)) for g in gc),
                    init = RGBAf[])
            else
                Makie.collect_vector(gc.colors, length(gc.glyphs))
            end
        end
        gl_attributes[:stroke_color] = lift(plot, glyphcollection) do gc
            if gc isa AbstractArray
                reduce(vcat, (Makie.collect_vector(g.strokecolors, length(g.glyphs)) for g in gc),
                    init = RGBAf[])
            else
                Makie.collect_vector(gc.strokecolors, length(gc.glyphs))
            end
        end

        gl_attributes[:rotation] = lift(plot, glyphcollection) do gc
            if gc isa AbstractArray
                reduce(vcat, (Makie.collect_vector(g.rotations, length(g.glyphs)) for g in gc),
                    init = Quaternionf[])
            else
                Makie.collect_vector(gc.rotations, length(gc.glyphs))
            end
        end

        gl_attributes[:shape] = Cint(DISTANCEFIELD)
        gl_attributes[:scale] = scale
        gl_attributes[:quad_offset] = quad_offset
        gl_attributes[:marker_offset] = char_offset
        gl_attributes[:uv_offset_width] = uv_offset_width
        gl_attributes[:distancefield] = get_texture!(atlas)
        gl_attributes[:visible] = plot.visible
        gl_attributes[:fxaa] = get(plot, :fxaa, Observable(false))
        gl_attributes[:depthsorting] = get(plot, :depthsorting, false)
        cam = scene.camera
        # gl_attributes[:preprojection] = Observable(Mat4f(I))
        gl_attributes[:preprojection] = lift(plot, space, markerspace, cam.projectionview, cam.resolution) do s, ms, pv, res
            Mat4f(Makie.clip_to_space(cam, ms) * Makie.space_to_clip(cam, s))
        end

        return draw_scatter(screen, (DISTANCEFIELD, positions), gl_attributes)
    end
end

# el32convert doesn't copy for array of Float32
# But we assume that xy_convert copies when we use it
xy_convert(x::AbstractArray, n) = copy(x)
xy_convert(x::Makie.EndPoints, n) = [LinRange(extrema(x)..., n + 1);]

function draw_atomic(screen::Screen, scene::Scene, plot::Heatmap)
    t = Makie.transform_func_obs(plot)

    if plot.x[] isa Makie.EndPoints && plot.y[] isa Makie.EndPoints && Makie.is_identity_transform(t[])
        # Fast path for regular heatmaps
        return draw_image(screen, scene, plot)
    end
    return cached_robj!(screen, scene, plot) do gl_attributes
        mat = plot[3]
        space = plot.space # needs to happen before connect_camera! call
        xypos = lift(plot, pop!(gl_attributes, :f32c), t, plot.model, plot[1], plot[2], space) do f32c, t, model, x, y, space
            # TODO: fix heatmaps for transforms that mix dimensions:
            # - transform_func's like Polar
            # - model matrices with rotation & Float32 precisionissues
            x1d = xy_convert(x, size(mat[], 1))
            y1d = xy_convert(y, size(mat[], 2))

            x1d = Makie.apply_transform_and_f32_conversion(f32c, t, model, x1d, 1, space)
            y1d = Makie.apply_transform_and_f32_conversion(f32c, t, model, y1d, 2, space)

            return (x1d, y1d)
        end
        xpos = lift(first, plot, xypos)
        ypos = lift(last, plot, xypos)
        gl_attributes[:position_x] = Texture(xpos, minfilter = :nearest)
        gl_attributes[:position_y] = Texture(ypos, minfilter = :nearest)
        # number of planes used to render the heatmap
        gl_attributes[:instances] = lift(plot, xpos, ypos) do x, y
            (length(x)-1) * (length(y)-1)
        end
        interp = to_value(pop!(gl_attributes, :interpolate))
        interp = interp ? :linear : :nearest
        intensity = haskey(gl_attributes, :intensity) ? pop!(gl_attributes, :intensity) : pop!(gl_attributes, :color)
        if intensity isa ShaderAbstractions.Sampler
            gl_attributes[:intensity] = to_value(intensity)
        else
            gl_attributes[:intensity] = Texture(el32convert(intensity); minfilter=interp)
        end

        return draw_heatmap(screen, gl_attributes)
    end
end

function draw_image(screen::Screen, scene::Scene, plot::Union{Heatmap, Image})
    return cached_robj!(screen, scene, plot) do gl_attributes
        position = lift(plot, plot[1], plot[2]) do x, y
            xmin, xmax = x
            ymin, ymax = y
            rect = Rect2(xmin, ymin, xmax - xmin, ymax - ymin)
            return decompose(Point2d, rect)
        end
        gl_attributes[:vertices] = apply_transform_and_f32_conversion(plot, pop!(gl_attributes, :f32c), position)
        rect = Rect2f(0, 0, 1, 1)
        gl_attributes[:faces] = decompose(GLTriangleFace, rect)
        gl_attributes[:texturecoordinates] = decompose_uv(rect)
        get!(gl_attributes, :shading, NoShading)
        _interp = to_value(pop!(gl_attributes, :interpolate, true))
        interp = _interp ? :linear : :nearest
        if haskey(gl_attributes, :intensity)
            gl_attributes[:image] = Texture(pop!(gl_attributes, :intensity); minfilter=interp)
        else
            gl_attributes[:image] = Texture(pop!(gl_attributes, :color); minfilter=interp)
        end
        gl_attributes[:picking_mode] = "#define PICKING_INDEX_FROM_UV"
        return draw_mesh(screen, gl_attributes)
    end
end

function draw_atomic(screen::Screen, scene::Scene, plot::Image)
    return draw_image(screen, scene, plot)
end

function mesh_inner(screen::Screen, mesh, transfunc, gl_attributes, plot, space=:data)
    # signals not supported for shading yet
    shading = to_value(gl_attributes[:shading])::Makie.MakieCore.ShadingAlgorithm
    matcap_active = !isnothing(to_value(get(gl_attributes, :matcap, nothing)))
    color = pop!(gl_attributes, :color)
    interp = to_value(pop!(gl_attributes, :interpolate, true))
    interp = interp ? :linear : :nearest
    
    if to_value(color) isa Colorant
        gl_attributes[:vertex_color] = color
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)
    elseif to_value(color) isa Makie.AbstractPattern
        img = lift(x -> el32convert(Makie.to_image(x)), plot, color)
        gl_attributes[:image] = ShaderAbstractions.Sampler(img, x_repeat=:repeat, minfilter=:nearest)
        get!(gl_attributes, :fetch_pixel, true)
        # different default with Patterns (no swapping and flipping of axes)
        gl_attributes[:uv_transform] = map(plot, plot.attributes[:uv_transform]) do uv_transform
            if uv_transform === Makie.automatic
                return Mat{2,3,Float32}(1,0,0,1,0,0)
            else
                return convert_attribute(uv_transform, key"uv_transform"())
            end
        end
    elseif to_value(color) isa ShaderAbstractions.Sampler
        gl_attributes[:image] = Texture(lift(el32convert, plot, color))
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)    
    elseif to_value(color) isa AbstractMatrix{<:Colorant}
        gl_attributes[:image] = Texture(lift(el32convert, plot, color), minfilter = interp)
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)
    elseif to_value(color) isa AbstractMatrix{<: Number}
        gl_attributes[:image] = Texture(lift(el32convert, plot, color), minfilter = interp)
        gl_attributes[:color] = nothing
    elseif to_value(color) isa AbstractVector{<: Union{Number, Colorant}}
        gl_attributes[:vertex_color] = lift(el32convert, plot, color)
    else
        # error("Unsupported color type: $(typeof(to_value(color)))")
    end

    if haskey(gl_attributes, :intensity)
        intensity = pop!(gl_attributes, :intensity)
        if intensity[] isa Matrix
            gl_attributes[:image] = Texture(intensity, minfilter = interp)
        else
            gl_attributes[:vertex_color] = intensity
        end
        gl_attributes[:color] = nothing
    end

    # TODO: avoid intermediate observable
    # TODO: Should these use direct getters? (faces, normals, texturecoordinates)
    positions = map(coordinates, mesh)
    gl_attributes[:vertices] = apply_transform_and_f32_conversion(plot, pop!(gl_attributes, :f32c), positions)
    gl_attributes[:faces] = lift(x-> decompose(GLTriangleFace, x), mesh)
    if hasproperty(to_value(mesh), :uv)
        gl_attributes[:texturecoordinates] = lift(decompose_uv, mesh)
    end
    if hasproperty(to_value(mesh), :normal) && (shading !== NoShading || matcap_active)
        gl_attributes[:normals] = lift(decompose_normals, mesh)
    end
    return draw_mesh(screen, gl_attributes)
end

function draw_atomic(screen::Screen, scene::Scene, meshplot::Mesh)
    x = cached_robj!(screen, scene, meshplot) do gl_attributes
        t = transform_func_obs(meshplot)
        space = meshplot.space # needs to happen before connect_camera! call
        x = mesh_inner(screen, meshplot[1], t, gl_attributes, meshplot, space)
        return x
    end

    return x
end

function draw_atomic(screen::Screen, scene::Scene, plot::Surface)
    robj = cached_robj!(screen, scene, plot) do gl_attributes
        color = pop!(gl_attributes, :color)
        img = nothing
        # We automatically insert x[3] into the color channel, so if it's equal we don't need to do anything
        if haskey(gl_attributes, :intensity)
            img = pop!(gl_attributes, :intensity)
        elseif to_value(color) isa Makie.AbstractPattern
            pattern_img = lift(x -> el32convert(Makie.to_image(x)), plot, color)
            img = ShaderAbstractions.Sampler(pattern_img, x_repeat=:repeat, minfilter=:nearest)
            haskey(gl_attributes, :fetch_pixel) || (gl_attributes[:fetch_pixel] = true)
            gl_attributes[:color_map] = nothing
            gl_attributes[:color] = nothing
            gl_attributes[:color_norm] = nothing
        elseif isa(to_value(color), AbstractMatrix{<: Colorant})
            img = color
            gl_attributes[:color_map] = nothing
            gl_attributes[:color] = nothing
            gl_attributes[:color_norm] = nothing
        end

        space = plot.space
        interp = to_value(pop!(gl_attributes, :interpolate, true))
        interp = interp ? :linear : :nearest
        gl_attributes[:image] = Texture(img; minfilter=interp)

        @assert to_value(plot[3]) isa AbstractMatrix
        gl_attributes[:instances] = map(z -> (size(z,1)-1) * (size(z,2)-1), plot[3])
        types = map(v -> typeof(to_value(v)), plot[1:2])

        if all(T -> T <: Union{AbstractMatrix, AbstractVector}, types)
            t = Makie.transform_func_obs(plot)
            mat = plot[3]
            xypos = lift(plot, pop!(gl_attributes, :f32c), plot.model, t, plot[1], plot[2], space) do f32c, model, t, x, y, space
                # Only if transform doesn't do anything, we can stay linear in 1/2D
                if Makie.is_identity_transform(t) && isnothing(f32c)
                    return (x, y)
                elseif Makie.is_translation_scale_matrix(model)
                    matrix = if x isa AbstractMatrix && y isa AbstractMatrix
                        Makie.f32_convert(f32c, apply_transform.((t,), Point.(x, y), space), space)
                    else
                        # If we do any transformation, we have to assume things aren't on the grid anymore
                        # so x + y need to become matrices.
                        [Makie.f32_convert(f32c, apply_transform(t, Point(x, y), space), space) for x in x, y in y]
                    end
                    return (first.(matrix), last.(matrix))
                else
                    matrix = if x isa AbstractMatrix && y isa AbstractMatrix
                        Makie.f32_convert(f32c, apply_transform_and_model.((model,), (t,), Point.(x, y), space, Point2d), space)
                    else
                        # If we do any transformation, we have to assume things aren't on the grid anymore
                        # so x + y need to become matrices.
                        [Makie.f32_convert(f32c, apply_transform_and_model(model, t, Point(x, y), space, Point2d), space) for x in x, y in y]
                    end
                    return (first.(matrix), last.(matrix))
                end
            end
            xpos = lift(first, plot, xypos)
            ypos = lift(last, plot, xypos)
            args = map((xpos, ypos, mat)) do arg
                Texture(lift(x-> convert(Array, el32convert(x)), plot, arg); minfilter=:linear)
            end
            if isnothing(img)
                gl_attributes[:image] = args[3]
            end
            return draw_surface(screen, args, gl_attributes)
        else
            gl_attributes[:ranges] = to_range.(to_value.(plot[1:2]))
            z_data = Texture(lift(el32convert, plot, plot[3]); minfilter=:linear)
            if isnothing(img)
                gl_attributes[:image] = z_data
            end
            return draw_surface(screen, z_data, gl_attributes)
        end
    end
    return robj
end

function draw_atomic(screen::Screen, scene::Scene, plot::Volume)
    return cached_robj!(screen, scene, plot) do gl_attributes
        model = plot.model
        x, y, z = plot[1], plot[2], plot[3]
        gl_attributes[:model] = lift(plot, model, x, y, z) do m, xyz...
            mi = minimum.(xyz)
            maxi = maximum.(xyz)
            w = maxi .- mi
            m2 = Mat4f(
                w[1], 0, 0, 0,
                0, w[2], 0, 0,
                0, 0, w[3], 0,
                mi[1], mi[2], mi[3], 1
            )
            return convert(Mat4f, m) * m2
        end
        gl_attributes[:modelinv] = const_lift(inv, gl_attributes[:model])

        # Handled manually without using OpenGL clipping
        gl_attributes[:_num_clip_planes] = pop!(gl_attributes, :num_clip_planes)
        gl_attributes[:num_clip_planes] = Observable(0)
        pop!(gl_attributes, :clip_planes)
        gl_attributes[:clip_planes] = map(plot, gl_attributes[:modelinv], plot.clip_planes, plot.space) do modelinv, planes, space
            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            # model/modelinv has no perspective projection so we should be fine
            # with just applying it to the plane origin and transpose(inv(modelinv))
            # to plane.normal
            @assert (length(planes) == 0) || isapprox(modelinv[4, 4], 1, atol = 1e-6)

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                origin = modelinv * to_ndim(Point4f, planes[i].distance * planes[i].normal, 1)
                normal = transpose(gl_attributes[:model][]) * to_ndim(Vec4f, planes[i].normal, 0)
                distance = dot(Vec3f(origin[1], origin[2], origin[3]) / origin[4],
                    Vec3f(normal[1], normal[2], normal[3]))
                output[i] = Vec4f(normal[1], normal[2], normal[3], distance)
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e9)
            end

            return output
        end

        interp = to_value(pop!(gl_attributes, :interpolate))
        interp = interp ? :linear : :nearest
        Tex(x) = Texture(x; minfilter=interp)
        if haskey(gl_attributes, :intensity)
            intensity = pop!(gl_attributes, :intensity)
            return draw_volume(screen, Tex(intensity), gl_attributes)
        else
            return draw_volume(screen, Tex(plot[4]), gl_attributes)
        end
    end
end

function draw_atomic(screen::Screen, scene::Scene, plot::Voxels)
    return cached_robj!(screen, scene, plot) do gl_attributes
        @assert to_value(plot.converted[end]) isa Array{UInt8, 3}

        # voxel ids
        tex = Texture(plot.converted[end], minfilter = :nearest)

        # local update
        buffer = Vector{UInt8}(undef, 1)
        on(plot, pop!(gl_attributes, :_local_update)) do (is, js, ks)
            required_length = length(is) * length(js) * length(ks)
            if length(buffer) < required_length
                resize!(buffer, required_length)
            end
            idx = 1
            for k in ks, j in js, i in is
                buffer[idx] = plot.converted[end].val[i, j, k]
                idx += 1
            end
            GLAbstraction.texsubimage(tex, buffer, is, js, ks)
            return
        end

        # adjust model matrix according to x/y/z limits
        gl_attributes[:model] = map(
                plot, plot.converted...,  pop!(gl_attributes, :model)
            ) do xs, ys, zs, chunk, model
            mini = minimum.((xs, ys, zs))
            width = maximum.((xs, ys, zs)) .- mini
            return Mat4f(model *
                Makie.transformationmatrix(Vec3f(mini), Vec3f(width ./ size(chunk)))
            )
        end

        # Handled manually without using OpenGL clipping
        gl_attributes[:_num_clip_planes] = pop!(gl_attributes, :num_clip_planes)
        gl_attributes[:num_clip_planes] = Observable(0)
        pop!(gl_attributes, :clip_planes)
        gl_attributes[:clip_planes] = map(plot, gl_attributes[:model], plot.clip_planes, plot.space) do model, planes, space
            Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

            # model/modelinv has no perspective projection so we should be fine
            # with just applying it to the plane origin and transpose(inv(modelinv))
            # to plane.normal
            modelinv = inv(model)
            @assert (length(planes) == 0) || isapprox(modelinv[4, 4], 1, atol = 1e-6)

            output = Vector{Vec4f}(undef, 8)
            for i in 1:min(length(planes), 8)
                origin = modelinv * to_ndim(Point4f, planes[i].distance * planes[i].normal, 1)
                normal = transpose(model) * to_ndim(Vec4f, planes[i].normal, 0)
                distance = dot(Vec3f(origin[1], origin[2], origin[3]) / origin[4],
                    Vec3f(normal[1], normal[2], normal[3]))
                output[i] = Vec4f(normal[1], normal[2], normal[3], distance)
            end
            for i in min(length(planes), 8)+1:8
                output[i] = Vec4f(0, 0, 0, -1e9)
            end

            return output
        end

        # color attribute adjustments
        pop!(gl_attributes, :lowclip, nothing)
        pop!(gl_attributes, :highclip, nothing)
        # Invalid:
        pop!(gl_attributes, :nan_color, nothing)
        pop!(gl_attributes, :alpha, nothing) # Why is this even here?
        pop!(gl_attributes, :intensity, nothing)
        pop!(gl_attributes, :color_norm, nothing)
        # cleanup
        pop!(gl_attributes, :_limits)
        pop!(gl_attributes, :is_air)

        # make sure these exist
        get!(gl_attributes, :color, nothing)
        get!(gl_attributes, :color_map, nothing)

        # process texture mapping
        uv_map = pop!(gl_attributes, :uvmap)
        if !isnothing(to_value(uv_map))
            gl_attributes[:uv_map] = Texture(uv_map, minfilter = :nearest)

            interp = to_value(pop!(gl_attributes, :interpolate))
            interp = interp ? :linear : :nearest
            color = gl_attributes[:color]
            gl_attributes[:color] = Texture(color, minfilter = interp)
        elseif !isnothing(to_value(gl_attributes[:color]))
            gl_attributes[:color] = Texture(gl_attributes[:color], minfilter = :nearest)
        end

        # for depthsorting
        gl_attributes[:view_direction] = camera(scene).view_direction

        return draw_voxels(screen, tex, gl_attributes)
    end
end
