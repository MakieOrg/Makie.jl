function attribute_groups(::Type{PolarAxis})
    groups = default_block_attribute_groups()

    attr = documented_attributes(PolarAxis)
    str_keys = string.(keys(attr))
    title = filter(k -> startswith(k, "title"), str_keys)
    subtitle = filter(k -> startswith(k, "subtitle"), str_keys)
    label = filter(k -> startswith(k, r"thetalabel|rlabel"), str_keys)
    tick = filter(k -> startswith(k, r"thetatick|rtick"), str_keys)
    grid = filter(k -> startswith(k, r"thetagrid|rgrid"), str_keys)
    minortick = filter(k -> startswith(k, r"thetaminortick|rminortick"), str_keys)
    minorgrid = filter(k -> startswith(k, r"thetaminorgrid|rminorgrid"), str_keys)
    spine = filter(k -> contains(k, "spine"), str_keys)
    interactive = filter(k -> contains(k, r"key|button|zoom|lock"), str_keys)
    dimconvert = [:dim1_conversion, :dim2_conversion, :x_unit_in_ticklabel, :y_unit_in_ticklabel, :x_unit_in_label, :y_unit_in_label, :xlabel_suffix, :ylabel_suffix]

    # Note xlabel_suffix and ylabel_suffix are in xlabel and ylabel too. They
    # will be associated with the first group in groups.

    push!(
        groups,
        "Dim Convert Attributes" => sort!(dimconvert),
        "Interaction Attributes" => Symbol.(sort!(interactive)),
        "Title Attributes" => Symbol.(sort!(vcat(title, subtitle))),
        "Tick Attributes" => Symbol.(sort!(tick)),
        "Minor Tick Attributes" => Symbol.(sort!(minortick)),
        "Grid Attributes" => Symbol.(vcat(sort!(grid), sort!(minorgrid))),
        "Label Attributes" => Symbol.(sort!(label)),
        "Spine Attributes" => Symbol.(sort!(spine))
    )

    return groups
end