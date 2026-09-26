# This file was generated, do not modify it. # hide
__result = begin # hide
  
using FileIO
using GLMakie
GLMakie.activate!() # hide
catmesh = FileIO.load(assetpath("cat.obj"))
gold = FileIO.load(download("https://raw.githubusercontent.com/nidorx/matcaps/master/1024/E6BF3C_5A4719_977726_FCFC82.png"))

mesh(catmesh, matcap=gold, shading=false)

  end # hide
  save(joinpath(@OUTPUT, "example_11281650883990564318.png"), __result) # hide
  
  nothing # hide