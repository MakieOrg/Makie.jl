## Refactor how internal events are handled

### Motivation

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

Further problems with our observable infrastructure:

* updating observables is not thread-safe and kind of slow because it handles all events by iterating a listener array and calling all functions via `invoke_latest`.
* it's not possible to update multiple attributes efficiently, without double updates, and without running into resizing problems (e.g. when adding new points to scatter with new colors). The double updates are especially bad for WGLMakie over a slow network
* CairoMakie doesn't need any of this, so it's pure overhead
* We need to track a lot of ObserverFuncs to unregister them when a plot gets freed, which is also expensive
* Observable creation alone is relatively expensive (up to 20% of plot creation time)
* GLMakie is especially bad, because it registers an additional observable for every attribute, to check if any attribute has changed for the on demand renderloop
* We could quite easily achieve thread safety for Makie, if we introduce a lock for `setproperty!` and make the attribute conversions pull based. This should also work quite easily for GLMakie, since it will pull the updates from it's own event thread/task, which doesn't care about where the update came from.

## Proposal


Get rid of all observables in `Plot`

instead have two Dicts and a Set of changed fields:
```
user_attributes::Dict{Symbol, Any}
computed_attributes::Dict{Symbol, Any}
changed_fields::Set{Symbol}
```
Now, when accessing any of these in the backend, we will go through all `changed_fields` and run any `convert_arguments`/`convert_attributes`, that relies on that value.

`isempty(changed_fields)` can also be used as an unexpensive check for GLMakie's on demand renderloop, and in `setproperty!` we could also already tell the parent scene that there are changed plots.

We can also still make `setproperty!` directly notify the backend by having an observable/condition triggered in `setproperty!`.

I would also remove the `args` vs `kw` thing and make them all attributes, if that doesn't make to many problems.

Since we have the mapping from `arg_n` -> `attribute_name`, it should be possible to make this backward compatible.
We will also add `Dict{Symbol, Observable}` to have `plot.attribute` still return an observable for backwards compatibility, but I think we should not rely on this in Makie and the backends itself, so that we don't end up with all attributes always materializing back as observables.

## Problems

* `calculated_attributes!` depends on connecting the calculations via observables. This is a mess, but I also am not 100% sure how to do this going forward. Same goes for `convert_arguments`, but I kind of hope without observables the code should actually become easier - but it's still a bit hard to judge.
* Axis/Dim converts rely on observables - this was already a difficult decision back when I wrote it, but Observables made it very easy to have dim convert local state:
```julia
function dim_convert(..., data::Observable)
    local_state = copy(data[])
    on(data) do new_data
        # the simplest local state required for dim converts
        # This is harder to implement,
        # if `dim_convert` gets called for any change instead.
        if new_data != local_state
            ...
        end
    end
end
```
* We still kind of need a compute graph if we don't want to run everything every time (e.g., which functions to run if argument 1 changed, or if only one color changed). I almost think this can be somewhat hardcoded, since we only have `convert_attributes`, `convert_arguments` and `calculated_attributes!` that need to run on each update.
* `plot!(... ; other_plot.attributes...)` wouldn't propagate the updates anymore. `plot!(recipe_plot, ...; color=recipe_plot.color)` neither. I feel like this needs a cleaner API anyways, but simply forwarding the observables here surely is simple from the users perspective. Instead of the above `Dict{Symbol, Observable}` for backwards compatibility, we could also return something like `color=AttributeView(other_plot, :color)`, which the plot constructor connects internally to the other plot object (`plot.color isa AttributeView`). AttributeView would have the large problem, that `on(f, plot.color)` won't easily work, which must be widely used across the Makie ecosystem.

## APIS

```julia
on(plot, :attr1, :attr2) do attr1, attr2

end

update!(plot, attr1=> 22, attr2=> :red)
```
