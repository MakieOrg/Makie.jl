# dict = default_theme(nothing, Axis2D)
# print_rec(STDOUT, dict)

const Axis2D_attr_desc = Dict(
    :framestyle => "",
    :gridstyle => "",
    :scale => "",
    :showaxis => "NTuple{3,Bool}, specifies whether to show the axes.",
    :showgrid => "NTuple{3,Bool}, specifies whether to show the axis grids.",
    :showticks => "NTuple{3,Bool}, specifies whether to show the axis ticks.",
    :tickstyle => "",
    :titlestyle => ""
)

# frame
const Axis2D_attr_frame = Dict(
    :axis_position => "",
    :linestyle => "",
    :linewidth => "",
    :arrow_size => "",
    :axis_arrow => "",
    :linecolor => "",
    :frames => ""
)

# grid
const Axis2D_attr_grid = Dict(
    :linestyle => "",
    :linewidth => "",
    :linecolor => ""
)

# names
const Axis2D_attr_names = Dict(
    :axisnames => "",
    :rotation => "",
    :font => "",
    :textcolor => "",
    :align => "",
    :textsize => ""
)

# ticks
const Axis2D_attr_ticks = Dict(
    :linestyle => "",
    :rotation => "",
    :title_gap => "",
    :font => "",
    :textcolor => "",
    :linewidth => "",
    :align => "",
    :gap => "",
    :linecolor => "",
    :textsize => ""
)
