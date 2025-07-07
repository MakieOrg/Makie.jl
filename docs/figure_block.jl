abstract type FigureBlocks <: Documenter.Expanders.NestedExpanderPipeline end


Documenter.Selectors.order(::Type{FigureBlocks}) = 8.0 # like @example
Documenter.Selectors.matcher(::Type{FigureBlocks}, node, page, doc) = Documenter.iscode(node, r"^@figure")

module MakieDocsHelpers
    import ImageTransformations
    import Makie
    import FileIO

    struct Png
        bytes::Vector{UInt8}
        size_px::Tuple{Int, Int}
        id::String
    end

    struct PageInfo
        path::String
        title::String
    end

    FIGURES = Dict{PageInfo, Vector{Png}}()
    struct AsMIME{M <: MIME, V}
        mime::M
        value::V
    end

    Base.show(io::IO, m::MIME"image/svg+xml", a::AsMIME{MIME"image/svg+xml"}) = show(io, m, a.value)
    Base.show(io::IO, m::MIME"image/png", a::AsMIME{MIME"image/png"}) = show(io, m, a.value)

    function register_figure!(page, pagetitle, id, figurelike)
        vec = get!(Vector, FIGURES, PageInfo(page, pagetitle))
        Makie.update_state_before_display!(figurelike)
        scene = Makie.get_scene(figurelike)
        img = Makie.colorbuffer(scene)
        backend = nameof(Makie.current_backend())
        px_per_unit = Makie.to_value(Makie.current_default_theme()[backend][:px_per_unit])
        size_px = Tuple(round.(Int, reverse(size(img)) ./ px_per_unit))

        ntrim = 3 # `restrict` makes dark border pixels which we cut off
        img = @view ImageTransformations.restrict(img)[ntrim:(end - ntrim), ntrim:(end - ntrim)]
        # img = @view ImageTransformations.restrict(img)[ntrim:end-ntrim,ntrim:end-ntrim]
        io = IOBuffer()
        FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
        push!(vec, Png(take!(io), size_px, id))
        return
    end

    struct FileInfo
        filename::String
        id::String
        size_px::Tuple{Int, Int}
    end
    struct OverviewSection
        d::Dict{PageInfo, Vector{FileInfo}}
    end

    function OverviewSection(page::String)
        r = Regex("/$page/")

        filtered = filter(pairs(FIGURES)) do (pageinfo, pngs)
            match(r, pageinfo.path) !== nothing
        end

        fileinfo_dict = Dict{PageInfo, Vector{FileInfo}}()
        for (pageinfo, pngs) in pairs(filtered)
            fileinfos = map(pngs) do png
                filename = "$(string(hash(png.bytes), base = 62)).png"
                open(filename, "w") do _io
                    write(_io, png.bytes)
                end
                return FileInfo(filename, png.id, png.size_px)
            end
            fileinfo_dict[pageinfo] = fileinfos
        end

        return OverviewSection(fileinfo_dict)
    end

    function Base.show(io::IO, ::MIME"text/markdown", o::OverviewSection)
        pages = sort(collect(keys(o.d)), by = x -> x.path)
        for page in pages
            fileinfos = o.d[page]
            pagename, _ = splitext(basename(page.path))
            println(io, "### $(page.title)") # these links are created too late for Documenter's crossref mechanism, which is good because they should not conflict with the originals
            println(io)
            println(io, """<div :class="\$style.container">""")
            for fileinfo in fileinfos
                println(
                    io, """
                    <a href="./$pagename.html#example-$(fileinfo.id)">
                        <img src=\"./$(fileinfo.filename)\" />
                    </a>
                    """
                )
            end
            println(io, "</div>")
            println(io)
        end

        return println(
            io, """
            <style module>
                .container {
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    grid-gap: 1.5em;
                    padding: 2em 0;
                }

                @media (min-width: 640px) {
                    .container {
                        grid-template-columns: repeat(3, 1fr);
                    }
                }

                @media (min-width: 960px) {
                    .container {
                        grid-template-columns: repeat(4, 1fr);
                    }
                }
            </style>
            """
        )
    end
end

const IMAGE_COUNTER = Ref(0)

function Documenter.Selectors.runner(::Type{FigureBlocks}, node, page, doc)
    title = first(
        Iterators.filter(page.elements) do el
            el isa Markdown.Header{1}
        end
    ).text[]

    if title isa Markdown.Link
        title = title.text[]
    end

    el = node.element
    infoexpr = Meta.parse(el.info)
    args = infoexpr.args[3:end]
    if !isempty(args) && args[1] isa Symbol
        blockname = string(args[1])
        kwargs = args[2:end]
    else
        blockname = ""
        kwargs = args
    end

    is_continued = false
    # check if any previous code block is an @example block and has the same name (previous @figure blocks are
    # already converted at this point)
    if blockname != ""
        # iterate all the previous siblings
        prev = node.previous
        while prev !== nothing
            if prev.element isa Documenter.MultiOutput && prev.element.codeblock.info == "@example $blockname"
                is_continued = true
                break
            end
            prev = prev.previous
        end
    end

    kwargs = Dict(
        map(kwargs) do expr
            if !(expr isa Expr) && expr.head !== :(=) && length(expr.args) == 2 && expr.args[1] isa Symbol && expr.args[2] isa Union{String, Number, Symbol}
                error("Invalid keyword arg expression: $expr")
            end
            expr.args[1] => expr.args[2]
        end
    )
    el.info = "@example $blockname"

    id = string(hash(IMAGE_COUNTER[], hash(el.code)), base = 16)[1:7]
    IMAGE_COUNTER[] += 1
    el.code = transform_figure_code(el.code; id, page = page.source, pagetitle = title, is_continued, kwargs...)
    Documenter.Selectors.runner(Documenter.Expanders.ExampleBlocks, node, page, doc)

    last_png = MakieDocsHelpers.FIGURES[MakieDocsHelpers.PageInfo(page.source, title)][end]
    @assert last_png.id == id
    size_px = last_png.size_px

    mime = get(kwargs, :mime, :png)
    image_name = "$id.$mime"

    MarkdownAST.insert_before!(node, @ast Documenter.RawNode(:html, "<a id=\"example-$id\" />"))
    # we save and insert the image manually, just because we want to be able to set width and height.
    # this makes images look sharp as intended, and it improves the accuracy with which one gets to
    # image examples from the overview pages, as with annotated width and height the right locations can
    # be computed even before all the images have been loaded. Otherwise they are usually wrong the first time.
    return MarkdownAST.insert_after!(node, @ast Documenter.RawNode(:html, "<img src=\"./$image_name\" width=\"$(size_px[1])px\" height=\"$(size_px[2])px\"/>"))
end

function transform_figure_code(code::String; id::String, page::String, pagetitle::String, is_continued::Bool, backend::Symbol = :CairoMakie, mime = :png)
    backend in (:CairoMakie, :GLMakie) || error("Invalid backend $backend")
    mimetype = mime == :svg ? "image/svg+xml" : mime == :png ? "image/png" : error("Unknown mimetype $mime")

    return (
        is_continued ? "" : """
            using $backend
            $backend.activate!(; px_per_unit = 2) # hide
            """
    ) *
        """
        import ..MakieDocsHelpers # hide
        var"#result" = begin # hide
        $code
        end # hide
        MakieDocsHelpers.register_figure!("$page", "$pagetitle", "$id", var"#result") # hide
        save("$id.$mime", var"#result") # hide
        nothing # hide
        """
end
