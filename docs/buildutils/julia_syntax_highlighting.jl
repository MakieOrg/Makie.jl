"""
Replaces all absolute links in all html files in the __site folder with
relative links.
"""
function add_julia_syntax_highlighting()
    cd("__site") do
        for (root, _, files) in walkdir(".")
            path = join(splitpath(root)[2:end], "/")

            html_files = filter(endswith(".html"), files)
            for file in html_files
                s = read(joinpath(root, file), String)
                s = replace(s, '\0' => "\\0")

                html = parsehtml(s)

                for e in PreOrderDFS(html.root)
                    if e isa HTMLElement{:code} && haskey(e.attributes, "class") && e.attributes["class"] == "language-julia"
                        e.attributes["class"] = "language-julia hljs"
                        text = only(e.children)::HTMLText
                        code = text.text
                        empty!(e.children)
                        append!(e.children, highlighted_julia_code(code))
                    end
                end

                open(joinpath(root, file), "w") do f
                    return print(f, html)
                end
            end
        end
    end
end

# function highlighted_julia_code(code::String)
#     highlighted = try 
#         parsed = JuliaSyntax.parseall(JuliaSyntax.GreenNode, code; ignore_trivia = false)
#         handle_green_node(parsed, code)
#     catch e
#         if e isa JuliaSyntax.ParseError
#             [HTMLText(code)]
#         else
#             rethrow(e)
#         end
#     end
#     return highlighted
# end

# function handle_green_node(node, code)
#     elements = HTMLNode[]
#     handle_green_node!(elements, node, code, 0)
#     return elements
# end


# function handle_green_node!(elements, node, code, offset)
#     if isempty(node.args)
#         endindex = prevind(code, offset+node.span+1)
#         handle_leaf!(elements, node, @view(code[offset+1:endindex]))
#     # elseif node.head.kind == JuliaSyntax.K"string"
#     #     id = node.args[1]
#     #     if id.head.kind == JuliaSyntax.K"Identifier"

#     #     else

#     #     end
#     #     cum_span = sum(x -> x.span, node.args)
#     #     endindex = prevind(code, offset+cum_span+1)
#     #     push!(elements, _span("hljs-string", @view(code[offset+1:endindex])))
#     elseif node.head.kind == JuliaSyntax.K"call"
#         cum_span = sum(x -> x.span, node.args)
#         endindex = prevind(code, offset+cum_span+1)
#         push!(elements, _span("hljs-string", @view(code[offset+1:endindex])))
#     else
#         cum_offset = 0
#         for arg in node.args
#             handle_green_node!(elements, arg, code, offset + cum_offset)
#             cum_offset += arg.span
#         end
#     end
# end

# function handle_leaf!(elements, node, code)
#     k = node.head.kind
#     if k == JuliaSyntax.K"Comment"
#         push!(elements, _span("hljs-comment", code))
#     elseif k in (JuliaSyntax.K"Float", JuliaSyntax.K"Integer")
#         push!(elements, _span("hljs-number", code))
#     elseif k === JuliaSyntax.K"Identifier"
#         push!(elements, _span("hljs-variable", code))
#     elseif k in (JuliaSyntax.K"block", JuliaSyntax.K"end", JuliaSyntax.K"for", JuliaSyntax.K"using", JuliaSyntax.K"if", JuliaSyntax.K"elseif", JuliaSyntax.K"else", JuliaSyntax.K"while", JuliaSyntax.K"do", JuliaSyntax.K"mutable", JuliaSyntax.K"struct", JuliaSyntax.K"function")
#         push!(elements, _span("hljs-keyword", code))
#     else
#         push!(elements, HTMLText(code))
#     end
# end

import JuliaSyntax
import JuliaSyntax: var"@K_str", Kind, Tokenize, tokenize
import .Tokenize: kind, untokenize

_span(class, code) = HTMLElement{:span}([HTMLText(code)], NullNode(), Dict("class" => class))

function highlighted_julia_code(code)
    vec = highlight(tokenize(code))
    map(vec) do (rang, face)
        start = rang.start
        stop = prevind(code, rang.stop+1) # have to index on the first codepoint of last char
        if face === nothing
            HTMLText(@view(code[start:stop]))
        else
            _span(string(face), @view(code[start:stop]))
        end
    end
end

function highlight(tokens)
    MAX_PAREN_HIGHLIGHT_DEPTH = 6
    RAINBOW_DELIMITERS_ENABLED = Ref(true)

    highlighted = Vector{Tuple{UnitRange{Int}, Union{Nothing,Symbol}}}()
    lastk = K"None"
    last2k = K"None"
    parendepth, bracketdepth, curlydepth = 0, 0, 0
    for (; head::JuliaSyntax.SyntaxHead, range::UnitRange{UInt32}) in tokens
        kind = head.kind
        face = if kind == K"Identifier"
            if lastk == K":" && !JuliaSyntax.is_number(last2k) &&
                last2k ∉ (K"Identifier", K")", K"]", K"end", K"'")
                highlighted[end] = (highlighted[end][1], :julia_symbol)
                :julia_symbol
            elseif lastk == K"::"; :julia_type
            else :julia_identifier end
        elseif kind == K"@"; :julia_macro
        elseif kind == K"MacroName"; :julia_macro
        elseif kind == K"StringMacroName"; :julia_macro
        elseif kind == K"CmdMacroName"; :julia_macro
        elseif kind == K"::"; :julia_type
        # elseif kind == K"nothing"; :julia_nothing
        elseif kind == K"Comment"; :julia_comment
        elseif kind == K"String"; :julia_string
        elseif JuliaSyntax.is_string_delim(kind); :julia_string_delim
        elseif kind == K"CmdString"; :julia_cmdstring
        elseif kind == K"`" || kind == K"```"; :julia_cmdstring
        elseif kind == K"Char"
            lastk == K"'" &&
                (highlighted[end] = (highlighted[end][1], :julia_char_delim))
            :julia_char
        elseif kind == K"'" && lastk == K"Char"; :julia_char_delim
        elseif kind == K"true" || kind == K"false"; :julia_bool
        elseif JuliaSyntax.is_number(kind); :julia_number
        elseif JuliaSyntax.is_prec_assignment(kind); :julia_assignment
        elseif JuliaSyntax.is_prec_comparison(kind); :julia_comparison
        elseif JuliaSyntax.is_operator(kind); :julia_operator
        elseif JuliaSyntax.is_keyword(kind); :julia_keyword
        elseif JuliaSyntax.is_error(kind); :julia_error
        elseif !RAINBOW_DELIMITERS_ENABLED[] && kind == K"("
            lastk == K"Identifier" &&
                (highlighted[end] = (highlighted[end][1], :julia_funcall))
            :julia_parenthetial
        elseif !RAINBOW_DELIMITERS_ENABLED[] && kind in (K")", K"[", K"]", K"{", K"}")
            :julia_parenthetial
        elseif kind == K"("
            lastk == K"Identifier" &&
                (highlighted[end] = (highlighted[end][1], :julia_funcall))
            name = Symbol("julia_rainbow_paren_$(parendepth+1)")
            parendepth = mod(parendepth + 1, MAX_PAREN_HIGHLIGHT_DEPTH)
            name
        elseif kind == K")"
            parendepth = mod(parendepth - 1, MAX_PAREN_HIGHLIGHT_DEPTH)
            Symbol("julia_rainbow_paren_$(parendepth+1)")
        elseif kind == K"["
            name = Symbol("julia_rainbow_bracket_$(bracketdepth+1)")
            bracketdepth = mod(bracketdepth + 1, MAX_PAREN_HIGHLIGHT_DEPTH)
            name
        elseif kind == K"]"
            bracketdepth = mod(bracketdepth - 1, MAX_PAREN_HIGHLIGHT_DEPTH)
            Symbol("julia_rainbow_bracket_$(bracketdepth+1)")
        elseif kind == K"{"
            name = Symbol("julia_rainbow_curly_$(curlydepth+1)")
            curlydepth = mod(curlydepth + 1, MAX_PAREN_HIGHLIGHT_DEPTH)
            name
        elseif kind == K"}"
            curlydepth = mod(curlydepth - 1, MAX_PAREN_HIGHLIGHT_DEPTH)
            Symbol("julia_rainbow_curly_$(curlydepth+1)")
        end
        push!(highlighted, (range, face))
        last2k, lastk = lastk, kind
    end
    highlighted
end