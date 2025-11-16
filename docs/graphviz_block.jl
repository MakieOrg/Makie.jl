abstract type GraphvizBlocks <: Documenter.Expanders.NestedExpanderPipeline end

Documenter.Selectors.order(::Type{GraphvizBlocks}) = 8.1 # like @example, but after FigureBlocks
Documenter.Selectors.matcher(::Type{GraphvizBlocks}, node, page, doc) = Documenter.iscode(node, r"^@graphviz")

module GraphvizDocsHelpers
    import Graphviz_jll

    struct GraphvizSVG
        dot_code::String
    end

    function Base.show(io::IO, ::MIME"image/svg+xml", g::GraphvizSVG)
        # Create a temporary directory and work within it
        return mktempdir() do temp_dir
            dot_file = joinpath(temp_dir, "temp.dot")
            svg_file = joinpath(temp_dir, "temp.svg")

            # Write dot code to temporary file
            write(dot_file, g.dot_code)

            # Run Graphviz to generate SVG with styling options
            run(`$(Graphviz_jll.dot()) 
                -Tsvg 
                -Gfontname="system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif"
                -Gfontsize=11
                -Gbgcolor=transparent
                -Nshape=box
                -Nstyle=filled
                -Nfillcolor="#f5f5f5ff"
                -Ncolor="#727272ff"
                -Nfontcolor="#202020ff"
                -Nfontname="system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif"
                -Nfontsize=11
                -Ecolor="#5b5b5bff"
                -Efontname="system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif"
                -Efontsize=10
                -o $svg_file 
                $dot_file`)

            # Read and write the generated SVG content directly to io
            svg_content = read(svg_file, String)
            write(io, svg_content)
        end
    end
end

function Documenter.Selectors.runner(::Type{GraphvizBlocks}, node, page, doc)
    el = node.element
    el.info = "@example"
    el.code = transform_graphviz_code(el.code)
    return Documenter.Selectors.runner(Documenter.Expanders.ExampleBlocks, node, page, doc)
end

function transform_graphviz_code(code::String)
    # Add # hide to each line of the DOT code
    hidden_code = join([line * " # hide" for line in split(code, '\n')], '\n')

    return """
    import ..GraphvizDocsHelpers # hide
    dot_code = raw\"\"\" # hide
    $hidden_code
    \"\"\" # hide
    GraphvizDocsHelpers.GraphvizSVG(dot_code) # hide
    """
end
