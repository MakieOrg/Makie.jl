using Test
using Makie, GeometryBasics, Hikari, RayMakie
using Makie: Scene, cam3d!, mesh!, Point3f, Sphere
using RayMakie: extract_material, color_was_set

# What `material = ...` on a plot is allowed to survive.
#
# `color` is a CYCLED attribute, so Makie never leaves it unset in
# `attributes.inputs` — `resolve_cycled!` writes the symbol `:cycled` for every
# cycled attribute the user did not assign. `extract_material` used to decide
# "did the user give a colour?" with `!== nothing`, which is true for `:cycled`
# too, so it merged the palette colour over the material on every plot. The
# material was accepted, converted and uploaded, and then overwritten: asking for
# `Diffuse(Kd = green)` rendered the cycler's blue.
#
# Asserted on `extract_material` rather than on pixels because the failure is a
# precedence decision, not a shading one — and a pixel test for it would need a
# GPU to say something these three lines already say exactly.

const GREEN = Hikari.RGBSpectrum(0.05f0, 0.95f0, 0.05f0)
const ORANGE_TEX = Hikari.ConstTexture(Hikari.RGBSpectrum(1.0f0, 0.65f0, 0.0f0))

kd_of(mat) = Hikari.device_param(nothing, mat.Kd)

@testset "material/color precedence" begin
    @testset "color_was_set distinguishes :cycled from a real colour" begin
        scene = Scene(); cam3d!(scene)
        no_color = mesh!(scene, Sphere(Point3f(0), 1.0f0); material=Hikari.Diffuse(Kd=GREEN))
        with_color = mesh!(scene, Sphere(Point3f(0), 1.0f0); color=:orange)

        # The exact shape of the bug: unset is `:cycled`, and it is not nothing.
        @test no_color.attributes.inputs[:color].value === :cycled
        @test no_color.attributes.inputs[:color].value !== nothing

        @test !color_was_set(no_color)
        @test color_was_set(with_color)
    end

    @testset "a material with no colour is returned untouched" begin
        scene = Scene(); cam3d!(scene)
        plot = mesh!(scene, Sphere(Point3f(0), 1.0f0); material=Hikari.Diffuse(Kd=GREEN))
        mat = extract_material(plot, ORANGE_TEX)
        @test mat isa Hikari.Diffuse
        # Green, not the cycled palette colour the texture carries.
        @test kd_of(mat).rgb == GREEN
    end

    @testset "an explicit colour still merges over the material" begin
        scene = Scene(); cam3d!(scene)
        plot = mesh!(scene, Sphere(Point3f(0), 1.0f0);
                     color=:orange, material=Hikari.Diffuse(Kd=GREEN))
        mat = extract_material(plot, ORANGE_TEX)
        @test mat isa Hikari.Diffuse
        @test kd_of(mat).rgb == Hikari.RGBSpectrum(1.0f0, 0.65f0, 0.0f0)
    end

    @testset "a colour with no material still builds a Diffuse" begin
        scene = Scene(); cam3d!(scene)
        plot = mesh!(scene, Sphere(Point3f(0), 1.0f0); color=:orange)
        mat = extract_material(plot, ORANGE_TEX)
        @test mat isa Hikari.Diffuse
        @test kd_of(mat).rgb == Hikari.RGBSpectrum(1.0f0, 0.65f0, 0.0f0)
    end
end
