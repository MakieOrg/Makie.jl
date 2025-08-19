"""
    DQConversion(unit=automatic; units_in_label=false)

Allows to plot arrays of DynamicQuantity objects into an axis.

# Arguments
- `units_in_label=true`: controls, whether plots are shown in the label_prefix of the axis labels, or in the tick labels

# Examples

```julia
using DynamicQuantities, CairoMakie

scatter(1:4, [1u"ns", 2u"ns", 3u"ns", 4u"ns"])
```

Fix unit to always use Meter & display unit in the xlabel:

```julia
dqc = Makie.DQConversion(us"m"; units_in_label = false)

scatter(1:4, [0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"]; axis=(dim2_conversion=dqc, xlabel="x (km)"))
```
"""
struct DQConversion <: AbstractDimConversion
    quantity::Observable{Any}
    units_in_label::Observable{Bool}
end

function DQConversion(quantity = automatic; units_in_label = true)
    return DQConversion(quantity, units_in_label)
end
