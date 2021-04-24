struct Key{K} end
macro key_str(arg)
    :(Key{$(QuoteNode(Symbol(arg)))})
end
Base.broadcastable(x::Key) = (x,)
Key(x::Symbol) = Key{x}()

function convert_attribute(::Type{P}, key, arg) where P
    return convert_attribute(key, arg)
end

convert_attribute(key, x) = x

convert_attribute(::key"strokecolor", c) = convert_attribute(Key(:color), c)
convert_attribute(::key"color", c::Colorant) = convert(RGBAf0, c)
convert_attribute(k::key"color", c::Symbol) = convert_attribute(k, string(c))

function convert_attribute(::key"color", c::String)
    return parse(RGBA{Float32}, c)
end

function convert_arguments(::Type{P}, args...) where P
    return args[1]
end
