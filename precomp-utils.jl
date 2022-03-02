using Base: UUID, PkgId, require

macro import(name, uuid)
    qname = QuoteNode(name)
    return quote
        if !isdefined(@__MODULE__, $(qname))
            const $(name) = require(PkgId($uuid, $(string(name))))
        end
    end
end

macro precompile(args)
    return quote
        try
            precompile($(args))
        catch e
            println("Could not precompile: ", $(string(args)))
        end
    end
end
