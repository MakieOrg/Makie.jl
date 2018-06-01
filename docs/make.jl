using Documenter, Makie
cd(Pkg.dir("Makie", "docs"))
include("../examples/library.jl")

using Documenter: Selectors, Expanders, Markdown
using Documenter.Markdown: Link, Paragraph
struct DatabaseLookup <: Expanders.ExpanderPipeline end

Selectors.order(::Type{DatabaseLookup}) = 0.5
Selectors.matcher(::Type{DatabaseLookup}, node, page, doc) = false

const regex_pattern = r"example_database\(([\"a-zA-Z_0-9. ]+)\)"

match_kw(x::String) = ismatch(regex_pattern, x)
match_kw(x::Paragraph) = any(match_kw, x.content)
match_kw(x::Any) = false
Selectors.matcher(::Type{DatabaseLookup}, node, page, doc) = match_kw(node)

function look_up_source(database_key)
    entries = find(x-> x.title == database_key, database)
    isempty(entries) && error("No entry found for database reference $database_key")
    length(entries) > 1 && error("Multiple entries found for database reference $database_key")
    sprint() do io
        print_code(
            io, database, entries[1],
            scope_start = "",
            scope_end = "",
            indent = "",
            resolution = (entry)-> "resolution = (500, 500)",
            outputfile = (entry, ending)-> Pkg.dir("Makie", "docs", "media", string(entry.unique_name, ending))
        )
    end
end
function Selectors.runner(::Type{DatabaseLookup}, x, page, doc)
    matched = nothing
    for elem in x.content
        if isa(elem, AbstractString)
            matched = match(regex_pattern, elem)
            matched != nothing && break
        end
    end
    matched == nothing && error("No match: $x")
    # The sandboxed module -- either a new one or a cached one from this page.
    database_keys = filter(x-> !(x in ("", " ")), split(matched[1], '"'))
    content = map(database_keys) do database_key
        Markdown.Code("julia", look_up_source(database_key))
    end
    # Evaluate the code block. We redirect stdout/stderr to `buffer`.
    page.mapping[x] = Markdown.MD(content)
end

# =============================================
# automatically generate gallery based on tags
# tags_list = []
tags_list = sort(unique(tags_list))
path = joinpath(@__DIR__, "..", "docs", "src", "examples-for-tags.md")
open(path, "w") do io
    println(io, "# List of all tags including 1 randomly-selected example from each tag")
    println(io, "## List of tags")
    for tag in tags_list
        println(io, "* $tag")
    end
    println(io, "\n")
    for tag in tags_list
        # search for the indices where tag is found
        indices = find_indices(tag; title = nothing, author = nothing)
        # pick a random example from the list
        idx = indices[rand(1:length(indices))];
        println(io, "## $tag")
        try
            _print_source(io, idx; style = "julia")
        catch
            println("ERROR: Didn't work with $tag\n")
        end
        println(io, "\n")
    end
end


makedocs(
    modules = [Makie],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = [
        "Home" => "index.md",
        "Basics" => [
            "scene.md",
            "conversions.md",
            "functions.md",
            "documentation.md",
            "backends.md",
            "extending.md",
            "themes.md",
            "interaction.md",
            "axis.md",
            "legends.md",
            "output.md",
            "reflection.md",
            "layout.md"
        ],
        "Developper Documentation" => [
            "devdocs.md",
        ],
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
