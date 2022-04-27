####################################################################################################
#                                          Infrastructure                                          #
####################################################################################################

################################################################################
#                                    Types                                     #
################################################################################

@enum RenderType SVG PNG PDF EPS

"The Cairo backend object.  Used to dispatch to CairoMakie methods."
struct CairoBackend <: Makie.AbstractBackend
    typ::RenderType
    path::String
    px_per_unit::Float64
    pt_per_unit::Float64
end

"""
    struct CairoScreen{S} <: AbstractScreen
A "screen" type for CairoMakie, which encodes a surface
and a context which are used to draw a Scene.
"""
struct CairoScreen{S} <: Makie.AbstractScreen
    scene::Scene
    surface::S
    context::Cairo.CairoContext
    pane::Nothing # TODO: GtkWindowLeaf
end


function CairoBackend(path::String; px_per_unit=1, pt_per_unit=1)
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
    CairoBackend(typ, path, px_per_unit, pt_per_unit)
end

# we render the scene directly, since we have
# no screen dependent state like in e.g. opengl
Base.insert!(screen::CairoScreen, scene::Scene, plot) = nothing

function Base.show(io::IO, ::MIME"text/plain", screen::CairoScreen{S}) where S
    println(io, "CairoScreen{$S} with surface:")
    println(io, screen.surface)
end

# Default to ARGB Surface as backing device
# TODO: integrate Gtk into this, so we can have an interactive display
"""
    CairoScreen(scene::Scene; antialias = Cairo.ANTIALIAS_BEST)
Create a CairoScreen backed by an image surface.
"""
function CairoScreen(scene::Scene; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)
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
    @ccall Cairo.libcairo.cairo_set_miter_limit(ctx.ptr::Ptr{Nothing}, 2.0::Cdouble)::Cvoid

    return CairoScreen(scene, surf, ctx, nothing)
end

function get_type(surface::Cairo.CairoSurface)
    return ccall((:cairo_surface_get_type, Cairo.libcairo), Cint, (Ptr{Nothing},), surface.ptr)
end

is_vector_backend(ctx::Cairo.CairoContext) = is_vector_backend(ctx.surface)

function is_vector_backend(surf::Cairo.CairoSurface)
    typ = get_type(surf)
    return typ in (Cairo.CAIRO_SURFACE_TYPE_PDF, Cairo.CAIRO_SURFACE_TYPE_PS, Cairo.CAIRO_SURFACE_TYPE_SVG)
end

"""
    CairoScreen(
        scene::Scene, path::Union{String, IO}, mode::Symbol;
        antialias = Cairo.ANTIALIAS_BEST
    )
Creates a CairoScreen pointing to a given output path, with some rendering type defined by `mode`.
"""
function CairoScreen(scene::Scene, path::Union{String, IO}, mode::Symbol; device_scaling_factor = 1, antialias = Cairo.ANTIALIAS_BEST)

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
    @ccall Cairo.libcairo.cairo_surface_set_device_scale(surf.ptr::Ptr{Nothing}, device_scaling_factor::Cdouble, device_scaling_factor::Cdouble)::Cvoid

    ctx = Cairo.CairoContext(surf)
    Cairo.set_antialias(ctx, antialias)
    # Set the miter limit (when miter transitions to bezel) to mimic GLMakie behaviour
    @ccall Cairo.libcairo.cairo_set_miter_limit(ctx.ptr::Ptr{Nothing}, 2.0::Cdouble)::Cvoid

    return CairoScreen(scene, surf, ctx, nothing)
end


function Base.delete!(screen::CairoScreen, scene::Scene, plot::AbstractPlot)
    # Currently, we rerender every time, so nothing needs
    # to happen here.  However, in the event that changes,
    # e.g. if we integrate a Gtk window, we may need to
    # do something here.
end

"Convert a rendering type to a MIME type"
function to_mime(x::RenderType)
    x == SVG && return MIME("image/svg+xml")
    x == PDF && return MIME("application/pdf")
    x == EPS && return MIME("application/postscript")
    return MIME("image/png")
end
to_mime(x::CairoBackend) = to_mime(x.typ)

################################################################################
#                              Rendering pipeline                              #
################################################################################

########################################
#           Drawing pipeline           #
########################################

# The main entry point into the drawing pipeline
function cairo_draw(screen::CairoScreen, scene::Scene)
    draw_background(screen, scene)

    allplots = get_all_plots(scene)
    zvals = Makie.zvalue2d.(allplots)
    permute!(allplots, sortperm(zvals))

    last_scene = scene

    Cairo.save(screen.context)
    for p in allplots
        to_value(get(p, :visible, true)) || continue
        # only prepare for scene when it changes
        # this should reduce the number of unnecessary clipping masks etc.
        pparent = p.parent::Scene
        if pparent != last_scene
            Cairo.restore(screen.context)
            Cairo.save(screen.context)
            prepare_for_scene(screen, pparent)
            last_scene = pparent
        end
        Cairo.save(screen.context)
        draw_plot(pparent, screen, p)
        Cairo.restore(screen.context)
    end

    return
end

function get_all_plots(scene, plots = AbstractPlot[])
    append!(plots, scene.plots)
    for c in scene.children
        get_all_plots(c, plots)
    end
    plots
end

function prepare_for_scene(screen::CairoScreen, scene::Scene)

    # get the root area to correct for its pixel size when translating
    root_area = Makie.root(scene).px_area[]

    root_area_height = widths(root_area)[2]
    scene_area = pixelarea(scene)[]
    scene_height = widths(scene_area)[2]
    scene_x_origin, scene_y_origin = scene_area.origin

    # we need to translate x by the origin, so distance from the left
    # but y by the distance from the top, which is not the origin, but can
    # be calculated using the parent's height, the scene's height and the y origin
    # this is because y goes downwards in Cairo and upwards in Makie

    top_offset = root_area_height - scene_height - scene_y_origin
    Cairo.translate(screen.context, scene_x_origin, top_offset)

    # clip the scene to its pixelarea
    Cairo.rectangle(screen.context, 0, 0, widths(scene_area)...)
    Cairo.clip(screen.context)

    return
end

function draw_background(screen::CairoScreen, scene::Scene)
    cr = screen.context
    Cairo.save(cr)
    if scene.clear[]
        bg = to_color(theme(scene, :backgroundcolor)[])
        Cairo.set_source_rgba(cr, red(bg), green(bg), blue(bg), alpha(bg));
        r = pixelarea(scene)[]
        Cairo.rectangle(cr, origin(r)..., widths(r)...) # background
        fill(cr)
    end
    Cairo.restore(cr)
    foreach(child_scene-> draw_background(screen, child_scene), scene.children)
end

function draw_plot(scene::Scene, screen::CairoScreen, primitive::Combined)
    if to_value(get(primitive, :visible, true))
        if isempty(primitive.plots)
            Cairo.save(screen.context)
            draw_atomic(scene, screen, primitive)
            Cairo.restore(screen.context)
        else
            for plot in primitive.plots
                draw_plot(scene, screen, plot)
            end
        end
    end
    return
end

function draw_atomic(::Scene, ::CairoScreen, x)
    @warn "$(typeof(x)) is not supported by cairo right now"
end

function clear(screen::CairoScreen)
    ctx = screen.ctx
    Cairo.save(ctx)
    Cairo.set_operator(ctx, Cairo.OPERATOR_SOURCE)
    Cairo.set_source_rgba(ctx, rgbatuple(screen.scene[:backgroundcolor])...);
    Cairo.paint(ctx)
    Cairo.restore(ctx)
end

#########################################
# Backend interface to Makie #
#########################################

function Makie.backend_display(x::CairoBackend, scene::Scene)
    return open(x.path, "w") do io
        Makie.backend_show(x, io, to_mime(x), scene)
    end
end

Makie.backend_showable(x::CairoBackend, ::MIME"image/svg+xml", scene::Scene) = x.typ == SVG
Makie.backend_showable(x::CairoBackend, ::MIME"application/pdf", scene::Scene) = x.typ == PDF
Makie.backend_showable(x::CairoBackend, ::MIME"application/postscript", scene::Scene) = x.typ == EPS
Makie.backend_showable(x::CairoBackend, ::MIME"image/png", scene::Scene) = x.typ == PNG


function Makie.backend_show(x::CairoBackend, io::IO, ::MIME"image/svg+xml", scene::Scene)
    proxy_io = IOBuffer()
    pt_per_unit = get(io, :pt_per_unit, x.pt_per_unit)

    screen = CairoScreen(scene, proxy_io, :svg; device_scaling_factor = pt_per_unit)
    cairo_draw(screen, scene)
    Cairo.flush(screen.surface)
    Cairo.finish(screen.surface)
    svg = String(take!(proxy_io))

    # for some reason, in the svg, surfaceXXX ids keep counting up,
    # even with the very same figure drawn again and again
    # so we need to reset them to counting up from 1
    # so that the same figure results in the same svg and in the same salt
    surfaceids = sort(unique(collect(m.match for m in eachmatch(r"surface\d+", svg))))

    for (i, id) in enumerate(surfaceids)
        svg = replace(svg, id => "surface$i")
    end

    # salt svg ids with the first 8 characters of the base64 encoded
    # sha512 hash to avoid collisions across svgs when embedding them on
    # websites. the hash and therefore the salt will always be the same for the same file
    # so the output is deterministic
    salt = String(Base64.base64encode(SHA.sha512(svg)))[1:8]

    ids = sort(unique(collect(m[1] for m in eachmatch(r"id\s*=\s*\"([^\"]*)\"", svg))))

    for id in ids
        svg = replace(svg, id => "$id-$salt")
    end

    print(io, svg)
    return screen
end

function Makie.backend_show(x::CairoBackend, io::IO, ::MIME"application/pdf", scene::Scene)

    pt_per_unit = get(io, :pt_per_unit, x.pt_per_unit)

    screen = CairoScreen(scene, io, :pdf; device_scaling_factor = pt_per_unit)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end


function Makie.backend_show(x::CairoBackend, io::IO, ::MIME"application/postscript", scene::Scene)

    pt_per_unit = get(io, :pt_per_unit, x.pt_per_unit)

    screen = CairoScreen(scene, io, :eps; device_scaling_factor = pt_per_unit)

    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

function Makie.backend_show(x::CairoBackend, io::IO, ::MIME"image/png", scene::Scene)

    # multiply the resolution of the png with this factor for more or less detail
    # while relative line and font sizes are unaffected
    px_per_unit = get(io, :px_per_unit, x.px_per_unit)
    # create an ARGB surface, to speed up drawing ops.
    screen = CairoScreen(scene; device_scaling_factor = px_per_unit)
    cairo_draw(screen, scene)
    Cairo.write_to_png(screen.surface, io)
    return screen
end


########################################
#    Fast colorbuffer for recording    #
########################################

function Makie.colorbuffer(screen::CairoScreen)
    # extract scene
    scene = screen.scene
    # get resolution
    w, h = size(scene)
    # preallocate an image matrix
    img = Matrix{ARGB32}(undef, w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    # draw the scene onto the image matrix
    ctx = Cairo.CairoContext(surf)
    scr = CairoScreen(scene, surf, ctx, nothing)

    cairo_draw(scr, scene)

    # x and y are flipped - return the transpose
    return permutedims(img)
end
