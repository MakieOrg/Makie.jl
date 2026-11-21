function attribute_groups(::Type{Colorbar})
    groups = default_block_attribute_groups()

    attr = documented_attributes(Colorbar)
    str_keys = string.(keys(attr))
    label = filter(k -> startswith(k, "label"), str_keys)
    tick = filter(k -> startswith(k, "tick"), str_keys)
    grid = filter(k -> startswith(k, "grid"), str_keys)
    minortick = filter(k -> startswith(k, "minortick"), str_keys)
    spine = filter(k -> contains(k, "spine"), str_keys)
    manual = [:colormap, :colorrange, :value, :highclip, :lowclip, :scale, :alpha, :dim_conversion, :limits, :values]

    push!(
        groups,
        "Manual Colormapping Attribute" => Symbol.(sort!(manual)),
        "Tick Attributes" => Symbol.(sort!(tick)),
        "Minor Tick Attributes" => Symbol.(sort!(minortick)),
        "Grid Attributes" => Symbol.(sort!(grid)),
        "Label Attributes" => Symbol.(sort!(label)),
        "Spine Attributes" => Symbol.(sort!(spine)),
    )

    return groups
end