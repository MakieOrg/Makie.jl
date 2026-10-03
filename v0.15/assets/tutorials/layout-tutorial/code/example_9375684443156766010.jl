# This file was generated, do not modify it. # hide
__result = begin # hide
  
brain = load(assetpath("brain.stl"))

Axis3(gc[1, 1], title = "Brain activation")
m = mesh!(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:magma),
)
Colorbar(gc[1, 2], m, label = "BOLD level")

f

  end # hide
  save(joinpath(@OUTPUT, "example_9375684443156766010.png"), __result) # hide
  
  nothing # hide