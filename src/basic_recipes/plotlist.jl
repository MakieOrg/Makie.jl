"""
    plotlist!(
        [
            PlotSpec{SomePlotType}(args...; kwargs...),
            PlotSpec{SomeOtherPlotType}(args...; kwargs...),
        ]
    )

Plot a list of plotspecs, and dynamically replot based on the plot spec types.
Also, dynamically update the argument values and attributes whenever a new one is passed in!

## Example
```julia

fig = Figure()
ax = Axis(fig[1, 1])

pl = plotlist!(
    ax,
    [PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = :blue), PlotSpec{Heatmap}(0..1, 0..1, Makie.peaks(); transformation = (; translation = Vec3f(0, 0, -1)))]
)

fig

pl[1][] = [PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = :red), PlotSpec{Heatmap}(0..1, 0..1, Makie.peaks(); transformation = (; translation = Vec3f(0, 0, -1)))]

fig

pl[1][] = [
    PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = Makie.resample_cmap(:viridis, 101)), 
    PlotSpec{Surface}(0..1, 0..1, Makie.peaks(); transformation = (; translation = Vec3f(0, 0, -1))),
    PlotSpec{Poly}(Rect2f(0.45, 0.45, 0.1, 0.1)),
]

fig


pl[1][] = [
    PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = Makie.resample_cmap(:viridis, 101)), 
]

fig
```
"""
@recipe(PlotList) do scene
    default_theme(scene)
end

function Makie.plot!(p::PlotList{<: Tuple{<: AbstractArray{<: PlotSpec}}})
    # Cache the old PlotSpec types, so we can compare!
    old_plotspec_types = Type{PlotSpec}[]
    # 
    cached_plots = AbstractPlot[]

    lift(p[1]) do plotspecs
        plotspec_types = typeof.(plotspecs)
        types_unchanged = if length(plotspec_types) == length(old_plotspec_types)
            # if the length is the same, check whether one of
            # the types has changed.
            println("Length same")
            plotspec_types .== old_plotspec_types
        elseif length(plotspec_types) < length(old_plotspec_types) # have to delete one or more plots
            @show collect(length(old_plotspec_types):-1:(length(plotspec_types)+1))
            for i in length(old_plotspec_types):-1:length(plotspec_types)
                deleteat!(p.plots, i)
                delete!(p, cached_plots[i])
                pop!(cached_plots)
            end
            println("Length less")
            plotspec_types .== old_plotspec_types[1:length(plotspec_types)]
        elseif length(plotspec_types) > length(old_plotspec_types) # have to add one or more plots
            # first add the plots
            println("Length more")
            for i in (length(old_plotspec_types)+1):length(plotspec_types)
                push!(cached_plots, plot!(p, plotspec_types[i].parameters[1], Attributes(plotspecs[i].kwargs), plotspecs[i].args...))
            end
            vcat(plotspec_types[1:length(old_plotspec_types)] .== old_plotspec_types, fill(false, length(plotspec_types) - length(old_plotspec_types)))
        end

        old_plotspec_types = plotspec_types
        @show types_unchanged
        # If the types have changed, then we need to delete and replot certain plots.
        if !(all(types_unchanged)) 
            println("Found changed plottypes")
            indices_to_renew = findall(==(false), types_unchanged)
            for plot_ind in indices_to_renew
                if length(cached_plots) > plot_ind
                    old_plot = cached_plots[plot_ind]
                    delete!(p, old_plot)
                    deleteat!(p.plots, findfirst(==(old_plot), p.plots))
                end
                new_plot = plot!(p, plotspec_types[plot_ind].parameters[1], Attributes(plotspecs[plot_ind].kwargs), plotspecs[plot_ind].args...)
                if length(cached_plots) > plot_ind
                    cached_plots[plot_ind] = new_plot # reorder and re-store the plot - this can probably be more efficient!
                    _tmp = p.plots[plot_ind]
                    p.plots[plot_ind] = new_plot
                    p.plots[end] = _tmp
                else # there is no cached_plots entry at this index - push it!
                    push!(cached_plots, new_plot)
                end
            end
        end

        true_inds = findall(==(true), types_unchanged)
        isnothing(true_inds) && return

        for i in true_inds
            ps = plotspecs[i]
            cp = cached_plots[i]
            for arg_index in eachindex(ps.args)
                cp.input_args[arg_index].val = ps.args[arg_index]
            end
            for (attribute, new_value) in pairs(ps.kwargs)
                update_attributes_inplace!(cp, attribute, new_value)
            end
            map(notify, cp.input_args) # notify all args, without broadcasting
            map(_notify!, (getindex(cp, attr) for attr in keys(ps.kwargs))) # notify all accessed kwargs
        end

    end

end


"This function updates the attributes of a plot inplace, recursively."
function update_attributes_inplace!(p::Union{AbstractPlot, Symbol}, key::Symbol, new_value)
    return update_attributes_inplace!(getindex(p, key), new_value)
end

function update_attributes_inplace!(attrs::Attributes, new_attrs::Union{Attributes, NamedTuple})
    for key in keys(new_attrs)
        update_attributes_inplace!(attrs[key], new_attrs[key])
    end
end

function update_attributes_inplace!(obs::Observable, new_value) 
    obs.val = new_value
end

# TODO: make the below function an extension of Observables.notify
"This function notifies attributes inplace and recursively."
_notify!(obs::Observable) = notify(obs)
_notify!(attrs::Attributes) = for (key, val) in attrs
    _notify!(val)
end


# An example


fig = Figure()
ax = Axis(fig[1, 1])

pl = plotlist!(
    ax,
    [PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = :blue), PlotSpec{Heatmap}(0..1, 0..1, Makie.peaks(); transformation = (; translation = Vec3f(0, 0, -1)))]
)

fig

pl[1][] = [PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = :red), PlotSpec{Heatmap}(0..1, 0..1, Makie.peaks(); transformation = (; translation = Vec3f(0, 0, -1)))]

fig

pl[1][] = [
    PlotSpec{Lines}(0..1, sin.(0:0.01:1); color = Makie.resample_cmap(:viridis, 101)), 
    PlotSpec{Surface}(0..1, 0..1, Makie.peaks(); transformation = (; translation = Vec3f(0, 0, -1))),
    PlotSpec{Poly}(Rect2f(0.45, 0.45, 0.1, 0.1)),
]

fig


pl[1][] = [
    PlotSpec{Surface}(0..1, 0..1, Makie.peaks(); colormap = :viridis, transformation = (; translation = Vec3f(0, 0, -1))),
]

fig

pl.plots