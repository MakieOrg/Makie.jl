# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
using CairoMakie # hide
CairoMakie.activate!() # hide

f = Figure()

tb = Textbox(f[2, 1], placeholder = "Enter a frequency",
    validator = Float64, tellwidth = false)

frequency = Observable(1.0)

on(tb.stored_string) do s
    frequency[] = parse(Float64, s)
end

xs = 0:0.01:10
sinecurve = @lift(sin.($frequency .* xs))

lines(f[1, 1], xs, sinecurve)

f
end # hide
save(joinpath(@OUTPUT, "example_877434523072579138.png"), __result; ) # hide

nothing # hide