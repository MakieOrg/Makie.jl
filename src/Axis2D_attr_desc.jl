# dict = default_theme(nothing, Axis2D)
# print_rec(STDOUT, dict)


const Axis2D_attr_desc = Dict(
    :frame => "See the detailed descriptions for `frame` attributes.",
    :grid => "See the detailed descriptions for `grid` attributes.",
    :names => "See the detailed descriptions for `names` attributes.",
    :ticks => "See the detailed descriptions for `ticks` attributes."
)

Axis2D_attr_groups = [
    "Axis2D_attr_frame",
    "Axis2D_attr_grid",
    "Axis2D_attr_names",
    "Axis2D_attr_ticks"
]

# frame
const Axis2D_attr_frame = Dict(
    :arrow_size => "Number. Size of the axes arrows.",
    :axis_position => "",
    :axis_arrow => "Bool. Toggles the axes arrows.",
    :frames => "NTuple{2,NTuple{2,Bool}}.",
    :linecolor => "Symbol or Colorant. Specifies the color of the grid lines. Can be a color symbol/string like :red, or a Colorant.",
    :linestyle => "",
    :linewidth => "Number. Widths of the axes frame lines."
)

# grid
const Axis2D_attr_grid = Dict(
    :linecolor => "Symbol or Colorant. Specifies the color of the grid lines. Can be a color symbol/string like :red, or a Colorant.",
    :linestyle => "",
    :linewidth => "NTuple{2, Number}. Width of the x and y grids."
)

# names
const Axis2D_attr_names = Dict(
    :align => "`(:pos, :pos)`. Specify the text alignment, where `:pos` can be `:left`, `:center`, or `:right`.",
    :axisnames => "NTuple{2,String}. Specifies the text labels for the axes.",
    :font => "NTuple{2,String}. Specifies the font and can name any font available on the system.",
    :rotation => "NTuple{3,Float32}. Specifies the rotations for each axis's label, in radians.",
    :textcolor => "NTuple{2,Symbol or Colorant}. Specifies the color of the axes labels. Can be a color symbol/string like :red, or a Colorant.",
    :textsize => "Integer. Font pointsize for text."
)

# ticks
const Axis2D_attr_ticks = Dict(
    :align => "`NTuple{2,(:pos, :pos)}`. Specify the text alignment for the axis ticks, where `:pos` can be `:left`, `:center`, or `:right`",
    :font => "NTuple{2,String}. Specifies the font and can name any font available on the system.",
    :gap => "Number. Specifies the gap (in pixels) between the axis tick labels and the axes themselves.",
    :linecolor => "NTuple{2,Symbol or Colorant}. Specifies the color of the grid lines. Can be a color symbol/string like :red, or a Colorant.",
    :linestyle => "",
    :linewidth => "NTuple{2,Number}. Width of the axes ticks.",
    :rotation => "NTuple{3,Float32}. Specifies the rotations for each axis's ticks, in radians.",
    :textcolor => "NTuple{2,Symbol or Colorant}. Specifies the color of the axes ticks. Can be a color symbol/string like :red, or a Colorant.",
    :textsize => "NTuple{2,Int}. Font pointsize for tick labels.",
    :title_gap => "Number. Specifies the gap (in pixels) between the axis titles and the axis tick labels."
)
