using Documenter, Makie
cd(@__DIR__)
include("../examples/library.jl")
include("documenter_extension.jl")
import AbstractPlotting: _help, to_string, to_func, to_type

pathroot = Pkg.dir("Makie")
docspath = Pkg.dir("Makie", "docs")
srcpath = joinpath(pathroot, "docs", "src")
buildpath = joinpath(pathroot, "docs", "build")
mediapath = joinpath(pathroot, "docs", "build", "media")
expdbpath = joinpath(buildpath, "examples-database.html")
# TODO can we teach this to documenter somehow?
ispath(mediapath) || mkpath(mediapath)
output_path(entry, ending) = joinpath(mediapath, string(entry.unique_name, ending))
function save_example(entry, x::Scene)
    path = output_path(entry, ".jpg")
    Makie.save(path, x)
    path
end
save_example(entry, x::String) = x # to do
AbstractPlotting.set_theme!(resolution = (500, 500))
eval_examples(outputfile = output_path) do example, value
    AbstractPlotting.set_theme!(resolution = (500, 500))
    srand(42)
    path = save_example(example, value)
    name = string("thumb-", example.unique_name, ".jpg")
    generate_thumbnail(path, joinpath(dirname(path), name))
end

# =============================================
# automatically generate an overview of the atomic functions, using a source md file
path = joinpath(srcpath, "functions-overview.md")
srcdocpath = joinpath(srcpath, "src-functions.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    medialist = readdir(mediapath)
    isempty(medialist) && error("media folder is empty -- perhaps you forgot to generate the plots? :)")
    println(io, "# Atomic functions overview")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    for func in (atomics..., contour)
        fname = to_string(func)
        expdbpath = joinpath(buildpath, "examples-$fname.html")
        println(io, "## `$fname`\n")
        try
            println(io, "```@docs")
            println(io, "$fname")
            println(io, "```\n")
            embed_thumbnail_link(io, func, buildpath, expdbpath)
        catch e
            println("ERROR: Didn't work with $fname\n")
            Base.showerror(STDERR, e)
        end
        println(io, "\n")
    end
end

# =============================================
# automatically generate gallery based on looping through the database
# using pre-generated plots from generate_plots.jl
cd(docspath)
example_pages = nothing
example_list = String[]
for func in (atomics..., contour)
    fname = to_string(func)
    info("generating examples database for $fname")
    path = joinpath(srcpath, "examples-$fname.md")
    indices = find_indices(func)
    open(path, "w") do io
        println(io, "# `$fname`")
        examples2source(fname) do entry, source
            # print bibliographic stuff
            println(io, "## \"$(entry.title)\"")
            print(io, "Tags: ")
            tags = sort(collect(entry.tags))
            for j = 1:length(tags) - 1; print(io, "`$(tags[j])`, "); end
            println(io, "`$(tags[end])`.\n")
            uname = string(entry.unique_name)
            src_lines = entry.file_range
            println(io, """
            ```julia
            $source
            ```
            """)
            embed_plot(io, uname, mediapath, buildpath; src_lines = src_lines)
        end
    end
    push!(example_list, "examples-$fname.md")
end
example_pages = "Examples" => example_list


# =============================================
# automatically generate an overview of the plot attributes (keyword arguments), using a source md file
include("../src/attr_desc.jl")
path = joinpath(srcpath, "attributes.md")
srcdocpath = joinpath(srcpath, "src-attributes.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot attributes")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    print_table(io, attr_desc)
end

# documenter deletes everything in build, so we need to move the media out and then back in again.
tmp_path = joinpath(mktempdir(), "media")
ispath(tmp_path) && rm(tmp_path, force = true, recursive = true)
cp(mediapath, tmp_path)

makedocs(
    modules = [Makie, AbstractPlotting],
    doctest = false, clean = true,
    format = :html,
    sitename = "Makie.jl",
    pages = Any[
        "Home" => "index.md",
        "Basics" => [
            # "scene.md",
            # "conversions.md",
            "help_functions.md",
            "functions-overview.md",
            "signatures.md",
            "attributes.md",
            # "documentation.md",
            # "backends.md",
            # "extending.md",
            # "themes.md",
            "interaction.md",
            # "axis.md",
            # "legends.md",
            "output.md",
            # "docs-test.md"
            # "reflection.md",
            # "layout.md"
        ],
        # atomics_pages,
        "Examples" => [
            example_list
            # "tags_wordcloud.md",
            #"linking-test.md"
        ]
        # "Developper Documentation" => [
        #     "devdocs.md",
        # ],
    ]
)
# move it back
mv(tmp_path, mediapath)
#
# ENV["TRAVIS_BRANCH"] = "latest"
# ENV["TRAVIS_PULL_REQUEST"] = "false"
# ENV["TRAVIS_REPO_SLUG"] = "github.com/JuliaPlots/Makie.jl.git"
# ENV["TRAVIS_TAG"] = "v1.0.0"
# ENV["TRAVIS_OS_NAME"] = "linux"
# ENV["TRAVIS_JULIA_VERSION"] = "0.6"
#
# deploydocs(
#     deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
#     repo   = "github.com/JuliaPlots/Makie.jl.git",
#     julia  = "0.6",
#     target = "build",
#     osname = "linux",
#     make = nothing
# )
