# scatterlines

{{doc scatterlines}}
## Examples

Example demonstrating different jitter types in rows, with clamping and without in column, and different jitter widths in the rows.
\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


y = vcat([rand(k.*50).*5*k.+k for k = 1:5]...)

f = Figure()
	for (j,type) = enumerate([:uniform,:pseudorandom,:quasirandom])
        for (i,clamp) = enumerate([0.,0.3])
		ax = f[j,i] = Axis(f)
	    scatterjitter!(ax,ones(length(y)).*1,y;jitter_type=type,jitter_width=1.0,clamped_portion=clamp)
        scatterjitter!(ax,ones(length(y)).*2,y;jitter_type=type,jitter_width=0.2,clamped_portion=clamp)
        scatterjitter!(ax,ones(length(y)).*3,y;jitter_type=type,jitter_width=1.5,clamped_portion=clamp)
        end
	end
	
	f


f
```
\end{examplefigure}
