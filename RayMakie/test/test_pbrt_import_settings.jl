# `pbrt_to_makie` must carry the .pbrt's camera and integrator settings all the
# way into the objects that render, not just parse them into a NamedTuple.
#
# Two settings were parsed and then dropped, and both quietly changed the image:
#
#   * `lensradius` / `focaldistance` were never written to the Camera3D, so every
#     depth-of-field scene rendered as a pinhole.
#   * `regularize` and `maxcomponentvalue` were returned in
#     `integrator_settings` but nothing consumed them, so callers hand-built a
#     `VolPath` and inherited Hikari's defaults — which are the OPPOSITE of
#     pbrt-v4's on both counts:
#
#       regularize         pbrt false (cpu/integrators.cpp:817)  Hikari true
#       maxcomponentvalue  pbrt Infinity (film.cpp:576)          Hikari 10f0
#
#     Both roughen/clamp specular highlights, so a scene that omits them (crown
#     does) rendered with energy pushed out of its highlights: a 1.6 % global
#     deficit, concentrated entirely in the bright quintiles.
#
# This is a parse-and-construct test — no device, no rendering — so it runs in
# the CPU-only block of runtests.jl.
using Test
using RayMakie, Hikari, Makie

const SCENE = joinpath(@__DIR__, "pbrt_import_settings.pbrt")

# A scene that sets every knob to a NON-default value on both sides, so a
# dropped setting can't coincidentally match either renderer's default.
open(SCENE, "w") do io
    print(io, """
    LookAt 0 0 5   0 0 0   0 1 0
    Camera "perspective" "float fov" 30
        "float lensradius" 0.25
        "float focaldistance" 7.5
    Film "rgb" "integer xresolution" 64 "integer yresolution" 64
        "float maxcomponentvalue" 42
    Sampler "halton" "integer pixelsamples" 17
    Integrator "volpath" "integer maxdepth" 11 "bool regularize" true
    WorldBegin
    LightSource "point" "rgb I" [10 10 10] "point3 from" [0 0 3]
    Material "diffuse" "rgb reflectance" [0.5 0.5 0.5]
    Shape "trianglemesh"
      "point3 P" [ -1 -1 0  1 -1 0  1 1 0  -1 1 0 ]
      "integer indices" [ 0 1 2  0 2 3 ]
    """)
end

res = RayMakie.pbrt_to_makie(SCENE)

@testset "camera lens reaches Camera3D" begin
    cc = res.scene.camera_controls
    @test cc.lens_radius[] ≈ 0.25
    @test cc.focal_distance[] ≈ 7.5
end

@testset "integrator settings are parsed" begin
    s = res.integrator_settings
    @test s.max_depth == 11
    @test s.regularize == true
    @test s.max_component_value ≈ 42
end

@testset "VolPath(res) applies them" begin
    # The whole point: no keyword threading, and nothing falls back to Hikari's
    # defaults (regularize=true, max_component_value=10, max_depth=8).
    vp = Hikari.VolPath(res)
    @test vp.max_depth == 11
    @test vp.regularize == true
    @test vp.max_component_value ≈ 42
    @test vp.sensor === res.sensor
end

@testset "pbrt defaults win over Hikari's when the file is silent" begin
    # A file that sets NEITHER knob must come out with pbrt's defaults
    # (regularize off, no clamp), which is what crown.pbrt does. Hikari's own
    # defaults here would be `true` / `10f0`.
    quiet = joinpath(@__DIR__, "pbrt_import_defaults.pbrt")
    open(quiet, "w") do io
        print(io, """
        LookAt 0 0 5   0 0 0   0 1 0
        Camera "perspective" "float fov" 30
        Film "rgb" "integer xresolution" 64 "integer yresolution" 64
        Integrator "volpath" "integer maxdepth" 100
        WorldBegin
        LightSource "point" "rgb I" [10 10 10] "point3 from" [0 0 3]
        Material "diffuse" "rgb reflectance" [0.5 0.5 0.5]
        Shape "trianglemesh"
          "point3 P" [ -1 -1 0  1 -1 0  1 1 0  -1 1 0 ]
          "integer indices" [ 0 1 2  0 2 3 ]
        """)
    end
    r2 = RayMakie.pbrt_to_makie(quiet)
    vp = Hikari.VolPath(r2)
    @test vp.regularize == false
    @test isinf(vp.max_component_value)
    @test vp.max_depth == 100
    # A silent camera is a pinhole, not Hikari's 1e6-focal placeholder leaking in.
    @test r2.scene.camera_controls.lens_radius[] == 0.0
    rm(quiet; force=true)
end

@testset "explicit keywords still win" begin
    vp = Hikari.VolPath(res; regularize=false, max_depth=3, samples=99)
    @test vp.regularize == false
    @test vp.max_depth == 3
    @test vp.samples_per_pixel == 99
end

rm(SCENE; force=true)
