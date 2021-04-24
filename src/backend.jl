using Cairo

"""
    struct CairoScreen{S} <: AbstractScreen
A "screen" type for CairoMakie, which encodes a surface
and a context which are used to draw a Scene.
"""
struct CairoScreen{S}
    surface::S
    context::Cairo.CairoContext
end

function CairoScreen(w, h; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)
    w, h = (w, h) .* device_scaling_factor
    surf = Cairo.CairoARGBSurface(w, h)
    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution
    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, device_scaling_factor, device_scaling_factor)

    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)

    return CairoScreen(surf, ctx)
end

function rgbatuple(c::Colorant)
    rgba = RGBA(c)
    red(rgba), green(rgba), blue(rgba), alpha(rgba)
end

to_2d_scale(x::Number) = Vec2f0(x)
to_2d_scale(x::Vec) = Vec2f0(x)

function project_position(scene, point, model)
    # use transform func
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    @inbounds begin
    # between -1 and 1
        p = (clip ./ clip[4])[Vec(1, 2)]
        # flip y to match cairo
        p_yflip = Vec2f0(p[1], -p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1f0) / 2f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

project_scale(scene, s::Number, model = Mat4f0(I)) = project_scale(scene, Vec2f0(s), model)

function project_scale(scene, s, model = Mat4f0(I))
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = @inbounds (scene.camera.projectionview[] * model * p4d)[Vec(1, 2)] ./ 2f0
    return p .* scene.camera.resolution[]
end

function draw_marker(ctx, m, pos, scale, strokecolor, strokewidth, marker_offset)

    marker_offset = marker_offset + scale ./ 2

    pos += Point2f0(marker_offset[1], -marker_offset[2])

    # Cairo.scale(ctx, scale...)
    Cairo.move_to(ctx, pos[1] + scale[1]/2, pos[2])
    Cairo.arc(ctx, pos[1], pos[2], scale[1]/2, 0, 2*pi)
    Cairo.fill_preserve(ctx)

    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.stroke(ctx)
end

function draw_atomic(screen::CairoScreen, p::Scatter)
    ctx = screen.context
    model = p.transformation.model[]
    isempty(p.positions) && return
    size_model = p.transform_marker ? model : Mat4f0(I)

    # if we give size in pixels, the size is always equal to that value
    is_pixelspace = p.markerspace == Pixel
    broadcast_foreach(p.positions, p.color, p.markersize, p.strokecolor,
                      p.strokewidth, p.marker, p.markeroffset) do point, col,
                          markersize, strokecolor, strokewidth, marker, mo

        scale = if is_pixelspace
            to_2d_scale(markersize)
        else
            # otherwise calculate a scaled size
            project_scale(p, markersize, size_model)
        end
        offset = if is_pixelspace
            to_2d_scale(mo)
        else
            project_scale(p, mo, size_model)
        end

        pos = project_position(p, point, model)

        isnan(pos) && return

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)

        draw_marker(ctx, marker, pos, scale, strokecolor, strokewidth, offset)
    end
    nothing
end
