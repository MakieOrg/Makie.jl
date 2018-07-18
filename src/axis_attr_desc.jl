# axis_attr_list = []
# for a in (Axis2D, Axis3D)
#     attr = keys(default_theme(nothing, a))
#     push!(axis_attr_list, attr...)
# end
# axis_attr_list = string.(sort!(unique(axis_attr_list)))


const axis_attr_desc = Dict(
    :framestyle =>
    :gridstyle =>
    :scale =>
    :showaxis => "NTuple{3,Bool}, specifies whether to show the axes."
    :showgrid => "NTuple{3,Bool}, specifies whether to show the axis grids."
    :showticks => "NTuple{3,Bool}, specifies whether to show the axis ticks."
    :tickstyle =>
    :titlestyle =>
)
