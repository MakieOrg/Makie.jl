# hexbin

{{doc hexbin}}

## Examples
### Standard
\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide


x = randn(100000)
y = randn(100000)

hexbin(x,y)
```
\end{examplefigure}

### Changing the bin size

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

x = randn(100000)
y = randn(100000)

hexbin(x,y,colormap=:heat, gridsize=50)
```
\end{examplefigure}

### Changing the minimal shown value

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

x = randn(100000)
y = randn(100000)

hexbin(x,y,colormap=:heat,gridsize=50,mincnt=1)
```
\end{examplefigure}



### Changing the scale of the number of observations in a bin

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

x = randn(100000)
y = randn(100000)

hexbin(x,y,colormap=:rainbow,gridsize=50,mincnt=1, scale=log10)
```
\end{examplefigure}

### Full figure
\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
x = randn(100000)
y = randn(100000)
fig = Figure()
ax = Axis(fig[1,1],title="mincnt=1")
hexbin!(ax, x,y,colormap=:heat, gridsize=20,mincnt=1)

ax2=Axis(fig[1,2],limits=(-2,2,-2,2),title="Axis limits")
hexbin!(ax2, x,y,colormap=:haline,gridsize=40,mincnt=0)

ax3=Axis(fig[2,1],title="With colorbar")
hb = hexbin!(ax3,x,y,colormap=:inferno, gridsize=50,mincnt=0)
Colorbar(fig[3,1],hb, vertical=false,label="Number of observations in a bin")

ax4=Axis(fig[2,2],title="Log scale")
hb2 = hexbin!(ax4,x,y,colormap=:rainbow, gridsize=50,mincnt=1,scale=Makie.pseudolog10)
cb=Colorbar(fig[3,2],hb2,vertical=false, scale=Makie.pseudolog10)
cb.tickformat=x->"10^".*string.(x)
```
\end{examplefigure}