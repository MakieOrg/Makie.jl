
"""
    struct CairoScreen{S} <: AbstractScreen
A "screen" type for CairoMakie, which encodes a surface
and a context which are used to draw a Scene.
"""
struct CairoScreen{S} <: AbstractScreen
    surface::S
    context::Cairo.CairoContext
end

function CairoScreen(w, h; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)
    w, h = round.(Int, (w, h) .* device_scaling_factor)
    surf = Cairo.CairoARGBSurface(w, h)
    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution
    ccall(
        (:cairo_surface_set_device_scale, Cairo.libcairo),
        Cvoid,
        (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr,
        device_scaling_factor,
        device_scaling_factor,
    )

    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)

    return CairoScreen(surf, ctx)
end

function colorbuffer(scene::Scene)
    # get resolution
    w, h = widths(scene)
    # preallocate an image matrix
    img = Matrix{ARGB32}(undef, w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    # draw the scene onto the image matrix
    ctx = Cairo.CairoContext(surf)
    scr = CairoScreen(surf, ctx)
    cairo_draw(scr, scene)
    # x and y are flipped - return the transpose
    return permutedims(img)
end
