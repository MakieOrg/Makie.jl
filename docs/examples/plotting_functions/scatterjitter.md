# scatterlines

{{doc scatterlines}}
## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


y = vcat([rand(k.*50).*5*k.+k for k = 1:5]...)

f = Figure()
	for (i,type) = enumerate([:uniform,:pseudorandom,:quasirandom])
        for (j,clamp) = enumerate([0.,0.3])
		ax = f[j,i] = Axis(f)
	    scatterjitter!(ax,ones(length(y)).*1,y;jitter_type=type,jitter_width=1.0,clamped_portion=clamp)
        scatterjitter!(ax,ones(length(y)).*2,y;jitter_type=type,jitter_width=0.2,clamped_portion=clamp)
        scatterjitter!(ax,ones(length(y)).*2,y;jitter_type=type,jitter_width=1.5,clamped_portion=clamp)
        end
	end
	
	f


f
```
\end{examplefigure}
