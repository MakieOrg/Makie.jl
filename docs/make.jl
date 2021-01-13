using ImageMagick
using FileIO
using Documenter
using Highlights
using Markdown
using Random
using GLMakie
using AbstractPlotting
AbstractPlotting.inline!(true)
import AbstractPlotting: to_string

# Pause renderloop for slow software rendering.
# This way, we only render if we actualy save e.g. an image
GLMakie.set_window_config!(;
    framerate = 15.0,
    pause_rendering = true
)
# ImageIO seems broken on 1.6 ... and there doesn't
# seem to be a clean way anymore to force not to use a loader library?
filter!(x-> x !== :ImageIO, FileIO.sym2saver[:PNG])
filter!(x-> x !== :ImageIO, FileIO.sym2loader[:PNG])

"""
    print_table(io::IO, dict::Dict)

Print a Markdown-formatted table with the entries from `dict` to specified `io`.
"""
function print_table(io::IO, dict::Dict)
    # get max length of the keys
    k = string.("`", collect(keys(dict)), "`")
    maxlen_k = max(length.(k)...)

    # get max length of the values
    v = string.(collect(values(dict)))
    maxlen_v = max(length.(v)...)

    j = sort(collect(dict), by = x -> x[1])

    # column labels
    labels = ["Symbol", "Description"]

    # print top header
    print(io, "|")
    print(io, "$(labels[1])")
    print(io, " "^(maxlen_k - length(labels[1])))
    print(io, "|")
    print(io, "$(labels[2])")
    print(io, " "^(maxlen_v - length(labels[2])))
    print(io, "|")
    print(io, "\n")

    # print second line (toprule)
    print(io, "|")
    print(io, "-"^maxlen_k)
    print(io, "|")
    print(io, "-"^maxlen_v)
    print(io, "|")
    print(io, "\n")

    for (idx, entry) in enumerate(j)
        print(io, "|")
        print(io, "`$(entry[1])`")
        print(io, " "^(maxlen_k - length(string(entry[1])) - 2))
        print(io, "|")
        print(io, "$(entry[2])")
        print(io, " "^(maxlen_v - length(entry[2])))
        print(io, "|")
        print(io, "\n")
    end
end



################################################################################
#                              Utility functions                               #
################################################################################


################################################################################
#                                    Setup                                     #
################################################################################

pathroot  = normpath(@__DIR__, "..")
docspath  = joinpath(pathroot, "docs")
srcpath   = joinpath(docspath, "src")
srcgenpath   = joinpath(docspath, "src_generation")
buildpath = joinpath(docspath, "build")
genpath   = joinpath(srcpath, "generated")

mkpath(genpath)

################################################################################
#                          Syntax highlighting theme                           #
################################################################################

@info("Writing highlighting stylesheet")

open(joinpath(srcpath, "assets", "syntaxtheme.css"), "w") do io
    Highlights.stylesheet(io, MIME("text/css"), Highlights.Themes.DefaultTheme)
end

################################################################################
#                      Automatic Markdown page generation                      #
################################################################################


########################################
#       Plot attributes overview       #
########################################

# automatically generate an overview of the plot attributes (keyword arguments), using a source md file
@info("Generating attributes page")
# axis_attr_list = []
# for a in (Axis3D,)
#     attr = keys(default_theme(nothing, a))
#     push!(axis_attr_list, attr...)
# end
# axis_attr_list = string.(sort!(unique(axis_attr_list)))

# dict = default_theme(nothing, Axis3D)
# print_rec(STDOUT, dict)


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
# dict = default_theme(nothing, Axis2D)
# print_rec(STDOUT, dict)


const Axis2D_attr_desc = Dict(
    :frame => "See the detailed descriptions for `frame` attributes.",
    :grid => "See the detailed descriptions for `grid` attributes.",
    :names => "See the detailed descriptions for `names` attributes.",
    :ticks => "See the detailed descriptions for `ticks` attributes."
)


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


const Axis2D_attr_groups = Dict(
    :frame => Axis2D_attr_frame,
    :grid => Axis2D_attr_grid,
    :names => Axis2D_attr_names,
    :ticks => Axis2D_attr_ticks
)


const plot_attr_desc = Dict(
    :absorption => "Float32. Sets the absorption value for `volume` plots.",
    :algorithm => "Algorithm to be used for `volume` plots. Can be one of `:iso`, `:absorption`, `:mip`, `:absorptionrgba`, or `:indexedabsorption`.",
    :align => "`(:pos, :pos)`. Specify the text alignment, where `:pos` can be `:left`, `:center`, or `:right`.",
    :alpha => "Float in [0,1]. The alpha value (transparency).",
    :color => "Symbol or Colorant. The color of the main plot element (markers, lines, etc.). Can be a color symbol/string like :red, or a Colorant.  Can also be an array or matrix of 'z-values' that are converted into colors by the colormap automatically.",
    :colormap => "The color map of the main plot. Call available_gradients() to see what gradients are available. Can also be used with any Vector{<: Colorant}, or e.g. [:red, :black], or `ColorSchemes.jl` colormaps (by `colormap = ColorSchemes.<colorscheme name>.colors`).",
    :colorrange => "A tuple `(min, max)` where `min` and `max` specify the data range to be used for indexing the colormap. E.g. color = [-2, 4] with colorrange = (-2, 4) will map to the lowest and highest color value of the colormap.",
    :fillrange => "Bool. Toggles range filling in `contour` plots.",
    :font => "String. Specifies the font, and can choose any font available on the system.",
    :glowcolor => "Color Type. Color of the marker glow (outside the border) in `scatter` plots.",
    :glowwidth => "Number. Width of the marker glow in `scatter` plots.",
    :image => "The image to be plotted on the plot.",
    :interpolate => "Bool. For `heatmap` and `images`. Toggles color interpolation between nearby pixels.",
    :isorange => "Float32. Sets the isorange for `volume` plots.",
    :isovalue => "Float32. Sets the isovalue for `volume` plots.",
    :levels => "Integer. Number of levels for a `contour`-type plot.",
    :linestyle => "Symbol. Style of the line (for `line` and `linesegments` plots). Available styles are `:dash`, `:dot`, `:dashdot`, and `:dashdotdot`. You can also supply an array describing the length of each gap/fill.",
    :linewidth => "Number. Width of the line in `line` and `linesegments` plots.",
    :marker => "Symbol, Shape, or AbstractVector.",
    :marker_offset => "Array of `GeometryBasics.Point`'s. Specifies the offset coordinates for the markers. See the [Marker offset](https://simondanisch.github.io/ReferenceImages/gallery/marker_offset/index.html) example.",
    :markersize => "Number or AbstractVector. Specifies size (radius pixels) of the markers.",
    :position => "NTuple{2,Float}, `(x, y)`. Specify the coordinates to position text at.",
    :rotation => "Float32. Specifies the rotation in radians.",
    :rotations => "AbstractVector{Float32}. Similar to `:rotation`, except it specifies the rotations for each element in the plot.",
    :shading => "Bool. Specifies if shading should be on or not (for meshes).",
    :strokecolor => "Color Type. Color of the marker stroke (border).",
    :strokewidth => "Number. Width of the marker stroke (in pixels).",
    :textsize => "Integer. Font pointsize for text.",
    :transformation => "`(:plane, location)`. Transforms the `:plane` to the specified location. Possible `:plane`'s are `:xy`, `:yz`, and `:xz`.",
    :visible => "Bool. Toggle visibility of plot."
)

path = joinpath(genpath, "plot-attributes.md")
srcdocpath = joinpath(srcgenpath, "src-plot-attributes.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot attributes")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    println(io, "## List of attributes")
    print_table(io, plot_attr_desc)
end

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
    # Axis2D section
    println(io, "## `Axis2D`")
    println(io, "### `Axis2D` attributes groups")
    print_table(io, Axis2D_attr_desc)
    print(io)
    for (k, v) in Axis2D_attr_groups
        println(io, "#### `:$k`\n")
        print_table(io, v)
        println(io)
    end
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

########################################
#          Colormap reference          #
########################################

@info "Generating colormap reference"

include(joinpath(srcgenpath, "colormap_generation.jl"))

generate_colorschemes_markdown(
    joinpath(srcgenpath, "src-colors.md"),
    joinpath(genpath, "colors.md")
)

################################################################################
#                 Building HTML documentation with Documenter                  #
################################################################################

@info("Running `makedocs` with Documenter.")

makedocs(
    doctest = false, clean = true,
    repo = "https://github.com/JuliaPlots/AbstractPlotting.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(
        prettyurls = false,
        assets = [
            "assets/favicon.ico",
            "assets/syntaxtheme.css"
        ],
    ),
    sitename = "Makie.jl",
    expandfirst = [
        "plotting_functions.md",
    ],
    pages = Any[
        "Home" => "index.md",
        "Basics" => [
            "Basic Tutorial" => "basic-tutorial.md",
            "Layout Tutorial" => "makielayout/tutorial.md",
            "animation.md",
            "interaction.md",
            "plotting_functions.md",
            "theming.md",
        ],
        "Documentation" => [
            "plot_method_signatures.md",
            "Figure" => "figure.md",
            "Axis" => "makielayout/laxis.md",
            "GridLayout" => "makielayout/grids.md",
            "Legend" => "makielayout/llegend.md",
            "Other Layoutables" => "makielayout/layoutables_examples.md",
            "How Layouting Works" => "makielayout/layouting.md",
            "generated/colors.md",
            "generated/plot-attributes.md",
            "recipes.md",
            "backends.md",
            "output.md",
            "scenes.md",
            "lighting.md",
            "cameras.md",
            "faq.md",
            "API Reference AbstractPlotting" => "abstractplotting_api.md",
            "API Reference MakieLayout" => "makielayout/reference.md",
            "generated/axis.md",
        ],
    ],
    strict = true, # experimental kwarg, so that the docs fail if there are any errors encountered
    # this way the docs serve better as another test case, because nobody looks at warnings
)

################################################################################
#                           Deploying documentation                            #
################################################################################

# for github actions, documenter checks that GITHUB_REPOSITORY matches the repo
# keyword, but since we want to push to a different repo, we need to override the
# env variable, which is JuliaPlots/AbstractPlotting.jl by default
ENV["GITHUB_REPOSITORY"] = "JuliaPlots/MakieDocumentation"

deploydocs(
    repo = "github.com/JuliaPlots/MakieDocumentation",
    push_preview = true
)
