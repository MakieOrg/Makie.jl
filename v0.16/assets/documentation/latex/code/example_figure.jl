# This file was generated, do not modify it. # hide
__result = begin # hide
    scatter(randn(50, 2), axis = (; title = L"\frac{x + y}{\sin(k^2)}"))
end # hide
save(joinpath(@OUTPUT, "example_270713340373674549.png"), __result) # hide
save(joinpath(@OUTPUT, "example_270713340373674549.svg"), __result) # hide
nothing # hide