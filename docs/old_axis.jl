
const Axis3D_attr_desc = Dict(
    :frame => "See the detailed descriptions for `frame` attributes.",
    :names => "See the detailed descriptions for `names` attributes.",
    :scale => "NTuple{3,Float}. Specifies the scaling for the axes.",
    :showaxis => "NTuple{3,Bool}. Specifies whether to show the axes.",
    :showgrid => "NTuple{3,Bool}. Specifies whether to show the axis grids.",
    :showticks => "NTuple{3,Bool}. Specifies whether to show the axis ticks.",
    :ticks => "See the detailed descriptions for `ticks` attributes."
)


# frame
const Axis3D_attr_frame = Dict(
    :axiscolor => "Symbol or Colorant. Specifies the color of the axes. Can be a color symbol/string like :red, or a Colorant.",
    :linewidth => "Number. Width of the axes grid lines.",
    :linecolor => "Symbol or Colorant. Specifies the color of the grid lines. Can be a color symbol/string like :red, or a Colorant."
)

# names
const Axis3D_attr_names = Dict(
    :align => "`NTuple{3,(:pos, :pos)}`. Specify the text alignment for the axis labels, where `:pos` can be `:left`, `:center`, or `:right`.",
    :axisnames => "NTuple{3,String}. Specifies the axis labels.",
    :font => "NTuple{3,String}. Specifies the font for the axis labels, and can choose any font available on the system.",
    :gap => "Number. Specifies the gap (in pixels) between the axis labels and the axes themselves.",
    :rotation => "NTuple{3,Quaternion{Float32}}. Specifies the rotations for each axis's label, in radians.",
    :textcolor => "NTuple{3,Symbol or Colorant}. Specifies the color of the axes labels. Can be a color symbol/string like :red, or a Colorant.",
    :textsize => "NTuple{3,Int}. Font pointsize for axes labels."
)

# ticks
const Axis3D_attr_ticks = Dict(
    :align => "`NTuple{3,(:pos, :pos)}`. Specify the text alignment for the axis ticks, where `:pos` can be `:left`, `:center`, or `:right`.",
    :font => "NTuple{3,String}. Specifies the font for the axis ticks, and can choose any font available on the system.",
    :gap => "Number. Specifies the gap (in pixels) between the axis ticks and the axes themselves.",
    :rotation => "NTuple{3,Quaternion{Float32}}. Specifies the rotations for each axis's ticks, in radians.",
    :textcolor => "NTuple{3,Symbol or Colorant}. Specifies the color of the axes ticks. Can be a color symbol/string like :red, or a Colorant.",
    :textsize => "Integer. Font pointsize for text."
)


const Axis3D_attr_groups = Dict(
    :frame => Axis3D_attr_frame,
    :names => Axis3D_attr_names,
    :ticks => Axis3D_attr_ticks
)

########################################
#       OldAxis attributes overview       #
########################################

# automatically generate an overview of the axis attributes, using a source md file
@info("Generating axis page")
path = joinpath(genpath, "axis.md")
srcdocpath = joinpath(srcgenpath, "src-axis.md")

open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    src = read(srcdocpath, String)
    println(io, src)
    print(io)
    # Axis3D section
    println(io, "## `Axis3D`")
    println(io, "### `Axis3D` attributes groups")
    print_table(io, Axis3D_attr_desc)
    print(io)
    for (k, v) in Axis3D_attr_groups
        println(io, "#### `:$k`\n")
        print_table(io, v)
        println(io)
    end

end
