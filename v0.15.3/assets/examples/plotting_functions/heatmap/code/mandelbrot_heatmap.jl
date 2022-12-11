# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

function mandelbrot(x, y)
    z = c = x + y*im
    for i in 1:30.0; abs(z) > 2 && return i; z = z^2 + c; end; 0
end

heatmap(-2:0.1:1, -1.1:0.1:1.1, mandelbrot,
    colormap = Reverse(:deep))

  end # hide
  save(joinpath(@OUTPUT, "mandelbrot_heatmap.png"), __result) # hide
  
  nothing # hide