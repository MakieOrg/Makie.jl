# =============================================================================
# draw_atomic for Makie.scatter (overlay plot)
# =============================================================================
# Produces :sprite trace_renderobjects with full per-element attributes
# matching GLMakie's sprite pipeline (rotation, per-element sizes/colors, etc.)

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.scatter})
    attr = plot.attributes
    state = screen.state
    backend = screen.config.device

    # Register marker SDF computations (sdf_marker_shape, sdf_uv, image)
    Makie.all_marker_computations!(attr)
    # Register f32c_scale
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    deps = [
        :positions_transformed_f32c,
        :quad_offset, :quad_scale,
        :marker_offset,
        :converted_rotation, :billboard,
        :scaled_color, :alpha_colormap, :scaled_colorrange,
        :sdf_marker_shape, :sdf_uv,
        :model_f32c, :f32c_scale, :transform_marker,
    ]

    register_computation!(attr, deps, [:trace_renderobject]) do args, changed, last
        positions_raw = args.positions_transformed_f32c
        n = length(positions_raw)
        n == 0 && return (nothing,)

        # Per-element positions (handle both Point2f and Point3f)
        positions = [Makie.to_ndim(Point3f, p, 0f0) for p in positions_raw]

        # Per-element quad geometry
        quad_offsets = _sprite_broadcast_vec2f(args.quad_offset, n)
        quad_scales = _sprite_broadcast_vec2f(args.quad_scale, n)

        # Per-element marker offset
        marker_offsets = _sprite_broadcast_vec3f(args.marker_offset, n)

        # Per-element rotation (Quaternionf → Vec4f) and billboard flag
        rotations = _sprite_broadcast_rotation(args.converted_rotation, n)
        is_billboard = args.billboard isa Bool ? args.billboard : true

        # Per-element colors
        colors = _sprite_resolve_colors(
            args.scaled_color, args.alpha_colormap, args.scaled_colorrange, n
        )

        # Per-element SDF UV and shape
        uv_rects = _sprite_broadcast_vec4f(args.sdf_uv, n)
        shape_val = _sprite_shape_to_uint8(args.sdf_marker_shape)
        shapes = fill(shape_val, n)

        # Uniforms
        is_transform_marker = args.transform_marker isa Bool ? args.transform_marker : false
        model = Mat4f(args.model_f32c)

        state.needs_film_clear = true
        return ((
            type = :sprite,
            positions = Adapt.adapt(backend, positions),
            quad_offsets = Adapt.adapt(backend, quad_offsets),
            quad_scales = Adapt.adapt(backend, quad_scales),
            marker_offsets = Adapt.adapt(backend, marker_offsets),
            rotations = Adapt.adapt(backend, rotations),
            colors = Adapt.adapt(backend, colors),
            uv_rects = Adapt.adapt(backend, uv_rects),
            shapes = Adapt.adapt(backend, shapes),
            billboard = is_billboard,
            scale_primitive = is_transform_marker,
            model = model,
        ),)
    end
end

# =============================================================================
# Sprite attribute conversion helpers (shared by scatter and text)
# =============================================================================

_sprite_broadcast_vec2f(x::Vec2f, n::Int) = fill(x, n)
_sprite_broadcast_vec2f(x::AbstractVector, n::Int) = Vec2f.(x)
_sprite_broadcast_vec2f(x, n::Int) = fill(Vec2f(Makie.to_2d_scale(x)), n)

_sprite_broadcast_vec3f(x::Vec3f, n::Int) = fill(x, n)
_sprite_broadcast_vec3f(x::Point3f, n::Int) = fill(Vec3f(x), n)
_sprite_broadcast_vec3f(x::AbstractVector, n::Int) = [Vec3f(Makie.to_ndim(Point3f, v, 0f0)) for v in x]
_sprite_broadcast_vec3f(x, n::Int) = fill(Vec3f(0f0), n)

_sprite_broadcast_vec4f(x::Vec4f, n::Int) = fill(x, n)
_sprite_broadcast_vec4f(x::AbstractVector, n::Int) = Vec4f.(x)
_sprite_broadcast_vec4f(x, n::Int) = fill(Vec4f(0f0, 0f0, 1f0, 1f0), n)

function _sprite_broadcast_rotation(x::AbstractVector, n::Int)
    return [Vec4f(q[1], q[2], q[3], q[4]) for q in x]
end
function _sprite_broadcast_rotation(x, n::Int)
    q = Makie.to_rotation(x)
    return fill(Vec4f(q[1], q[2], q[3], q[4]), n)
end

function _sprite_shape_to_uint8(shape)
    s = Int(shape)
    # Map Makie's Cint shape constants to our Overlay module constants
    # GLMakie: CIRCLE=0, RECTANGLE=1, ROUNDED_RECTANGLE=2, DISTANCEFIELD=3, TRIANGLE=4
    # Our Overlay: CIRCLE=0, RECTANGLE=1, ROUNDED_RECTANGLE=2, DISTANCEFIELD=3, TRIANGLE=4, ...
    return UInt8(s)
end

function _sprite_resolve_colors(scaled_color, colormap, colorrange, n::Int)
    if scaled_color isa AbstractVector{<:Colorant}
        return [RGBA{Float32}(c) for c in scaled_color]
    elseif scaled_color isa Colorant
        return fill(RGBA{Float32}(scaled_color), n)
    elseif scaled_color isa AbstractVector{<:Real}
        # Numeric: apply colormap lookup
        cmin = Float32(colorrange[1])
        cmax = Float32(colorrange[2])
        cmap = colormap isa AbstractVector ? colormap : RGBAf[RGBAf(0,0,0,1)]
        return [_sprite_cmap_lookup(cmap, Float32(v), cmin, cmax) for v in scaled_color]
    elseif scaled_color isa Real
        cmin = Float32(colorrange[1])
        cmax = Float32(colorrange[2])
        cmap = colormap isa AbstractVector ? colormap : RGBAf[RGBAf(0,0,0,1)]
        return fill(_sprite_cmap_lookup(cmap, Float32(scaled_color), cmin, cmax), n)
    else
        return fill(RGBA{Float32}(0f0, 0f0, 0f0, 1f0), n)
    end
end

function _sprite_cmap_lookup(cmap::AbstractVector, v::Float32, cmin::Float32, cmax::Float32)
    t = clamp((v - cmin) / (cmax - cmin + 1f-10), 0f0, 1f0)
    n = length(cmap)
    idx = t * Float32(n - 1) + 1f0  # 1-based
    i0 = clamp(floor(Int, idx), 1, n)
    i1 = clamp(i0 + 1, 1, n)
    frac = idx - Float32(i0)
    c0 = RGBA{Float32}(cmap[i0])
    c1 = RGBA{Float32}(cmap[i1])
    return RGBA{Float32}(
        (1f0 - frac) * c0.r + frac * c1.r,
        (1f0 - frac) * c0.g + frac * c1.g,
        (1f0 - frac) * c0.b + frac * c1.b,
        (1f0 - frac) * c0.alpha + frac * c1.alpha,
    )
end
