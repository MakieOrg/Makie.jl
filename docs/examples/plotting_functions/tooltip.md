# tooltip

{{doc tooltip}}

## Examples

### Basic tooltip

\begin{examplefigure}{svg = true}
```julia
fig, ax, p = scatter(Point2f(0), marker = 'x', markersize = 20)
# p[1] is the first argument of the scatter plot, i.e. Point2f(0), wrapped in
# an Observable.
tooltip!(p[1], "This is a tooltip pointing at x")
fig
```
\end{examplefigure}
