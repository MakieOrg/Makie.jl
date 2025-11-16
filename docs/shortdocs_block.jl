abstract type ShortDocsBlocks <: Documenter.Expanders.NestedExpanderPipeline end


Documenter.Selectors.order(::Type{ShortDocsBlocks}) = 3.0 # like @docs
Documenter.Selectors.matcher(::Type{ShortDocsBlocks}, node, page, doc) = Documenter.iscode(node, r"^@shortdocs")

function unlink_with_all_following_siblings!(node)
    next = node.next
    MarkdownAST.unlink!(node)
    if next !== nothing
        unlink_with_all_following_siblings!(next)
    end
    return
end

# ```@shortdocs is like ```@docs but it cuts off the docstring for the plot functions at the attributes
# section because all the attributes are already added with examples anyway
function Documenter.Selectors.runner(::Type{ShortDocsBlocks}, node, page, doc)
    el = node.element
    el.info = replace(el.info, "@shortdocs" => "@docs")
    Documenter.Selectors.runner(Documenter.Expanders.DocsBlocks, node, page, doc)

    docsnode = first(node.children).element
    if !(docsnode isa Documenter.DocsNode)
        error("docs node conversion failed for $el")
    end

    mdasts = docsnode.mdasts

    ast_to_look_for = MarkdownAST.@ast MarkdownAST.Paragraph() do
        MarkdownAST.Strong() do
            "Attributes"
        end
    end

    for mdast in mdasts
        found = false
        for child in mdast.children
            if child == ast_to_look_for
                unlink_with_all_following_siblings!(child)
                found = true
                break
            end
        end
        if !found
            display(mdast)
            error("Found no Attributes section in above markdown ast")
        end
    end
    return
end
