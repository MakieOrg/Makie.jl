
# Time axis


\begin{examplefigure}{}
```julia
using CairoMakie, Unitful, Dates
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
ax = TimeAxis(f[1,1]; backgroundcolor=:white)
scatter!(ax, rand(Second(1):Second(60):Second(20*60), 10), 1:10)
f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
scatter!(ax, rand(Hour(1):Hour(1):Hour(20), 10), 1:10)
# scatter!(ax, rand(10), 1:10) # should error!
f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
f = Figure()
ax = TimeAxis(f[1,1]; backgroundcolor=:white)
ax.axis.finallimits
scatter!(ax, u"ns" .* (1:10), u"d" .* rand(10) .* 10)
f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
f = Figure()
ax = TimeAxis(f[1,1]; backgroundcolor=:white)
scatter!(ax, u"cm" .* (1:10), u"d" .* rand(10) .* 10)
f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
f = Figure()
ax = TimeAxis(f[1,1]; backgroundcolor=:white)
linesegments!(ax, 1:10, Nanosecond.(round.(LinRange(0, 4599800000000, 10))))
f
```
\end{examplefigure}
