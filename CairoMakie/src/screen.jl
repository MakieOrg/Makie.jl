@enum RenderType SVG PNG PDF EPS

const SCREEN_CONFIG = Ref((
    type = "png",
    px_per_unit = 1.0,
    pt_per_unit = 0.75,
    antialias = Cairo.ANTIALIAS_BEST
))

function activate!(; screen_config...)
    Makie.set_screen_config!(SCREEN_CONFIG, screen_config)
    Makie.register_backend!(CairoMakie)
    return
end

"""
    struct Screen{S} <: AbstractScreen
A "screen" type for CairoMakie, which encodes a surface
and a context which are used to draw a Scene.
"""
struct Screen{S} <: Makie.AbstractScreen
    scene::Scene
    surface::S
    context::Cairo.CairoContext
    pane::Nothing # TODO: GtkWindowLeaf

    px_per_unit::Float64
    pt_per_unit::Float64
    antialias::Int # cairo_antialias_t
end

function CairoBackend(path::String; px_per_unit=1, pt_per_unit=1, antialias = Cairo.ANTIALIAS_BEST)
    ext = splitext(path)[2]
    typ = if ext == ".png"
        PNG
    elseif ext == ".svg"
        SVG
    elseif ext == ".pdf"
        PDF
    elseif ext == ".eps"
        EPS
    else
        error("Unsupported extension: $ext")
    end
    CairoBackend(typ, path, px_per_unit, pt_per_unit, antialias)
end

# we render the scene directly, since we have
# no screen dependent state like in e.g. opengl
Base.insert!(screen::Screen, scene::Scene, plot) = nothing

function Base.show(io::IO, ::MIME"text/plain", screen::Screen{S}) where S
    println(io, "Screen{$S} with surface:")
    println(io, screen.surface)
end

# Default to ARGB Surface as backing device
# TODO: integrate Gtk into this, so we can have an interactive display
"""
    Screen(scene::Scene; antialias = Cairo.ANTIALIAS_BEST)
Create a Screen backed by an image surface.
"""
function Screen(scene::Scene; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)
    w, h = round.(Int, scene.camera.resolution[] .* device_scaling_factor)
    surf = Cairo.CairoARGBSurface(w, h)

    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution
    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, device_scaling_factor, device_scaling_factor)

    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)
    # Set the miter limit (when miter transitions to bezel) to mimic GLMakie behaviour
    ccall((:cairo_set_miter_limit, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble), ctx.ptr, 2.0)

    return Screen(scene, surf, ctx, nothing, px_per_unit, pt_per_unit, antialias)
end

"""
    Screen(
        scene::Scene, path::Union{String, IO}, mode::Symbol;
        antialias = Cairo.ANTIALIAS_BEST
    )
Creates a Screen pointing to a given output path, with some rendering type defined by `mode`.
"""
function Screen(scene::Scene, path::Union{String, IO}, mode::Symbol; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)

    # the surface size is the scene size scaled by the device scaling factor
    w, h = round.(Int, scene.camera.resolution[] .* device_scaling_factor)

    if mode == :svg
        surf = Cairo.CairoSVGSurface(path, w, h)
    elseif mode == :pdf
        surf = Cairo.CairoPDFSurface(path, w, h)
    elseif mode == :eps
        surf = Cairo.CairoEPSSurface(path, w, h)
    elseif mode == :png
        surf = Cairo.CairoARGBSurface(w, h)
    else
        error("No available Cairo surface for mode $mode")
    end

    # this sets a scaling factor on the lowest level that is "hidden" so its even
    # enabled when the drawing space is reset for strokes
    # that means it can be used to increase or decrease the image resolution
    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, device_scaling_factor, device_scaling_factor)

    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)
    # Set the miter limit (when miter transitions to bezel) to mimic GLMakie behaviour
    ccall((:cairo_set_miter_limit, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble), ctx.ptr, 2.0)

    return Screen(scene, surf, ctx, nothing)
end

GeometryBasics.widths(screen::Screen) = round.(Int, (screen.surface.width, screen.surface.height))

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    # Currently, we rerender every time, so nothing needs
    # to happen here.  However, in the event that changes,
    # e.g. if we integrate a Gtk window, we may need to
    # do something here.
end


########################################
#    Fast colorbuffer for recording    #
########################################

function Makie.colorbuffer(screen::Screen)
    # extract scene
    scene = screen.scene
    # get resolution
    w, h = GeometryBasics.widths(screen)
    scene_w, scene_h = size(scene)
    @assert w/scene_w ≈ h/scene_h

    device_scaling_factor = w/scene_w
    # preallocate an image matrix
    img = Matrix{ARGB32}(undef, w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, device_scaling_factor, device_scaling_factor)

    # draw the scene onto the image matrix
    ctx = Cairo.CairoContext(surf)
    ccall((:cairo_set_miter_limit, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble), ctx.ptr, 2.0)

    scr = Screen(scene, surf, ctx, nothing)

    cairo_draw(scr, scene)

    # x and y are flipped - return the transpose
    return permutedims(img)
end
