ENV["JULIA_DEBUG"] = "Documenter"

using Pkg
cd(@__DIR__)
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()

using CairoMakie
using GLMakie
using WGLMakie
using RPRMakie
using Graphviz_jll

##

include("copy_changelog.jl")

using Documenter: Documenter
using Documenter.MarkdownAST
using Documenter.MarkdownAST: @ast
using DocumenterVitepress
using Markdown


include("figure_block.jl")
include("graphviz_block.jl")
include("attrdocs_block.jl")
include("shortdocs_block.jl")
include("fake_interaction.jl")

function nested_filter(x, regex)
    _match(x::String) = match(regex, x) !== nothing
    _match(x::Pair) = x[2] isa String ? match(regex, x[2]) !== nothing : true
    fn(el::Pair) = el[2] isa Vector ? el[1] => nested_filter(el[2], regex) : el
    fn(el) = el
    return filter(_match, map(fn, x))
end

unnest(vec::Vector) = collect(Iterators.flatten([unnest(el) for el in vec]))
unnest(p::Pair) = p[2] isa String ? [p[2]] : unnest(p[2])
unnest(s::String) = [s]

pages = [
    "Home" => "index.md",
    "Reference" => [
        "Blocks" => joinpath.("reference", "blocks", [
            "overview.md",
            "axis.md",
            "axis3.md",
            "box.md",
            "button.md",
            "checkbox.md",
            "colorbar.md",
            "gridlayout.md",
            "intervalslider.md",
            "label.md",
            "legend.md",
            "lscene.md",
            "menu.md",
            "polaraxis.md",
            "slider.md",
            "slidergrid.md",
            "textbox.md",
            "toggle.md",
        ]),
        "Plots" => joinpath.("reference", "plots", [
            "overview.md",
            "ablines.md",
            "annotation.md",
            "arc.md",
            "arrows.md",
            "band.md",
            "barplot.md",
            "boxplot.md",
            "bracket.md",
            "contour.md",
            "contour3d.md",
            "contourf.md",
            "crossbar.md",
            "datashader.md",
            "dendrogram.md",
            "density.md",
            "ecdf.md",
            "errorbars.md",
            "heatmap.md",
            "hexbin.md",
            "hist.md",
            "hlines.md",
            "hspan.md",
            "image.md",
            "lines.md",
            "linesegments.md",
            "mesh.md",
            "meshscatter.md",
            "pie.md",
            "poly.md",
            "qqnorm.md",
            "qqplot.md",
            "rainclouds.md",
            "rangebars.md",
            "scatter.md",
            "scatterlines.md",
            "series.md",
            "spy.md",
            "stairs.md",
            "stem.md",
            "stephist.md",
            "streamplot.md",
            "surface.md",
            "text.md",
            "textlabel.md",
            "tooltip.md",
            "tricontourf.md",
            "triplot.md",
            "violin.md",
            "vlines.md",
            "volume.md",
            "volumeslices.md",
            "voronoiplot.md",
            "voxels.md",
            "vspan.md",
            "waterfall.md",
            "wireframe.md",
        ]),
        "Generic Concepts" => joinpath.("reference", "generic", [
            "clip_planes.md",
            "transformations.md",
            "space.md",
        ]),
        "Scene" => joinpath.("reference", "scene", [
            "lighting.md",
            "matcap.md",
            "SSAO.md",
        ]),
    ],
    "Tutorials" => joinpath.("tutorials", [
        "getting-started.md",
        "aspect-tutorial.md",
        "layout-tutorial.md",
        "scenes.md",
        "wrap-existing-recipe.md",
        "pixel-perfect-rendering.md",
        "inset-plot-tutorial.md",
    ]),
    "Explanations" => [
        "Backends" => joinpath.("explanations", "backends", [
            "backends.md",
            "cairomakie.md",
            "glmakie.md",
            "rprmakie.md",
            "wglmakie.md",
        ]),
        joinpath.("explanations", [
            "animation.md",
            "architecture.md",
            "blocks.md",
            "cameras.md",
            "conversion_pipeline.md",
            "colors.md",
            "dim-converts.md",
            "events.md",
            "figure.md",
            "faq.md",
            "fonts.md",
            "layouting.md",
            "headless.md",
            "inspector.md",
            "latex.md",
            "observables.md",
            "plot_method_signatures.md",
            "recipes.md",
            "scenes.md",
            "specapi.md",
        ])...,
        "Theming" => joinpath.("explanations", "theming", [
            "themes.md",
            "predefined_themes.md",
        ]),
        joinpath.("explanations", [
            "transparency.md",
            "compute-pipeline.md",
            "transformations.md",
        ])...,
    ],
    "How-Tos" => joinpath.("how-to", [
        "match-figure-size-font-sizes-and-dpi.md",
        "draw-boxes-around-subfigures.md",
        "save-figure-with-transparency.md",
    ]),
    "Resources" => [
        "API" => "api.md",
        "Changelog" => "changelog.md",
        "Ecosystem" => "ecosystem.md",
    ],
]

function make_docs(; pages)
    empty!(MakieDocsHelpers.FIGURES)

    return Documenter.makedocs(;
        sitename = "Makie",
        format = DocumenterVitepress.MarkdownVitepress(;
            repo = "github.com/MakieOrg/Makie.jl",
            devurl = "dev",
            devbranch = "master",
            deploy_url = "https://docs.makie.org", # for local testing not setting this has broken links with Makie.jl in them
            description = "Create impressive data visualizations with Makie, the plotting ecosystem for the Julia language. Build aesthetic plots with beautiful customizable themes, control every last detail of publication quality vector graphics, assemble complex layouts and quickly prototype interactive applications to explore your data live.",
        ),
        pages,
        expandfirst = unnest(nested_filter(pages, r"reference/(plots|blocks)/(?!overview)")),
        warnonly = get(ENV, "CI", "false") != "true",
        pagesonly = true,
    )
end

make_docs(;
    # filter pages here when working on docs interactively
    pages # = nested_filter(pages, r"explanations/figure|match-figure"),
)

##

include("buildutils/redirect_generation.jl")
generate_redirects(
    [
        r"/reference/blocks/(.*).html" => s"/examples/blocks/\1/index.html",
        r"/reference/blocks/(.*).html" => s"/reference/blocks/\1/index.html",
        r"/reference/plots/(.*).html" => s"/examples/plotting_functions/\1/index.html",
        r"/reference/plots/(.*).html" => s"/reference/plots/\1/index.html",
        r"/explanations/(.*).html" => s"/documentation/\1/index.html",
        r"/tutorials/(.*).html" => s"/tutorials/\1/index.html",
        r"/explanations/(.*).html" => s"/explanations/\1/index.html",
        "/explanations/observables.html" => "/explanations/nodes/index.html",
        "/reference/plots/overview.html" => "/reference/plots/index.html",
        "/reference/blocks/overview.html" => "/reference/blocks/index.html",
        "/tutorials/getting-started.html" => "/tutorials/basic-tutorial.html",
    ], dry_run = false
)

DocumenterVitepress.deploydocs(
    repo = "github.com/MakieOrg/Makie.jl.git",
    push_preview = true,
    devbranch = "master",
    devurl = "dev",
)
