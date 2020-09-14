################################################################################
#                  MakieGallery.jl documentation build script                  #
################################################################################
##############################
#      Generic imports       #
##############################

using Documenter, Markdown, Pkg, Random, FileIO


##############################
#      Specific imports      #
##############################

using MakieGallery, AbstractPlotting

import AbstractPlotting: to_string

using MakieGallery: print_table


################################################################################
#                              Utility functions                               #
################################################################################


################################################################################
#                                    Setup                                     #
################################################################################

cd(@__DIR__)
database = MakieGallery.load_database()

pathroot  = normpath(@__DIR__, "..")
docspath  = joinpath(pathroot, "docs")
srcpath   = joinpath(docspath, "src")
buildpath = joinpath(docspath, "build")
genpath   = joinpath(srcpath, "generated")

mkpath(genpath)

################################################################################
#                          Syntax highlighting theme                           #
################################################################################

@info("Writing highlighting stylesheet")
open(joinpath(srcpath, "assets", "syntaxtheme.css"), "w") do io
    MakieGallery.Highlights.stylesheet(io, MIME("text/css"), MakieGallery.DEFAULT_HIGHLIGHTER[])
end

################################################################################
#                      Automatic Markdown page generation                      #
################################################################################

########################################
#     Plotting functions overview      #
########################################

@info("Generating functions overview")
path = joinpath(srcpath, "functions-overview.md")
srcdocpath = joinpath(srcpath, "src-functions.md")

plotting_functions = (
    AbstractPlotting.atomic_functions..., contour, arrows,
    barplot, poly, band, slider, vbox, hbox
)

open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plotting functions overview")
    src = read(srcdocpath, String)
    println(io, src, "\n")
    for func in plotting_functions
        fname = to_string(func)
        println(io, "## `$fname`\n")
        println(io, "```@docs")
        println(io, "$fname")
        println(io, "```\n")
        # add previews of all tags related to function
        println(io, "\n")
    end
end


########################################
#       Plot attributes overview       #
########################################

# automatically generate an overview of the plot attributes (keyword arguments), using a source md file
@info("Generating attributes page")
include("../src/plot_attr_desc.jl")
path = joinpath(srcpath, "plot-attributes.md")
srcdocpath = joinpath(srcpath, "src-plot-attributes.md")
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
#       Axis attributes overview       #
########################################

# automatically generate an overview of the axis attributes, using a source md file
@info("Generating axis page")
path = joinpath(srcpath, "axis.md")
srcdocpath = joinpath(srcpath, "src-axis.md")
include("../src/Axis2D_attr_desc.jl")
include("../src/Axis3D_attr_desc.jl")

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
#     Function signatures overview     #
########################################

# automatically generate an overview of the function signatures, using a source md file
@info("Generating signatures page")
path = joinpath(srcpath, "signatures.md")
srcdocpath = joinpath(srcpath, "src-signatures.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot function signatures")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    println(io, "```@docs")
    println(io, "convert_arguments")
    println(io, "```\n")

    println(io, "See [Plot attributes](@ref) for the available plot attributes.")
end

########################################
#          Colormap reference          #
########################################

@info "Generating colormap reference"

MakieGallery.generate_colorschemes_markdown(; GENDIR = genpath)

########################################
#              Type trees              #
########################################

################################################################################
#                 Building HTML documentation with Documenter                  #
################################################################################

@info("Running `makedocs` with Documenter.")

makedocs(
    doctest = false, clean = true,
    format = Documenter.HTML(
        prettyurls = false,
        assets = [
            "assets/favicon.ico",
            "assets/syntaxtheme.css"
        ],
    ),
    sitename = "Makie.jl",
    pages = Any[
        "Home" => "index.md",
        "Basics" => [
            "basic-tutorial.md",
            "animation.md",
            "interaction.md",
            "functions-overview.md",
        ],
        "Documentation" => [
            "scenes.md",
            "axis.md",
            "convenience.md",
            "signatures.md",
            "plot-attributes.md",
            "generated/colors.md",
            "lighting.md",
            "theming.md",
            "cameras.md",
            "recipes.md",
            "output.md",
            "backends.md",
            "troubleshooting.md"
        ],
        "MakieLayout" => [
            "Tutorial" => "makielayout/tutorial.md",
            "GridLayout" => "makielayout/grids.md",
            "LAxis" => "makielayout/laxis.md",
            "LLegend" => "makielayout/llegend.md",
            "Layoutables Examples" => "makielayout/layoutables_examples.md",
            "Theming Layoutables" => "makielayout/theming.md",
            "How Layouting Works" => "makielayout/layouting.md",
            "Frequently Asked Questions" => "makielayout/faq.md",
            "API Reference" => "makielayout/reference.md",
        ],
        "Developer Documentation" => [
            "why-makie.md",
            "devdocs.md",
            "AbstractPlotting Reference" => "abstractplotting_api.md",
        ],
    ]
)

################################################################################
#                           Deploying documentation                            #
################################################################################

# add a custom configuration for Gitlab so the GPU-powered docs can be
# automatically uploaded to Github Pages

struct Gitlab <: Documenter.DeployConfig
    commit_branch::String
    pull_request_iid::String
    repo_slug::String
    commit_tag::String
    pipeline_source::String
end

function Gitlab()
    commit_branch = get(ENV, "CI_COMMIT_BRANCH", "")
    pull_request_iid = get(ENV, "CI_EXTERNAL_PULL_REQUEST_IID", "")
    repo_slug = get(ENV, "CI_PROJECT_PATH_SLUG", "")
    commit_tag = get(ENV, "CI_COMMIT_TAG", "")
    pipeline_source = get(ENV, "CI_PIPELINE_SOURCE", "")
    Gitlab(
        commit_branch,
        pull_request_iid,
        repo_slug,
        commit_tag,
        pipeline_source,
    )
end

function Documenter.deploy_folder(cfg::Gitlab;
        repo,
        repo_previews = repo,
        devbranch,
        push_preview,
        devurl,
        branch = "gh-pages",
        branch_previews = branch,
        kwargs...)

    marker(x) = x ? "✔" : "✘"

    io = IOBuffer()
    all_ok = true

    println(io, "\nGitlab config:")
    println(io, "  Commit branch: \"", cfg.commit_branch, "\"")
    println(io, "  Pull request IID: \"", cfg.pull_request_iid, "\"")
    println(io, "  Repo slug: \"", cfg.repo_slug, "\"")
    println(io, "  Commit tag: \"", cfg.commit_tag, "\"")
    println(io, "  Pipeline source: \"", cfg.pipeline_source, "\"")

    build_type = if cfg.pull_request_iid != ""
        :preview
    elseif cfg.commit_tag != ""
        :release
    else
        :devbranch
    end

    println(io, "Detected build type: ", build_type)

    if build_type == :release
        tag_ok = occursin(Base.VERSION_REGEX, cfg.commit_tag)
        println(io, "- $(marker(tag_ok)) ENV[\"CI_COMMIT_TAG\"] contains a valid VersionNumber")
        all_ok &= tag_ok

        is_preview = false
        subfolder = cfg.commit_tag
        deploy_branch = branch
        deploy_repo = repo
        
    elseif build_type == :preview
        pr_number = tryparse(Int, cfg.pull_request_iid)
        pr_ok = pr_number !== nothing
        all_ok &= pr_ok
        println(io, "- $(marker(pr_ok)) ENV[\"CI_EXTERNAL_PULL_REQUEST_IID\"]=\"$(cfg.pull_request_iid)\" is a number")
        btype_ok = push_preview
        all_ok &= btype_ok
        is_preview = true
        println(io, "- $(marker(btype_ok)) `push_preview` keyword argument to deploydocs is `true`")
        ## deploy to previews/PR
        subfolder = "previews/PR$(something(pr_number, 0))"
        deploy_branch = branch_previews
        deploy_repo = repo_previews
    else
        branch_ok = !isempty(cfg.commit_tag) || cfg.commit_branch == devbranch
        all_ok &= branch_ok
        println(io, "- $(marker(branch_ok)) ENV[\"CI_COMMIT_BRANCH\"] matches devbranch=\"$(devbranch)\"")
        is_preview = false
        subfolder = devurl
        deploy_branch = branch
        deploy_repo = repo
    end

    key_ok = haskey(ENV, "DOCUMENTER_KEY")
    println(io, "- $(marker(key_ok)) ENV[\"DOCUMENTER_KEY\"] exists")
    all_ok &= key_ok

    print(io, "Deploying to folder \"$(subfolder)\": $(marker(all_ok))")
    @info String(take!(io))

    return Documenter.DeployDecision(; all_ok = all_ok, branch = deploy_branch, repo = deploy_repo,
        subfolder = subfolder, is_preview = is_preview)
end

Documenter.authentication_method(::Gitlab) = Documenter.SSH

function Documenter.documenter_key(::Gitlab)
    return ENV["DOCUMENTER_KEY"]
end

deploydocs(
    repo = "github.com/JuliaPlots/MakieGallery.jl",
    deploy_config = Gitlab(),
    push_preview = false
)
