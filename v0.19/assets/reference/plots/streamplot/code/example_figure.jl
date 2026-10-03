# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


struct FitzhughNagumo{T}
    ϵ::T
    s::T
    γ::T
    β::T
end

P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)

f(x, P::FitzhughNagumo) = Point2f(
    (x[1]-x[2]-x[1]^3+P.s)/P.ϵ,
    P.γ*x[1]-x[2] + P.β
)

f(x) = f(x, P)

fig, ax, pl = streamplot(f, -1.5..1.5, -1.5..1.5, colormap = :magma)
# you can also pass a function to `color`, to either return a number or color value
streamplot(fig[1,2], f, -1.5 .. 1.5, -1.5 .. 1.5, color=(p)-> RGBAf(p..., 0.0, 1))
fig
end # hide
save(joinpath(@OUTPUT, "example_14626251530112261731.png"), __result; ) # hide

nothing # hide