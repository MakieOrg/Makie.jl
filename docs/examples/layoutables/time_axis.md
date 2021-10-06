
# Time axis


\begin{examplefigure}{}
```julia
using CairoMakie, Unitful, Dates
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
ax = Axis(f[1,1])
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
scatter!(ax, rand(1u"yr":1u"yr":20u"yr", 10), 1:10)
f
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
f = Figure()
scatter!(Axis(f[1,1]), u"ns" .* (1:10), u"d" .* rand(10) .* 10)
f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
f = Figure()
scatter!(Axis(f[1,1]), u"cm" .* (1:10), u"d" .* rand(10) .* 10)
f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
f = Figure()
linesegments!(Axis(f[1,1]), 1:10, Nanosecond.(round.(LinRange(0, 4599800000000, 10))))
f
```
\end{examplefigure}
