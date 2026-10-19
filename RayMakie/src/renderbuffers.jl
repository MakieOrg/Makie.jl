"""
    renderbuffers(screen; clear = true, samples = nothing, px_per_unit = nothing) -> NamedTuple

Trace the screen's scenes (`clear`, `samples` and `px_per_unit` as for
`colorbuffer`) and capture them, see [`capturebuffers`](@ref).
"""
function renderbuffers(screen::Screen; clear::Bool = true, samples = nothing, px_per_unit = nothing)
    screen.config.rasterize && error("HDR render buffers require raytracing")
    screen.config.denoise && error("capture HDR before destructive renderer denoising")
    isempty(screen.scene_states) && init_scene!(screen, screen.scene)
    setdensity!(screen, px_per_unit)
    trace!(screen; clear, samples)
    return capturebuffers(screen)
end

"""
    capturebuffers(screen) -> NamedTuple

The screen's films as linear Float32 radiance, first-hit guides (albedo, world
normal, depth), coverage and the raster overlay: DEVICE arrays, x-by-y (w×h),
that belong to the screen and are overwritten by its next capture. Not
denoised, tone-mapped or clamped, and nothing comes to the host: a caller
downloads what it keeps (a source master) and reads the rest where it is.
Raster annotations are a separate, display-referred premultiplied overlay.

Assembled by one kernel per traced scene. This used to download every film and
copy it pixel by pixel on the host, and to download and upload the whole output
image around the overlay pass.
"""
function capturebuffers(screen::Screen)
    h, w = size(screen.output_buffer)
    p = hdrplanes!(screen, w, h)
    background = scenebackground(screen.scene)
    bg_a = Float32(alpha(background))
    fill!(p.color, linearrgb(background))
    fill!(p.albedo, RGB{Float32}(0, 0, 0))
    fill!(p.normal, Vec3f(0))
    fill!(p.depth, Inf32)
    fill!(p.coverage, bg_a)
    for state in screen.scene_states
        composites(state) || continue
        sky = fillauxbuffers!(screen, state)
        film = state.film
        vh, vw = size(film.framebuffer)
        vp = scene_viewport_px(state.makie_scene, screen.px_per_unit)
        vx, vy = vp.origin
        row0 = state.makie_scene === screen.scene ? 1 : h - round(Int, max(0, vy)) - vh + 1
        col0 = state.makie_scene === screen.scene ? 1 : round(Int, max(0, vx)) + 1
        capturefilm_kernel!(KernelAbstractions.get_backend(p.color))(
            p.color, p.albedo, p.normal, p.depth, p.coverage,
            film.framebuffer, film.albedo, film.normal, film.depth,
            row0, col0, linearrgb(scenebackground(state.makie_scene)), sky, bg_a; ndrange = (vh, vw))
    end
    overlayplane!(p, screen)
    return (
        color = p.color, albedo = p.albedo, normal = p.normal, depth = p.depth,
        coverage = p.coverage, overlay = p.overlay,
        metadata = Dict{String, Any}(
            "color_space" => "linear-sRGB", "sensor_calibrated" => true,
            "albedo_valid" => isdefined(Hikari, :guide_hit), "normal_valid" => isdefined(Hikari, :guide_hit),
            "normal_space" => "world", "guide_version" => 1,
            "guide_policy" => "first opaque centre hit; alpha threshold 0.5; texture/base reflectance; bounded mixes; white specular fallback"
        ),
    )
end

"""An sRGB-encoded colour (a background) as the linear radiance the film holds."""
function linearrgb(c)
    linear(v) = v <= 0.04045f0 ? v / 12.92f0 : ((v + 0.055f0) / 1.055f0)^2.4f0
    return RGB{Float32}(linear(Float32(red(c))), linear(Float32(green(c))), linear(Float32(blue(c))))
end

"""
One traced scene's film into the capture planes, at its viewport (`row0`,
`col0`: the film's first row and column in the output, which is h×w while the
planes are w×h). Escaped rays show the scene's background unless a light paints
the sky; coverage is the postprocess's: the background's alpha plus what the
rays hit, the hit fraction over the 3×3 neighbourhood (`Hikari.postprocess!`).
"""
@kernel function capturefilm_kernel!(color, albedo, normal, depth, coverage,
                                     @Const(rad), @Const(alb), @Const(nrm), @Const(dep),
                                     row0::Int, col0::Int, bglinear::RGB{Float32}, sky::Bool, bg_a::Float32)
    r, c = @index(Global, NTuple)
    vh, vw = size(dep)
    w, h = size(depth)
    row = row0 + r - 1
    col = col0 + c - 1
    if 1 <= row <= h && 1 <= col <= w
        @inbounds begin
            d = dep[r, c]
            color[col, row] = Hikari.missed(d) && !sky ? bglinear : rad[r, c]
            albedo[col, row] = alb[r, c]
            normal[col, row] = nrm[r, c]
            depth[col, row] = d
            escaped = 0
            total = 0
            for dc in -1:1, dr in -1:1
                nr = r + dr
                nc = c + dc
                if 1 <= nr <= vh && 1 <= nc <= vw
                    escaped += Int(Hikari.missed(dep[nr, nc]))
                    total += 1
                end
            end
            a = escaped == total ? 1f0 : Float32(escaped) / Float32(total)
            coverage[col, row] = bg_a + (1f0 - bg_a) * (1f0 - a)
        end
    end
end

"""
The raster overlay alone into `p.overlay`: the overlay pass drawn over a blank
image instead of the traced one, read back on the device. Zero where nothing is
drawn.
"""
function overlayplane!(p, screen::Screen)
    if any(ss -> !isempty(collect_overlay_robjs(ss, screen.scene, screen.rasterize)), screen.scene_states)
        out = overlayreadback!(screen, :overlay, p.blank)
        overlaypixels_kernel!(KernelAbstractions.get_backend(p.overlay))(
            p.overlay, Mantle.storage(out.result); ndrange = length(p.overlay))
    else
        fill!(p.overlay, RGBA{Float32}(0, 0, 0, 0))
    end
    return p
end

"""The read-back overlay (column-major w×h, `COMPOSITE_FORMAT`) as Float32 RGBA."""
@kernel function overlaypixels_kernel!(dst, @Const(src))
    i = @index(Global, Linear)
    @inbounds dst[i] = RGBA{Float32}(src[i])
end

"""
The capture planes of a w×h output, the screen's and reused frame to frame, and
the blank image the overlay alone is drawn over.
"""
function hdrplanes!(screen::Screen, w::Int, h::Int)
    p = screen.hdrplanes
    p !== nothing && size(p.color) == (w, h) && return p
    freehdrplanes!(screen)
    dev = screen.config.device
    plane(T) = KernelAbstractions.allocate(dev, T, w, h)
    blank = fill!(similar(screen.output_buffer), RGBA{Float32}(0, 0, 0, 0))
    screen.hdrplanes = (color = plane(RGB{Float32}), albedo = plane(RGB{Float32}), normal = plane(Vec3f),
                        depth = plane(Float32), coverage = plane(Float32), overlay = plane(RGBA{Float32}),
                        blank)
    return screen.hdrplanes
end

function freehdrplanes!(screen::Screen)
    p = screen.hdrplanes
    p === nothing || foreach(KernelAbstractions.unsafe_free!, p)
    screen.hdrplanes = nothing
    return screen
end

"""
    refreshguidebuffers!(screen)

Trace centre primary rays only. No radiance sampling, denoising or tonemapping.
Used to upgrade cached guides while keeping the original HDR radiance intact.
"""
function refreshguidebuffers!(screen::Screen)
    screen.config.rasterize && error("guide refresh requires a traced scene")
    isempty(screen.scene_states) && init_scene!(screen, screen.scene)
    for state in screen.scene_states
        composites(state) && Hikari.sync!(state.hikari_scene)
    end
    # The capture fills the guides from primary rays itself (`fillauxbuffers!`)
    # and traces nothing: the film's radiance is whatever it holds.
    return capturebuffers(screen)
end
