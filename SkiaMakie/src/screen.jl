using Base.Docs: doc

@enum RenderType IMAGE SVG PDF

function Base.convert(::Type{RenderType}, type::String)
    type == "png" && return IMAGE
    type == "svg" && return SVG
    type == "pdf" && return PDF
    error("Unsupported SkiaMakie render type: $type")
end

function to_mime(type::RenderType)
    type == SVG && return MIME("image/svg+xml")
    type == PDF && return MIME("application/pdf")
    return MIME("image/png")
end

"""
* `px_per_unit = 2.0`
* `pt_per_unit = 0.75`
* `antialias::Symbol = :best`
* `visible::Bool`: if true, an image viewer will open to display rendered output.
"""
struct ScreenConfig
    px_per_unit::Float64
    pt_per_unit::Float64
    antialias::Symbol
    visible::Bool
    start_renderloop::Bool

    function ScreenConfig(
            px_per_unit::Real, pt_per_unit::Real,
            antialias::Symbol, visible::Bool, start_renderloop::Bool
        )
        return new(px_per_unit, pt_per_unit, antialias, visible, start_renderloop)
    end
end

function device_scaling_factor(::Type{<:RenderType}, sc::ScreenConfig)
    return sc.px_per_unit
end
function device_scaling_factor(rt::RenderType, sc::ScreenConfig)
    rt === SVG && return sc.pt_per_unit / 0.75
    rt === PDF && return sc.pt_per_unit
    return sc.px_per_unit
end

const LAST_INLINE = Ref{Union{Makie.Automatic, Bool}}(Makie.automatic)

"""
    SkiaMakie.activate!(; screen_config...)

Sets SkiaMakie as the currently active backend.
"""
function activate!(; inline = LAST_INLINE[], type = "png", screen_config...)
    Makie.inline!(inline)
    LAST_INLINE[] = inline
    Makie.set_screen_config!(SkiaMakie, screen_config)
    if type == "png"
        disable_mime!("svg", "pdf")
    elseif type == "svg"
        disable_mime!("text/html", "application/vnd.webio.application+html",
            "application/prs.juno.plotpane+html", "juliavscode/html")
    else
        enable_only_mime!(type)
    end
    Makie.set_active_backend!(SkiaMakie)
    return
end

"""
    Screen(; screen_config...)

$(Base.doc(ScreenConfig))
$(Base.doc(MakieScreen))
"""
mutable struct Screen{SurfaceRenderType} <: Makie.MakieScreen
    scene::Scene
    # Skia resources — surface may be C_NULL for SVG (canvas-only)
    surface::Ptr{Skia.sk_surface_t}
    canvas::Ptr{Skia.sk_canvas_t}
    width::Int
    height::Int
    device_scaling_factor::Float64
    visible::Bool
    config::ScreenConfig

    function Screen()
        return new{IMAGE}()
    end
    function Screen{RT}(
            scene, surface, canvas, w, h, dsf, visible, config
        ) where {RT}
        return new{RT}(scene, surface, canvas, w, h, dsf, visible, config)
    end
end

function Base.empty!(screen::Screen)
    isopen(screen) || return
    bg = rgbatuple(screen.scene.backgroundcolor[])
    sk_canvas_clear(screen.canvas, to_skia_color(bg...))
    return
end

Base.close(screen::Screen) = empty!(screen)

function destroy!(screen::Screen)
    # Skia objects are ref-counted C pointers; we don't have explicit destroy
    # for surfaces in the Julia wrapper, so we just null them out
    screen.surface = Ptr{Skia.sk_surface_t}(C_NULL)
    screen.canvas = Ptr{Skia.sk_canvas_t}(C_NULL)
    return
end

function Base.isopen(screen::Screen)
    return screen.canvas != C_NULL
end

function Base.size(screen::Screen)
    isdefined(screen, :width) || return (0, 0)
    return (screen.width, screen.height)
end

Base.insert!(screen::Screen, scene::Scene, plot) = nothing
function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot) end

function Base.show(io::IO, ::MIME"text/plain", screen::Screen{S}) where {S}
    return println(io, "SkiaMakie.Screen{$S}")
end

function scaled_scene_resolution(typ::RenderType, config::ScreenConfig, scene::Scene)
    dsf = device_scaling_factor(typ, config)
    return round.(Int, Makie.size(scene) .* dsf)
end

function Screen(scene::Scene; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(scene, config)
end

Screen(scene::Scene, config::ScreenConfig) = Screen(scene, config, nothing, IMAGE)

function Screen(scene::Scene, config::ScreenConfig, io_or_path::Union{Nothing, String, IO}, typ::Union{MIME, Symbol, RenderType})
    rtype = typ isa RenderType ? typ : convert(RenderType, string(typ))
    w, h = scaled_scene_resolution(rtype, config, scene)
    return create_screen(scene, config, rtype, w, h, io_or_path)
end

function Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat)
    w, h = scaled_scene_resolution(IMAGE, config, scene)
    return create_screen(scene, config, IMAGE, w, h, nothing)
end

function create_screen(scene, config, rtype::RenderType, w, h, io_or_path)
    dsf = device_scaling_factor(rtype, config)

    if rtype === IMAGE
        surface, canvas = make_raster_surface(w, h)
        # Apply device scale: the surface has w*dsf × h*dsf pixels but Makie
        # draws in scene coordinates (w × h). This mirrors Cairo's
        # surface_set_device_scale which applies a hidden base scaling.
        sk_canvas_scale(canvas, Float32(dsf), Float32(dsf))
        return Screen{IMAGE}(scene, surface, canvas, w, h, dsf, config.visible, config)
    elseif rtype === SVG
        # SVG: use file wstream → canvas (no surface)
        error("SVG output not yet implemented in SkiaMakie")
    elseif rtype === PDF
        error("PDF output not yet implemented in SkiaMakie")
    else
        error("Unsupported render type: $rtype")
    end
end

function Makie.apply_screen_config!(
        screen::Screen{SCREEN_RT}, config::ScreenConfig, scene::Scene, io::Union{Nothing, IO}, m::MIME{SYM}
    ) where {SYM, SCREEN_RT}
    new_rendertype = convert(RenderType, string(SYM))
    new_resolution = scaled_scene_resolution(new_rendertype, config, scene)
    if SCREEN_RT !== new_rendertype || is_vector_backend(new_rendertype) || Base.size(screen) != new_resolution
        old_screen = screen
        screen = Screen(scene, config, io, new_rendertype)
        destroy!(old_screen)
    end
    screen.scene = scene
    screen.config = config
    screen.device_scaling_factor = device_scaling_factor(new_rendertype, config)
    return screen
end

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, scene::Scene, args...)
    return Makie.apply_screen_config!(screen, config, scene, nothing, MIME"image/png"())
end

function Makie.px_per_unit(s::Screen)::Float64
    return s.config.px_per_unit
end

########################################
#    Fast colorbuffer for recording    #
########################################

function Makie.colorbuffer(screen::Screen; figure = nothing)
    scene = screen.scene
    w, h = Base.size(screen)
    scr = Screen(scene, screen.config, nothing, IMAGE)
    return Makie.colorbuffer(scr)
end

function Makie.colorbuffer(screen::Screen{IMAGE}; figure = nothing)
    Makie.push_screen!(screen.scene, screen)
    empty!(screen)
    skia_draw(screen, screen.scene)
    w, h = Base.size(screen)
    pixels = read_surface_pixels(screen.surface, w, h)
    # Convert from Skia RGBA UInt32 to ARGB32 for Makie
    # Skia RGBA_8888: R in low byte, A in high byte  → 0xAABBGGRR
    # Makie ARGB32:   A in high byte, R next         → 0xAARRGGBB
    result = Matrix{ARGB32}(undef, w, h)
    for j in 1:h, i in 1:w
        px = pixels[i, j]
        r = (px >>  0) & 0xFF
        g = (px >>  8) & 0xFF
        b = (px >> 16) & 0xFF
        a = (px >> 24) & 0xFF
        # un-premultiply
        if a > 0
            r = min(UInt32(255), div(r * 255, a))
            g = min(UInt32(255), div(g * 255, a))
            b = min(UInt32(255), div(b * 255, a))
        end
        result[i, j] = ARGB32(reinterpret(N0f8, UInt8(r)), reinterpret(N0f8, UInt8(g)),
            reinterpret(N0f8, UInt8(b)), reinterpret(N0f8, UInt8(a)))
    end
    return PermutedDimsArray(result, (2, 1))
end

is_vector_backend(rt::RenderType) = rt in (PDF, SVG)

Base.resize!(screen::Screen, w, h) = nothing
