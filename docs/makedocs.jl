using Pkg
cd(@__DIR__)
Pkg.activate(".")
pkg"dev .. ../MakieCore ../CairoMakie ../GLMakie ../WGLMakie ../RPRMakie"
Pkg.precompile()

include("copy_changelog.jl")

using Documenter: Documenter
using Documenter.MarkdownAST
using Documenter.MarkdownAST: @ast
using DocumenterVitepress
using Markdown


include("buildutils/deploydocs.jl")
include("buildutils/redirect_generation.jl")

using CairoMakie
using WGLMakie
using RPRMakie
using GLMakie

# remove GLMakie's renderloop completely, because any time `GLMakie.activate!()`
# is called somewhere, it's reactivated and slows down CI needlessly
function GLMakie.renderloop(screen)
    return
end

include("figure_block.jl")
include("attrdocs_block.jl")
include("shortdocs_block.jl")

docs_url = "docs.makie.org"
repo = "github.com/MakieOrg/Makie.jl.git"
push_preview = true
devbranch = "master"
devurl = "dev"

params = deployparameters(; repo, devbranch, devurl, push_preview)
deploy_decision = Documenter.DeployDecision(;
    params.all_ok,
    params.branch,
    params.is_preview,
    params.repo,
    params.subfolder,
)

Documenter.makedocs(;
    # modules=[Makie],
    sitename="Makie",
    format=DocumenterVitepress.MarkdownVitepress(;
        repo = "https://github.com/MakieOrg/Makie.jl",
        devurl = "dev",
        devbranch = "master",
        deploy_url = "https://docs.makie.org", # for local testing not setting this has broken links with Makie.jl in them
        description = "Create impressive data visualizations with Makie, the plotting ecosystem for the Julia language. Build aesthetic plots with beautiful customizable themes, control every last detail of publication quality vector graphics, assemble complex layouts and quickly prototype interactive applications to explore your data live.",
        deploy_decision,
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => [
            "Blocks" => [
                "reference/blocks/axis.md",
                "reference/blocks/axis3.md",
                "reference/blocks/box.md",
                "reference/blocks/button.md",
                "reference/blocks/colorbar.md",
                "reference/blocks/gridlayout.md",
                "reference/blocks/intervalslider.md",
                "reference/blocks/label.md",
                "reference/blocks/legend.md",
                "reference/blocks/lscene.md",
                "reference/blocks/menu.md",
                "reference/blocks/polaraxis.md",
                "reference/blocks/slider.md",
                "reference/blocks/slidergrid.md",
                "reference/blocks/textbox.md",
                "reference/blocks/toggle.md",
            ],
            "Plots" => [
                "reference/plots/ablines.md",
                "reference/plots/arc.md",
                "reference/plots/arrows.md",
                "reference/plots/band.md",
                "reference/plots/barplot.md",
                "reference/plots/boxplot.md",
                "reference/plots/bracket.md",
                "reference/plots/contour.md",
                "reference/plots/contour3d.md",
                "reference/plots/contourf.md",
                "reference/plots/crossbar.md",
                "reference/plots/datashader.md",
                "reference/plots/density.md",
                "reference/plots/ecdf.md",
                "reference/plots/errorbars.md",
                "reference/plots/heatmap.md",
                "reference/plots/hexbin.md",
                "reference/plots/hist.md",
                "reference/plots/hlines.md",
                "reference/plots/hspan.md",
                "reference/plots/image.md",
                "reference/plots/lines.md",
                "reference/plots/linesegments.md",
                "reference/plots/mesh.md",
                "reference/plots/meshscatter.md",
                "reference/plots/pie.md",
                "reference/plots/poly.md",
                "reference/plots/qqnorm.md",
                "reference/plots/qqplot.md",
                "reference/plots/rainclouds.md",
                "reference/plots/rangebars.md",
                "reference/plots/scatter.md",
                "reference/plots/scatterlines.md",
                "reference/plots/series.md",
                "reference/plots/spy.md",
                "reference/plots/stairs.md",
                "reference/plots/stem.md",
                "reference/plots/stephist.md",
                "reference/plots/streamplot.md",
                "reference/plots/surface.md",
                "reference/plots/text.md",
                "reference/plots/tooltip.md",
                "reference/plots/tricontourf.md",
                "reference/plots/triplot.md",
                "reference/plots/violin.md",
                "reference/plots/vlines.md",
                "reference/plots/volume.md",
                "reference/plots/volumeslices.md",
                "reference/plots/voronoiplot.md",
                "reference/plots/voxels.md",
                "reference/plots/vspan.md",
                "reference/plots/waterfall.md",
                "reference/plots/wireframe.md",  
            ],
            "Scene" => [
                "reference/scene/lighting.md",
                "reference/scene/matcap.md",
                "reference/scene/SSAO.md",
            ]
        ],

        "Tutorials" => [
            "tutorials/basic-tutorial.md",
            "tutorials/aspect-tutorial.md",
            "tutorials/layout-tutorial.md",
            "tutorials/scenes.md",
            "tutorials/wrap-existing-recipe.md",
        ],
        "Explanations" => [
            "Backends" => [
                "explanations/backends/backends.md",
                "explanations/backends/cairomakie.md",
                "explanations/backends/glmakie.md",
                "explanations/backends/rprmakie.md",
                "explanations/backends/wglmakie.md",
            ],
            "explanations/animation.md",
            "explanations/blocks.md",
            "explanations/cameras.md",
            "explanations/conversion_pipeline.md",
            "explanations/colors.md",
            "explanations/dim-converts.md",
            "explanations/events.md",
            "explanations/figure.md",
            "explanations/faq.md",
            "explanations/fonts.md",
            "explanations/layouting.md",
            "explanations/headless.md",
            "explanations/inspector.md",
            "explanations/latex.md",
            "explanations/observables.md",
            "explanations/plot_method_signatures.md",
            "explanations/recipes.md",
            "explanations/scenes.md",
            "explanations/specapi.md",
            "Theming" => [
                "explanations/theming/themes.md",
                "explanations/theming/predefined_themes.md",
            ],
            "explanations/transparency.md",
        ],
        "How-Tos" => [
            "how-to/draw-boxes-around-subfigures.md",
            "how-to/save-figure-with-transparency.md",
        ],
        "Resources" => [
            "API" => "api.md",
            "Changelog" => "changelog.md",
            "Ecosystem" => "ecosystem.md",
        ]
    ],
    warnonly = false,
    pagesonly = true,
)

# DocumenterVitepress moves rendered files from `build/final_site` into `build` on CI by default, but not when running locally

generate_redirects([
    r"/reference/blocks/(.*).html" => s"/examples/blocks/\1/index.html",
    r"/reference/plots/(.*).html" => s"/examples/plotting_functions/\1/index.html",
    r"/explanations/(.*).html" => s"/documentation/\1/index.html",
    "/explanations/observables.html" => "/explanations/nodes/index.html",
], dry_run = false)

deploy(params; target = "build")
