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
        attributes[:color_map] = Texture(screen.glscreen, color[].colormap; minfilter=interp)
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

        connect_camera!(plot, gl_attributes, scene.camera, get_space(plot))
        handle_intensities!(screen, gl_attributes, plot)

        if to_value(gl_attributes[:color]) isa Makie.AbstractPattern
            get!(gl_attributes, :fetch_pixel, true)

            # different default with Patterns (no swapping and flipping of axes)
            # also includes px to uv coordinate transform so we can use linear
            # interpolation (no jitter) and related pattern to (0,0,0) in world space
            gl_attributes[:uv_transform] = map(plot,
                    plot.attributes[:uv_transform], scene.camera.projectionview,
                    scene.camera.resolution, gl_attributes[:model], gl_attributes[:color];
                    priority = -1
                ) do uvt, pv, res, model, pattern
                Makie.pattern_uv_transform(uvt, pv * model, res, pattern)
            end
        end

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
    # Note: Calling pollevents() here will allow `on(events(scene)...)` to take
    #       action while a plot is getting created. If the plot is deleted at
    #       that point the robj will get orphaned.
    ShaderAbstractions.switch_context!(screen.glscreen)
    add_scene!(screen, scene)
    # poll inside functions to make wait on compile less prominent
    if isempty(x.plots) # if no plots inserted, this truly is an atomic
        draw_atomic(screen, scene, x)
    else
        foreach(x.plots) do x
            # poll inside functions to make wait on compile less prominent
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



# el32convert doesn't copy for array of Float32
# But we assume that xy_convert copies when we use it
xy_convert(x::AbstractArray, n) = copy(x)
xy_convert(x::Makie.EndPoints, n) = [LinRange(extrema(x)..., n + 1);]

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
        gl_attributes[:image] = ShaderAbstractions.Sampler(img, x_repeat=:repeat)
    elseif to_value(color) isa ShaderAbstractions.Sampler
        gl_attributes[:image] = Texture(screen.glscreen, lift(el32convert, plot, color))
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)
    elseif to_value(color) isa AbstractMatrix{<:Colorant}
        gl_attributes[:image] = Texture(screen.glscreen, lift(el32convert, plot, color), minfilter = interp)
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)
    elseif to_value(color) isa Union{AbstractMatrix{<: Number}, AbstractArray{<: Number, 3}}
        gl_attributes[:image] = Texture(screen.glscreen, lift(el32convert, plot, color), minfilter = interp)
        gl_attributes[:color] = nothing
    elseif to_value(color) isa AbstractVector{<: Union{Number, Colorant}}
        gl_attributes[:vertex_color] = lift(el32convert, plot, color)
    elseif to_value(color) isa Nothing
        # this is ok, since e.g. colormapped colors will go into `intensity`
    else
        error("Unsupported color type: $(typeof(to_value(color)))")
    end

    if haskey(gl_attributes, :intensity)
        intensity = pop!(gl_attributes, :intensity)
        if intensity[] isa Union{AbstractMatrix, AbstractArray{<: Any, 3}}
            gl_attributes[:image] = Texture(screen.glscreen, intensity, minfilter = interp)
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
        if eltype(to_value(mesh).uv) <: Vec2
            gl_attributes[:texturecoordinates] = lift(decompose_uv, mesh)
        elseif eltype(to_value(mesh).uv) <: Vec3
            gl_attributes[:texturecoordinates] = lift(GeometryBasics.decompose_uvw, mesh)
        end
    end
    if hasproperty(to_value(mesh), :normal) && (shading !== NoShading || matcap_active)
        gl_attributes[:normals] = lift(decompose_normals, mesh)
    end
    return draw_mesh(screen, gl_attributes)
end
