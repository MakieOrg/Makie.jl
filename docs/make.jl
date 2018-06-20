using Documenter, Makie
cd(@__DIR__)
include("../examples/library.jl")
include("documenter_extension.jl")
import AbstractPlotting: _help, to_string, to_func, to_type

pathroot = Pkg.dir("Makie")
docspath = Pkg.dir("Makie", "docs")
srcpath = joinpath(pathroot, "docs", "src")
buildpath = joinpath(pathroot, "docs", "build")
mediapath = joinpath(pathroot, "docs", "media")
expdbpath = joinpath(buildpath, "examples-database.html")

# =============================================
# automatically generate an overview of the atomic functions
# path = joinpath(srcpath, "functions-overview.md")
# open(path, "w") do io
#     println(io, "# Atomic functions overview")
#     for func in (atomics..., contour)
#         expdbpath = joinpath(buildpath, "examples-$func.html")
#         println(io, "## `$(to_string(func))`\n")
#         try
#             println(io, "```@docs")
#             println(io, "$(to_string(func))")
#             println(io, "```\n")
#             embed_thumbnail_link(io, func, buildpath, expdbpath)
#         catch e
#             println("ERROR: Didn't work with $func\n")
#             Base.showerror(STDERR, e)
#         end
#         println(io, "\n")
#     end
# end

# =============================================
# automatically generate an overview of the atomic functions, using a source md file
path = joinpath(srcpath, "functions-overview.md")
srcdocpath = joinpath(srcpath, "src-functions.md")
open(path, "w") do io
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
# automatically generate an detailed overview of each of the atomic functions
# includes plot thumbnails
# atomics_pages = nothing
# atomics_list = String[]
# atomicspath = joinpath(srcpath, "atomics_details")
# isdir(atomicspath) || mkdir(atomicspath)
# for func in (atomics..., contour)
#     path = joinpath(atomicspath, "$(to_string(func)).md")
#     open(path, "w") do io
#         println(io, "# `$(to_string(func))`")
#         try
#             _help(io, func; extended = true)
#             embed_thumbnail_link(io, func, atomicspath, expdbpath)
#         catch e
#             println("ERROR: Didn't work with $func\n")
#             Base.showerror(STDERR, e)
#         end
#         println(io, "\n")
#     end
#     push!(atomics_list, "atomics_details/$(to_string(func)).md")
# end
# atomics_pages = "Atomic functions details" => atomics_list

# =============================================
# automatically generate gallery based on tags - all examples
# tags_list = sort!(unique(tags_list), by = x -> lowercase(x))
# path = joinpath(srcpath, "examples-database-tags.md")
# open(path, "w") do io
#     println(io, "# Examples gallery, sorted by tag")
#     println(io, "## Tags")
#     for tag in tags_list
#         println(io, "  * [$tag](@ref tag_$(replace(tag, " ", "_")))")
#     end
#     println(io, "\n")
#     for tag in tags_list
#         counter = 1
#         # search for the indices where tag is found
#         indices = find_indices(tag; title = nothing, author = nothing)
#         println(io, "## [$tag](@id tag_$(replace(tag, " ", "_")))")
#         for idx in indices
#             try
#                 entry = database[idx]
#                 uname = string(entry.unique_name)
#                 src_lines = entry.file_range
#                 println(io, "### Example $counter, \"$(entry.title)\"")
#                 _print_source(io, idx; style = "julia")
#                 embed_plot(io, uname, mediapath, buildpath; src_lines = src_lines)
#                 counter += 1
#             catch e
#                 println("ERROR: Didn't work with $tag at index $idx\n")
#                 Base.showerror(STDERR, e)
#             end
#         end
#         println(io, "\n")
#     end
# end

# =============================================
# automatically generate gallery based on looping through the database
# using pre-generated plots from generate_plots.jl
cd(docspath)
medialist = readdir(mediapath)
example_pages = nothing
example_list = String[]
for func in (atomics..., contour)
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
            "functions-autogen.md",
            "functions.md"
            # "documentation.md",
            # "backends.md",
            # "extending.md",
            # "themes.md",
            # "interaction.md",
            # "axis.md",
            # "legends.md",
            # "output.md",
            # "reflection.md",
            # "layout.md"
        ],
        atomics_pages,
        "Examples" => [
            "examples-for-tags.md",
            "examples-database.md",
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
# ENV["TRAVIS_REPO_SLUG"] = "github.com/SimonDanisch/MakieDocs.git"
# ENV["TRAVIS_TAG"] = "tag"
# ENV["TRAVIS_OS_NAME"] = "linux"
# ENV["TRAVIS_JULIA_VERSION"] = "0.6"
#
# deploydocs(
#     deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
#     repo   = "github.com/SimonDanisch/MakieDocs.git",
#     julia  = "0.6",
#     target = "build",
#     osname = "linux",
#     make = nothing
# )
