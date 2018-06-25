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
            help_attributes(io, func; extended = true)
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
medialist = readdir(mediapath)
example_pages = nothing
example_list = String[]
for func in (atomics..., contour)
    isempty(medialist) && error("media folder is empty -- perhaps you forgot to generate the plots? :)")
    fname = to_string(func)
    info("generating examples database for $fname")
    path = joinpath(srcpath, "examples-$fname.md")
    indices = find_indices(func)
    open(path, "w") do io
        println(io, "# `$fname`")
        counter = 1
        groupid_last = NO_GROUP
        for i in indices
            entry = database[i]
            # print bibliographic stuff
            println(io, "## \"$(entry.title)\"")
            print(io, "Tags: ")
            tags = sort(collect(entry.tags))
            for j = 1:length(tags) - 1; print(io, "`$(tags[j])`, "); end
            println(io, "`$(tags[end])`.\n")
            # There are 3 possible conditions:
            #  cond 1: entry is part of a group, and is in same group as last example (continuation)
            #  cond 2: entry is part of a new group
            #  cond 3: entry is not part of a group
            if isgroup(entry) && entry.groupid == groupid_last
                try
                    uname = string(entry.unique_name)
                    src_lines = entry.file_range
                    _print_source(io, i; style = "julia", example_counter = counter)
                    embed_plot(io, uname, mediapath, buildpath; src_lines = src_lines)
                    embedpath = nothing
                catch e
                    Base.showerror(STDERR, e)
                    println("ERROR: Didn't work with \"$(entry.title)\" at index $i\n")
                end
            elseif isgroup(entry)
                try
                    groupid_last = entry.groupid
                    uname = string(entry.unique_name)
                    src_lines = entry.file_range
                    _print_source(io, i; style = "julia", example_counter = counter)
                    embed_plot(io, uname, mediapath, buildpath; src_lines = src_lines)
                    embedpath = nothing
                catch e
                    Base.showerror(STDERR, e)
                    println("ERROR: Didn't work with \"$(entry.title)\" at index $i\n")
                end
            else
                try
                    uname = string(entry.unique_name)
                    src_lines = entry.file_range
                    _print_source(io, i; style = "julia", example_counter = counter)
                    embed_plot(io, uname, mediapath, buildpath; src_lines = src_lines)
                    embedpath = nothing
                    counter += 1
                    groupid_last = entry.groupid
                catch e
                    Base.showerror(STDERR, e)
                    println("ERROR: Didn't work with \"$(entry.title)\" at index $i\n")
                end
            end
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


# automatically generate an overview of the function signatures, using a source md file
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


# TODO can we teach this to documenter somehow?
cp(Pkg.dir("Makie", "docs", "media"), mediapath)

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
