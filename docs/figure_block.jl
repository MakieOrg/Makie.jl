abstract type FigureBlocks <: Documenter.Expanders.NestedExpanderPipeline end


Documenter.Selectors.order(::Type{FigureBlocks})  = 8.0 # like @example
Documenter.Selectors.matcher(::Type{FigureBlocks},  node, page, doc) = Documenter.iscode(node, r"^@figure")

module MakieDocsHelpers
    struct AsMIME{M<:MIME,V}
        mime::M
        value::V
    end

    Base.show(io::IO, m::MIME"image/svg+xml", a::AsMIME{MIME"image/svg+xml"}) = show(io,m, a.value)
    Base.show(io::IO, m::MIME"image/png", a::AsMIME{MIME"image/png"}) = show(io,m, a.value)
end

function Documenter.Selectors.runner(::Type{FigureBlocks}, node, page, doc)
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
    kwargs = Dict(map(kwargs) do expr
        if !(expr isa Expr) && expr.head !== :(=) && length(expr.args) == 2 && expr.args[1] isa Symbol && expr.args[2] isa Union{String,Number,Symbol}
            error("Invalid keyword arg expression: $expr")
        end
        expr.args[1] => expr.args[2]
    end)
    el.info = "@example $blockname"
    el.code = transform_figure_code(el.code; kwargs...)
    Documenter.Selectors.runner(Documenter.Expanders.ExampleBlocks, node, page, doc)
end

function transform_figure_code(code::String; backend::Symbol = :CairoMakie, mime=backend==:CairoMakie ? "svg" : "png")
    backend in (:CairoMakie, :GLMakie) || error("Invalid backend $backend")
    mimetype = mime == "svg" ? "image/svg+xml" : mime == "png" ? "image/png" : error("Unknown mimetype $mime")
    """
    using $backend
    $backend.activate!() # hide
    import ..MakieDocsHelpers # hide
    var"#result" = begin # hide
    $code
    end # hide
    MakieDocsHelpers.AsMIME(MIME"$mimetype"(), var"#result") # hide
    """
end