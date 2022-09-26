@enum RenderType SVG PNG PDF EPS

const SCREEN_CONFIG = Ref((
    type = "png",
    px_per_unit = 1.0,
    pt_per_unit = 0.75,
    antialias = Cairo.ANTIALIAS_BEST
))

function activate!(; screen_config...)
    Makie.set_screen_config!(SCREEN_CONFIG, screen_config)
    Makie.set_active_backend!(CairoMakie)
    return
end

"""
    struct Screen{S} <: MakieScreen
A "screen" type for CairoMakie, which encodes a surface
and a context which are used to draw a Scene.
"""
struct Screen{S} <: Makie.MakieScreen
    scene::Scene
    surface::S
    context::Cairo.CairoContext
    device_scaling_factor::Float64
    antialias::Int # cairo_antialias_t
    image::Union{Nothing, Matrix{<: Colorant}}
    pane::Nothing # TODO: GtkWindowLeaf
end

Base.size(screen::Screen) = round.(Int, (screen.surface.width, screen.surface.height))
# we render the scene directly, since we have
# no screen dependent state like in e.g. opengl
Base.insert!(screen::Screen, scene::Scene, plot) = nothing
function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    # Currently, we rerender every time, so nothing needs
    # to happen here.  However, in the event that changes,
    # e.g. if we integrate a Gtk window, we may need to
    # do something here.
end

function Base.show(io::IO, ::MIME"text/plain", screen::Screen{S}) where S
    println(io, "Screen{$S} with surface:")
    println(io, screen.surface)
end

function path_to_type(path)
    ext = splitext(path)[2]
    if ext == ".png"
        return PNG
    elseif ext == ".svg"
        return SVG
    elseif ext == ".pdf"
        return PDF
    elseif ext == ".eps"
        return EPS
    else
        error("Unsupported extension: $ext")
    end
end

"Convert a rendering type to a MIME type"
function to_mime(type::RenderType)
    type == SVG && return MIME("image/svg+xml")
    type == PDF && return MIME("application/pdf")
    type == EPS && return MIME("application/postscript")
    return MIME("image/png")
end
to_mime(screen::Screen) = to_mime(screen.typ)

"convert a mime to a RenderType"
function mime_to_rendertype(mime::Symbol)::RenderType
    if mime == Symbol("image/png")
        return PNG
    elseif mime == Symbol("image/svg+xml")
        return SVG
    elseif mime == Symbol("application/pdf")
        return PDF
    elseif mime == Symbol("application/postscript")
        return EPS
    else
        error("Unsupported mime: $mime")
    end
end

function surface_from_output_type(mime::MIME{M}, io, w, h) where M
    surface_from_output_type(M, io, w, h)
end

function surface_from_output_type(mime::Symbol, io, w, h)
    surface_from_output_type(mime_to_rendertype(mime, io, w, h))
end

function surface_from_output_type(type::RenderType, io, w, h)
    if type === SVG
        return Cairo.CairoSVGSurface(io, w, h)
    elseif type === PDF
        return Cairo.CairoPDFSurface(io, w, h)
    elseif type === EPS
        return Cairo.CairoEPSSurface(io, w, h)
    elseif type === PNG
        return Cairo.CairoARGBSurface(w, h)
    else
        error("No available Cairo surface for mode $type")
    end
end

########################################
#    Constructor                       #
########################################


# Default to ARGB Surface as backing device
# TODO: integrate Gtk into this, so we can have an interactive display
"""
    Screen(scene::Scene; screen_attributes...)

Create a Screen backed by an image surface.
"""
Screen(scene::Scene; screen_attributes...) = Screen(scene, nothing, PNG; screen_attributes...)

function Screen(scene::Scene, io_or_path::Union{Nothing, String, IO}, typ::Union{MIME, Symbol, RenderType}; screen_attributes...)
    # the surface size is the scene size scaled by the device scaling factor
    w, h = round.(Int, size(scene) .* device_scaling_factor)
    surface = surface_from_output_type(typ, io_or_path, w, h)
    return Screen(scene, surface; screen_attributes...)
end

function Screen(scene::Scene, image::Matrix{<: Colorant}; screen_attributes...)
    img = Matrix{ARGB32}(undef, reverse(size(image))...)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    return Screen(scene, surf)
end

function Screen(scene::Scene, surface::Cairo.CairoSurface; screen_attributes...)
    # the surface size is the scene size scaled by the device scaling factor
    surface_set_device_scale(surf, device_scaling_factor)
    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)
    set_miter_limit(ctx, 2.0)
    return Screen(scene, surf, ctx, nothing, px_per_unit, pt_per_unit, antialias)
end

########################################
#    Fast colorbuffer for recording    #
########################################

function Makie.colorbuffer(screen::Screen)
    # extract scene
    scene = screen.scene
    # get resolution
    w, h = size(screen)
    scene_w, scene_h = size(scene)

    @assert w/scene_w ≈ h/scene_h
    device_scaling_factor = w/scene_w
    # preallocate an image matrix
    img = Matrix{ARGB32}(undef, w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    screen = Screen(scene, surf)
    # draw the scene onto the image matrix
    cairo_draw(screen, scene)

    # x and y are flipped - return the transpose
    return permutedims(img)
end
