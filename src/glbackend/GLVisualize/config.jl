"""
default returns common defaults for a certain style and datatype.
This is convenient, to quickly switch out default styles.
"""
default(::T, s::Style=Style{:default}()) where {T} = default(T, s)

function default(::Type{T}, s::Style=Style{:default}(), index=1) where T <: Colorant
    color_defaults = RGBA{Float32}[
    	RGBA{Float32}(0.0f0,0.74736935f0,1.0f0,1.0f0),
    	RGBA{Float32}(0.78, 0.01, 0.93, 1.0),
    	RGBA{Float32}(0, 0, 0, 1.0),
    	RGBA{Float32}(0.78, 0.01, 0, 1.0)
    ]
    index > length(color_defaults) && error("There are only three color defaults.")
    color_defaults[index]
end
function default(::Type{Vector{T}}, s::Style = Style{:default}()) where T <: Colorant
    map(RGBA{N0f8}, colormap("Blues", 7))
end
