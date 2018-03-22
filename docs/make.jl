using Documenter#, Makie
cd(Pkg.dir("Makie", "docs"))
include("../examples/library.jl")

using Documenter: Selectors, Expanders, Markdown
using Documenter.Markdown: Link, Paragraph
struct DatabaseLookup <: Expanders.ExpanderPipeline end

Selectors.order(::Type{DatabaseLookup}) = 0.5
Selectors.matcher(::Type{DatabaseLookup}, node, page, doc) = false
match_kw(x::String) = (println(x);ismatch(r"\@library\[example\] \"(.*)\"", x))
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
            matched = match(r"\@library\[example\] \"(.*)\"", elem)
            matched != nothing && break
        end
    end
    matched == nothing && error("No match: $x")
    # The sandboxed module -- either a new one or a cached one from this page.
    database_key = matched[1]
    # Evaluate the code block. We redirect stdout/stderr to `buffer`.
    page.mapping[x] = Markdown.Code("julia", look_up_source(database_key))
end




makedocs(
    #modules = [Makie],
    debug = true,
    format = :html,
    source = "src",
    sitename = "Plotting in pure Julia",
    pages = ["Home" => "index.md"]
)
# args = [
#     :debug => true,
#     :format => :html,
#     :source => "preprocessed",
#     :sitename => "Plotting in pure Julia",
#     :pages => ["Home" => "index.md"]
# ]
# document = Documenter.Documents.Document(; args...)
# document.user.root
# subtypes(Documenter.Builder.DocumentPipeline)

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
