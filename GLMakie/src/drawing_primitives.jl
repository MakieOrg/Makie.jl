using Makie: get_texture_atlas, glyph_uv_width!, transform_func_obs, apply_transform
using Makie: attribute_per_char, FastPixel, el32convert, Pixel
using Makie: convert_arguments

Makie.el32convert(x::GLAbstraction.Texture) = x
Makie.convert_attribute(s::ShaderAbstractions.Sampler{RGBAf}, k::key"color") = s
function Makie.convert_attribute(s::ShaderAbstractions.Sampler{T, N}, k::key"color") where {T, N}
    ShaderAbstractions.Sampler(
        el32convert(s.data), minfilter = s.minfilter, magfilter = s.magfilter,
        x_repeat = s.repeat[1], y_repeat = s.repeat[min(2, N)], z_repeat = s.repeat[min(3, N)],
        anisotropic = s.anisotropic, color_swizzel = s.color_swizzel
    )
end

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
    k == :rotations && return :rotation
    k == :markersize && return :scale
    k == :glowwidth && return :glow_width
    k == :glowcolor && return :glow_color
    k == :strokewidth && return :stroke_width
    k == :strokecolor && return :stroke_color
    k == :positions && return :position
    k == :linewidth && return :thickness
    k == :marker_offset && return :quad_offset
    k == :colormap && return :color_map
    k == :colorrange && return :color_norm
    k == :transform_marker && return :scale_primitive
    return k
end

function connect_camera!(gl_attributes, cam, space = gl_attributes[:space])
    for key in (:pixel_space, :resolution, :eyeposition)
        get!(gl_attributes, key, getfield(cam, key))
    end
    get!(gl_attributes, :view) do
        return map(cam.view, space) do view, space
            return is_data_space(space) ? view : Mat4f(I)
        end
    end
    get!(gl_attributes, :normalmatrix) do
        return map(gl_attributes[:view], gl_attributes[:model]) do v, m
            i = Vec(1, 2, 3)
            return transpose(inv(v[i, i] * m[i, i]))
        end
    end

    get!(gl_attributes, :projection) do
        return map(cam.projection, cam.pixel_space, space) do _, _, space
            return Makie.space_to_clip(cam, space, false)
        end
    end

    get!(gl_attributes, :projectionview) do
        return map(cam.projectionview, cam.pixel_space, space) do _, _, space
            Makie.space_to_clip(cam, space, true)
        end
    end

    delete!(gl_attributes, :space)
    delete!(gl_attributes, :markerspace)
    return nothing
end

function cached_robj!(robj_func, screen, scene, x::AbstractPlot)
    # poll inside functions to make wait on compile less prominent
    pollevents(screen)
    robj = get!(screen.cache, objectid(x)) do
        filtered = filter(x.attributes) do (k, v)
            !in(k, (
                :transformation, :tickranges, :ticklabels, :raw, :SSAO, 
                :lightposition, :material, 
                :inspector_label, :inspector_hover, :inspector_clear
            ))
        end

        gl_attributes = Dict{Symbol, Any}(map(filtered) do key_value
            key, value = key_value
            gl_key = to_glvisualize_key(key)
            gl_value = lift_convert(key, value, x)
            gl_key => gl_value
        end)

        pointlight = Makie.get_point_light(scene)
        if !isnothing(pointlight)
            gl_attributes[:lightposition] = pointlight.position
        end

        ambientlight = Makie.get_ambient_light(scene)
        if !isnothing(ambientlight)
            gl_attributes[:ambient] = ambientlight.color
        end

        robj = robj_func(gl_attributes)

        !haskey(gl_attributes, :ssao) && (robj[:ssao] = Observable(false))
        screen.cache2plot[robj.id] = x
        robj
    end
    push!(screen, scene, robj)
    robj
end

function Base.insert!(screen::GLScreen, scene::Scene, x::Combined)
    ShaderAbstractions.switch_context!(screen.glscreen)
    # poll inside functions to make wait on compile less prominent
    pollevents(screen)
    if isempty(x.plots) # if no plots inserted, this truly is an atomic
        draw_atomic(screen, scene, x)
    else
        foreach(x.plots) do x
            # poll inside functions to make wait on compile less prominent
            pollevents(screen)
            insert!(screen, scene, x)
        end
    end
end

function remove_automatic!(attributes)
    filter!(attributes) do (k, v)
        to_value(v) != automatic
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

function lift_convert(key, value, plot)
    return lift_convert_inner(value, Key{key}(), Key{Makie.plotkey(plot)}(), plot)
end

function lift_convert_inner(value, key, plot_key, plot)
    return lift(value) do value
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

function handle_intensities!(attributes)
    if haskey(attributes, :color) && attributes[:color][] isa AbstractVector{<: Number}
        c = pop!(attributes, :color)
        attributes[:intensity] = lift(x-> convert(Vector{Float32}, x), c)
    else
        delete!(attributes, :intensity)
        delete!(attributes, :color_map)
        delete!(attributes, :color_norm)
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, @nospecialize(x::Union{Scatter, MeshScatter}))
    return cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        gl_attributes[:shading] = to_value(get(gl_attributes, :shading, true))
        marker = lift_convert(:marker, pop!(gl_attributes, :marker), x)

        positions = handle_view(x[1], gl_attributes)
        positions = apply_transform(transform_func_obs(x), positions)

        if isa(x, Scatter)
            space = get(gl_attributes, :space, :data)
            mspace = get(gl_attributes, :markerspace, :pixel)
            cam = scene.camera
            gl_attributes[:preprojection] = map(space, mspace, cam.projectionview, cam.resolution) do space, mspace, _, _
                return Makie.clip_to_space(cam, mspace) * Makie.space_to_clip(cam, space)
            end
            if !(marker[] isa FastPixel)
                # fast pixel does its own camera setup
                connect_camera!(gl_attributes, cam, mspace)
            end

            gl_attributes[:billboard] = map(rot-> isa(rot, Billboard), x.rotations)
            isnothing(gl_attributes[:distancefield][]) && delete!(gl_attributes, :distancefield)
            gl_attributes[:uv_offset_width][] == Vec4f(0) && delete!(gl_attributes, :uv_offset_width)
        else
            connect_camera!(gl_attributes, scene.camera)
        end

        if marker[] isa FastPixel
            # connect camera
            connect_camera!(gl_attributes, cam, get(gl_attributes, :space, :data))
            filter!(gl_attributes) do (k, v,)
                k in (:color_map, :color, :color_norm, :scale, :model, :projectionview)
            end
            if !(gl_attributes[:color][] isa AbstractVector{<: Number})
                delete!(gl_attributes, :color_norm)
                delete!(gl_attributes, :color_map)
            end
            return draw_pixel_scatter(screen.shader_cache, positions, gl_attributes)
        else
            handle_intensities!(gl_attributes)
            if x isa MeshScatter
                return draw_mesh_particle(screen.shader_cache, (marker, positions), gl_attributes)
            else
                return draw_scatter(screen.shader_cache, (marker, positions), gl_attributes)
            end
        end
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, @nospecialize(x::Lines))
    return cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        ls = to_value(linestyle)
        if isnothing(ls)
            data[:pattern] = ls
        else
            linewidth = gl_attributes[:thickness]
            data[:pattern] = ls .* (to_value(linewidth) * 0.25)
        end
        positions = handle_view(x[1], data)
        positions = apply_transform(transform_func_obs(x), positions)
        handle_intensities!(data)
        connect_camera!(data, scene.camera)
        return draw_lines(screen.shader_cache, positions, data)
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, @nospecialize(x::LineSegments))
    return cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        ls = to_value(linestyle)
        if isnothing(ls)
            data[:pattern] = ls
        else
            linewidth = gl_attributes[:thickness]
            data[:pattern] = ls .* (to_value(linewidth) * 0.25)
        end
        positions = handle_view(x.converted[1], data)
        positions = apply_transform(transform_func_obs(x), positions)
        if haskey(data, :color) && data[:color][] isa AbstractVector{<: Number}
            c = pop!(data, :color)
            data[:color] = el32convert(c)
        else
            delete!(data, :color_map)
            delete!(data, :color_norm)
        end
        connect_camera!(data, scene.camera)

        return draw_linesegments(screen.shader_cache, positions, data)
    end
end

function draw_atomic(screen::GLScreen, scene::Scene,
        x::Text{<:Tuple{<:Union{<:Makie.GlyphCollection, <:AbstractVector{<:Makie.GlyphCollection}}}})

    return cached_robj!(screen, scene, x) do gl_attributes
        glyphcollection = x[1]

        transfunc =  Makie.transform_func_obs(scene)
        pos = gl_attributes[:position]
        space = get(gl_attributes, :space, Observable(:data))
        markerspace = gl_attributes[:markerspace]
        offset = pop!(gl_attributes, :offset, Vec2f(0))

        # calculate quad metrics
        glyph_data = map(pos, glyphcollection, offset, transfunc) do pos, gc, offset, transfunc
            Makie.text_quads(pos, to_value(gc), offset, transfunc)
        end

        # unpack values from the one signal:
        positions, char_offset, quad_offset, uv_offset_width, scale = map((1, 2, 3, 4, 5)) do i
            lift(getindex, glyph_data, i)
        end

        atlas = get_texture_atlas()

        filter!(gl_attributes) do (k, v)
            # These are liftkeys without model
            !(k in (
                :position, :space, :markerspace, :font,
                :textsize, :rotation, :justification
            )) # space,
        end

        gl_attributes[:color] = lift(glyphcollection) do gc
            if gc isa AbstractArray
                reduce(vcat, (Makie.collect_vector(g.colors, length(g.glyphs)) for g in gc),
                    init = RGBAf[])
            else
                Makie.collect_vector(gc.colors, length(gc.glyphs))
            end
        end
        gl_attributes[:stroke_color] = lift(glyphcollection) do gc
            if gc isa AbstractArray
                reduce(vcat, (Makie.collect_vector(g.strokecolors, length(g.glyphs)) for g in gc),
                    init = RGBAf[])
            else
                Makie.collect_vector(gc.strokecolors, length(gc.glyphs))
            end
        end

        gl_attributes[:rotation] = lift(glyphcollection) do gc
            if gc isa AbstractArray
                reduce(vcat, (Makie.collect_vector(g.rotations, length(g.glyphs)) for g in gc),
                    init = Quaternionf[])
            else
                Makie.collect_vector(gc.rotations, length(gc.glyphs))
            end
        end

        gl_attributes[:scale] = scale
        gl_attributes[:quad_offset] = quad_offset
        gl_attributes[:marker_offset] = char_offset
        gl_attributes[:uv_offset_width] = uv_offset_width
        gl_attributes[:distancefield] = get_texture!(atlas)
        gl_attributes[:visible] = x.visible
        cam = scene.camera
        # gl_attributes[:preprojection] = Observable(Mat4f(I))
        gl_attributes[:preprojection] = map(space, markerspace, cam.projectionview, cam.resolution) do s, ms, pv, res
            Makie.clip_to_space(cam, ms) * Makie.space_to_clip(cam, s)
        end
        connect_camera!(gl_attributes, cam, markerspace)

        # Avoid julia#15276
        _robj = draw_scatter(screen.shader_cache, (DISTANCEFIELD, positions), gl_attributes)

        return _robj
    end
end

# el32convert doesn't copy for array of Float32
# But we assume that xy_convert copies when we use it
xy_convert(x::AbstractArray{Float32}, n) = copy(x)
xy_convert(x::AbstractArray, n) = el32convert(x)
xy_convert(x, n) = Float32[LinRange(extrema(x)..., n + 1);]

function draw_atomic(screen::GLScreen, scene::Scene, x::Heatmap)
    return cached_robj!(screen, scene, x) do gl_attributes
        t = Makie.transform_func_obs(scene)
        mat = x[3]
        xypos = map(t, x[1], x[2]) do t, x, y
            x1d = xy_convert(x, size(mat[], 1))
            y1d = xy_convert(y, size(mat[], 2))
            # Only if transform doesn't do anything, we can stay linear in 1/2D
            if Makie.is_identity_transform(t)
                return (x1d, y1d)
            else
                # If we do any transformation, we have to assume things aren't on the grid anymore
                # so x + y need to become matrices.
                map!(x1d, x1d) do x
                    return apply_transform(t, Point(x, 0))[1]
                end
                map!(y1d, y1d) do y
                    return apply_transform(t, Point(0, y))[2]
                end
                return (x1d, y1d)
            end
        end
        xpos = map(first, xypos)
        ypos = map(last, xypos)
        gl_attributes[:position_x] = Texture(xpos, minfilter = :nearest)
        gl_attributes[:position_y] = Texture(ypos, minfilter = :nearest)
        # number of planes used to render the heatmap
        gl_attributes[:instances] = map(xpos, ypos) do x, y
            (length(x)-1) * (length(y)-1)
        end
        interp = to_value(pop!(gl_attributes, :interpolate))
        interp = interp ? :linear : :nearest
        if !(to_value(mat) isa ShaderAbstractions.Sampler)
            tex = Texture(el32convert(mat), minfilter = interp)
        else
            tex = to_value(mat)
        end
        pop!(gl_attributes, :color)
        gl_attributes[:stroke_width] = pop!(gl_attributes, :thickness)
        connect_camera!(gl_attributes, scene.camera)

        return draw_heatmap(screen.shader_cache, tex, gl_attributes)
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Image)
    return cached_robj!(screen, scene, x) do gl_attributes
        mesh = const_lift(x[1], x[2]) do x, y
            r = to_range(x, y)
            x, y = minimum(r[1]), minimum(r[2])
            xmax, ymax = maximum(r[1]), maximum(r[2])
            rect =  Rect2f(x, y, xmax - x, ymax - y)
            points = decompose(Point2f, rect)
            faces = decompose(GLTriangleFace, rect)
            uv = map(decompose_uv(rect)) do uv
                return 1f0 .- Vec2f(uv[2], uv[1])
            end
            return GeometryBasics.Mesh(meta(points; uv=uv), faces)
        end
        gl_attributes[:color] = x[3]
        gl_attributes[:shading] = false
        connect_camera!(gl_attributes, scene.camera)
        return mesh_inner(screen.shader_cache, mesh, transform_func_obs(x), gl_attributes)
    end
end

function update_positions(mesh::GeometryBasics.Mesh, positions)
    points = coordinates(mesh)
    attr = GeometryBasics.attributes(points)
    delete!(attr, :position) # position == metafree(points)
    return GeometryBasics.Mesh(meta(positions; attr...), faces(mesh))
end

function mesh_inner(shader_cache, mesh, transfunc, gl_attributes)
    # signals not supported for shading yet
    gl_attributes[:shading] = to_value(pop!(gl_attributes, :shading))
    color = pop!(gl_attributes, :color)
    interp = to_value(pop!(gl_attributes, :interpolate, true))
    interp = interp ? :linear : :nearest
    if to_value(color) isa Colorant
        gl_attributes[:vertex_color] = color
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)
    elseif to_value(color) isa Makie.AbstractPattern
        img = lift(x -> el32convert(Makie.to_image(x)), color)
        gl_attributes[:image] = ShaderAbstractions.Sampler(img, x_repeat=:repeat, minfilter=:nearest)
        haskey(gl_attributes, :fetch_pixel) || (gl_attributes[:fetch_pixel] = true)
    elseif to_value(color) isa AbstractMatrix{<:Colorant}
        gl_attributes[:image] = Texture(const_lift(el32convert, color), minfilter = interp)
        delete!(gl_attributes, :color_map)
        delete!(gl_attributes, :color_norm)
    elseif to_value(color) isa AbstractMatrix{<: Number}
        gl_attributes[:image] = Texture(const_lift(el32convert, color), minfilter = interp)
        gl_attributes[:color] = nothing
    elseif to_value(color) isa AbstractVector{<: Union{Number, Colorant}}
        mesh = lift(mesh, color) do mesh, color
            return GeometryBasics.pointmeta(mesh, color=el32convert(color))
        end
    else
        error("Unsupported color type: $(typeof(to_value(color)))")
    end
    mesh = map(mesh, transfunc) do mesh, func
        if !Makie.is_identity_transform(func)
            return update_positions(mesh, apply_transform.(Ref(func), mesh.position))
        end
        return mesh
    end
    return draw_mesh(shader_cache, mesh, gl_attributes)
end

function draw_atomic(screen::GLScreen, scene::Scene, meshplot::Mesh)
    return cached_robj!(screen, scene, meshplot) do gl_attributes
        t = transform_func_obs(meshplot)
        connect_camera!(gl_attributes, scene.camera)
        return mesh_inner(screen.shader_cache, meshplot[1], t, gl_attributes)
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Surface)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        color = pop!(gl_attributes, :color)
        img = nothing
        # signals not supported for shading yet
        # We automatically insert x[3] into the color channel, so if it's equal we don't need to do anything
        if isa(to_value(color), AbstractMatrix{<: Number}) && to_value(color) !== to_value(x[3])
            img = el32convert(color)
        elseif to_value(color) isa Makie.AbstractPattern
            pattern_img = lift(x -> el32convert(Makie.to_image(x)), color)
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

        gl_attributes[:image] = img
        gl_attributes[:shading] = to_value(get(gl_attributes, :shading, true))
        connect_camera!(gl_attributes, scene.camera)

        @assert to_value(x[3]) isa AbstractMatrix
        types = map(v -> typeof(to_value(v)), x[1:2])

        if all(T -> T <: Union{AbstractMatrix, AbstractVector}, types)
            t = Makie.transform_func_obs(scene)
            mat = x[3]
            xypos = map(t, x[1], x[2]) do t, x, y
                # Only if transform doesn't do anything, we can stay linear in 1/2D
                if Makie.is_identity_transform(t)
                    return (x, y)
                else
                    matrix = if x isa AbstractMatrix && y isa AbstractMatrix
                        apply_transform.((t,), Point.(x, y))
                    else
                        # If we do any transformation, we have to assume things aren't on the grid anymore
                        # so x + y need to become matrices.
                        [apply_transform(t, Point(x, y)) for x in x, y in y]
                    end
                    return (first.(matrix), last.(matrix))
                end
            end
            xpos = map(first, xypos)
            ypos = map(last, xypos)
            args = map((xpos, ypos, mat)) do arg
                Texture(map(x-> convert(Array, el32convert(x)), arg); minfilter=:linear)
            end
            if isnothing(img)
                gl_attributes[:image] = args[3]
            end
            return draw_surface(screen.shader_cache, args, gl_attributes)
        else
            gl_attributes[:ranges] = to_range.(to_value.(x[1:2]))
            z_data = Texture(el32convert(x[3]); minfilter=:linear)
            if isnothing(img)
                gl_attributes[:image] = z_data
            end
            return draw_surface(screen.shader_cache, z_data, gl_attributes)
        end
    end
    return robj
end

function draw_atomic(screen::GLScreen, scene::Scene, vol::Volume)
    robj = cached_robj!(screen, scene, vol) do gl_attributes
        model = vol[:model]
        x, y, z = vol[1], vol[2], vol[3]
        gl_attributes[:model] = lift(model, x, y, z) do m, xyz...
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
        connect_camera!(gl_attributes, scene.camera)
        return draw_volume(screen.shader_cache, vol[4], gl_attributes)
    end
end
