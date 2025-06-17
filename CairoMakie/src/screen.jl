using Base.Docs: doc

@enum RenderType SVG IMAGE PDF EPS HTML

Base.convert(::Type{RenderType}, ::MIME{SYM}) where {SYM} = mime_to_rendertype(SYM)
function Base.convert(::Type{RenderType}, type::String)
    if type == "png"
        return IMAGE
    elseif type == "svg"
        return SVG
    elseif type == "pdf"
        return PDF
    elseif type == "eps"
        return EPS
    elseif type in ("html", "text/html", "application/vnd.webio.application+html", "application/prs.juno.plotpane+html", "juliavscode/html")
        return HTML
    else
        error("Unsupported cairo render type: $type")
    end
end

"Convert a rendering type to a MIME type"
function to_mime(type::RenderType)
    type == SVG && return MIME("image/svg+xml")
    type == PDF && return MIME("application/pdf")
    type == EPS && return MIME("application/postscript")
    type == HTML && return MIME("text/html")
    return MIME("image/png")
end

"convert a mime to a RenderType"
function mime_to_rendertype(mime::Symbol)::RenderType
    if mime == Symbol("image/png")
        return IMAGE
    elseif mime == Symbol("image/svg+xml")
        return SVG
    elseif mime == Symbol("application/pdf")
        return PDF
    elseif mime == Symbol("application/postscript")
        return EPS
    elseif mime in (Symbol("text/html"), Symbol("text/html"), Symbol("application/vnd.webio.application+html"), Symbol("application/prs.juno.plotpane+html"), Symbol("juliavscode/html"))
        return HTML
    else
        error("Unsupported mime: $mime")
    end
end

function surface_from_output_type(mime::MIME{M}, io, w, h) where {M}
    return surface_from_output_type(M, io, w, h)
end

function surface_from_output_type(mime::Symbol, io, w, h)
    return surface_from_output_type(mime_to_rendertype(mime), io, w, h)
end

function surface_from_output_type(type::RenderType, io, w, h)
    if type === SVG
        return Cairo.CairoSVGSurface(io, w, h)
    elseif type === PDF
        return Cairo.CairoPDFSurface(io, w, h)
    elseif type === EPS
        return Cairo.CairoEPSSurface(io, w, h)
    elseif type === IMAGE || type === HTML
        img = fill(ARGB32(0, 0, 0, 0), w, h)
        return Cairo.CairoImageSurface(img)
    else
        error("No available Cairo surface for mode $type")
    end
end

@enum PDFVersion PDFv14 PDFv15 PDFv16 PDFv17
function pdfversion(version::AbstractString)
    version == "1.4" && return PDFv14
    version == "1.5" && return PDFv15
    version == "1.6" && return PDFv16
    version == "1.7" && return PDFv17
    throw(ArgumentError("PDF version must be one of '1.4', '1.5', '1.6', '1.7' (received '$version')"))
end

"""
Supported options: `[:best => Cairo.ANTIALIAS_BEST, :good => Cairo.ANTIALIAS_GOOD, :subpixel => Cairo.ANTIALIAS_SUBPIXEL, :none => Cairo.ANTIALIAS_NONE]`
"""
function to_cairo_antialias(sym::Symbol)
    sym === :best && return Cairo.ANTIALIAS_BEST
    sym === :good && return Cairo.ANTIALIAS_GOOD
    sym === :subpixel && return Cairo.ANTIALIAS_SUBPIXEL
    sym === :none && return Cairo.ANTIALIAS_NONE
    error("Wrong antialias setting: $(sym). Allowed: :best, :good, :subpixel, :none")
end
to_cairo_antialias(aa::Int) = aa

"""
* `px_per_unit = 2.0`
* `pt_per_unit = 0.75`
* `antialias::Union{Symbol, Int} = :best`: antialias modus Cairo uses to draw. Applicable options: `[:best => Cairo.ANTIALIAS_BEST, :good => Cairo.ANTIALIAS_GOOD, :subpixel => Cairo.ANTIALIAS_SUBPIXEL, :none => Cairo.ANTIALIAS_NONE]`.
* `visible::Bool`: if true, a browser/image viewer will open to display rendered output.
* `pdf_version::String = nothing`: the version of output PDFs. Applicable options are `"1.4"`, `"1.5"`, `"1.6"`, `"1.7"`, or `nothing`, which leaves the PDF version unrestricted.
"""
struct ScreenConfig
    px_per_unit::Float64
    pt_per_unit::Float64
    antialias::Symbol
    visible::Bool
    start_renderloop::Bool # Only used to satisfy the interface for record using `Screen(...; start_renderloop=false)` for GLMakie
    pdf_version::Union{Nothing, PDFVersion}

    function ScreenConfig(
            px_per_unit::Real, pt_per_unit::Real,
            antialias::Symbol, visible::Bool, start_renderloop::Bool,
            pdf_version::Union{Nothing, AbstractString}
        )
        v = isnothing(pdf_version) ? nothing : pdfversion(pdf_version)
        return new(px_per_unit, pt_per_unit, antialias, visible, start_renderloop, v)
    end
end

css_px_per_unit(pt_per_unit) = pt_per_unit / 0.75

function device_scaling_factor(rendertype, sc::ScreenConfig)
    rt = convert(RenderType, rendertype)
    isv = is_vector_backend(rt)
    # from version 1.18 on, Cairo saves SVGs without the pt unit specified, so they are actually in CSS px now
    return rt === SVG ? css_px_per_unit(sc.pt_per_unit) : isv ? sc.pt_per_unit : sc.px_per_unit
end

function device_scaling_factor(surface::Cairo.CairoSurface, sc::ScreenConfig)
    return device_scaling_factor(get_render_type(surface), sc)
end

const LAST_INLINE = Ref{Union{Makie.Automatic, Bool}}(Makie.automatic)

"""
    CairoMakie.activate!(; screen_config...)

Sets CairoMakie as the currently active backend and also allows to quickly set the `screen_config`.
Note, that the `screen_config` can also be set permanently via `Makie.set_theme!(CairoMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; inline = LAST_INLINE[], type = "png", screen_config...)
    Makie.inline!(inline)
    LAST_INLINE[] = inline
    Makie.set_screen_config!(CairoMakie, screen_config)
    if type == "png"
        # So this is a bit counter intuitive, since the display system doesn't let us prefer a mime.
        # Instead, any IDE with rich output usually has a priority list of mimes, which it iterates to figure out the best mime.
        # So, if we want to prefer the png mime, we disable the mimes that are usually higher up in the stack.
        disable_mime!("svg", "pdf")
    elseif type == "svg"
        disable_mime!("text/html", "application/vnd.webio.application+html", "application/prs.juno.plotpane+html", "juliavscode/html")
    else
        enable_only_mime!(type)
    end

    Makie.set_active_backend!(CairoMakie)
    return
end

"""
    Screen(; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen{SurfaceRenderType} <: Makie.MakieScreen
    scene::Scene
    surface::Cairo.CairoSurface
    context::Cairo.CairoContext
    device_scaling_factor::Float64
    antialias::Int # cairo_antialias_t
    visible::Bool
    config::ScreenConfig

    function Screen()
        return new{IMAGE}()
    end
    function Screen{SurfaceRenderType}(
            scene::Scene,
            surface::Cairo.CairoSurface,
            context::Cairo.CairoContext,
            device_scaling_factor::Float64,
            antialias::Int,
            visible::Bool,
            config::ScreenConfig
        ) where {SurfaceRenderType}

        return new{SurfaceRenderType}(
            scene,
            surface,
            context,
            device_scaling_factor,
            antialias,
            visible,
            config,
        )
    end

end

function Base.empty!(screen::Screen)
    isopen(screen) || return
    ctx = screen.context
    Cairo.save(ctx)
    bg = rgbatuple(screen.scene.backgroundcolor[])
    Cairo.set_source_rgba(ctx, bg...)
    Cairo.set_operator(ctx, Cairo.OPERATOR_CLEAR)
    Cairo.rectangle(ctx, 0, 0, size(screen)...)
    Cairo.paint_with_alpha(ctx, 1.0)
    return Cairo.restore(ctx)
end

Base.close(screen::Screen) = empty!(screen)

function destroy!(screen::Screen)
    isdefined(screen, :surface) || return
    Cairo.destroy(screen.surface)
    return Cairo.destroy(screen.context)
end

function Base.isopen(screen::Screen)
    return !(screen.surface.ptr == C_NULL || screen.context.ptr == C_NULL)
end

function Base.size(screen::Screen)
    isdefined(screen, :surface) || return (0, 0)
    return round.(Int, (screen.surface.width, screen.surface.height))
end
# we render the scene directly, since we have
# no screen dependent state like in e.g. opengl
Base.insert!(screen::Screen, scene::Scene, plot) = nothing

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    # Currently, we rerender every time, so nothing needs
    # to happen here.  However, in the event that changes,
    # e.g. if we integrate a Gtk window, we may need to
    # do something here.
end

function Base.show(io::IO, ::MIME"text/plain", screen::Screen{S}) where {S}
    return println(io, "CairoMakie.Screen{$S}")
end

function path_to_type(path)
    type = splitext(path)[2][2:end]
    return convert(RenderType, type)
end
to_mime(screen::Screen) = to_mime(screen.typ)


########################################
#    Constructor                       #
########################################

function apply_config!(screen::Screen, config::ScreenConfig)
    empty!(screen)
    surface = screen.surface
    context = screen.context
    dsf = device_scaling_factor(surface, config)
    surface_set_device_scale(surface, dsf)
    aa = to_cairo_antialias(config.antialias)
    Cairo.set_antialias(context, aa)
    set_miter_limit(context, 2.0)

    if get_render_type(surface) === PDF && !isnothing(config.pdf_version)
        restrict_pdf_version!(surface, Int(config.pdf_version))
    end

    screen.antialias = aa
    screen.device_scaling_factor = dsf
    screen.config = config
    return screen
end

function scaled_scene_resolution(typ::RenderType, config::ScreenConfig, scene::Scene)
    dsf = device_scaling_factor(typ, config)
    return round.(Int, size(scene) .* dsf)
end

function Makie.apply_screen_config!(
        screen::Screen{SCREEN_RT}, config::ScreenConfig, scene::Scene, io::Union{Nothing, IO}, m::MIME{SYM}
    ) where {SYM, SCREEN_RT}
    # the surface size is the scene size scaled by the device scaling factor
    new_rendertype = mime_to_rendertype(SYM)
    # we need to re-create the screen if the rendertype changes, or for all vector backends
    # since they need to use the new IO, or if the resolution changed!
    new_resolution = scaled_scene_resolution(new_rendertype, config, scene)
    if SCREEN_RT !== new_rendertype || is_vector_backend(new_rendertype) || size(screen) != new_resolution
        old_screen = screen
        surface = surface_from_output_type(new_rendertype, io, new_resolution...)
        screen = Screen(scene, config, surface)
        @assert new_resolution == size(screen)
        destroy!(old_screen)
    end
    apply_config!(screen, config)
    screen.scene = scene
    return screen
end

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, scene::Scene, args...)
    # No mime as an argument implies we want an image based surface
    return Makie.apply_screen_config!(screen, config, scene, nothing, MIME"image/png"())
end

function Makie.px_per_unit(s::Screen)::Float64
    return s.config.px_per_unit
end

function Screen(scene::Scene; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(scene, config)
end

Screen(scene::Scene, config::ScreenConfig) = Screen(scene, config, nothing, IMAGE)

function Screen(screen::Screen, io_or_path::Union{Nothing, String, IO}, typ::Union{MIME, Symbol, RenderType})
    rtype = convert(RenderType, typ)
    # the resolution may change between rendertypes, so, we can't just use `size(screen)` here for recreating the Screen:
    w, h = scaled_scene_resolution(rtype, screen.config, screen.scene)
    surface = surface_from_output_type(rtype, io_or_path, w, h)
    return Screen(screen.scene, screen.config, surface)
end

function Screen(scene::Scene, config::ScreenConfig, io_or_path::Union{Nothing, String, IO}, typ::Union{MIME, Symbol, RenderType})
    rtype = convert(RenderType, typ)
    w, h = scaled_scene_resolution(rtype, config, scene)
    surface = surface_from_output_type(rtype, io_or_path, w, h)
    return Screen(scene, config, surface)
end

function Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat)
    w, h = scaled_scene_resolution(IMAGE, config, scene)
    # create an image surface to draw onto the image
    img = fill(ARGB32(0, 0, 0, 0), w, h)
    surface = Cairo.CairoImageSurface(img)
    return Screen(scene, config, surface)
end

function Screen(scene::Scene, config::ScreenConfig, surface::Cairo.CairoSurface)
    # the surface size is the scene size scaled by the device scaling factor
    dsf = device_scaling_factor(surface, config)
    surface_set_device_scale(surface, dsf)
    ctx = Cairo.CairoContext(surface)
    aa = to_cairo_antialias(config.antialias)
    Cairo.set_antialias(ctx, aa)
    set_miter_limit(ctx, 2.0)

    if get_render_type(surface) === PDF && !isnothing(config.pdf_version)
        restrict_pdf_version!(surface, Int(config.pdf_version))
    end

    return Screen{get_render_type(surface)}(scene, surface, ctx, dsf, aa, config.visible, config)
end

########################################
#    Fast colorbuffer for recording    #
########################################

function Makie.colorbuffer(screen::Screen)
    # extract scene
    scene = screen.scene
    # get resolution
    w, h = size(screen)
    # preallocate an image matrix
    img = fill(ARGB32(0, 0, 0, 0), w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    s = Screen(scene, screen.config, surf)
    return Makie.colorbuffer(s)
end

function Makie.colorbuffer(screen::Screen{IMAGE})
    Makie.push_screen!(screen.scene, screen)
    empty!(screen)
    cairo_draw(screen, screen.scene)
    return PermutedDimsArray(screen.surface.data, (2, 1))
end

is_vector_backend(ctx::Cairo.CairoContext) = is_vector_backend(ctx.surface)
is_vector_backend(surf::Cairo.CairoSurface) = is_vector_backend(get_render_type(surf))
is_vector_backend(rt::RenderType) = rt in (PDF, EPS, SVG)

# no need for resizing screen, since we need to redisplay anyways!
Base.resize!(screen::Screen, w, h) = nothing
