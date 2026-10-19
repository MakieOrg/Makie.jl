"""
    renderbuffers(screen) -> NamedTuple

Capture linear Float32 radiance and first-hit guides after rendering. Does not
denoise, tone-map or clamp radiance. Raster annotations remain a separate,
display-referred premultiplied overlay. Arrays use Makie's x-by-y orientation.
"""
function renderbuffers(screen::Screen)
    screen.config.rasterize && error("HDR render buffers require raytracing")
    screen.config.denoise && error("capture HDR before destructive renderer denoising")
    h, w = size(screen.output_buffer)
    linear(v) = v <= 0.04045f0 ? v / 12.92f0 : ((v + 0.055f0) / 1.055f0)^2.4f0
    background = scenebackground(screen.scene)
    color = fill(RGB{Float32}(linear(background.r), linear(background.g), linear(background.b)), h, w)
    albedo = zeros(RGB{Float32}, h, w); normal = zeros(Vec3f, h, w)
    depth = fill(Inf32, h, w); coverage = fill(Float32(background.alpha), h, w)
    for state in screen.scene_states
        composites(state) || continue
        film = state.film
        rad = Array(film.framebuffer); alb = Array(film.albedo); nrm = Array(film.normal)
        dep = Array(film.depth); alpha = Array(film.postprocess)
        vh, vw = size(rad)
        vp = scene_viewport_px(state.makie_scene, screen.px_per_unit)
        vx, vy = vp.origin
        row0 = state.makie_scene === screen.scene ? 1 : h - round(Int, max(0, vy)) - vh + 1
        col0 = state.makie_scene === screen.scene ? 1 : round(Int, max(0, vx)) + 1
        bg = scenebackground(state.makie_scene)
        bglinear = RGB{Float32}(linear(bg.r), linear(bg.g), linear(bg.b))
        sky = any(paints_background, state.hikari_scene.lights.data_order)
        for y in 1:vw, x in 1:vh
            xx = row0 + x - 1; yy = col0 + y - 1
            1 <= xx <= h && 1 <= yy <= w || continue
            color[xx, yy] = Hikari.missed(dep[x, y]) && !sky ? bglinear : rad[x, y]
            albedo[xx, yy] = alb[x, y]; normal[xx, yy] = nrm[x, y]
            depth[xx, yy] = dep[x, y]; coverage[xx, yy] = alpha[x, y].alpha
        end
    end
    overlay = zeros(RGBA{Float32}, h, w)
    if any(ss -> !isempty(collect_overlay_robjs(ss, screen.scene, screen.rasterize)), screen.scene_states)
        saved = Array(screen.output_buffer)
        try
            fill!(screen.output_buffer, zero(RGBA{Float32}))
            overlay = composited_frame(screen)
        finally
            copyto!(screen.output_buffer, saved)
        end
    end
    orient(x) = permutedims(x)
    return (
        color = orient(color), albedo = orient(albedo), normal = orient(normal),
        depth = orient(depth), coverage = orient(coverage), overlay = orient(overlay),
        metadata = Dict(
            "color_space" => "linear-sRGB", "sensor_calibrated" => true,
            "albedo_valid" => isdefined(Hikari, :guide_hit), "normal_valid" => isdefined(Hikari, :guide_hit),
            "normal_space" => "world", "guide_version" => 1,
            "guide_policy" => "first opaque centre hit; alpha threshold 0.5; texture/base reflectance; bounded mixes; white specular fallback"
        ),
    )
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
        state.overlay_only && continue
        Hikari.sync!(state.hikari_scene)
        adapted = Adapt.adapt(screen.config.device, state.hikari_scene)
        has_inf = any(Hikari.is_infinite_light, state.hikari_scene.lights.data_order)
        if Raycore.n_instances(get_tlas(state)) == 0
            fill!(state.film.depth, has_inf ? Hikari.MISS_DEPTH : Inf32)
            fill!(state.film.normal, Vec3f(0))
            fill!(state.film.albedo, RGB{Float32}(0, 0, 0))
        else
            Hikari.fill_aux_buffers!(state.film, adapted, state.camera[]; has_infinite_lights = has_inf)
        end
    end
    return renderbuffers(screen)
end
