using Base.Docs: doc

@enum RenderType SVG IMAGE PDF EPS

function Base.convert(::Type{RenderType}, type::String)
    if type == "png"
        return IMAGE
    elseif type == "svg"
        return SVG
    elseif type == "pdf"
        return PDF
    elseif type == "eps"
        return EPS
    else
        error("Unsupported cairo render type: $type")
    end
end

"Convert a rendering type to a MIME type"
function to_mime(type::RenderType)
    type == SVG && return MIME("image/svg+xml")
    type == PDF && return MIME("application/pdf")
    type == EPS && return MIME("application/postscript")
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
    else
        error("Unsupported mime: $mime")
    end
end

function surface_from_output_type(mime::MIME{M}, io, w, h) where M
    surface_from_output_type(M, io, w, h)
end

function surface_from_output_type(mime::Symbol, io, w, h)
    surface_from_output_type(mime_to_rendertype(mime), io, w, h)
end

function surface_from_output_type(type::RenderType, io, w, h)
    if type === SVG
        return Cairo.CairoSVGSurface(io, w, h)
    elseif type === PDF
        return Cairo.CairoPDFSurface(io, w, h)
    elseif type === EPS
        return Cairo.CairoEPSSurface(io, w, h)
    elseif type === IMAGE
        img = Matrix{ARGB32}(undef, w, h)
        return Cairo.CairoImageSurface(img)
    else
        error("No available Cairo surface for mode $type")
    end
end

"""
Supported options: `[:best => Cairo.ANTIALIAS_BEST, :good => Cairo.ANTIALIAS_GOOD, :subpixel => Cairo.ANTIALIAS_SUBPIXEL, :none => Cairo.ANTIALIAS_NONE]`
"""
function to_cairo_antialias(sym::Symbol)
    sym == :best && return Cairo.ANTIALIAS_BEST
    sym == :good && return Cairo.ANTIALIAS_GOOD
    sym == :subpixel && return Cairo.ANTIALIAS_SUBPIXEL
    sym == :none && return Cairo.ANTIALIAS_NONE
    error("Wrong antialias setting: $(sym). Allowed: :best, :good, :subpixel, :none")
end
to_cairo_antialias(aa::Int) = aa

"""
* `px_per_unit = 1.0`: see [figure size docs](https://docs.makie.org/v0.17.13/documentation/figure_size/index.html).
* `pt_per_unit = 0.75`: see [figure size docs](https://docs.makie.org/v0.17.13/documentation/figure_size/index.html).
* `antialias::Union{Symbol, Int} = :best`: antialias modus Cairo uses to draw. Applicable options: `[:best => Cairo.ANTIALIAS_BEST, :good => Cairo.ANTIALIAS_GOOD, :subpixel => Cairo.ANTIALIAS_SUBPIXEL, :none => Cairo.ANTIALIAS_NONE]`.
* `visible::Bool`: if true, a browser/image viewer will open to display rendered output.
"""
struct ScreenConfig
    type::RenderType
    px_per_unit::Float64
    pt_per_unit::Float64
    antialias::Symbol
    visible::Bool
    start_renderloop::Bool
    function ScreenConfig(type, px_per_unit::Number, pt_per_unit::Number, anitalias::Symbol, visible::Bool, start_renderloop::Bool)
        return new(convert(RenderType, type), px_per_unit, pt_per_unit, anitalias, visible, start_renderloop)
    end
end

function device_scaling_factor(sc::ScreenConfig)
    if is_vector_backend(sc.type)
        return sc.pt_per_unit
    else
        return sc.px_per_unit
    end
end

"""
    CairoMakie.activate!(; screen_config...)

Sets CairoMakie as the currently active backend and also allows to quickly set the `screen_config`.
Note, that the `screen_config` can also be set via permanently via `Makie.set_theme!(CairoMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; screen_config...)
    config = Makie.set_screen_config!(CairoMakie, screen_config)
    Makie.set_preferred_mime!(to_mime(convert(RenderType, config.type[])))
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
struct Screen{SurfaceRenderType} <: Makie.MakieScreen
    scene::Scene
    surface::Cairo.CairoSurface
    context::Cairo.CairoContext
    device_scaling_factor::Float64
    antialias::Int # cairo_antialias_t
    visible::Bool
end

function Base.empty!(screen::Screen)
    ctx = screen.context
    Cairo.save(ctx)
    bg = rgbatuple(screen.scene.backgroundcolor[])
    Cairo.set_source_rgba(ctx, bg...)
    Cairo.set_operator(ctx, Cairo.OPERATOR_CLEAR)
    Cairo.rectangle(ctx, 0, 0, size(screen)...)
    Cairo.paint_with_alpha(ctx, 1.0)
    Cairo.restore(ctx)
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
    println(io, "CairoMakie.Screen{$S}")
end


function path_to_type(path)
    type = splitext(path)[2][2:end]
    return convert(RenderType, type)
end
to_mime(screen::Screen) = to_mime(screen.typ)


########################################
#    Constructor                       #
########################################

Screen(scene::Scene; screen_config...) = Screen(scene, nothing, IMAGE; screen_config...)

function Screen(scene::Scene, io_or_path::Union{Nothing, String, IO}, typ::Union{MIME, Symbol, RenderType}; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, screen_config)
    # the surface size is the scene size scaled by the device scaling factor
    w, h = round.(Int, size(scene) .* device_scaling_factor(config))
    surface = surface_from_output_type(typ, io_or_path, w, h)
    return Screen(scene, surface, config)
end

function Screen(scene::Scene, ::Makie.ImageStorageFormat; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, screen_config)
    w, h = round.(Int, size(scene) .* device_scaling_factor(config))
    # create an image surface to draw onto the image
    img = Matrix{ARGB32}(undef, w, h)
    surface = Cairo.CairoImageSurface(img)
    return Screen(scene, surface, config)
end

function Screen(scene::Scene, surface::Cairo.CairoSurface, config::ScreenConfig)
    # the surface size is the scene size scaled by the device scaling factor
    dsf = device_scaling_factor(config)
    surface_set_device_scale(surface, dsf)
    ctx = Cairo.CairoContext(surface)
    aa = to_cairo_antialias(config.antialias)
    Cairo.set_antialias(ctx, aa)
    set_miter_limit(ctx, 2.0)
    return Screen{get_render_type(surface)}(scene, surface, ctx, dsf, aa, config.visible)
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
    img = Matrix{ARGB32}(undef, w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    s = Screen(scene, surf; device_scaling_factor=screen.device_scaling_factor, antialias=screen.antialias)
    return colorbuffer(s)
end

function Makie.colorbuffer(screen::Screen{IMAGE})
    empty!(screen)
    cairo_draw(screen, screen.scene)
    return PermutedDimsArray(screen.surface.data, (2, 1))
end

is_vector_backend(ctx::Cairo.CairoContext) = is_vector_backend(ctx.surface)
is_vector_backend(surf::Cairo.CairoSurface) = is_vector_backend(get_render_type(surf))
is_vector_backend(rt::RenderType) = rt in (PDF, EPS, SVG)
