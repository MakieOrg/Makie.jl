using ImageMagick
using FileIO
using Documenter
using Highlights
using Markdown
using Random
using WGLMakie
using GLMakie
using CairoMakie
using Makie
using JSServe
import Makie: to_string

Makie.inline!(true)

# Pause renderloop for slow software rendering.
# This way, we only render if we actualy save e.g. an image
GLMakie.set_window_config!(;
    framerate = 15.0,
    pause_rendering = true
)

# use svgs for CairoMakie which look crisper by default
CairoMakie.activate!(type = "svg")

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

const plot_attr_desc = Dict(
    :absorption => "Float32. Sets the absorption value for `volume` plots.",
    :algorithm => "Algorithm to be used for `volume` plots. Can be one of `:iso`, `:absorption`, `:mip`, `:absorptionrgba`, or `:indexedabsorption`.",
    :align => "`(:pos, :pos)`. Specify the text alignment, where `:pos` can be `:left`, `:center`, or `:right`.",
    :color => "Symbol or Colorant. The color of the main plot element (markers, lines, etc.). Can be a color symbol/string like :red, or a Colorant.  Can also be an array or matrix of 'z-values' that are converted into colors by the colormap automatically.",
    :colormap => "The color map of the main plot. Call `available_gradients()` to see what gradients are available. Can also be used with any Vector{<: Colorant}, or e.g. [:red, :black], or `ColorSchemes.jl` colormaps (by `colormap = ColorSchemes.<colorscheme name>.colors`).",
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
    :marker => "Symbol, Char, Shape, or AbstractVector. Call `available_marker_symbols`() to see which ones.",
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

include("old_axis.jl")

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
    repo = "https://github.com/JuliaPlots/Makie.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(
        prettyurls = false,
        assets = [
            "assets/favicon.ico",
            "assets/syntaxtheme.css"
        ],
        sidebar_sitename=false,
    ),
    sitename = "Makie Plotting Ecosystem",
    pages = Any[
        "Home" => "index.md",
        "Basics" => [
            "Basic Tutorial" => "basic-tutorial.md",
            "Layout Tutorial" => "makielayout/tutorial.md",
            "animation.md",
            "Interaction" => [
                "interaction/nodes.md",
                "interaction/events.md",
                "interaction/inspector.md"
            ],
            # "interaction.md",
            "Plotting Functions" =>
                joinpath.(
                    "plotting_functions",
                    filter(
                        endswith(".md"),
                        readdir(joinpath(srcpath, "plotting_functions"),
                            sort = true)
                    )
                ),
            "Theming" => [
                "theming.md",
                "predefined_themes.md",
            ],
        ],
        "Documentation" => [
            "plot_method_signatures.md",
            "Figure" => "figure.md",
            "Layoutables & Widgets" => [
                "makielayout/layoutables.md",
                "makielayout/axis.md",
                "makielayout/axis3.md",
                "makielayout/box.md",
                "makielayout/button.md",
                "makielayout/colorbar.md",
                "makielayout/gridlayout.md",
                "makielayout/intervalslider.md",
                "makielayout/label.md",
                "makielayout/legend.md",
                "makielayout/lscene.md",
                "makielayout/menu.md",
                "makielayout/slider.md",
                "makielayout/toggle.md",

            ],

            "makielayout/layouting.md",
            "generated/colors.md",
            "generated/plot-attributes.md",
            "recipes.md",
            "backends" => [
                "backends_and_output.md",
                "wglmakie.md"
            ],
            "scenes.md",
            "lighting.md",
            "cameras.md",
            "remote.md",
            "faq.md",
            "API Reference Makie" => "makie_api.md",
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

if !isempty(get(ENV, "DOCUMENTER_KEY", ""))
    deploydocs(
        repo = "github.com/JuliaPlots/Makie.jl",
        push_preview = true
    )
end
