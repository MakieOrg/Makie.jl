"""
    Pretransformed(f)

A scale for axes where data has already been transformed by `f` before plotting.

The axis remains linear (so all plot types like `ablines!` work), but ticks are
computed and labelled as if the original scale `f` were active.

# Example

```julia
# Plot pre-transformed data with log-style ticks
xs = range(0, 3, length=100)         # already in log10 space
ys = xs .^ 2
lines(xs, ys; axis = (xscale = Pretransformed(log10),))
# x-axis ticks will read "10⁰", "10¹", "10²", "10³" at positions 0,1,2,3
```
"""
struct Pretransformed{F} <: Function
    f::F
end

# Acts as identity for data transformation — data is already in transformed space
(::Pretransformed)(x) = x

Makie.inverse_transform(::Pretransformed) = identity

function Makie.defaultlimits(p::Pretransformed)
    dl = Makie.defaultlimits(p.f)
    return (p.f(dl[1]), p.f(dl[2]))
end

Makie.defined_interval(::Pretransformed) = OpenInterval(-Inf, Inf)

Makie.is_identity_transform(::Pretransformed) = true

# All tick specifications are in original (untransformed) data space.
# Results are positioned in the pre-transformed axis space via p.f.

function _pretransformed_ticks(p::Pretransformed, vmin, vmax)
    inv = Makie.inverse_transform(p.f)
    return inv(vmin), inv(vmax)
end

function Makie.get_ticks(::Makie.Automatic, p::Pretransformed, formatter, vmin, vmax)
    vmin_orig, vmax_orig = _pretransformed_ticks(p, vmin, vmax)
    tickvalues_orig, ticklabels = Makie.get_ticks(Makie.automatic, p.f, formatter, vmin_orig, vmax_orig)
    return p.f.(tickvalues_orig), ticklabels
end

# Resolve ambiguity with get_ticks(::Tuple{Any,Any}, _, ::Automatic, ...)
function Makie.get_ticks(ticks_and_labels::Tuple{Any, Any}, p::Pretransformed, ::Makie.Automatic, vmin, vmax)
    tickvalues = p.f.(ticks_and_labels[1])
    return tickvalues, ticks_and_labels[2]
end

# Resolve ambiguity with get_ticks(::Function, _, formatter, ...)
function Makie.get_ticks(tickfunction::Function, p::Pretransformed, formatter, vmin, vmax)
    vmin_orig, vmax_orig = _pretransformed_ticks(p, vmin, vmax)
    result = tickfunction(vmin_orig, vmax_orig)
    if result isa Tuple{Any, Any}
        tickvalues_orig, ticklabels = result
    else
        tickvalues_orig = result
        ticklabels = Makie.get_ticklabels(formatter, tickvalues_orig)
    end
    return p.f.(tickvalues_orig), ticklabels
end

# Generic: arrays, LinearTicks, WilkinsonTicks, etc.
function Makie.get_ticks(ticks, p::Pretransformed, formatter, vmin, vmax)
    vmin_orig, vmax_orig = _pretransformed_ticks(p, vmin, vmax)
    tickvalues_orig = Makie.get_tickvalues(ticks, p.f, vmin_orig, vmax_orig)
    ticklabels = Makie.get_ticklabels(formatter, tickvalues_orig)
    return p.f.(tickvalues_orig), ticklabels
end
