# This file was generated, do not modify it. # hide
__result = begin # hide
    GLMakie.activate!() # hide
# Now, rotate the "joints"
rotate!(s2, Vec3f(0, 1, 0), 0.5)
rotate!(s3, Vec3f(1, 0, 0), 0.5)
parent
end # hide
save(joinpath(@OUTPUT, "example_11571802228848375181.png"), __result) # hide

nothing # hide