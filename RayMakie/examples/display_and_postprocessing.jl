# =============================================================================
# RayMakie: display(), postprocessing, filtering, and denoising
#
# All examples use display() which opens an interactive window and renders
# progressively (1 sample per frame). Camera rotation/zoom/pan resets
# accumulation automatically.
# =============================================================================

using RayMakie, Hikari, GeometryBasics, Colors, Lava

function demo_scene()
    lights = [
        PointLight(RGBf(80, 80, 80), Vec3f(5, 5, 8)),
        PointLight(RGBf(30, 30, 30), Vec3f(-3, -5, 4)),
    ]
    scene = Scene(; size=(800, 600), lights, ambient=RGBf(0.02, 0.02, 0.02))
    cam3d!(scene)

    mesh!(scene, Rect3f(Vec3f(-5, -5, -0.01), Vec3f(10, 10, 0.01));
          material=Hikari.Diffuse(Kd=(0.7, 0.7, 0.7)))
    mesh!(scene, Sphere(Point3f(-1.0, 0, 0.5), 0.5f0);
          material=Hikari.Gold(roughness=0.05))
    mesh!(scene, Sphere(Point3f(0.5, 0, 0.5), 0.5f0);
          material=Hikari.Dielectric(Kt=(1, 1, 1), index=1.5))
    mesh!(scene, Sphere(Point3f(2.0, 0, 0.5), 0.5f0);
          material=Hikari.Plastic(color=(0.2, 0.4, 0.8), roughness=0.1))

    cam = cameracontrols(scene)
    cam.eyeposition[] = Vec3f(0, -5, 3)
    cam.lookat[] = Vec3f(0.5, 0, 0.3)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(scene, cam)
    return scene
end


# =============================================================================
# 1. Default display -- opens window, renders progressively
# =============================================================================

screen = display(demo_scene(); backend=RayMakie)
# close(screen)


# =============================================================================
# 2. Postprocessing: exposure, tonemapping, gamma
#
#    These are display-side transforms on the linear HDR framebuffer.
#    Pipeline: framebuffer -> exposure -> tonemap -> gamma -> output
#
#    Tonemapping operators:
#      :aces            ACES filmic (default, industry standard)
#      :reinhard        simple L/(1+L)
#      :reinhard_ext    extended Reinhard with white point
#      :uncharted2      Uncharted 2 / John Hable filmic
#      :filmic          Hejl-Dawson filmic
#      nothing          no tonemapping (linear clamp to [0,1])
# =============================================================================

# ACES with default exposure (the default)
screen = display(demo_scene(); backend=RayMakie,
    exposure=1.0f0, tonemap=:aces, gamma=2.2f0,
)

# Bright exposure + Reinhard
screen = display(demo_scene(); backend=RayMakie,
    exposure=3.0f0, tonemap=:reinhard,
)

# Linear output (no tonemap, no gamma -- for compositing)
screen = display(demo_scene(); backend=RayMakie,
    exposure=0.5f0, tonemap=nothing, gamma=nothing,
)


# =============================================================================
# 3. Pixel reconstruction filter
#
#    The filter controls how sub-pixel samples are combined into pixels.
#    Set via the `filter` kwarg on the integrator (VolPath).
#
#    BoxFilter()                        -- sharp, aliased (1 sample = 1 pixel)
#    TriangleFilter()                   -- simple tent, mild AA
#    GaussianFilter()                   -- soft, good default (pbrt-v4 default)
#    MitchellFilter(; B=1/3, C=1/3)    -- cubic, good sharpness/ringing tradeoff
#    LanczosSincFilter(; tau=3)         -- sharpest, slight ringing
# =============================================================================

# Default: Gaussian (radius 1.5, sigma 0.5) -- smooth, minimal aliasing
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64,
        filter=Hikari.GaussianFilter(),
    ),
)

# Box filter -- each sample contributes only to its pixel (sharp but aliased)
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64,
        filter=Hikari.BoxFilter(),
    ),
)

# Mitchell-Netravali -- good sharpness with minimal ringing
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64,
        filter=Hikari.MitchellFilter(),
    ),
)

# Lanczos sinc -- sharpest reconstruction, slight ringing at high-contrast edges
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64,
        filter=Hikari.LanczosSincFilter(),
    ),
)


# =============================================================================
# 4. Denoising (a-trous wavelet filter)
#
#    Uses normals + depth auxiliary buffers to preserve edges while
#    smoothing Monte Carlo noise. Most useful at low sample counts (1-8 spp).
#
#    Set via `denoise=true` and optionally `denoise_config=DenoiseConfig(...)`.
#    DenoiseConfig fields:
#      iterations     -- filter passes, each doubles radius (default: 5)
#      sigma_color    -- color edge sensitivity (default: 4.0, lower = sharper)
#      sigma_normal   -- normal edge sensitivity (default: 128.0)
#      sigma_depth    -- depth edge sensitivity (default: 1.0)
# =============================================================================

# Denoising with defaults (good general-purpose settings)
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64),
    denoise=true,
)

# Aggressive denoising -- very smooth, may lose fine detail
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64),
    denoise=true,
    denoise_config=Hikari.DenoiseConfig(
        iterations=7,
        sigma_color=8.0f0,
        sigma_normal=256.0f0,
        sigma_depth=2.0f0,
    ),
)

# Conservative denoising -- preserves detail, mainly removes fireflies
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64),
    denoise=true,
    denoise_config=Hikari.DenoiseConfig(
        iterations=3,
        sigma_color=2.0f0,
        sigma_normal=64.0f0,
        sigma_depth=0.5f0,
    ),
)


# =============================================================================
# 5. Re-apply postprocessing without re-rendering
#
#    After accumulating samples, tweak exposure/tonemap/gamma instantly.
#    RayMakie.postprocess!() re-processes the existing HDR framebuffer.
# =============================================================================

screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64),
    exposure=1.0f0, tonemap=:aces,
)
# Let it accumulate a few samples, then tweak:
#   RayMakie.postprocess!(screen; exposure=0.3f0)
#   RayMakie.postprocess!(screen; exposure=2.0f0, tonemap=:filmic)
#   RayMakie.postprocess!(screen; tonemap=nothing, gamma=nothing)


# =============================================================================
# 6. Sensor simulation (ISO, white balance, exposure time)
#
#    The PixelSensor simulates a physical camera sensor (pbrt-v4 style).
#    This affects how spectral light transport maps to pixel values during
#    path tracing -- different from postprocessing exposure.
#    Set via the `sensor` kwarg on the integrator.
# =============================================================================

# High ISO (brighter sensor, like cranking up camera sensitivity)
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64,
        sensor=Hikari.PixelSensor(iso=400)),
)

# D65 daylight white balance (6500K)
screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64,
        sensor=Hikari.PixelSensor(iso=100, whitebalance=6500f0)),
)


# =============================================================================
# 7. Hardware ray tracing (Vulkan RT cores)
# =============================================================================

screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(samples=64, hw_accel=true),
)


# =============================================================================
# 8. Combined: everything together
# =============================================================================

screen = display(demo_scene(); backend=RayMakie,
    integrator=Hikari.VolPath(
        samples=64,
        max_depth=8,
        hw_accel=true,
        filter=Hikari.MitchellFilter(),
        sensor=Hikari.PixelSensor(iso=100, whitebalance=6500f0),
    ),
    exposure=1.2f0,
    tonemap=:aces,
    gamma=2.2f0,
    denoise=true,
    denoise_config=Hikari.DenoiseConfig(iterations=5, sigma_color=4.0f0),
)
