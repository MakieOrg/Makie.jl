
using Documenter: Selectors, Expanders, Markdown
using Documenter.Markdown: Link, Paragraph
struct DatabaseLookup <: Expanders.ExpanderPipeline end

Selectors.order(::Type{DatabaseLookup}) = 0.5
Selectors.matcher(::Type{DatabaseLookup}, node, page, doc) = false

const regex_pattern = r"example_database\(([\"a-zA-Z_0-9. ]+)\)"
const atomics = (
    heatmap,
    image,
    lines,
    linesegments,
    mesh,
    meshscatter,
    scatter,
    surface,
    text,
    Makie.volume
)

match_kw(x::String) = ismatch(regex_pattern, x)
match_kw(x::Paragraph) = any(match_kw, x.content)
match_kw(x::Any) = false
Selectors.matcher(::Type{DatabaseLookup}, node, page, doc) = match_kw(node)

# ============================================= Simon's implementation
function look_up_source(database_key)
    entries = find(x-> x.title == database_key, database)
    # current implementation finds titles, but we can also search for tags too
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

"""
    embed_video(relapath::AbstractString)

Generates a MD-formatted string for embedding video into Markdown files
(since `Documenter.jl` doesn't support directly embedding mp4's).
"""
function embed_video(relapath::AbstractString)
    return str = """
        ```@raw html
        <video controls autoplay>
          <source src="$(relapath)" type="video/mp4">
          Your browser does not support mp4. Please use a modern browser like Chrome or Firefox.
        </video>
        ```
        """
end

"""
    generate_thumbnail(path::AbstractString; sz::Int = 200)

Generates a (proportionally-scaled) thumbnail with maximum side dimension `sz`.
`sz` must be an integer, and the default value is 200 pixels.
"""
function generate_thumbnail(path::AbstractString; sz::Int = 200)
    !isfile(path) && warn("Input argument must be a file!")
    dir = dirname(path)
    origname = basename(path)
    thumbname = "thumb-$(origname)"

    img = Images.load(path)
    (height, width) = size(img)

    scale_height = sz / height
    scale_width = sz / width

    scale = min(scale_height, scale_width)

    (new_height, new_width) = (height, width) .* scale

    newimg = Images.imresize(img, round.(Int, (new_height, new_width)))
    Makie.save(joinpath(dir, thumbname), newimg)
end
