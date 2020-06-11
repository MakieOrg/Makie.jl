# Proxy GLAbstraction Textures to allow configuration thereof
struct Texture
    img::Array{RGBAf0, 2}
    data::Dict{Symbol, Any}
end

Texture(img; kwargs...) = Texture(img, Dict{Symbol, Any}(kwargs))
