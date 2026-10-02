# =============================================================================
# The raster path's shadow maps: the brightest directional light's, and the
# ambient light's from many directions. Rendered depth-only before the frame
# and read back into buffers the mesh stages sample.
# =============================================================================
#
# The traced picture has both because every light sample traces a shadow ray:
# a figure on a sunlit deck stands in its shadow, and the deck along the rail
# gets less of the sky. The raster picture stands in for it, and without them a
# figure floated and every corner was as bright as open deck. A delta light
# casts HARD shadows in the tracer, so the sun's map is a plain depth map with a
# small filter (`shadow_visibility`), not a soft one.
#
# Both cover the part of the view frustum nearer than a distance, clipped to
# what casts, and move in whole texels: fitted afresh each frame with a size
# that followed the camera, every edge crawled as it moved.

shadow_vertex(positions, faces, model::Mat4f, light_space::Mat4f) =
    shadow_vertex(VertexIndex(vertex_index()), positions, faces, model, light_space)

function shadow_vertex(vertexid::VertexIndex, positions, faces, model::Mat4f, light_space::Mat4f)
    @inbounds vi = Int32(faces[vertexid.value])
    @inbounds p = positions[vi]
    return (position = gl_to_clip_depth(light_space * (model * Vec4f(p[1], p[2], p[3], 1f0))),)
end

# Writes no attachment: the depth test is the whole pass.
shadow_fragment(inputs) = nothing

function get_shadow_pipeline!(screen)
    get!(screen.gfx_pipelines, :shadow) do
        GraphicsPipeline(; vertex = VertexShader(shadow_vertex),
                           fragment = FragmentShader(shadow_fragment),
                           topology = TriangleList(),
                           # Cards and single-sided hulls cast from either face.
                           cull = NoCull(),
                           depth = DepthLess())
    end
end

"""Columns of the ambient atlas; its rows follow from the direction count."""
const AO_COLUMNS = 8

ao_atlas_size(config) =
    (AO_COLUMNS * config.ao_resolution, cld(config.ambient_occlusion, AO_COLUMNS) * config.ao_resolution)

"""
    shadow_buffer(screen) -> device vector of Float32
    ao_buffer(screen) -> device vector of Float32

The sun's map and the ambient atlas as the mesh stages read them, depths row by
row. One each per screen and never replaced: every mesh render object holds
them as arguments, and a plan bakes those addresses.
"""
function shadow_buffer(screen)
    if screen.shadowmap === nothing
        n = screen.config.shadow_resolution^2
        screen.shadowmap = Mantle.devicearray(screen.config.device, ones(Float32, n))
    end
    return screen.shadowmap
end

function ao_buffer(screen)
    if screen.aomap === nothing
        n = max(1, prod(ao_atlas_size(screen.config)))
        screen.aomap = Mantle.devicearray(screen.config.device, ones(Float32, n))
    end
    return screen.aomap
end

"""
    shadow_light(types, colors, parameters) -> (index, direction)

The light that casts: the brightest directional one, as its place in the light
list and the direction it travels. A scene lit only by glowing meshes (a
softbox) gets its shadows from the brightest of those instead (radiance times
area), cast straight along its normal: from overhead, which is where a softbox
hangs, when it shines both ways. `(0, Vec3f(0))` when there is none.
"""
function shadow_light(types, colors, parameters)
    best, lum, dir = 0, 0f0, Vec3f(0)
    ebest, elum, edir = 0, 0f0, Vec3f(0)
    idx = 0
    for i in eachindex(types)
        kind = Int32(types[i])
        c = RGBf(colors[i])
        l = 0.2126f0 * c.r + 0.7152f0 * c.g + 0.0722f0 * c.b
        if kind == LIGHT_DIRECTIONAL
            if l > lum
                best, lum = i, l
                dir = normalize(Vec3f(parameters[idx + 1], parameters[idx + 2], parameters[idx + 3]))
            end
        elseif kind == LIGHT_EMITTER
            power = l * parameters[idx + 7]
            if power > elum
                ebest, elum = i, power
                n = normalize(Vec3f(parameters[idx + 4], parameters[idx + 5], parameters[idx + 6]))
                edir = parameters[idx + 8] != 0f0 && n[3] > 0f0 ? -n : n
            end
        end
        idx += light_parameter_count(kind)
    end
    best == 0 && return Int32(ebest), edir
    return Int32(best), dir
end

"""The world-space box of `bounds` moved by `model`."""
function world_bounds(bounds::Rect3f, model::Mat4f)
    corners = map(GeometryBasics.coordinates(bounds)) do c
        p = model * Vec4f(c[1], c[2], c[3], 1f0)
        Point3f(p[1], p[2], p[3]) / p[4]
    end
    return Rect3f(corners)
end

"""
The part of the view frustum nearer than `distance` to the eye, as its eight
corners.
"""
function frustum_slice(view::Mat4f, projection::Mat4f, distance::Float32)
    inv_pv = inv(projection * view)
    unproject(n) = (h = inv_pv * Vec4f(n[1], n[2], n[3], 1f0); Vec3f(h[1], h[2], h[3]) / h[4])
    eye = (h = inv(view) * Vec4f(0, 0, 0, 1); Vec3f(h[1], h[2], h[3]) / h[4])
    slice = Vec3f[]
    for cx in (-1f0, 1f0), cy in (-1f0, 1f0)
        push!(slice, unproject(Vec3f(cx, cy, -1f0)))
        far = unproject(Vec3f(cx, cy, 1f0)) - eye
        push!(slice, eye + far * (min(norm(far), distance) / norm(far)))
    end
    return slice
end

"""The smallest sphere about the corners' mean that holds them all, as (centre, radius)."""
function bounding_sphere(points)
    centre = Vec3f(sum(Vec3f, points) / length(points))
    return centre, maximum(p -> norm(Vec3f(p) - centre), points)
end

"""
    shadow_matrix(direction, slice, casters, res) -> (light_space, texel) or nothing

The sun map's orthographic light matrix, GL clip convention, and the world size
of one texel.

The square is as wide as the frustum slice's bounding sphere, which does not
change as the camera turns, or as the casters when they are smaller; it is
placed over the slice, kept over the casters, and snapped to its own texels.
Depth spans every caster, in view or not, since a pole behind the camera still
shades the deck in front of it.
"""
function shadow_matrix(direction::Vec3f, slice, casters::Rect3f, res::Int)
    x, y, z = light_basis(-normalize(direction))
    tolight(p) = Vec3f(dot(x, p), dot(y, p), dot(z, p))
    centre, radius = bounding_sphere(slice)
    lb = Rect3f(map(c -> Point3f(tolight(Vec3f(c))), GeometryBasics.coordinates(casters)))
    lo, hi = minimum(lb), maximum(lb)
    side = min(2f0 * radius, max(hi[1] - lo[1], hi[2] - lo[2]))
    side <= 0f0 && return nothing
    texel = side / res
    c = tolight(centre)
    place(v, a, b) = b - a <= side ? (a + b) / 2 : clamp(v, a + side / 2, b - side / 2)
    lc = x * place(c[1], lo[1], hi[1]) + y * place(c[2], lo[2], hi[2]) + z * ((lo[3] + hi[3]) / 2)
    depth_radius = (hi[3] - lo[3]) / 2 * 1.01f0 + 1f-3
    return ortho_light(z, lc, side / 2, depth_radius, texel), texel
end

"""
    ao_fit(slice, casters, config) -> (centre, params)

The sphere every ambient map covers — the frustum slice's, or the casters' when
they are smaller — as the two uniforms `ambient_visibility` reads: (centre,
radius) and (depth radius, resolution, directions, atlas columns). The depth
radius reaches every caster, so a mast outside the sphere still occludes.
"""
function ao_fit(slice, casters::Rect3f, config)
    centre, radius = bounding_sphere(slice)
    bcentre, bradius = bounding_sphere(GeometryBasics.coordinates(casters))
    bradius < radius && ((centre, radius) = (bcentre, bradius))
    depth_radius = max(radius, maximum(p -> norm(Vec3f(p) - centre), GeometryBasics.coordinates(casters))) * 1.01f0
    return Vec4f(centre..., radius),
           Vec4f(depth_radius, config.ao_resolution, config.ambient_occlusion, AO_COLUMNS)
end

"""
    shadow_frame(screen, robjs) -> NamedTuple or nothing

Fit this frame's maps and tell every lit mesh which it looks up.

The first mesh lit like the tracer decides the camera; meshes seen through the
same camera cast and receive. The sun's map is made for the light the first of
them names, and only meshes naming that light read it. A mesh of another scene
keeps its lights unshadowed rather than reading maps made for someone else's.
"""
function shadow_frame(screen, robjs)
    meshes = [robj for (robj, _) in robjs if haskey(robj.uniforms, :shadow_light)]
    for robj in meshes
        robj.uniforms[:shadow_params] = Vec4f(0)
        robj.uniforms[:ao_params] = Vec4f(0)
    end
    lit(r) = r.uniforms[:physical]::Int32 != Int32(0) && r.uniforms[:shading_mode]::Int32 != SHADING_NONE
    first = findfirst(lit, meshes)
    first === nothing && return nothing
    view = meshes[first].uniforms[:view]::Mat4f
    projection = meshes[first].uniforms[:projection]::Mat4f
    casters = filter(r -> r.uniforms[:view] == view && r.vertex_count > 0 &&
                          get(r.uniforms, :casts_shadow, true)::Bool &&
                          !isempty(r.uniforms[:local_bounds]::Rect3f), meshes)
    isempty(casters) && return nothing
    bounds = mapreduce(r -> world_bounds(r.uniforms[:local_bounds], r.uniforms[:model]), union, casters)
    receivers = filter(r -> lit(r) && r.uniforms[:view] == view, meshes)
    config = screen.config

    sun = nothing
    ref = findfirst(r -> r.uniforms[:shadow_light]::Int32 != Int32(0), receivers)
    if ref !== nothing
        dir = receivers[ref].uniforms[:shadow_direction]::Vec3f
        fit = shadow_matrix(dir, frustum_slice(view, projection, config.shadow_distance), bounds,
                            config.shadow_resolution)
        if fit !== nothing
            light_space, texel = fit
            params = Vec4f(config.shadow_resolution, texel, 1, 0)
            for robj in receivers
                robj.uniforms[:shadow_light]::Int32 != Int32(0) &&
                    robj.uniforms[:shadow_direction] == dir || continue
                robj.uniforms[:light_space] = light_space
                robj.uniforms[:shadow_params] = params
            end
            sun = (light_space = light_space, res = config.shadow_resolution)
        end
    end

    ao = nothing
    if config.ambient_occlusion > 0
        centre, params = ao_fit(frustum_slice(view, projection, config.ao_distance), bounds, config)
        for robj in receivers
            robj.uniforms[:ao_centre] = centre
            robj.uniforms[:ao_params] = params
        end
        ao = (matrices = [ao_matrix(Int32(k), centre, params) for k in 0:config.ambient_occlusion - 1],
              res = config.ao_resolution)
    end
    sun === nothing && ao === nothing && return nothing
    return (casters = casters, sun = sun, ao = ao)
end

"""
    shadow_jobs(shadow) -> Vector

Every depth draw of the frame as (render object, light matrix, pass, viewport):
each caster once into the sun's map and once per direction into its tile of the
ambient atlas. The order is the order of the draw cells, rebound each frame.
"""
function shadow_jobs(shadow)
    jobs = Tuple{RenderObject, Mat4f, Symbol, NTuple{4, Float32}}[]
    if shadow.sun !== nothing
        vp = (0f0, 0f0, Float32(shadow.sun.res), Float32(shadow.sun.res))
        for robj in shadow.casters
            push!(jobs, (robj, shadow.sun.light_space, :sun, vp))
        end
    end
    if shadow.ao !== nothing
        res = shadow.ao.res
        for (i, m) in enumerate(shadow.ao.matrices)
            k = i - 1
            vp = (Float32((k % AO_COLUMNS) * res), Float32((k ÷ AO_COLUMNS) * res), Float32(res), Float32(res))
            for robj in shadow.casters
                push!(jobs, (robj, m, :ao, vp))
            end
        end
    end
    return jobs
end

"""What a plan built for `shadow` fixes: the maps it renders and who casts into them."""
shadow_signature(::Nothing) = nothing
shadow_signature(shadow) = (shadow.sun === nothing ? 0 : shadow.sun.res,
                            shadow.ao === nothing ? 0 : (shadow.ao.res, length(shadow.ao.matrices)),
                            map(objectid, shadow.casters))

shadow_args(robj, light_space) =
    (robj.buffers[:raster_positions], robj.buffers[:raster_faces], robj.uniforms[:model]::Mat4f, light_space)

shadow_cells(dev, jobs) =
    Mantle.DrawBinding[Mantle.DrawBinding(dev, shadow_args(robj, m), robj.vertex_count) for (robj, m, _, _) in jobs]

function rebind_shadow_cells!(cells, dev, jobs)
    for (cell, (robj, m, _, _)) in zip(cells, jobs)
        Mantle.rebind!(cell, dev, shadow_args(robj, m), robj.vertex_count)
    end
    return nothing
end

"""
    shadow_pass!(g, screen, shadow, jobs, cells)

Declare the depth passes and their readbacks into [`shadow_buffer`](@ref) and
[`ao_buffer`](@ref). Declared first, so the frame that samples the buffers
comes after them.
"""
function shadow_pass!(g, screen, shadow, jobs, cells)
    pipeline = get_shadow_pipeline!(screen)
    if shadow.sun !== nothing
        depth = Mantle.Transient.Image(g, Float32, (shadow.sun.res, shadow.sun.res))
        Mantle.render!(g, "shadow", depth => Mantle.Clear(1f0)) do p
            for (cell, (_, _, pass, vp)) in zip(cells, jobs)
                pass === :sun && Mantle.draw!(p, pipeline, cell; viewport = vp)
            end
        end
        Mantle.copy!(g, "read shadow", shadow_buffer(screen), depth)
    end
    if shadow.ao !== nothing
        atlas = Mantle.Transient.Image(g, Float32, ao_atlas_size(screen.config))
        Mantle.render!(g, "ambient occlusion", atlas => Mantle.Clear(1f0)) do p
            for (cell, (_, _, pass, vp)) in zip(cells, jobs)
                pass === :ao && Mantle.draw!(p, pipeline, cell; viewport = vp)
            end
        end
        Mantle.copy!(g, "read ambient occlusion", ao_buffer(screen), atlas)
    end
    return nothing
end
