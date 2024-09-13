## Refactor how internal events are handled

Right now we heavily use Observables to propagate events internally, right up to the GPU memory.
A single scatter plot (with axis to be fair) creates 4403 observables:
```julia
using GLMakie
start = Makie.Observables.OBSID_COUNTER[]
f, ax, pl = scatter(1:10)
id_end = Makie.Observables.OBSID_COUNTER[]
Int(id_end - start)
```
4403
